{%
let eth_used = {};
let upstream_assigned = false;
// All other bridges start from br1
let next_br_index = 1;
%}

interfaces {
	{% if (type(config.interfaces) == "array"): %}
		{% for (let iface in config.interfaces): %}
			{%
				// Skip VLAN sub-interfaces here; they are rendered as VIFs under the downstream bridge
				if (type(iface?.vlan) == "object")
					continue;

				if (iface?.role != "upstream" && iface?.role != "downstream")
					continue;

				let role = iface.role;
				let bname;

				if (role == "upstream" && !upstream_assigned) {
					bname = ethernet.upstream_bridge_name();
					upstream_assigned = true;
				}
				else {
					bname = ethernet.calculate_next_bridge_name(next_br_index);
					next_br_index++;
				}

				let members = ethernet.lookup_interface_by_port(iface);
				ethernet.mark_eth_used(members, eth_used);
			%}

{{ include('interface/bridge.uc', { config, role, bname, iface, members }) }}

		{% endfor %}
	{% endif %}

	{%
		let eth_list = sort(keys(eth_used));
	%}
{{ include('interface/ethernet.uc', { eth_list }) }}
}
