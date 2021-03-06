#!/bin/sh

# This will be ran from the chrooted env.

user=$1
password=$2
fast=$3

# setup mirrors
if [ "$fast" -eq "1" ]
then
    echo 'Setting up mirrors'
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
    rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
else
    echo 'Skipping mirror ranking because fast'
fi

# setup timezone
echo 'Setting up timezone'
timedatectl set-ntp true
ln -s /usr/share/zoneinfo/Europe/Dublin /etc/localtime
#timedatectl set-timezone Europe/Dublin
hwclock --systohc

# setup locale
echo 'Setting up locale'
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# setup hostname
echo 'Setting up hostname'
echo 'artix' > /etc/hostname

# setup hosts
echo '127.0.0.1        localhost
::1              localhost
127.0.1.1        artix.localdomain        artix' > /etc/hosts
wget https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts -O blockedHosts
sed -i 1,39d blockedHosts
cat blockedHosts >> /etc/hosts

# build
# echo 'Building'
# mkinitcpio -p linux

# install bootloader
echo 'Installing bootloader'
pacman -S grub os-prober efibootmgr --noconfirm
if [ -d /sys/firmware/efi/ ]
then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
else
    grub-install --recheck /dev/sda
fi
grub-mkconfig -o /boot/grub/grub.cfg

# check if virtual machine
pacman -S --noconfirm facter
if [ ${facter virtual} != 'physical' ]
then
    # install virtualbox guest modules
    echo 'Installing VB-guest-modules'
    pacman -S --noconfirm virtualbox-guest-modules-artix virtualbox-guest-utils

    # vbox modules
    echo 'vboxsf' > /etc/modules-load.d/vboxsf.conf
fi

# user mgmt
echo 'Setting up user'
read -tr 1 -n 1000000 discard      # discard previous input
echo 'root:'$password | chpasswd
useradd -m -G wheel -s /bin/zsh $user
echo $user:$password | chpasswd
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
echo "permit root
permit $user as root" >> /etc/doas.conf

# enable services
#systemctl enable ntpdate.service

# Network configuration
pacman -S --noconfirm networkmanager-runit

# using larbs as post install
wget https://raw.githubusercontent.com/KeithButler-WIT/spartan-artix-runit/master/post-install.sh -O /home/$user/post-install.sh
chown $user:$user /home/$user/post-install.sh

echo 'Done'
