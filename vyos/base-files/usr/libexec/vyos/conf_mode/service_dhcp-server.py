#!/usr/bin/env python3
# GPL-2.0-or-later — VyOS DHCP conf-mode with dynamic Kea shaping
#
# Adds:
# - interfaces_list: ["eth1/<LAN ip from subnet-id 1>"] (template uses RAW sockets)
# - client-classes from subnet-id (!=1) using Opt82 circuit-id hex match
# - shared-networks list (with per-shared-network relay from file)
# - numeric normalization for ids/lifetimes
# - optional HA/DDNS passthrough (stock behavior)
#
# Relay IPs are loaded at runtime from /etc/vyos/kea-relays.json
# Accepted formats:
#   {"10": "192.168.50.10"}
#   {"10": ["192.168.50.10", "192.168.50.11"]}
#   {"relay_map": {"10": ["192.168.50.10"], "20": "192.168.50.10"}}

import os
import json
from sys import exit, argv
from glob import glob
from ipaddress import ip_address, ip_network
from netaddr import IPRange

from vyos.config import Config
from vyos.pki import wrap_certificate, wrap_private_key
from vyos.template import render
from vyos.utils.dict import dict_search, dict_search_args
from vyos.utils.file import chmod_775, makedir, write_file
from vyos.utils.permission import chown
from vyos.utils.process import call
from vyos.utils.network import interface_exists, is_subnet_connected, is_addr_assigned
from vyos import ConfigError, airbag

airbag.enable()

# ---------- constants / globals ----------
RELAYS_FILE = "/etc/vyos/kea-relays.json"

ctrl_socket = ''
config_file = ''
config_file_d2 = ''
lease_file = ''
lease_file_glob = ''

ca_cert_file = ''
cert_file = ''
cert_key_file = ''

user_group = '_kea'


# ---------- small helpers ----------
def _to_int(val):
    if isinstance(val, int):
        return val
    if isinstance(val, str) and val.isdigit():
        try:
            return int(val)
        except Exception:
            return val
    return val


def _normalize_numeric(dhcp: dict):
    for _, ncfg in (dhcp.get('shared_network_name') or {}).items():
        for _, scfg in (ncfg.get('subnet') or {}).items():
            if 'subnet_id' in scfg:
                scfg['subnet_id'] = _to_int(scfg['subnet_id'])
            if 'lease' in scfg:
                scfg['lease'] = _to_int(scfg['lease'])


def _first_host(cidr: str):
    try:
        net = ip_network(cidr, strict=False)
        return str(next(net.hosts()))
    except Exception:
        return None


def _ascii_hex(s: str) -> str:
    return ''.join(f'{ord(c):02x}' for c in s)


def _opt82_cid_test(val: str) -> str:
    # circuit-id equals ascii digits, e.g. "10" => 0x3130
    return f'option[82].option[1].hex == 0x{_ascii_hex(val)}'


def _maybe_stringify_singleton(v):
    # turn ["1.2.3.4"] into "1.2.3.4" for nicer JSON where single values are expected
    if isinstance(v, list) and len(v) == 1:
        return v[0]
    return v


def _load_relay_map(path: str = RELAYS_FILE) -> dict[int, list[str]]:
    """
    Load relay agent IPs from JSON.
    Accepts any of these shapes:
      {"10": "192.168.50.10"}
      {"10": ["192.168.50.10", "192.168.50.11"]}
      {"relay_map": {"10": ["192.168.50.10"], "20": "192.168.50.10"}}
    Keys may be strings or ints. Values may be string or list of strings.
    Only valid IPv4 addresses are kept.
    """
    try:
        with open(path, "r") as f:
            data = json.load(f)
    except FileNotFoundError:
        return {}
    except Exception:
        return {}

    if isinstance(data, dict) and "relay_map" in data and isinstance(data["relay_map"], dict):
        data = data["relay_map"]

    out: dict[int, list[str]] = {}
    if not isinstance(data, dict):
        return out

    for k, v in data.items():
        try:
            sid = int(k)
        except Exception:
            continue

        ips = v if isinstance(v, list) else [v]
        cleaned = []
        for ip in ips:
            try:
                s = str(ip_address(str(ip)))
                if ":" not in s:  # keep only IPv4
                    cleaned.append(s)
            except Exception:
                pass
        if cleaned:
            # dedupe while preserving order
            seen = set()
            uniq = []
            for ip in cleaned:
                if ip not in seen:
                    seen.add(ip)
                    uniq.append(ip)
            out[sid] = uniq
    return out


