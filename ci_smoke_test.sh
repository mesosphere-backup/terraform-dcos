#!/bin/bash
# Required environment variables:
# GOOGLE_APPLICATION_CREDENTIALS=the path to your service account credentials file - or - GCP_CREDENTIALS: your service account json string
# GCP_PROJECT=the name of your project e.g. development-12345
# TERRAFORM_PATH=the path to your terraform binary; will default to "terraform"
# TF_DCOS_CORE_BRANCH=branch name for the tf_dcos_core repo that terraform-dcos depends on; will default to "master"
set -euxo pipefail

ssh-keygen -f id_rsa -t rsa -N ''
chmod 600 id_rsa

if [[ ! -v TERRAFORM_PATH ]]
then
  TERRAFORM_PATH="terraform"
fi

if [[ ! -v TF_DCOS_CORE_BRANCH ]]
then
  TF_DCOS_CORE_BRANCH="master"
fi

cd gcp
if [[ ! -v GOOGLE_APPLICATION_CREDENTIALS ]]
then
  echo "$GCP_CREDENTIALS" > creds.json
  export GOOGLE_APPLICATION_CREDENTIALS=`pwd`/creds.json
fi
$TERRAFORM_PATH init
$TERRAFORM_PATH validate -var "gcp_project=${GCP_PROJECT}" -var "gcp_ssh_pub_key_file=`pwd`/../id_rsa.pub" -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"
$TERRAFORM_PATH plan -var "gcp_project=${GCP_PROJECT}" -var "gcp_ssh_pub_key_file=`pwd`/../id_rsa.pub" -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"
$TERRAFORM_PATH validate -var-file desired_cluster_profile.tfvars.example -var "gcp_project=${GCP_PROJECT}" -var "gcp_ssh_pub_key_file=`pwd`/../id_rsa.pub" -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"
$TERRAFORM_PATH plan -var-file desired_cluster_profile.tfvars.example -var "gcp_project=${GCP_PROJECT}" -var "gcp_ssh_pub_key_file=`pwd`/../id_rsa.pub" -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"

cd ../aws
$TERRAFORM_PATH init
$TERRAFORM_PATH validate -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"
$TERRAFORM_PATH plan -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"
$TERRAFORM_PATH validate -var-file desired_cluster_profile.tfvars.example -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"
$TERRAFORM_PATH plan -var-file desired_cluster_profile.tfvars.example -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"

cd ../azure
$TERRAFORM_PATH init
$TERRAFORM_PATH validate -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"
$TERRAFORM_PATH plan -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"
$TERRAFORM_PATH validate -var-file desired_cluster_profile.tfvars.example -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"
$TERRAFORM_PATH plan -var-file desired_cluster_profile.tfvars.example -var "tf_dcos_core_branch=$TF_DCOS_CORE_BRANCH"

