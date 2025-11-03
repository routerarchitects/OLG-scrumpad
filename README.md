# How to Run OLG ISO in KVM and Connect it to OpenWiFi Cloud SDK
This is a very simple OLG Installer to get you onboard in a flash and validate your OLG use cases.
This is also configurable via Cloud Controller and provide connectivity to APNOS devices as well.
## PreRequisite — Install KVM and Related Tools in Ubuntu 24.04
### Execute Following Commands on the Ubuntu Host to setup KVM
```sh
sudo apt update
sudo apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  virtinst \
  virt-viewer \
  bridge-utils \
  virt-manager
sudo usermod -aG libvirt,kvm $USER
sudo virt-manager
```
### Setup New VM from GUI (virt-manager)
- Click Create a New VM
- Choose “Local install media (ISO)”.
- Choose the Operating System as Debian 12 , if not Automatically Detected.
- Choose atleast 2GB Ram and 2 CPU Cores.
- Choose 8GB Disk.
- Name your VM and in Network Selection , select Macvtap Device and in Device Name field, set the interface name in your host which you need to setup as WAN interface for OLG (eg. eth0).
- Select "Customize Configuration before install" , then Click Finish.
- Click on "Add Hardware" and then Network , select "Network source" as Macvtap and device name should be the interface name on host which is required to be used for LAN (eg. eth1). "Device model" should be virtio. Then click Finish.
- Now Click on "Begin Installation". Then let it boot with live KVM Installation.
- Then Login to VyOS . Username & Password = vyos
- Install image if you need to make it permanent with command inside KVM.
    ```sh    
        install image
    ```
- Follow the Instructions and select config.boot as default config file for VyOS.
- Reboot after image is installed successfully.

## Working within VyOS
- After you login, the VyOS will have an eth0 interface , which should get IP from the DHCP Server connected to eth0 interface of host and default ucentral configurations should get applied.
- You can modify the following in order to make it work with your Cloud Controller.
    - Copy certificates in "/etc/ucentral/". Follow "How to Copy Certificates to OLG running in KVM"
    - Modify Cloud URL and Serial Number in the ucentral service file (/lib/systemd/system/ucentral.service). Modify the field "ExecStart".
- Restart daemon and ucentral.
    ```sh
        sudo systemctl daemon-reload
        sudo systemctl restart ucentral
    ```
## How to Copy Certificates to OLG running in KVM
1. Setup Host-Guest Bridge (Host Side)
On your host machine, you create a virtual link to the physical interface. This allows the host to communicate "sideways" into the macvtap interface of the VM.
    - Create the macvlan bridge link
    ```sh
        sudo ip link add link eth0 name virt-host type macvlan mode bridge
    ```
    - Assign a management IP to the host within the same subnet as VyOS
    ```sh
        sudo ip addr add <HOST_MANAGEMENT_IP>/24 dev virt-host
    ```
    - Bring the interface up
    ```sh
        sudo ip link set virt-host up
    ```
2. Copy Certificates to OLG
    -By "pulling" the files from inside VyOS using sudo, you bypass the folder permission restrictions on /etc/ucentral/.
    ```sh
        ssh vyos@<VYOS_IP>
    ```
    - Execute the transfer, Pull files from Host to VyOS system directory
    ```sh
        sudo scp <USER>@<HOST_PHYSICAL_IP>:/path/to/certs/cas.pem /etc/ucentral/
        sudo scp <USER>@<HOST_PHYSICAL_IP>:/path/to/certs/cert.pem /etc/ucentral/
        sudo scp <USER>@<HOST_PHYSICAL_IP>:/path/to/certs/key.pem /etc/ucentral/
    ```

## OLG ISO Release

| ISO Image | Description | Link | Note
| ------ | ------ |------ |------ |
| vyos-1.5-rolling-202512181356-generic-amd64.iso | This image contains VyOS+Ucental and supports configurations from Cloud Controller, Based on OpenWiFi 3.2 Release and is able to provide connectivity to APNOS device as well. | https://drive.google.com/file/d/11k_b-si7pz_svSxgWlE9RJaCg0_NGAdr/view?usp=drive_link  | The ucentral client service runs with 20 seconds delay due to issue in running order of required VyOS services. This will be fixed in next release.
