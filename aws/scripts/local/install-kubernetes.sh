#!/bin/bash

# Install the kubernetes package on the DC/OS cluster. The DCOS_CLUSTER_URL
# env var is passed in the null_resource.kubernetes-install resource in master.tf.
echo "Installing kubernetes package on DC/OS cluster at '${DCOS_CLUSTER_URL}'"
dcos config set core.ssl_verify false
dcos config set core.dcos_url ${DCOS_CLUSTER_URL}
dcos package install --yes kubernetes
dcos kubernetes kubeconfig

echo "Kubernetes installation finished!"
