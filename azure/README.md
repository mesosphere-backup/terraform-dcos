&#x1F4D9; **Disclaimer: Community supported repository. Not supported by Mesosphere directly.**

# Open DC/OS on Azure with Terraform

## Prerequisites
- [Terraform 0.11.x](https://www.terraform.io/downloads.html)
- Azure SSH Private Key
- Azure SSH Public Key
- Azure ID Keys

## Getting Started

1. Create directory
2. Initialize Terraform
3. Configure Azure SSH and Azure ID keys
4. Configure settings
5. Apply Terraform

### Install Terraform

If you're on a Mac environment with homebrew installed, run this command.

```bash
brew install terraform
```

If you want to leverage the terraform installer, feel free to check out https://www.terraform.io/downloads.html.
### Create Installer Directory

Make your directory where Terraform will download and place your Terraform infrastructure files.

```bash
mkdir dcos-installer
cd dcos-installer
```

Run this command below to have Terraform initialized from this repository. There is **no git clone of this repo required** as Terraform performs this for you.
```
terraform init -from-module github.com/dcos/terraform-dcos/azure
cp desired_cluster_profile.tfvars.example desired_cluster_profile.tfvars
```

### Configure your Cloud Provider Credentials

#### Configure your Azure ssh Keys

Set the private key that you will be you will be using to your ssh-agent and set public key in terraform.

```bash
ssh-add ~/.ssh/your_private_key.pem
```

```bash
cat desired_cluster_profile.tfvars
ssh_pub_key = "INSERT_PUBLIC_KEY_HERE"
```

#### Configure your Azure ID Keys

Follow the Terraform instructions [here](https://www.terraform.io/docs/providers/azurerm/#creating-credentials) to setup your Azure credentials to provide to terraform.

When you've successfully retrieved your output of `az account list`, create a source file to easily run your credentials in the future.


```bash
$ cat ~/.azure/credentials
export ARM_TENANT_ID=45ef06c1-a57b-40d5-967f-88cf8example
export ARM_CLIENT_SECRET=Lqw0kyzWXyEjfha9hfhs8dhasjpJUIGQhNFExAmPLE
export ARM_CLIENT_ID=80f99c3a-cd7d-4931-9405-8b614example
export ARM_SUBSCRIPTION_ID=846d9e22-a320-488c-92d5-41112example
$ source ~/.azure/credentials
```

#### Source Credentials

Set your environment variables by sourcing the files before you run any terraform commands.

```bash
$ source ~/.azure/credentials
```



### Custom terraform-dcos variables

The default variables are tracked in the [variables.tf](/aws/variables.tf) file. Since this file can be overwritten during updates when you may run `terraform get --update` when you want to fetch new releases of DC/OS to upgrade too, its best to use the [desired_cluster_profile.tfvars](/aws/desired_cluster_profile.tfvars.example) and set your custom terraform and DC/OS flags there. This way you can keep track of a single file that you can use manage the lifecycle of your cluster.

###### Supported Operating Systems

For a list of supported operating systems for this repo, see the ones that DC/OS recommends [here](https://docs.mesosphere.com/1.10/installing/oss/custom/system-requirements/). You can find the list that Terraform for this repo [here](/aws/modules/dcos-tested-aws-oses/platform/cloud/aws).

###### Supported DC/OS Versions

For a list of all the DC/OS versions that this repository supports, you can find them at the `tf_dcos_core` module [here](https://github.com/dcos/tf_dcos_core/tree/master/dcos-versions).

_*Note*: Master DC/OS version is not meant for production use. It is only for CI/CD testing._

To apply the configuration file, you can use this command below.

```bash
terraform apply -var-file desired_cluster_profile.tfvars
```

#### Advance YAML Configuration

We have designed this project to be flexible. Here are the example working variables that allows very deep customization by using a single `tfvars` file.

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
dcos_use_proxy = "yes"
dcos_http_proxy = "example.com"
dcos_https_proxy = "example.com"
dcos_no_proxy = <<EOF
# YAML
 - "internal.net"
 - "168.63.129.16"
EOF
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
ssh_pub_key = "INSERT_PUBLIC_KEY_HERE"
```
_Note: The YAML comment is required for the DC/OS specific YAML settings._

## Upgrading DC/OS  

You can upgrade your DC/OS cluster with a single command. This terraform script was built to perform installs and upgrades from the inception of this project. With the upgrade procedures below, you can also have finer control on how masters or agents upgrade at a given time. This will give you the ability to change the parallelism of master or agent upgrades.

### DC/OS Upgrades

#### Rolling Upgrade
###### Supported upgraded by dcos.io

##### Prerequisite:
Update your terraform scripts to gain access to the latest DC/OS version with this command below:

```
terraform get --update
# change dcos_version = "<desired_version>" in desired_cluster_profile.tfvars
```

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
# update num_of_private_agents = "5" in desired_cluster_profile.tfvars
terraform apply -var-file desired_cluster_profile.tfvars
```

### Removing Agents

```bash
# update num_of_private_agents = "2" in desired_cluster_profile.tfvars
terraform apply -var-file desired_cluster_profile.tfvars
```

**Important**: Always remember to save your desired state in your `desired_cluster_profile.tfvars`

## Redeploy an existing Master

If you wanted to redeploy a problematic master (ie. storage filled up, not responsive, etc), you can tell terraform to redeploy during the next cycle.

**NOTE:** This only applies to DC/OS clusters that have set their `dcos_master_discovery` to `master_http_loadbalancer` and not `static`.

### Master Node

#### Taint Master Node

```bash
terraform taint azurerm_virtual_machine.master.0 # The number represents the agent in the list
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
terraform taint azurerm_virtual_machine.agent.0 # The number represents the agent in the list
```

#### Redeploy Agent

```bash
terraform apply -var-file desired_cluster_profile.tfvars
```


### Public Agents

#### Taint Private Agent

```bash
terraform taint azurerm_virtual_machine.public-agent.0 # The number represents the agent in the list
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

  - [X] Support for Azure
  - [X] Support for CoreOS
  - [X] Support for Public Agents
  - [X] Support for expanding Private Agents
  - [X] Support for expanding Public Agents
  - [X] Support for specific versions of CoreOS
  - [X] Support for Centos
  - [X] Secondary support for specific versions of Centos
  - [X] Support for RHEL
  - [X] Secondary support for specific versions of RHEL
  - [X] Multi AZ support via Availability Sets
