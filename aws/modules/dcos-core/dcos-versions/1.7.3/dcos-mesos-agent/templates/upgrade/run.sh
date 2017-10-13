#!/bin/sh

# Upgrade Mesos Agent
curl -O http://${bootstrap_private_ip}:${dcos_bootstrap_port}/dcos_install.sh
/opt/mesosphere/bin/pkgpanda uninstall
rm -rf /opt/mesosphere /etc/mesosphere
mkdir -p /var/lib/dcos
touch /var/lib/dcos/mesos-resources
bash dcos_install.sh -d slave
# Completed
