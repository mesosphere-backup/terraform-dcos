&#x1F4D9; **Disclaimer: For Internal Mesosphere Employees Usage. Not for external users or customers at this time.**

# Enterprise DC/OS on AWS with Terraform

## Getting Started

### Install Terraform

If you're on a Mac environment with homebrew installed, run this command.

```bash
brew install terraform
```

If you want to leverage the terraform installer, feel free to check out https://www.terraform.io/downloads.html.

### Configure your Cloud Provider Credentials

##### Configure your AWS ssh Keys

In the `variable.tf` there is a `ssh_key_name` variable. This key must be added to your host machine running your terraform script as it will be used to log into the machines to run setup scripts. The default is `default`. You can find aws documentation that talks about this [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws).

When you have your key available, you can use ssh-add.

```bash
ssh-add ~/.ssh/path_to_you_key.pem
```

_*NOTE*: When using an ssh agent it is best to add it the command above to your `~/.bash_profile`, next time your terminal gets reopened, it will reload your keys automatically._

##### Configure your IAM AWS Keys

You will need your AWS aws_access_key_id and aws_secret_access_key. If you don't have one yet, you can get them from the AWS documentation [here](
http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html). When you finally get them, you can install it in your home directory. The default location is `$HOME/.aws/credentials` on Linux and OS X, or `"%USERPROFILE%\.aws\credentials"` for Windows users.

Here is an example of the output when you're done:

```bash
$ cat ~/.aws/credentials
[default]
aws_access_key_id = ACHEHS71DG712w7EXAMPLE
aws_secret_access_key = /R8SHF+SHFJaerSKE83awf4ASyrF83sa471DHSEXAMPLE
```

## Example Terraform Deployments

### Quick Start

We've provided all the sensible defaults that you would want to play around with DC/OS. Just run this command to deploy a multi-master setup in the cloud. Three agents will be deployed for you. Two private agents, one public agent.

- There is no git clone of this repo required. Terraform does this for you under the hood.

```bash
terraform init -from-module git@github.com:mesosphere/enterprise-terraform-dcos//aws
terraform apply
```

###### Choosing Different AWS Credential Profiles

If you have different types of AWS profiles that you use within your organization, you can specify which credentials/keys you want terraform to use by appending this flag to terraform apply `-var aws_profile="default_or_custom_profile"`

### Custom terraform-dcos variables

The default variables are tracked in the [variables.tf](/aws/variables.tf) file. Since this file can be overwritten during updates when you may run `terraform get --update` when you want to fetch new releases of DC/OS to upgrade too, its best to use the [desired_cluster_profile.tfvars](/aws/desired_cluster_profile.tfvars.example) and set your custom terraform and DC/OS flags there. This way you can keep track of a single file that you can use manage the lifecycle of your cluster.

###### Supported Operating Systems

For a list of supported operating systems for this repo, see the ones that DC/OS recommends [here](https://docs.mesosphere.com/1.10/installing/oss/custom/system-requirements/). You can find the list that Terraform for this repo [here](/aws/modules/dcos-tested-aws-oses/platform/cloud/aws).

###### Supported DC/OS Versions

For a list of all the DC/OS versions that this repository supports, you can find them at the `tf_dcos_core` module [here](https://github.com/dcos/tf_dcos_core/tree/master/dcos-versions).

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

## Redeploy an existing Master

If you wanted to redeploy a problematic master (ie. storage filled up, not responsive, etc), you can tell terraform to redeploy during the next cycle.

**NOTE:** This only applies to DC/OS clusters that have set their `dcos_master_discovery` to `master_http_loadbalancer` and not `static`.

### Master Node

**Taint Master Node**

```bash
terraform taint aws_instance.master.0 # The number represents the agent in the list
```

**Redeploy Master Node**

```bash
terraform apply -var-file desired_cluster_profile
```

## Redeploy an existing Agent

If you wanted to redeploy a problematic agent, (ie. storage filled up, not responsive, etc), you can tell terraform to redeploy during the next cycle.


### Private Agents

**Taint Private Agent**

```bash
terraform taint aws_instance.agent.0 # The number represents the agent in the list
```

**Redeploy Agent**

```bash
terraform apply -var-file desired_cluster_profile
```


### Public Agents

**Taint Private Agent**

```bash
terraform taint aws_instance.public-agent.0 # The number represents the agent in the list
```

**Redeploy Agent**

```bash
terraform apply -var-file desired_cluster_profile
```

### Bootstrap Node

**Taint Bootstrap Node**

```bash
terraform taint aws_instance.bootstrap
```

**Redeploy Bootstrap Node**

```bash
terraform apply -var-file desired_cluster_profile
```

### Experimental

#### Adding GPU Private Agents

*NOTE: Best used with DC/OS 1.9*

As of Mesos 1.0, which now supports GPU agents, you can experiment with them immediately by simply removing `.disabled` from `dcos-gpu-agents.tf.disabled`. Once you do that, you can simply perform `terraform apply` and the agents will be deployed and configure and automatically join your mesos cluster. The default of `num_of_gpu_agents` is `1`. You can also remove GPU agents by simply adding `.disabled` and it will exit as well.



##### Add GPU Private Agents

```bash
mv dcos-gpu-agents.tf.disabled dcos-gpu-agents.tf
terraform get
terraform apply -var-file desired_cluster_profile --var num_of_gpu_agents=3
```

##### Remove GPU Private Agents

```bash
mv dcos-gpu-agents.tf dcos-gpu-agents.tf.disabled
terraform apply -var-file desired_cluster_profile
```


### Destroy Cluster

You can shutdown/destroy all resources from your environment by running this command below

```bash
terraform destroy -var-file desired_cluster_profile
```

  # Roadmaps

  - [X] Support for AWS
  - [X] Support for CoreOS
  - [X] Support for Public Agents
  - [X] Support for expanding Private Agents
  - [X] Support for expanding Public Agents
  - [X] Support for specific versions of CoreOS
  - [X] Support for Centos
  - [X] Secondary support for specific versions of Centos
  - [X] Support for RHEL
  - [ ] Secondary support for specific versions of RHEL
  - [ ] Multi AZ Support