def _override_for_vrf(vrf_name):
    global ctrl_socket, config_file, config_file_d2, lease_file, lease_file_glob
    global ca_cert_file, cert_file, cert_key_file

    ctrl_socket = f'/run/kea/dhcp4-{vrf_name}-ctrl-socket'
    config_file = f'/run/kea/kea-{vrf_name}-dhcp4.conf'
    config_file_d2 = f'/run/kea/kea-{vrf_name}-dhcp-ddns.conf'
    lease_file = f'/config/dhcp/dhcp4-{vrf_name}-leases.csv'
    lease_file_glob = f'/config/dhcp/dhcp4-{vrf_name}-leases*'

    ca_cert_file = f'/run/kea/kea-{vrf_name}-failover-ca.pem'
    cert_file = f'/run/kea/kea-{vrf_name}-failover.pem'
    cert_key_file = f'/run/kea/kea-{vrf_name}-failover-key.pem'


def _reset_vars():
    global ctrl_socket, config_file, config_file_d2, lease_file, lease_file_glob
    global ca_cert_file, cert_file, cert_key_file

    ctrl_socket = '/run/kea/dhcp4-ctrl-socket'
    config_file = '/run/kea/kea-dhcp4.conf'
    config_file_d2 = '/run/kea/kea-dhcp-ddns.conf'
    lease_file = '/config/dhcp/dhcp4-leases.csv'
    lease_file_glob = '/config/dhcp/dhcp4-leases*'

    ca_cert_file = '/run/kea/kea-failover-ca.pem'
    cert_file = '/run/kea/kea-failover.pem'
    cert_key_file = '/run/kea/kea-failover-key.pem'


def dhcp_slice_range(exclude_list, range_dict):
    """
    Slice a DHCP range by removing excluded IPs.
    """
    output = []
    exclude_list = sorted(exclude_list)
    range_start = range_dict['start']
    range_stop = range_dict['stop']
    range_last_exclude = ''

    for e in exclude_list:
        if ip_address(range_start) <= ip_address(e) <= ip_address(range_stop):
            range_last_exclude = e

    for e in exclude_list:
        if ip_address(range_start) <= ip_address(e) <= ip_address(range_stop):
            r = {'start': range_start, 'stop': str(ip_address(e) - 1)}
            if 'option' in range_dict:
                r['option'] = range_dict['option']
            range_start = str(ip_address(e) + 1)
            if not (ip_address(r['start']) > ip_address(r['stop'])):
                output.append(r)
            if ip_address(e) == ip_address(range_last_exclude):
                r = {'start': str(ip_address(e) + 1), 'stop': str(range_stop)}
                if 'option' in range_dict:
                    r['option'] = range_dict['option']
                if not (ip_address(r['start']) > ip_address(r['stop'])):
                    output.append(r)
        else:
            if not range_last_exclude and range_dict not in output:
                output.append(range_dict)
    return output


