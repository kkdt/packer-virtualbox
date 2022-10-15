#!/bin/bash
# Assumptions
# 1. The virtualbox-is puts the iso at /root/VBoxGuestAdditions.iso (see virtualbox-iso.guest_additions_path)

# Mount the disk image
mkdir -p /mnt/iso
mount -o loop /root/VBoxGuestAdditions.iso /mnt/iso

# Install the drivers
/mnt/iso/VBoxLinuxAdditions.run

# Cleanup
umount /mnt/iso
rm -rf /mnt/iso /root/VBoxGuestAdditions.iso