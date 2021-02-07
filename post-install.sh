#!/bin/bash

# Run install.sh first or this will fail due to missing dependencies

# network on boot?
# read -t 1 -n 1000000 discard      # discard previous input
# sudo dhclient enp0s3
# echo 'Waiting for internet connection'

# if there are ssh key
# if [ -d ~/workspace/ssh ]; then
#     if [ -d ~/.ssh ]; then
#         rm -rf ~/.ssh
#     fi
#     ln -s ~/workspace/ssh ~/.ssh
# fi

# wallpaper setup
# cd
# mkdir Pictures
# cd Pictures
# wget https://github.com/abrochard/spartan-arch/blob/master/wallpaper.jpg?raw=true -O wallpaper.jpg
# cd ~/.config/
# mkdir nitrogen
# cd nitrogen
# echo '[xin_-1]' > bg-saved.cfg
# echo "file=/home/$(whoami)/Pictures/wallpaper.jpg" >> bg-saved.cfg
# echo 'mode=0' >> bg-saved.cfg
# echo 'bgcolor=#000000' >> bg-saved.cfg

# Enable network daemon
ln -s /etc/runit/sv/NetworkManager /run/runit/service
sv up NetworkManager

# using larbs as post install
wget https://raw.githubusercontent.com/KeithButler-WIT/LARBS/master/larbs.sh -O post-install.sh
chown $user:$user /home/$user/post-install.sh

sh /home/$user/post-install.sh