# ---------- get/verify/generate/apply ----------
def get_config(config=None):
    conf = config or Config()

    # VRF awareness
    if argv and len(argv) > 1:
        vrf_name = argv[1]
        base = ['vrf', 'name', vrf_name, 'service', 'dhcp-server']
        _override_for_vrf(vrf_name)
    else:
        base = ['service', 'dhcp-server']
        _reset_vars()

    if not conf.exists(base):
        return None

    dhcp = conf.get_config_dict(
        base,
        key_mangling=('-', '_'),
        no_tag_node_value_mangle=True,
        get_first_key=True,
        with_recursive_defaults=True,
    )

    # annotate VRF in template inputs
    if argv and len(argv) > 1:
        dhcp['vrf_context'] = argv[1]

    # stock behavior: slice ranges if exclude is present
    if 'shared_network_name' in dhcp:
        for network, network_config in dhcp['shared_network_name'].items():
            if 'subnet' in network_config:
                for subnet, subnet_config in network_config['subnet'].items():
                    if {'exclude', 'range'} <= set(subnet_config):
                        new_range_id = 0
                        new_range_dict = {}
                        for _, r_config in subnet_config['range'].items():
                            for sl in dhcp_slice_range(subnet_config['exclude'], r_config):
                                new_range_dict.update({new_range_id: sl})
                                new_range_id += 1
                        dhcp['shared_network_name'][network]['subnet'][subnet]['range'] = new_range_dict

    # ---- our shaping starts here ----
    # (1) normalize numeric types
    _normalize_numeric(dhcp)

    # (2) derive interfaces_list from LAN (subnet-id == 1) -> force "eth1/<ip>"
    lan_ip = None
    for _, ncfg in (dhcp.get('shared_network_name') or {}).items():
        for cidr, scfg in (ncfg.get('subnet') or {}).items():
            if scfg.get('subnet_id') == 1:
                dr = (scfg.get('option') or {}).get('default_router')
                lan_ip = dr or _first_host(cidr)
                if lan_ip:
                    break
        if lan_ip:
            break
    if lan_ip:
        dhcp['interfaces_list'] = [f'eth1/{lan_ip}']

    # (3) build client-classes from every subnet-id != 1
    sids = set()
    for _, ncfg in (dhcp.get('shared_network_name') or {}).items():
        for _, scfg in (ncfg.get('subnet') or {}).items():
            sid = scfg.get('subnet_id')
            if isinstance(sid, int) and sid != 1:
                sids.add(sid)
    if sids:
        dhcp['client_classes'] = [{"name": f"vlan{sid}", "test": _opt82_cid_test(str(sid))} for sid in sorted(sids)]

    # (4) convert shared_network_name → shared-networks (attach relay per shared-network from file)
    relay_map = _load_relay_map()
    shared = []
    for net_name, ncfg in (dhcp.get('shared_network_name') or {}).items():
        sn = {'name': net_name, 'authoritative': False, 'subnet4': [], 'user-context': {}}
        non_lan = False
        relay_accum = []

        for cidr, scfg in (ncfg.get('subnet') or {}).items():
            sid = scfg.get('subnet_id')
            sub = {'subnet': cidr, 'id': sid, 'user-context': {}}

            # lifetimes: use per-subnet lease if present, else default 86400
            lease = scfg.get('lease', 86400)
            if isinstance(lease, int) and lease > 0:
                sub['valid-lifetime'] = lease
                sub['max-valid-lifetime'] = lease

            # option-data (dns, domain, routers)
            opt = scfg.get('option') or {}
            od = []
            if 'name_server' in opt:
                od.append({'name': 'domain-name-servers', 'data': _maybe_stringify_singleton(opt['name_server'])})
            if 'domain_name' in opt:
                od.append({'name': 'domain-name', 'data': opt['domain_name']})
            if 'default_router' in opt:
                od.append({'name': 'routers', 'data': opt['default_router']})
            if od:
                sub['option-data'] = od

            # client-class for non-LAN
            if isinstance(sid, int) and sid != 1:
                sub['client-class'] = f'vlan{sid}'
                non_lan = True
                # collect relay IPs for this SID from file
                if sid in relay_map:
                    relay_accum.extend(relay_map[sid])

            # pools from ranges
            pools = []
            for _, rc in (scfg.get('range') or {}).items():
                if 'start' in rc and 'stop' in rc:
                    pools.append({'pool': f"{rc['start']} - {rc['stop']}"})
            if pools:
                sub['pools'] = pools

            sn['subnet4'].append(sub)

        # attach relay only if non-LAN and we have any IPs
        if non_lan:
            seen = set()
            uniq = []
            for ip in relay_accum:
                if ip not in seen:
                    seen.add(ip)
                    uniq.append(ip)
            if uniq:
                sn['relay'] = {"ip-addresses": uniq}

        shared.append(sn)

    dhcp['shared_networks'] = shared
    dhcp['machine'] = os.uname().machine  # for hooks path in template
    dhcp['lease_file'] = lease_file       # for memfile path in template
    # ---- end shaping ----

    # stock HA passthrough
    if len(dhcp.get('high_availability', {})) == 1:
        del dhcp['high_availability']
    else:
        if dict_search('high_availability.certificate', dhcp):
            dhcp['pki'] = conf.get_config_dict(
                ['pki'],
                key_mangling=('-', '_'),
                get_first_key=True,
                no_tag_node_value_mangle=True,
            )

    return dhcp


def verify_ddns_domain_servers(domain_type, domain):
    if 'dns_server' in domain:
        invalid_servers = []
        for server_no, server_config in domain['dns_server'].items():
            if 'address' not in server_config:
                invalid_servers.append(server_no)
        if len(invalid_servers) > 0:
            raise ConfigError(f'{domain_type} DNS servers {", ".join(invalid_servers)} in DDNS configuration need to have an IP address')
    return None


