#!/bin/sh

# Upgrade Mesos Agent
curl -O http://${bootstrap_private_ip}:${dcos_bootstrap_port}/upgrade/current/dcos_node_upgrade.sh
bash dcos_node_upgrade.sh ${dcos_skip_checks ? "--skip-checks" : "" }
# Completed
