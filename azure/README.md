&#x1F4D9; **Disclaimer: Community supported repository. Not supported by Mesosphere directly.**

# Open DC/OS on Azure with Terraform

## Getting Started

### Install Terraform

If you're on a Mac environment with homebrew installed, run this command.

```bash
brew install terraform
```

If you want to leverage the terraform installer, feel free to check out https://www.terraform.io/downloads.html.

### Configure your Cloud Provider Credentials

#### Configure your Azure ssh Keys

Set the private key that you will be you will be using to your ssh-agent and set public key in terraform.

```bash
ssh-add ~/.ssh/your_private_key.pem
```

```bash
cat desired_cluster_profile
...
ssh_pub_key = "INSERT_PUBLIC_KEY_HERE"
...
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
```

#### Source Credentials

Set your environment variables by sourcing the files before you run any terraform commands.

```bash
$ source ~/.azure/credentials
```


### Quick Start

We've provided all the sensible defaults that you would want to play around with DC/OS. Just run this command to deploy a multi-master setup in the cloud. Three agents will be deployed for you. Two private agents, one public agent.

- There is no git clone of this repo required. Terraform does this for you under the hood.

_*Note:* Create a new directory before the command below as terraform will write its files within the current directory._

```bash
terraform init -from-module github.com/dcos/terraform-dcos//azure
terraform apply
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

## Example Terraform Deployments
#### Pull down the DC/OS terraform scripts below

There is a module called `dcos-tested-azure-oses` that contains all the tested scripts per operating system. The deployment strategy is based on a bare image coupled with a prereq `script.sh` to get it ready to install dcos-core components. Its simple to add other operating systems by adding the AMI, region, and install scripts to meet the dcos specifications that can be found [here](https://dcos.io/docs/1.9/installing/custom/system-requirements/) and [here](https://dcos.io/docs/1.9/installing/custom/system-requirements/install-docker-centos/) as an example.


For CoreOS 1235.9.0:
```bash
terraform init -from-module git@github.com:mesosphere/terraform-dcos-enterprise//azure
terraform plan --var os=coreos_1235.9.0
```

For CoreOS 835.13.0:

```bash
terraform init -from-module git@github.com:mesosphere/terraform-dcos-enterprise//azure
terraform plan --var os=coreos_835.13.0 --var dcos_overlay_enable=disable # This OS cannot support docker networking
```

For Centos 7.3:

```bash
terraform init -from-module git@github.com:mesosphere/terraform-dcos-enterprise//azure
terraform plan --var os=centos_7.3
```

## Pro-tip: Use Terraform’s -var-file

When reading the commands below relating to installing and upgrading, it may be easier for you to keep all these flags in a file instead. This way you can make a change to the file and it will persist when you do other commands to your cluster in the future.

For example:

This command below already has the flags on what I need to install such has:
* DC/OS Version 1.8.8
* Masters 3
* Private Agents 2
* Public Agents 1
* SSH Public Key <Testing Pub Key>

```bash
terraform apply -var-file desired_cluster_profile
```

When we view the file, you can see how you can save your state of your cluster:

```bash
$ cat desired_cluster_profile
num_of_masters = "3"
num_of_private_agents = "2"
num_of_public_agents = "1"
dcos_security = "permissive"
dcos_version = "1.8.8"
ssh_pub_key = "INSERT_PUBLIC_KEY_HERE"
```

When reading the instructions below regarding installing and upgrading, you can always use your `--var-file` instead to keep track of all the changes you've made. It's easy to share this file with others if you want them to deploy your same cluster. Never save `state=upgrade` in your `--var-file`, it should be only used for upgrades or one time file changes.


## Installing DC/OS

If you wanted to install a specific version of DC/OS you can either use the stable versions or early access. You can also pick and choose any version if you like when you're first starting out. On the section below, this will explain how you automate upgrades when you're ready along with changing what order you would like them upgraded.

### DC/OS Stable (1.8.8)
```bash
terraform apply --var dcos_version=1.8.8
```

### DC/OS EA (1.9)
```bash
terraform apply -var dcos_version=1.9.0
```

### DC/OS Master (default is stable)
```bash
terraform apply
```

### Config.yaml Modification

#### Recommended Configuration

You can modify all the DC/OS config.yaml flags via terraform. Here is an example of using the master_http_loadbalancer for cloud deployments. **master_http_loadbalancer is recommended for production**. You will be able to replace your masters in a multi master environment. Using the default static backend will not give you this option.

Here is an example default profile that will allow you to do this.

```bash
$ cat desired_cluster_profile
num_of_masters = "3"
num_of_private_agents = "2"
num_of_public_agents = "1"
dcos_security = "permissive"
dcos_version = "1.8.8"
dcos_master_discovery = "master_http_loadbalancer"
dcos_exhibitor_storage_backend = "azure"
ssh_pub_key = "INSERT_PUBLIC_KEY_HERE"
```

**NOTE:** This will append your exhibitor_azure_account_name, exhibitor_azure_account_key and exhibitor_azure_prefix key in your config.yaml on your bootstrap node so DC/OS will know how to upload its state to the azure storage backend.

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
dcos_license_key_contents = "<INSERT_LICENSE_HERE>"
ssh_pub_key = "INSERT_PUBLIC_KEY_HERE"
```
_Note: The YAML comment is required for the DC/OS specific YAML settings._

## Upgrading DC/OS

You can upgrade your DC/OS cluster with a single command. This terraform script was built to perform installs and upgrades from the inception of this project. With the upgrade procedures below, you can also have finer control on how masters or agents upgrade at a given time. This will give you the ability to change the parallelism of master or agent upgrades.

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
-var-file desired_cluster_profile \
--var num_of_private_agents=5 \
--var num_of_public_agents=3
```

### Removing Agents

```bash
terraform apply \
-var-file desired_cluster_profile \
--var num_of_private_agents=1 \
--var num_of_public_agents=1
```

**Important**: Always remember to save your desired state in your `desired_cluster_profile`

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
terraform apply -var-file desired_cluster_profile
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
terraform apply -var-file desired_cluster_profile
```


### Public Agents

#### Taint Private Agent

```bash
terraform taint azurerm_virtual_machine.public-agent.0 # The number represents the agent in the list
```

#### Redeploy Agent

```bash
terraform apply -var-file desired_cluster_profile
```

### Optional Mesosphere Internal AWS Expiration Tags (Cloud Cluster)

If you have [cloudcleaner](https://github.com/mesosphere/cloudcleaner), you can take advantge of the expiration and owner variable. At Mesosphere, we have this setup in our environment. If you dont have it in yours, you can ignore this. It will simply tag your instances with expiration, but it will never destroy your cluster.

```bash
terraform apply --var expiration=3h --var owner=mbernadin
```

By default, the expiration is `1h` and terraform will try to run `whoami` to determine who the owner is automatically. You can always change your expiration and let terraform do the rest.

### Experimental

#### Adding GPU Private Agents

Coming soon!

### Destroy Cluster

You can shutdown/destroy all resources from your environment by running this command below

```bash
terraform destroy -var-file desired_cluster_profile
```

##### Destroy Optimization

Azure's shutdown can take ~10 minutes at times compared to other cloud providers. The fastest way to destroy is to delete the resource group.

```
az group delete --name $(jq -r '.modules[0].resources."azurerm_resource_group.dcos".primary.attributes.name' terraform.tfstate) --no-wait --yes
rm terraform.tfstate*
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
