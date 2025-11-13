
// ---------- helper functions ----------
function indent(n){ let s=""; for (let i=0;i<n;i++) s+=" "; return s; }
function writeln(lines, ind, txt){ push(lines, indent(ind)+txt); }
function find_key_in_object(o,k){ if (type(o)!="object") return false; for (let kk in keys(o)) if (kk==k) return true; return false; }

function split_cidr(cidr){
    if (type(cidr)!="string") return null;
    let p = split(cidr, "/"); if (length(p)!=2) return null; return p; // ["a.b.c.d","p"]
}
function ip_to_tuple(ip){
    let parts = split(ip, "."); if (length(parts)!=4) return null;
    let t=[]; for (let i=0;i<4;i++){ let n=int(parts[i]); if (n<0||n>255) return null; push(t,n); }
    return t;
}
function tuple_to_ip(t){ return sprintf("%d.%d.%d.%d", t[0],t[1],t[2],t[3]); }
function tuple_to_int(t){ return ((t[0]&255)<<24)|((t[1]&255)<<16)|((t[2]&255)<<8)|(t[3]&255); }
function int_to_tuple(n){ n = n & 0xFFFFFFFF; return [ (n>>24)&255, (n>>16)&255, (n>>8)&255, n&255 ]; }
function prefix_to_mask(p){ p=int(p); if(p<0)p=0; if(p>32)p=32; return p==0?0:((0xFFFFFFFF<<(32-p))&0xFFFFFFFF); }
function host_ip(cidr){ let parts=split_cidr(cidr); return parts?parts[0]:null; }
function cidr_prefix(cidr){ let parts=split_cidr(cidr); return parts?int(parts[1]):null; }
function add_host(ip, add){
    let t=ip_to_tuple(ip); if(!t) return null;
    let n=tuple_to_int(t); n=(n+add)&0xFFFFFFFF;
    return tuple_to_ip(int_to_tuple(n));
}
function derive_network_base(cidr){
    let parts=split_cidr(cidr); if(!parts) return null;
    let ipt=ip_to_tuple(parts[0]); if(!ipt) return null;
    let p=int(parts[1]); let mask=prefix_to_mask(p);
    let ipn=tuple_to_int(ipt); let netn=ipn&mask; let nett=int_to_tuple(netn);
    return [ tuple_to_ip(nett)+"/"+p, parts[1], tuple_to_ip(nett), netn, p ];
}

function convert_hours_to_seconds(s, def){
    if (type(s)=="number") return int(s);
    if (type(s)!="string") return def;
    let m = match(s, /^([0-9]+)\s*([smhd])$/);
    if (!m){ let n=int(s); return n>0?n:def; }
    let n=int(m[1]), u=m[2];
    if(u=="s") return n;
    if(u=="m") return n*60;
    if(u=="h") return n*3600;
    if(u=="d") return n*86400;
    return def;
}

function json_config_ctx(){
    return {
        wan:  { ifname:"eth0", name:null, present:false, addressing:null },
        lans: [], // { ifname, name, addressing, cidr, dhcp }
        svc:  { ssh_port:22 }
    };
}
function next_lan_ifname(ctx){ return sprintf("eth%d", 1 + length(ctx.lans)); }

function prepare_json_config_ctx(uCentral_config){
    let ctx = json_config_ctx();

    if (type(uCentral_config.interfaces) == "array") {
        for (let i = 0; i < length(uCentral_config.interfaces); i++) {
            let iface = uCentral_config.interfaces[i];
            let ip4   = iface.ipv4;

            /* Detect WAN (upstream) */
            if (iface.role == "upstream" && !ctx.wan.present) {
                ctx.wan.present    = true;
                ctx.wan.name       = iface.name || "WAN";
                ctx.wan.addressing = (type(ip4) == "object") ? ip4.addressing : null;
            }

            /* Collect LANs (downstream) */
            if (iface.role == "downstream") {
                let lan = {
                    ifname:     next_lan_ifname(ctx),
                    name:       iface.name || sprintf("LAN%d", 1 + length(ctx.lans)),
                    addressing: (type(ip4) == "object") ? ip4.addressing : null,
                    cidr:       (type(ip4) == "object" && find_key_in_object(ip4, "subnet")) ? ip4.subnet : null,
                    dhcp:       (type(ip4) == "object" && find_key_in_object(ip4, "dhcp"))   ? ip4.dhcp   : null
                };
                push(ctx.lans, lan);
            }
        }
    }


    if (type(uCentral_config.services)=="object" && type(uCentral_config.services.ssh)=="object" && find_key_in_object(uCentral_config.services.ssh,"port"))
        ctx.svc.ssh_port = int(uCentral_config.services.ssh.port);

    return ctx;
}

function set_vyos_interfaces(lines, ctx){
    writeln(lines, 0, "interfaces {");

    if (ctx.wan.present){
        writeln(lines, 4, sprintf("ethernet %s {", ctx.wan.ifname));
        if (ctx.wan.addressing == "dynamic")
            writeln(lines, 8, "address dhcp");
        if (ctx.wan.name)
            writeln(lines, 8, sprintf("description %s", ctx.wan.name));
        writeln(lines, 4, "}");
    }

    for (let i=0;i<length(ctx.lans);i++){
        let lan = ctx.lans[i];
        writeln(lines, 4, sprintf("ethernet %s {", lan.ifname));
        if (lan.addressing == "dynamic")
            writeln(lines, 8, "address dhcp");
        else if (lan.addressing == "static" && lan.cidr)
            writeln(lines, 8, sprintf("address %s", lan.cidr));
        if (lan.name)
            writeln(lines, 8, sprintf("description %s", lan.name));
        writeln(lines, 4, "}");
    }

    writeln(lines, 0, "}");
}

