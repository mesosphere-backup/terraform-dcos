#!/bin/sh

# Install Agent Node
mkdir /tmp/dcos && cd /tmp/dcos
/usr/bin/curl -O ${bootstrap_private_ip}:${dcos_bootstrap_port}/dcos_install.sh
sudo bash dcos_install.sh slave_public
# Agent Node End
