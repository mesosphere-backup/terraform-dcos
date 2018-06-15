#!/bin/bash
# Required environment variables:
# GOOGLE_APPLICATION_CREDENTIALS=the path to your service account credentials file - or - GCP_CREDENTIALS: your service account json string
# GCP_PROJECT=the name of your project e.g. development-12345
# TERRAFORM_PATH=the path to your terraform binary; will default to "terraform"
set -euxo pipefail

ssh-keygen -f id_rsa -t rsa -N ''
chmod 600 id_rsa

# download the latest terraform binary in the current working directory
terraform_latest_version=$(curl -s "https://api.github.com/repos/hashicorp/terraform/releases/latest" | grep "tag_name" | grep -Po "(\d|\.)+")
base_url="https://releases.hashicorp.com/terraform/{version}/terraform_{version}_linux_amd64.zip"
terraform_download_url=$(echo ${base_url} | sed "s/{version}/$terraform_latest_version/g")
zip="terraform.zip"
wget --output-document="$zip" "$terraform_download_url"
unzip "$zip"
rm "$zip"

if [[ ! -v TERRAFORM_PATH ]]
then
  TERRAFORM_PATH="terraform"
fi

cd gcp
if [[ ! -v GOOGLE_APPLICATION_CREDENTIALS ]]
then
  echo "$GCP_CREDENTIALS" > creds.json
  export GOOGLE_APPLICATION_CREDENTIALS=${PWD}/creds.json
fi
${TERRAFORM_PATH} init
${TERRAFORM_PATH} validate -var "gcp_project=${GCP_PROJECT}" -var "gcp_ssh_pub_key_file=${PWD}/../id_rsa.pub"
${TERRAFORM_PATH} plan -var "gcp_project=${GCP_PROJECT}" -var "gcp_ssh_pub_key_file=${PWD}/../id_rsa.pub"
${TERRAFORM_PATH} validate -var-file desired_cluster_profile.tfvars.example -var "gcp_project=${GCP_PROJECT}" -var "gcp_ssh_pub_key_file=${PWD}/../id_rsa.pub"
${TERRAFORM_PATH} plan -var-file desired_cluster_profile.tfvars.example -var "gcp_project=${GCP_PROJECT}" -var "gcp_ssh_pub_key_file=${PWD}/../id_rsa.pub"

cd ../aws
${TERRAFORM_PATH} init
${TERRAFORM_PATH} validate
${TERRAFORM_PATH} plan
${TERRAFORM_PATH} validate -var-file desired_cluster_profile.tfvars.example
${TERRAFORM_PATH} plan -var-file desired_cluster_profile.tfvars.example

cd ../azure
${TERRAFORM_PATH} init
${TERRAFORM_PATH} validate
${TERRAFORM_PATH} plan
${TERRAFORM_PATH} validate -var-file desired_cluster_profile.tfvars.example
${TERRAFORM_PATH} plan -var-file desired_cluster_profile.tfvars.example