function set_vyos_nat(lines, ctx){
    if (!ctx.wan.present || !ctx.wan.ifname) return;

    let nets = [];
    for (let i=0;i<length(ctx.lans);i++){
        let lan = ctx.lans[i];
        if (lan.addressing == "static" && lan.cidr){
            let net = derive_network_base(lan.cidr);
            if (net) push(nets, net);
        }
    }
    if (length(nets) == 0) return;

    writeln(lines, 0, "nat {");
    writeln(lines, 4, "source {");

    for (let i=0;i<length(nets);i++){
        let rule = 100 + i;
        writeln(lines, 8, sprintf("rule %d {", rule));
        writeln(lines, 12, "outbound-interface {");
        writeln(lines, 16, sprintf("name %s", ctx.wan.ifname));
        writeln(lines, 12, "}");
        writeln(lines, 12, "source {");
        writeln(lines, 16, sprintf("address %s", nets[i][0]));
        writeln(lines, 12, "}");
        writeln(lines, 12, "translation {");
        writeln(lines, 16, "address masquerade");
        writeln(lines, 12, "}");
        writeln(lines, 8, "}");
    }

    writeln(lines, 4, "}");
    writeln(lines, 0, "}");
}

function set_vyos_service(lines, ctx){
    let slans = [];
    for (let i=0;i<length(ctx.lans);i++){
        let lan = ctx.lans[i];
        if (lan.addressing == "static" && lan.cidr){
            let net = derive_network_base(lan.cidr); if (!net) continue;
            push(slans, {
                name:    lan.name,
                lan_ip:  host_ip(lan.cidr),
                net_cidr:net[0],
                net_ip:  net[2],
                net_int: net[3],
                pfx:     net[4],
                dhcp:    lan.dhcp
            });
        }
    }

    writeln(lines, 0, "service {");

    if (length(slans) > 0){
        writeln(lines, 4, "dhcp-server {");
        for (let i=0;i<length(slans);i++){
            let L = slans[i];

            // Defaults
            let lease_secs = 86400; // 1 day
            let start_ip = null, stop_ip = null;

            // Pull from DHCP object if provided
            if (type(L.dhcp)=="object"){
                if (find_key_in_object(L.dhcp,"lease-time"))
                    lease_secs = convert_hours_to_seconds(L.dhcp["lease-time"], lease_secs);

                if (find_key_in_object(L.dhcp,"lease-first")){
                    let first = int(L.dhcp["lease-first"]); if (first < 1) first = 1;
                    start_ip = add_host(L.net_ip, first);
                }

                if (find_key_in_object(L.dhcp,"lease-count") && start_ip){
                    let count = int(L.dhcp["lease-count"]); if (count < 1) count = 1;
                    let size = 1 << (32 - L.pfx);
                    let last_host_int = (L.net_int + size - 2) & 0xFFFFFFFF;
                    let start_int = tuple_to_int(ip_to_tuple(start_ip));
                    let stop_by_count = (start_int + (count - 1)) & 0xFFFFFFFF;
                    if (stop_by_count > last_host_int) stop_by_count = last_host_int;
                    stop_ip = tuple_to_ip(int_to_tuple(stop_by_count));
                }
            }

            if (!start_ip) start_ip = (L.pfx==24) ? add_host(L.net_ip, 9)  : add_host(L.net_ip, 10);
            if (!stop_ip)  stop_ip  = (L.pfx==24) ? add_host(L.net_ip,254) : add_host(L.net_ip,200);

            writeln(lines, 8, sprintf("shared-network-name %s {", L.name));
            writeln(lines, 12, sprintf("subnet %s {", L.net_cidr));
            writeln(lines, 16, sprintf("lease %d", lease_secs));
            writeln(lines, 16, "option {");
            writeln(lines, 20, sprintf("default-router %s", L.lan_ip));
            writeln(lines, 20, "domain-name vyos.net");
            writeln(lines, 20, sprintf("name-server %s", L.lan_ip));
            writeln(lines, 16, "}");
            writeln(lines, 16, "range 0 {");
            writeln(lines, 20, sprintf("start %s", start_ip));
            writeln(lines, 20, sprintf("stop %s",  stop_ip));
            writeln(lines, 16, "}");
            writeln(lines, 16, "subnet-id 1");
            writeln(lines, 12, "}");
            writeln(lines, 8, "}");
        }
        writeln(lines, 4, "}");
    }

    if (length(slans) > 0){
        writeln(lines, 4, "dns {");
        writeln(lines, 8, "forwarding {");
        for (let i=0;i<length(slans);i++)
            writeln(lines, 12, sprintf("allow-from %s", slans[i].net_cidr));
        writeln(lines, 12, "cache-size 0");
        for (let i=0;i<length(slans);i++)
            writeln(lines, 12, sprintf("listen-address %s", slans[i].lan_ip));
        writeln(lines, 8, "}");
        writeln(lines, 4, "}");
    }

    writeln(lines, 4, "ssh {");
    writeln(lines, 8, sprintf("port %d", ctx.svc.ssh_port));
    writeln(lines, 4, "}");

    writeln(lines, 0, "}");
}

function render_vyos_from_json(uCentral_config){
    /* parse the ucentral config and update the internal structures */
    let json_conf_ctx = prepare_json_config_ctx(uCentral_config);
    let vyos_text_config = [];
    /* update interface section from internal format to vyos format */
    set_vyos_interfaces(vyos_text_config, json_conf_ctx);
    set_vyos_nat(vyos_text_config, json_conf_ctx);
    set_vyos_service(vyos_text_config, json_conf_ctx);
    return join("\n", vyos_text_config) + "\n";
}

return {
    convertvyos: (uCentral_config, errors) => render_vyos_from_json(uCentral_config)
};

