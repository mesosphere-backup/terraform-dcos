#!/bin/bash

echo "DC/OS auth login at '${DCOS_CLUSTER_URL}'"

dcos auth login --password=${TF_VAR_dcos_superuser_password} --username=${TF_VAR_dcos_superuser_username}

echo "DC/OS login successful"

