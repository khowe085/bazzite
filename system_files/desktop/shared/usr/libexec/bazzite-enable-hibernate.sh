#!/usr/bin/env bash
set -euo pipefail

SWAPDIR="/var/swap"
SWAPFILE="/var/swap/swapfile"


echo "[bazzite] Detecting system RAM..." 
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}') 
RAM_GB=$(( (RAM_KB + 1024*1024 - 1) / (1024*1024) )) 
SWAP_GB=$(( RAM_GB + (RAM_GB) ))
SWAPSIZE="${SWAP_GB}G"



echo "[bazzite] Creating /var/swap subvolume..."
if [[ ! -d "$SWAPDIR" ]]; then
    btrfs subvolume create "$SWAPDIR"
fi

echo "[bazzite] Setting SELinux context for swap directory..."
semanage fcontext -a -t var_t "$SWAPDIR"
restorecon "$SWAPDIR"

echo "[bazzite] Creating Btrfs-compatible swapfile..."
if [[ ! -f "$SWAPFILE" ]]; then
    btrfs filesystem mkswapfile --size "$SWAPSIZE" "$SWAPFILE"
fi

echo "[bazzite] Setting SELinux context for swapfile..."
semanage fcontext -a -t swapfile_t "$SWAPFILE"
restorecon "$SWAPFILE"

echo "[bazzite] Enabling swapfile..."
swapon "$SWAPFILE"

echo "[bazzite] Adding swapfile to /etc/fstab..."
if ! grep -q "$SWAPFILE" /etc/fstab; then
    echo "$SWAPFILE none swap defaults,nofail 0 0" >> /etc/fstab
fi

echo "[bazzite] Disabling zram using zram-generator override..."
echo "" > /etc/systemd/zram-generator.conf

echo "[bazzite] Swapfile setup complete (resume configuration still required)."
