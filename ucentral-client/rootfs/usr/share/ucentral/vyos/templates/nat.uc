{%
    let nets = [];

    if (type(config.interfaces) == "array") {
        for (let iface in config.interfaces) {
            if (iface.role != "downstream")
                continue;

            // Base LAN IPv4
            if (type(iface.ipv4) == "object" &&
                iface.ipv4.addressing == "static" &&
                type(iface.ipv4.subnet) == "string") {

                let nb = network_base(iface.ipv4.subnet);
                if (nb)
                    push(nets, nb[0]); // 192.168.50.0/24
            }

        }
    }
%}

nat {
    source {
        {% if (wan_ifname && length(nets) > 0): %}
            {% for (let i = 0; i < length(nets); i++): %}
        rule {{ i + 1 }} {
            outbound-interface {
                name {{ wan_ifname }}
            }
            source {
                address {{ nets[i] }}
            }
            translation {
                address masquerade
            }
        }
            {% endfor %}
        {% endif %}
    }
}

