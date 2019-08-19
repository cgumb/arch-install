#!/bin/sh
# Partition (cfdisk) /w swap
PART='a'

ROOT="/dev/sd${PART}1"
SWAP="/dev/sd${PART}2" # check connection

#ip link
#ping archlinux.org
# Set date/time
timedatectl set-ntp true
timedatectl status

mkfs.ext4 "$ROOT"
mkswap "$SWAP"
swapon "$SWAP"
mount "$ROOT" /mnt

# Edit Mirrors
grep -A1 "United States" /etc/pacman.d/mirrorlist | \
grep -v "\-\-" | grep -v "^#" > ./mirrorlist
mv ./mirrorlist /etc/pacman.d/mirrorlist
# Install!
pacstrap /mnt base

genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
# set timezone
#ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
# generate /etc/adjtime
#hwclock --systohc
# localization
# uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen
#sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
#locale-gen
#echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network
# echo "core" > /etc/hostname
# edit /etc/hosts to show:
# 127.0.0.1	localhost
# ::1		localhost
# 127.0.1.1	myhostname.localdomain	myhostname

# create root password
# passwd
# systemctl enable dhcpcd
# useradd -m user
# passwd user
# pacman -S sudo vim grub dialog
# usermod -aG wheel,audio,video,optical,storage user
# uncomment line to allow wheel users to execute any command using visudo
# visudo

# Bootloader
#grub-install /dev/sdX
#grub-mkconfig -o /boot/grub/grub.cfg
