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
    echo "Uefi partition detected"
    # dd if=/dev/zero of=/dev/sda

    DEV2="/dev/sda"
    echo "=======BEFORE======="
    sgdisk -p ${DEV2}
    echo "======CLEARING======"
    dd if=/dev/zero of=${DEV2} bs=1M count=100
    end_position=$(sgdisk -E ${DEV2})
    sgdisk -z ${DEV2}
    sgdisk -Z ${DEV2}
    sgdisk -g ${DEV2}
    echo "======Creating======"
    sgdisk -og ${DEV2}
    sgdisk -n 1:2048:1128447 -c 1:"BOOT" -t 1:ef02 ${DEV2}
    sgdisk -n 2:128448:9617055 -c 2:"SWAP" -t 2:8200 ${DEV2}
    sgdisk -n 3:9517056:${end_position} -c 3:"ROOT" -t 3:8300 ${DEV2}
    echo "=======RESULT======="
    sgdisk -p ${DEV2}
    
    # parted --script /dev/sda mklabel gpt mkpart primary BOOT fat32 0% 4% set bios_grub mkpart primary SWAP linux-swap 4% 10% mkpart primary ROOTxdvuyl7C4rted ext4 10% 100%
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
    echo "Bios partition detected"
    # dd if=/dev/zero of=/dev/sda
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
umount -R /mnt
reboot
