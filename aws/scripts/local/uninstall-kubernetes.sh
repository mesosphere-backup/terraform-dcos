#!/bin/bash

# Uninstall the kubernetes package from the DC/OS cluster. The DCOS_CLUSTER_URL
# env var is passed in the null_resource.kubernetes-install resource in master.tf.
echo "Uninstalling kubernetes package from DC/OS cluster at '${DCOS_CLUSTER_URL}'"
dcos config set core.ssl_verify false
dcos config set core.dcos_url ${DCOS_CLUSTER_URL}
dcos package uninstall --yes kubernetes

echo "Kubernetes uninstallation finished!"
