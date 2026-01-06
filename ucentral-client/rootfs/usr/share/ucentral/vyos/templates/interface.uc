{%
let wans  = [];
let lans  = [];
let vlans = [];

if (type(config.interfaces) == "array") {
	for (let iface in config.interfaces) {
		if (iface.role == "upstream")
			push(wans, iface);
		else if (iface.role == "downstream" && type(iface.vlan) == "object")
			push(vlans, iface);
		else if (iface.role == "downstream" && type(iface.vlan) != "object")
			push(lans, iface);
	}
}

let vid_map = {};
for (let v in vlans) {
	let vid = (type(v.vlan) == "object") ? v.vlan.id : null;
	if (!vid) continue;
	vid_map["" + vid] = true;
}
let vlan_ids = sort(keys(vid_map));
let eth_used = {};
let next_br = 0;
%}

interfaces {
	{% for (let i = 0; i < length(wans); i++): %}
	{%
		let wan       = wans[i];
		let ipv4      = wan.ipv4;
		let addr_mode = ipv4 ? ipv4.addressing : null;
		let cidr      = (ipv4 && type(ipv4.subnet) == "string") ? ipv4.subnet : null;

		let bname = "br" + next_br;
		next_br++;

		let members = ethernet.lookup_by_interface_port(wan);
		ethernet.mark_eth1_used(members, eth_used);
	%}
	bridge {{ bname }} {
		{% if (addr_mode == "dynamic"): %}
		address dhcp
		{% elif (addr_mode == "static" && cidr): %}
		address {{ cidr }}
		{% endif %}

		{% if (wan.name): %}
		description {{ wan.name }}
		{% endif %}

		{% if (length(members)): %}
		member {
			{% for (let m in members): %}
			interface {{ m }} {
			}
			{% endfor %}
		}
		{% endif %}
	}
	{% endfor %}

	{% for (let i = 0; i < length(lans); i++): %}
	{%
		let lan       = lans[i];
		let ipv4      = lan.ipv4;
		let addr_mode = ipv4 ? ipv4.addressing : null;
		let cidr      = (ipv4 && type(ipv4.subnet) == "string") ? ipv4.subnet : null;

		let bname = "br" + next_br;
		next_br++;

		let members = ethernet.lookup_by_interface_port(lan);
		ethernet.mark_eth1_used(members, eth_used);
	%}
	bridge {{ bname }} {
		{% if (addr_mode == "dynamic"): %}
		address dhcp
		{% elif (addr_mode == "static" && cidr): %}
		address {{ cidr }}
		{% endif %}

		{% if (lan.name): %}
		description {{ lan.name }}
		{% endif %}

		enable-vlan

		{% if (length(members)): %}
		member {
			{% for (let m in members): %}
			interface {{ m }} {
				{% for (let vid in vlan_ids): %}
				allowed-vlan {{ vid }}
				{% endfor %}
				native-vlan 1
			}
			{% endfor %}
		}
		{% endif %}

		{% for (let v in vlans): %}
			{% if (type(v.vlan) == "object" && v.vlan.id && type(v.ipv4) == "object" && type(v.ipv4.subnet) == "string"): %}
		vif {{ v.vlan.id }} {
			address {{ v.ipv4.subnet }}
			{% if (v.name): %}
			description {{ v.name }}
			{% else %}
			description VLAN{{ v.vlan.id }}
			{% endif %}
		}
			{% endif %}
		{% endfor %}
	}
	{% endfor %}

	{%
		let eth_list = sort(keys(eth_used));
	%}
	{% for (let e in eth_list): %}
	ethernet {{ e }} {
	}
	{% endfor %}
}
