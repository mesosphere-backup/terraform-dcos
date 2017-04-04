#!/bin/sh

# Upgrade Mesos Agent
curl -O http://${bootstrap_private_ip}:${dcos_bootstrap_port}/dcos_install.sh
sudo -i /opt/mesosphere/bin/pkgpanda uninstall
sudo rm -rf /opt/mesosphere /etc/mesosphere
sudo mkdir -p /var/lib/dcos
sudo touch /var/lib/dcos/mesos-resources
sudo bash dcos_install.sh -d slave
# Completed