def verify(dhcp):
    # bail out early - looks like removal from running config
    if not dhcp or 'disable' in dhcp:
        return None

    # must have at least one shared-network
    if 'shared_network_name' not in dhcp:
        raise ConfigError(
            'No DHCP shared networks configured.\n'
            'At least one DHCP shared network must be configured.'
        )

    listen_ok = False
    subnets = []
    shared_networks = len(dhcp['shared_network_name'])
    disabled_shared_networks = 0
    subnet_ids = []

    for network, network_config in dhcp['shared_network_name'].items():
        if 'disable' in network_config:
            disabled_shared_networks += 1

        if 'subnet' not in network_config:
            raise ConfigError(
                f'No subnets defined for {network}. At least one\n'
                'lease subnet must be configured.'
            )

        for subnet, subnet_config in network_config['subnet'].items():
            if 'subnet_id' not in subnet_config:
                raise ConfigError(f'Unique subnet ID not specified for subnet "{subnet}"')

            if subnet_config['subnet_id'] in subnet_ids:
                raise ConfigError(f'Subnet ID for subnet "{subnet}" is not unique')
            subnet_ids.append(subnet_config['subnet_id'])

            # static-route sanity (stock)
            if 'static_route' in subnet_config:
                for route, route_option in subnet_config['static_route'].items():
                    if 'next_hop' not in route_option:
                        raise ConfigError(f'DHCP static-route "{route}" requires router to be defined!')

            # ranges sanity
            if 'range' in subnet_config:
                networks = []
                for range_name, range_config in subnet_config['range'].items():
                    if not {'start', 'stop'} <= set(range_config):
                        raise ConfigError(f'DHCP range "{range_name}" start and stop address must be defined!')
                    for key in ['start', 'stop']:
                        if ip_address(range_config[key]) not in ip_network(subnet):
                            raise ConfigError(
                                f'DHCP range "{range_name}" {key} address not within shared-network "{network}, {subnet}"!'
                            )
                    if ip_address(range_config['stop']) < ip_address(range_config['start']):
                        raise ConfigError(
                            f'DHCP range "{range_name}" stop address must be greater or equal to the start address!'
                        )

                    tmp = IPRange(range_config['start'], range_config['stop'])
                    for net in networks:
                        # IPRange supports 'in' checks
                        if range_config['start'] in net or range_config['stop'] in net:
                            raise ConfigError(f'Overlapping ranges in "{subnet}"')
                    networks.append(tmp)

            # exclude sanity
            if 'exclude' in subnet_config:
                for exclude in subnet_config['exclude']:
                    if ip_address(exclude) not in ip_network(subnet):
                        raise ConfigError(
                            f'Excluded IP address "{exclude}" not within shared-network "{network}, {subnet}"!'
                        )

            # require pool or static_mapping
            if 'range' not in subnet_config and 'static_mapping' not in subnet_config:
                raise ConfigError(
                    f'No DHCP address range or active static-mapping configured within shared-network "{network}, {subnet}"!'
                )

            # listen_ok if any subnet is connected and network not disabled
            if 'disable' not in network_config and is_subnet_connected(subnet, primary=False):
                listen_ok = True

            # uniqueness & overlap
            if subnet in subnets:
                raise ConfigError(f'Configured subnets must be unique! Subnet "{subnet}" defined multiple times!')
            subnets.append(subnet)

            net = ip_network(subnet)
            for n in subnets:
                n2 = ip_network(n)
                if net != n2 and net.overlaps(n2):
                    raise ConfigError(f'Conflicting subnet ranges: "{net}" overlaps "{n2}"!')

    # at least one shared-network active
    if (shared_networks - disabled_shared_networks) < 1:
        raise ConfigError('At least one shared network must be active!')

    # explicit listen-address check (optional in our flow)
    for address in dict_search('listen_address', dhcp) or []:
        if is_addr_assigned(address, include_vrf=True):
            listen_ok = True
        else:
            raise ConfigError(f'listen-address "{address}" not configured on any interface')

    if 'listen_address' in dhcp and 'listen_interface' in dhcp:
        raise ConfigError('Cannot define listen-address and listen-interface at the same time')

    for interface in dict_search('listen_interface', dhcp) or []:
        if not interface_exists(interface):
            raise ConfigError(f'listen-interface "{interface}" does not exist')

    if 'dynamic_dns_update' in dhcp:
        ddns = dhcp['dynamic_dns_update']
        if 'tsig_key' in ddns:
            invalid_keys = []
            for tsig_key_name, tsig_key_config in ddns['tsig_key'].items():
                if not ('algorithm' in tsig_key_config and 'secret' in tsig_key_config):
                    invalid_keys.append(tsig_key_name)
            if len(invalid_keys) > 0:
                raise ConfigError(f'Both algorithm and secret need to be set for TSIG keys: {", ".join(invalid_keys)}')

        if 'forward_domain' in ddns:
            verify_ddns_domain_servers('Forward', ddns['forward_domain'])

        if 'reverse_domain' in ddns:
            verify_ddns_domain_servers('Reverse', ddns['reverse_domain'])

    # If no listen_ok yet, Kea will still bind using RAW sockets via interfaces_list in template,
    # but we keep stock behavior: require at least one connected subnet or explicit listen-address.
    if not listen_ok:
        raise ConfigError(
            'None of the configured subnets have an appropriate primary IP address on any '
            'broadcast interface configured, nor was there an explicit listen-address '
            'configured for serving DHCP relay packets!'
        )

    return None


