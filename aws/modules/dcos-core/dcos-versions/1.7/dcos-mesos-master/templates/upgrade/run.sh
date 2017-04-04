#!/bin/sh

# Master Commands
curl -O http://${bootstrap_private_ip}:${dcos_bootstrap_port}/dcos_install.sh
sudo -i /opt/mesosphere/bin/pkgpanda uninstall
sudo rm -rf /opt/mesosphere /etc/mesosphere 
sudo bash dcos_install.sh -d master
# Complete
