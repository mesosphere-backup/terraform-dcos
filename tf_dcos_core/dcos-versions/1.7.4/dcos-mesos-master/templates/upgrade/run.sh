#!/bin/sh

# Master Commands
curl -O http://${bootstrap_private_ip}:${dcos_bootstrap_port}/dcos_install.sh
/opt/mesosphere/bin/pkgpanda uninstall
rm -rf /opt/mesosphere /etc/mesosphere
bash dcos_install.sh -d master
# Complete
