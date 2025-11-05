# Ucentral Client
This document explains how to build the container image for the **uCentral Client** from rootfs and also how to prepare the root filesystem (rootfs) build context.

---

## 🔨 Steps to Build RootFs & Prepare uCentral Client Docker Image

### 1. Create workspace and fetch the OpenWiFi WLAN AP source  
```bash
mkdir WORKSPACE
cd WORKSPACE
mkdir OPENWIFI_WLANAP
cd OPENWIFI_WLANAP
git clone https://github.com/routerarchitects/ra-openwifi-wlan-ap.git
git checkout release/v3.1.0
./build.sh x64_vm
```

### 2. After the build completes, Set paths for image preparation 
Set environment variables for source and destination paths:
```bash
ROOT=~/WORKSPACE/OPENWIFI_WLANAP/ra-openwifi-wlan-ap/openwrt/build_dir/target-x86_64_musl/root-x86
DEST=~/OLG-scrumpad/ucentral-client/rootfs/
```
### 3. Create the necessary directory structure in the destination
```bash
mkdir -p "$DEST"/{bin,sbin,usr/bin,usr/sbin,usr/share,lib,usr/lib,etc/ucentral,lib/config,lib/functions}
```

### 4. Copy required files for uCentral Client image
```bash
cp -a "$ROOT"/usr/sbin/ucentral      "$DEST"/usr/sbin/
cp -a "$ROOT"/etc/group               "$DEST"/etc/
cp -a "$ROOT"/etc/passwd              "$DEST"/etc/
cp -a "$ROOT"/sbin/ubusd              "$DEST"/sbin/
cp -a "$ROOT"/bin/ubus                "$DEST"/bin/
cp -a "$ROOT"/usr/bin/curl            "$DEST"/usr/bin/
```

### 5. Add BusyBox and symlinks for common applets
```bash
cp -a "$ROOT"/bin/busybox "$DEST"/bin/
( cd "$DEST/bin" && ln -sf busybox sh && ln -sf busybox ash )
for a in ls ps ifconfig ping ip cat grep cut mkdir rm cp mv ln touch \
         mount umount basename readlink vi date uname echo sleep dmesg logger flock; do
  ln -sf busybox "$DEST/bin/$a"
done
# If BusyBox lacked a given applet, copy real ones if present:
[ -f "$ROOT/usr/bin/logger" ] && cp -a "$ROOT/usr/bin/logger" "$DEST/usr/bin/"
[ -f "$ROOT/usr/bin/flock"  ] && cp -a "$ROOT/usr/bin/flock"  "$DEST/usr/bin/"
```

### 6. Copy uCentral’s ucode scripts
```bash
cp -a "$ROOT"/usr/share/ucentral   "$DEST"/usr/share/        2>/dev/null || true
cp -a "$ROOT"/usr/bin/ucode        "$DEST"/usr/bin/          2>/dev/null || true
cp -a "$ROOT"/usr/lib/ucode        "$DEST"/usr/lib/          2>/dev/null || true
```

### 7. Copy all libraries
```bash
cp -a "$ROOT"/lib/*   "$DEST"/lib/
cp -a "$ROOT"/usr/lib "$DEST"/usr/
```

### 8. Make executables runnable
```bash
chmod +x "$DEST"/bin/busybox \
         "$DEST"/usr/sbin/ucentral \
         "$DEST"/usr/bin/ucode 2>/dev/null || true
```

### 9. Build the Docker Image
Once the rootfs/ directory is prepared, use the Dockerfile inside ucentral-client/ to build the container image.
Typically you will run:
```bash
cd ucentral-client
docker build -t ucentral-client:latest .
```
