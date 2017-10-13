#!/bin/sh

# Master Commands
curl -O http://${bootstrap_private_ip}:${dcos_bootstrap_port}/dcos_install.sh
/opt/mesosphere/bin/pkgpanda uninstall
rm -rf /opt/mesosphere /etc/mesosphere
useradd --system --home-dir /opt/mesosphere --shell /sbin/nologin -c 'DCOS System User' dcos_exhibitor 
chown -R dcos_exhibitor /var/lib/zookeeper
bash dcos_install.sh -d master
# Complete