def generate(dhcp):
    if not dhcp or 'disable' in dhcp:
        return None

    dhcp['lease_file'] = lease_file
    dhcp['machine'] = os.uname().machine

    # ensure lease dir exists
    lease_dir = os.path.dirname(lease_file)
    if not os.path.isdir(lease_dir):
        makedir(lease_dir, group='vyattacfg')
        chmod_775(lease_dir)

    # adjust ownership on ledger files
    for file in glob(lease_file_glob):
        chown(file, user=user_group, group='vyattacfg')

    # ensure main lease file exists
    if not os.path.exists(lease_file):
        write_file(lease_file, '', user=user_group, group=user_group, mode=0o644)

    # clear any old HA cert/key paths
    for f in [cert_file, cert_key_file, ca_cert_file]:
        if os.path.exists(f):
            os.unlink(f)

    # write HA certs if configured
    if 'high_availability' in dhcp:
        if 'certificate' in dhcp['high_availability']:
            cert_name = dhcp['high_availability']['certificate']
            cert_data = dhcp['pki']['certificate'][cert_name]['certificate']
            key_data = dhcp['pki']['certificate'][cert_name]['private']['key']
            write_file(cert_file, wrap_certificate(cert_data), user=user_group, mode=0o600)
            write_file(cert_key_file, wrap_private_key(key_data), user=user_group, mode=0o600)
            dhcp['high_availability']['cert_file'] = cert_file
            dhcp['high_availability']['cert_key_file'] = cert_key_file

        if 'ca_certificate' in dhcp['high_availability']:
            ca_cert_name = dhcp['high_availability']['ca_certificate']
            ca_cert_data = dhcp['pki']['ca'][ca_cert_name]['certificate']
            write_file(ca_cert_file, wrap_certificate(ca_cert_data), user=user_group, mode=0o600)
            dhcp['high_availability']['ca_cert_file'] = ca_cert_file

    # render Kea configs
    render(config_file, 'dhcp-server/kea-dhcp4.conf.j2', dhcp, user=user_group, group=user_group)
    if 'dynamic_dns_update' in dhcp:
        render(config_file_d2, 'dhcp-server/kea-dhcp-ddns.conf.j2', dhcp, user=user_group, group=user_group)

    return None


def apply(dhcp):
    # VRF aware units
    if argv and len(argv) > 1:
        vrf_name = argv[1]
        services = [f'kea-dhcp4-server@{vrf_name}', f'kea-dhcp-ddns-server@{vrf_name}']
    else:
        services = ['kea-dhcp4-server', 'kea-dhcp-ddns-server']

    if not dhcp or 'disable' in dhcp:
        for service in services:
            call(f'systemctl stop {service}.service')
        if os.path.exists(config_file):
            os.unlink(config_file)
        return None

    for service in services:
        action = 'restart'
        if 'kea-dhcp-ddns-server' in service and 'dynamic_dns_update' not in dhcp:
            action = 'stop'
        call(f'systemctl {action} {service}.service')

    return None


if __name__ == '__main__':
    try:
        c = get_config()
        verify(c)
        generate(c)
        apply(c)
    except ConfigError as e:
        print(e)
        exit(1)

