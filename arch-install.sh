#!/bin/sh
# Partition (cfdisk) /w swap
DEVICE='a'

ROOT="/dev/sd${DEVICE}1"
SWAP="/dev/sd${DEVICE}2" 

# check connection

#ip link
#ping archlinux.org
# Set date/time
echo "Setting Up Date/Time"
timedatectl set-ntp true
timedatectl status

echo "Formatting"
mkfs.ext4 "$ROOT"
mkswap "$SWAP"
swapon "$SWAP"
mount "$ROOT" /mnt

# Edit Mirrors
echo "Editing Mirror List"
grep -A1 "United States" /etc/pacman.d/mirrorlist | \
grep -v "\-\-" | grep -v "^#" > ./mirrorlist
mv ./mirrorlist /etc/pacman.d/mirrorlist

# Installation
echo "Installing Base Arch"
pacstrap /mnt base
echo "Installation Complete!\n"

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab


echo "Creating chroot-script"
cat <<'EOF'  > /mnt/chroot-script 
# Locale
echo "Inside chroot-script"
echo "Setting Locale"
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
generate /etc/adjtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network
echo "Setting Up Network"
echo "core" > /etc/hostname
# edit /etc/hosts to show:
# 127.0.0.1	localhost
# ::1		localhost
# 127.0.1.1	myhostname.localdomain	myhostname
echo "127.0.0.1\tlocalhost\n\
		::1\tlocalhost\n\
		127.0.1.1\${HOST}.localdomain\t${HOST}" >> /etc/hosts

echo "Creating Root Password"
passwd
# systemctl enable dhcpcd
# useradd -m user
# passwd user
# pacman -S sudo vim grub dialog
# usermod -aG wheel,audio,video,optical,storage user
# uncomment line to allow wheel users to execute any command using visudo
# visudo

# Bootloader
echo "Installing Bootloader"
grub-install "/dev/sd${DEVICE}"
grub-mkconfig -o /boot/grub/grub.cfg
EOF

chmod +x /mnt/chroot-script

echo "chroot"
arch-chroot /mnt ./chroot-script
