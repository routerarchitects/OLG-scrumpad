# 🧩 OLG Scrumpad

**OLG Scrumpad** is a local lab environment designed to emulate an OpenWiFi gateway–controller–client setup using Docker.  
It provides containerized instances of **VyOS** (as a gateway router) and the **uCentral Client**, along with a host setup script to create macvlan networks and establish communication between the simulated components.

---

## 📘 Overview

This environment simulates the end-to-end connectivity between:
- **uCentral Client** ↔ **VyOS Router**  
- **uCentral Client** ↔ **Cloud Controller**  
- **VyOS Router** ↔ **APNOS Device**

The goal is to replicate the OpenWiFi data flow from Access Point → Gateway → Cloud in a controlled, container-based environment.

## 🧱 Repository Structure
```bash
OLG-scrumpad
├── documents # Design Documents
├── olg_setup.sh # Host and docker container setup script (creates macvlan networks and start containers)
├── README.md
├── ucentral-client # uCentral client for OLG
│   └── README.md
│   └── Dockerfile # Dockerfile to create docker image of ucentral-client from rootfs
│   └── rootfs/ # Contains the ucentral-client specific files from which docker image is created
└── vyos # VyOS Gateway for OLG
    ├── README.md
    └── vyos_config # The host volume required to mount in VyOS container
        ├── config.boot # The default vyos configuration to setup gateway's upstream interface and VyOS HTTP API Server
        └── scripts
            └── vyos-postconfig-bootup.script # The script to load the default VyOS configurations and perform specific operations after container gets initialized
```

## ⚙️ Components

### **VyOS (Router Gateway)**
- Runs as a Docker container using an image (`docker pull docker.io/routerarchitect123/vyos-2025.09.10-0018-rolling-generic:olgV1`).
- Configured via `config.boot` and bootup scripts after reboot.
- Acts as a **gateway** device for **APNOS device**

### **uCentral Client**
- Runs as a Docker container using an image (`docker pull docker.io/routerarchitect123/ucentral-client:olgV1`).
- uCentral Client acts as a configuration endpoint for the Gateway and is configured via cloud.
- Configures VyOS via rest API's exposed by its HTTPS API Server.
- Connects to Cloud Controller which configures the VyOS.

### **Host Setup Script – `olg_setup.sh`**
- Prepares the Docker host environment:
  - Creates **macvlan Docker networks** for realistic L2 network segmentation.
  - Launches containers.

## 🧰 Execution Guide

### **Prerequisites**
Before execution, ensure your host system has:
- Loaded Container Images for uCentral Client and VyOS in the Host. 
- Two network interfaces:  
  - `eth0` – running a **DHCP client**, obtaining an IP from the upstream router.  
  - `eth1` – **statically configured** with a local IP.  
- Configure variables in olg_setup.sh according to the host , specifically for Network & IP settings, The WAN_NET should be same as the network of host's eth0 interface.

## **Note**
- The uCentral Client image is created from 3.1 and have certificates already embedded in it which works with Router-Architects Cloud Controller only.
- In order to make it work with custom cloud please replace the certificates.

### **Steps**
1. Run the setup script:
```bash
./olg_setup.sh
```
2. Once the setup script completes, wait about a minute for VyOS to initialize.
Then access the container:
```bash
docker exec -it vyos-olg su - vyos
```
3. Inside the VyOS container:
Wait until eth0 (WAN) receives an IP via DHCP from the upstream router and has default route on eth0.

4. Note down the IP assigned to eth0 . This will be used in the uCentral configuration to reach the VyOS router.
```bash
ifconfig eth0
```
5. Access the uCentral Client container:
```bash
docker exec -it ucentral-olg /bin/ash
```
6. Update VyOS Connection Info. Edit **/etc/ucentral/vyos-info.json** . Replace the placeholder IP with the VyOS IP you noted earlier.

7. Start UBUS Service
```bash
/sbin/ubusd  &
```
8. Start uCentral Client
This image **ucentral-client:olgV1**  is preconfigured with certificates and serial number details for demo purposes.
```bash
/usr/sbin/ucentral -S 74d4ddb965dc -s openwifi1.routerarchitects.com -P 15002 -d
```
