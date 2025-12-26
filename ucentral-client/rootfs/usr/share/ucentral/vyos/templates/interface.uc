{%
    let wan  = null;
    let lan  = null;
    let vlans = [];

    if (type(config.interfaces) == "array") {
        for (let iface in config.interfaces) {
            if (iface.role == "upstream" && !wan)
                wan = iface;
            else if (iface.role == "downstream" && type(iface.vlan) == "object")
                push(vlans, iface);
	    else if (iface.role == "downstream" && type(iface.vlan) != "object" && !lan)
		lan = iface;
        }
    }
%}

interfaces {
    {% if (wan): %}
    {%
        let ipv4      = wan.ipv4;
        let addr_mode = ipv4 ? ipv4.addressing : null;
        let cidr      = (ipv4 && type(ipv4.subnet) == "string") ? ipv4.subnet : null;
    %}
    ethernet {{ wan_ifname }} {
        {% if (addr_mode == "dynamic"): %}
        address dhcp
        {% elif (addr_mode == "static" && cidr): %}
        address {{ cidr }}
        {% endif %}
        {% if (wan.name): %}
        description {{ wan.name }}
        {% endif %}
    }
    {% endif %}
    {% if (lan): %}
    {%
        let ipv4      = lan.ipv4;
        let addr_mode = ipv4 ? ipv4.addressing : null;
        let cidr      = (ipv4 && type(ipv4.subnet) == "string") ? ipv4.subnet : null;

        let ifname = lan_ifname
    %}
    ethernet {{ ifname }} {
        {% if (addr_mode == "dynamic"): %}
        address dhcp
        {% elif (addr_mode == "static" && cidr): %}
        address {{ cidr }}
        {% endif %}
        {% if (lan.name): %}
        description {{ lan.name }}
        {% endif %}

        {% for (let v in vlans): %}
            {% if (type(v.vlan) == "object" && v.vlan.id && type(v.ipv4) == "object" && type(v.ipv4.subnet) == "string"): %}
        vif {{ v.vlan.id }} {
            address {{ v.ipv4.subnet }}
            description VLAN{{ v.vlan.id }}
        }
            {% endif %}
        {% endfor %}
    }
    {% endif %}
}
