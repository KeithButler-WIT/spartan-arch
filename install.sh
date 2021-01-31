#!/bin/bash

if [ -z "$1" ]
then
    echo "Enter your username: "
    read user
else
    user=$1
fi

if [ -z "$2" ]
then
    echo "Enter your master password: "
    read -s password
else
    password=$2
fi

if [ -z "$3" ]
then
    echo "Do you want to skip rankmirrors (faster upfront)? [y/N] "
    read response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        fast=1
    else
        fast=0
    fi
else
    fast=$3
fi

# set time
#timedatectl set-ntp true

# partitioning requirements
pacman -S --noconfirm parted

# partiton disk
if [ -d /sys/firmware/efi/ ]
then
    parted --script /dev/sda mklabel gpt mkpart primary fat32 550MB set bios_grub name BOOT mkpart primary linux-swap 4Gb mkpart primary ext4 100% name ROOT
    mkfs.fat -F 32 /dev/sda1
    mkswap /dev/sda2
    swapon /dev/sda2
    mkfs.ext4 /dev/sda3
    mount /dev/sda3 /mnt
    mkdir /mnt/boot
    mkdir /mnt/home
    mount /dev/sda3 /mnt/home
    mount /dev/sda1 /mnt/boot
else
    parted --script /dev/sda mklabel msdos mkpart primary ext4 0% 87% mkpart primary linux-swap 87% 100%
    mkfs.ext4 /dev/sda1
    mkswap /dev/sda2
    swapon /dev/sda2
    mount /dev/sda1 /mnt
fi

# basestrap
basestrap /mnt base base-devel runit elogind-runit

# Kernel
basestrap /mnt linux linux-firmware

# fstab
fstabgen -U /mnt >> /mnt/etc/fstab

# chroot
wget https://raw.githubusercontent.com/KeithButler-WIT/spartan-artix-runit/master/chroot-install.sh -O /mnt/chroot-install.sh
artix-chroot /mnt /bin/bash ./chroot-install.sh $user $password $fast

# reboot
umount /mnt
reboot
