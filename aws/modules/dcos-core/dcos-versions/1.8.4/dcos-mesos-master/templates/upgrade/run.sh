#!/bin/sh

# Master Commands
curl -O http://${bootstrap_private_ip}:${dcos_bootstrap_port}/dcos_install.sh
sudo -i /opt/mesosphere/bin/pkgpanda uninstall
sudo rm -rf /opt/mesosphere /etc/mesosphere 
sudo useradd --system --home-dir /opt/mesosphere --shell /sbin/nologin -c 'DCOS System User' dcos_exhibitor 
sudo chown -R dcos_exhibitor /var/lib/zookeeper
sudo bash dcos_install.sh -d master
# Complete
