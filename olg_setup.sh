#!/usr/bin/env bash

# === CONFIG VARIABLES ===
# Network & IP settings
WAN_NET_SUBNET="192.168.76.0/24"
WAN_NET_GATEWAY="192.168.76.1"
LAN_NET_SUBNET="192.168.50.0/24"
LAN_NET_GATEWAY="192.168.50.254"

UCENTRAL_IP="192.168.76.31"

# Volume / paths
VYOS_CONFIG_VOLUME="./vyos/vyos_config/"
MODULES_VOLUME="/lib/modules"

# Image names
VYOS_IMAGE="routerarchitect123/vyos-2025.09.10-0018-rolling-generic:olgV1"
UCENTRAL_IMAGE="routerarchitect123/ucentral-client:olgV1"

# === END CONFIG VARIABLES ===

# --- Clean up previous run ---
docker stop vyos-olg      2>/dev/null || true
docker rm   vyos-olg      2>/dev/null || true
docker stop ucentral-olg 2>/dev/null || true
docker rm   ucentral-olg 2>/dev/null
docker network rm wan_net 2>/dev/null || true
docker network rm lan_net 2>/dev/null || true

# --- Create networks ---
docker network create -d macvlan \
  --subnet=${WAN_NET_SUBNET} \
  --gateway=${WAN_NET_GATEWAY} \
  --subnet=fd00:aaaa:bbbb::/64 \
  --ipv6 \
  --gateway=fd00:aaaa:bbbb::1 \
  -o parent=eth0 \
  wan_net

docker network create -d macvlan \
  --subnet=${LAN_NET_SUBNET} \
  --gateway=${LAN_NET_GATEWAY} \
  --subnet=fd00:cccc:dddd::/64 \
  --gateway=fd00:cccc:dddd::1 \
  --ipv6 \
  -o parent=eth1 \
  --aux-address="vyos=192.168.50.1" \
  lan_net

# --- Run VyOS container ---
docker run -d --name vyos-olg --privileged \
  --network wan_net \
  -v ${MODULES_VOLUME}:/lib/modules \
  -v ${VYOS_CONFIG_VOLUME}:/opt/vyatta/etc/config \
  ${VYOS_IMAGE} /sbin/init

docker network connect lan_net vyos-olg

# --- Run UCentral container ---
docker run -dit --name ucentral-olg --privileged \
  --network wan_net --ip ${UCENTRAL_IP} \
  ${UCENTRAL_IMAGE}

echo "Setup completed successfully."

