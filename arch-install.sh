#!/bin/sh
# Partition (cfdisk) /w swap
DEVICE='a'

BOOT="/dev/sd${DEVICE}1"
#SWAP="/dev/sd${DEVICE}2"
ROOT="/dev/sd${DEVICE}2"
#HOME="/dev/sd${DEVICE}4"

HOST='core'

# Set date/time
echo "Setting Up Date/Time"
timedatectl set-timezone US/Eastern
timedatectl set-ntp true

echo "Formatting"
mkfs.fat -F32 "$BOOT"
mkfs.ext4 "$ROOT"
#mkfs.ext4 "$HOME"
#mkswap "$SWAP"
#swapon "$SWAP"

echo "Mounting"
mkdir /mnt/boot && mount "$BOOT" /mnt/boot
mount "$ROOT" /mnt
#mkdir /mnt/home && mount "$HOME" /mnt/home

# Edit Mirrors
#echo "Editing Mirror List"
#grep -A1 "United States" /etc/pacman.d/mirrorlist | \
#grep -v "\-\-" | grep -v "^#" > ./mirrorlist
#mv ./mirrorlist /etc/pacman.d/mirrorlist
yes | pacman -Sy reflector
reflector -C US -a 6 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyy

# Installation
echo "Installing Base Arch"
# dhcpd not found?
pacstrap /mnt base base-devel neovim grub efibootmgr dialog networkmanager network-manager-applet \
    wireless_tools wpa_supplicant os-prober linux linux-firmware linux-headers usbutils inetutils man-pages man-db netctl \
	reflector git bluez bluez-utils cups xdg-utils xdg-user-dirs openssh xf86-video-intel
echo "Installation Complete!\n"

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab


cat << EOF > /mnt/chroot-script
# Swap FIle option
fallocate -l 2GB /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

# Locale
echo "Inside chroot-script"

echo "Setting Locale"
ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
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
useradd -mG wheel chris
passwd chris
# usermod -aG wheel,audio,video,optical,storage chris
# uncomment line to allow wheel users to execute any command using visudo
EDITOR=nvim visudo

# Bootloader
echo "Installing Bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable Services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable org.cups.cupsd
EOF

chmod +x /mnt/chroot-script

arch-chroot /mnt ./chroot-script
# Notes
# `nmtui` for GUI wifi menu
