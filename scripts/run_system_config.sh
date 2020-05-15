#!/bin/bash

# create swap file
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile

# enable swap
sudo swapon /swapfile
sudo cp /etc/fstab /etc/fstab.backup
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# set 5w mode
sudo nvpmodel -m1


