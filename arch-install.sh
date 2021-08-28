#!/bin/sh
# Partition (cfdisk) /w swap
DEVICE='a'

BOOT="/dev/sd${DEVICE}1"
SWAP="/dev/sd${DEVICE}2"
ROOT="/dev/sd${DEVICE}3"
HOME="/dev/sd${DEVICE}4"

HOST='core'

# Set date/time
echo "Setting Up Date/Time"
timedatectl set-ntp true

echo "Formatting"
mkfs.ext4 "$BOOT"
mkfs.ext4 "$ROOT"
mkfs.ext4 "$HOME"
mkswap "$SWAP"
swapon "$SWAP"

echo "Mounting"
mkdir /mnt/boot && mount "$BOOT" /mnt/boot
mount "$ROOT" /mnt
mkdir /mnt/home && mount "$HOME" /mnt/home

# Edit Mirrors
echo "Editing Mirror List"
grep -A1 "United States" /etc/pacman.d/mirrorlist | \
grep -v "\-\-" | grep -v "^#" > ./mirrorlist
mv ./mirrorlist /etc/pacman.d/mirrorlist

# Installation
echo "Installing Base Arch"
pacstrap /mnt base base-devel neovim grub dialog networkmanager linux \
	linux-firmware usbutils inetutils dhcpd man-pages man-db netctl \
	xf86-video-intel
echo "Installation Complete!\n"

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab


cat << EOF > /mnt/chroot-script
# Locale
echo "Inside chroot-script"
echo "Setting Locale"
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
# generate /etc/adjtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network
echo "Setting Up Network"
echo "${HOST}" > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n\
		::1\t\tlocalhost\n\
		127.0.1.1\t${HOST}.localdomain\t${HOST}" >> /etc/hosts

echo "Creating Root Password"
passwd
# systemctl enable dhcpcd
# useradd -m user
# passwd user
# usermod -aG wheel,audio,video,optical,storage user
# uncomment line to allow wheel users to execute any command using visudo
# visudo

# Bootloader
echo "Installing Bootloader"
grub-install "/dev/sd${DEVICE}"
grub-mkconfig -o /boot/grub/grub.cfg
EOF

chmod +x /mnt/chroot-script

arch-chroot /mnt ./chroot-script
