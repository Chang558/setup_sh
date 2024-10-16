#!/bin/bash

wget https://download.nomachine.com/download/8.13/Arm/nomachine_8.13.1_1_aarch64.tar.gz -O nomachine.tar.gz

tar -xvzf nomachine.tar.gz

cd NX

sudo ./nxserver --install
#sudo sh -c "echo 'auto eth0
#iface eth0 inet static
#address 192.168.35.205
#netmask 255.255.255.0
#gateway 192.168.35.1
#dns-nameservers 210.220.163.82 219.250.36.130

#auto eth0:0
#iface eth0:0 inet static
#    address 192.168.10.205
#    netmask 255.255.255.0' >> /etc/network/interfaces"
#sudo systemctl restart networking.service

sudo rm -rf nomachine.tar.gz
