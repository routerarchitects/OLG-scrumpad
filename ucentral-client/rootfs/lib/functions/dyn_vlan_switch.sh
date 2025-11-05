
configure_switch_dynamic_vlan(){
vid=$1
switch_dev=$2
switch_wan_port=$3
switch_cpu_port=$4
debug "configured switch $switch_dev ports $switch_wan_port $switch_cpu_port for dynamic vlans $vid"
swconfig dev ${switch_dev} vlan $vid set ports "${switch_wan_port} ${switch_cpu_port}"

}


configure_bridge_dyn_vlans () {
interfaces=$(ls /sys/class/net/$1/brif)

switch_dev=$2
switch_wan_port=$3
switch_cpu_port=$4

# Convert the string into an array
IFS=' ' set -- $interfaces

# Loop through the array and print each element
for interface in "$@"; do
   case "$interface" in
        wlan*-v*)
            # Use parameter expansion to extract the part after "wlan*-v"
            dyn_vlan_id="${interface#*wlan*-v}"
	    configure_switch_dynamic_vlan $dyn_vlan_id $switch_dev $switch_wan_port $switch_cpu_port ;;
    esac
done
}

