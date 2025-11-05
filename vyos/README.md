# VyOS

### 📦 Container Image Generation for VyOS
Follow these steps to download a VyOS rolling release ISO and build a Docker-image from it.

1. Download the VyOS ISO
Go to the VyOS nightly builds page or official download page and fetch the desired version, e.g.:
https://vyos.net/get/nightly-builds/

2. Extract contents from ISO and prepare docker container image.
```bash
mkdir vyos && cd vyos
mkdir rootfs
sudo mount -o loop vyos-2025.09.10-0018-rolling-generic-amd64.iso rootfs
sudo apt-get install -y squashfs-tools
mkdir unsquashfs
sudo unsquashfs -f -d unsquashfs/ rootfs/live/filesystem.squashfs
sudo tar -C unsquashfs -c . | docker import - vyos-2025.09.10-0018-rolling-generic
sudo umount rootfs
cd ..
sudo rm -rf vyos
```
