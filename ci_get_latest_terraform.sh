#!/bin/bash
# Downloads the latest release of terraform for linux in the current working directory
set -euxo pipefail

terraform_latest_version=`curl -s "https://api.github.com/repos/hashicorp/terraform/releases/latest" | grep -o "tag_name\": \"[^\"]*\"" | grep -Po "(\d|\.)+"`
base_url="https://releases.hashicorp.com/terraform/{version}/terraform_{version}_linux_amd64.zip"
terraform_download_url=`echo $base_url | sed "s/{version}/$terraform_latest_version/g"`
zip="terraform.zip"
wget --output-document="$zip" "$terraform_download_url"
unzip "$zip"
rm "$zip"

