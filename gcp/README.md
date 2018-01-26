&#x1F4D9; **Disclaimer: Community supported repository. Not supported by Mesosphere directly.**

# Open DC/OS on GCP with Terraform
_Mission:  Allow for automated installs and upgrades for DC/OS on GCP._

## Prerequisites
- [Terraform 0.11.x](https://www.terraform.io/downloads.html)
- GCP Cloud Credentials. _[configure via: `gcloud auth login`](https://cloud.google.com/sdk/downloads)_
- SSH Keys
- Existing Google Project. Soon automated with Terraform using project creation as documented [here.](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform)

## Install Google SDK

Run this command to authenticate to the Google Provider. This will bring down your keys locally on the machine for terraform to use.

```bash
$ gcloud auth login
$ gcloud auth application-default login
```

## Configure your GCP SSH Keys

Set the private key that you will be you will be using to your ssh-agent and set public key in terraform. This will allow you to log into to the cluster after DC/OS is deployed and also helps Terraform setup your cluster at deployment time.

```bash
$ ssh-add ~/.ssh/your_private_key.pem
```

```bash
$ cat desired_cluster_profile.tfvars
gcp_ssh_pub_key_file = "INSERT_PUBLIC_KEY_PATH_HERE"
...
```

## Configure a Pre-existing Google Project

Currently terraform-dcos assumes a project already exist in GCP to start deploying your resources against. This repo soon will have support for terraform to create projects on behalf of the user soon via this document [here](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform). For the time being a user will have to create this project before time or leverage an existing project.

```bash
$ cat desired_cluster_profile.tfvars
gcp_project = "massive-bliss-781"
...
```

## Example Terraform Deployments

### Quick Start

We've provided all the sensible defaults that you would want to play around with DC/OS. Just run this command to deploy a multi-master setup in the cloud. Three agents will be deployed for you. Two private agents, one public agent.

- There is no git clone of this repo required. Terraform does this for you under the hood.

```bash
terraform init -from-module github.com/dcos/terraform-dcos//gcp
terraform apply -var gcp_project="your_existing_project"
```

### Custom terraform-dcos variables

The default variables are tracked via in the [variables.tf](/gcp/variables.tf) file. Since this file can be overwritten during updates when you may run `terraform get --update` when you want to fetch new releases of DC/OS to upgrade too, its best to use the [desired_cluster_profile.tfvars](/gcp/desired_cluster_profile.tfvars.example) and set your custom terraform and DC/OS flags there. This way you can keep track of a single file that you can use manage the lifecycle of your cluster.

For list of supported operating systems for this repo which expands, we're supporting the ones that DC/OS recommends [here](https://docs.mesosphere.com/1.10/installing/oss/custom/system-requirements/). You can find the list that Terraform supports for this repo [here](http://github.com/bernadinm/tf_dcos_core).

To apply the configuration file, you can use this command below.

```bash
terraform apply -var-file desired_cluster_profile.tfvars
```

#### Advance YAML Configuration

In this project we have designed to be flexible. Here are the example working variables that allows very deep customization by using a single `tfvars` file.

This file can have as little to as large as the DC/OS advance YAML configuration below.


For advance users with stringent requirements, here are the DC/OS flags examples where you can simply paste your YAML configuration in your desired_cluster_profile.tfvars. The alternative to YAML is to convert it to JSON.  

```bash
$ cat desired_cluster_profile.tfvars
dcos_version = "1.10.2"
os = "centos_7.3"
num_of_masters = "3"
num_of_private_agents = "2"
num_of_public_agents = "1"
expiration = "6h"  
dcos_security = "permissive"
dcos_cluster_docker_credentials_enabled =  "true"
dcos_cluster_docker_credentials_write_to_etc = "true"
dcos_cluster_docker_credentials_dcos_owned = "false"
dcos_cluster_docker_registry_url = "https://index.docker.io"
dcos_overlay_network = <<EOF
# YAML
    vtep_subnet: 44.128.0.0/20
    vtep_mac_oui: 70:B3:D5:00:00:00
    overlays:
      - name: dcos
        subnet: 12.0.0.0/8
        prefix: 26
EOF
dcos_rexray_config = <<EOF
# YAML
  rexray:
    loglevel: warn
    modules:
      default-admin:
        host: tcp://127.0.0.1:61003
    storageDrivers:
    - ec2
    volume:
      unmount:
        ignoreusedcount: true
EOF
dcos_cluster_docker_credentials = <<EOF
# YAML
  auths:
    'https://index.docker.io/v1/':
      auth: Ze9ja2VyY3licmljSmVFOEJrcTY2eTV1WHhnSkVuVndjVEE=
EOF
gcp_ssh_pub_key_file = "INSERT_PUBLIC_KEY_PATH_HERE"
```
_Note: The YAML comment is required for the DC/OS specific YAML settings._

## Upgrading DC/OS  

You can upgrade your DC/OS cluster with a single command. This terraform script was built to perform installs and upgrade from the inception of this project. With the upgrade procedures below, you can also have finer control on how masters or agents upgrade at a given time. This will give you the ability to change the parallelism of master or agent upgrades.

### DC/OS Upgrades

#### Rolling Upgrade
###### Supported upgraded by dcos.io

##### Masters Sequentially, Agents Parellel:
```bash
terraform apply -var-file desired_cluster_profile.tfvars -var state=upgrade -target null_resource.bootstrap -target null_resource.master -parallelism=1
terraform apply -var-file desired_cluster_profile.tfvars -var state=upgrade
```

##### All Roles Simultaniously
###### Not supported by dcos.io but it works without dcos_skip_checks enabled.

```bash
terraform apply -var-file desired_cluster_profile.tfvars -var state=upgrade
```


## Maintenance

If you would like to add more or remove (private) agents or public agents from your cluster, you can do so by telling terraform your desired state and it will make sure it gets you there. For example, if I have 2 private agents and 1 public agent in my `-var-file` I can always override that flag by specifying the `-var` flag. It has higher priority than the `-var-file`.

### Adding Agents

```bash
terraform apply \
-var-file desired_cluster_profile.tfvars \
-var num_of_private_agents=5 \
-var num_of_public_agents=3
```

### Removing Agents

```bash
terraform apply \
-var-file desired_cluster_profile.tfvars \
-var num_of_private_agents=1 \
-var num_of_public_agents=1
```

**Important**: Always remember to save your desired state in your `desired_cluster_profile.tfvars`

## Redeploy an existing Master

If you wanted to redeploy a problematic master (ie. storage filled up, not responsive, etc), you can tell terraform to redeploy during the next cycle.

**NOTE:** This only applies to DC/OS clusters that have set their `dcos_master_discovery` to `master_http_loadbalancer` and not `static`.

### Master Node

#### Taint Master Node

```bash
terraform taint google_compute_instance.master.0 # The number represents the agent in the list
```

#### Redeploy Master Node

```bash
terraform apply -var-file desired_cluster_profile.tfvars
```

## Redeploy an existing Agent

If you wanted to redeploy a problematic agent, (ie. storage filled up, not responsive, etc), you can tell terraform to redeploy during the next cycle.


### Private Agents

#### Taint Private Agent

```bash
terraform taint google_compute_instance.agent.0 # The number represents the agent in the list
```

#### Redeploy Agent

```bash
terraform apply -var-file desired_cluster_profile.tfvars
```


### Public Agents

#### Taint Private Agent

```bash
terraform taint google_compute_instance.public-agent.0 # The number represents the agent in the list
```

#### Redeploy Agent

```bash
terraform apply -var-file desired_cluster_profile.tfvars
```

### Experimental

#### Adding GPU Private Agents

Coming soon!

### Destroy Cluster

You can shutdown/destroy all resources from your environment by running this command below

```bash
terraform destroy -var-file desired_cluster_profile.tfvars
```

  # Roadmaps

  - [X] Support for GCP
  - [X] Support for CoreOS
  - [X] Support for Public Agents
  - [X] Support for expanding Private Agents
  - [X] Support for expanding Public Agents
  - [X] Support for specific versions of CoreOS
  - [X] Support for Centos
  - [X] Secondary support for specific versions of Centos
  - [X] Support for RHEL
  - [X] Secondary support for specific versions of RHEL
  - [ ] Multi AZ support
