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

# Enable network daemon
ln -s /etc/runit/sv/NetworkManager /run/runit/service
sv up NetworkManager

# using larbs as post install
# wget https://raw.githubusercontent.com/KeithButler-WIT/LARBS/master/larbs.sh -O post-install.sh
curl -LO https://raw.githubusercontent.com/KeithButler-WIT/LARBS/master/larbs.sh
chown $user:$user /home/$user/larbs.sh
sh /home/$user/larbs.sh
