# Install Mesosphere DC/OS on AWS

## Prerequisites
- [Terraform 0.11.x](https://www.terraform.io/downloads.html)
- AWS SSH Keys 
- AWS IAM Keys

## Getting Started

1. Create directory
2. Initialize Terraform
3. Configure AWS SSH and IAM keys
4. Configure settings
5. Apply Terraform


## Create Installer Directory

Make your directory where Terraform will download and place your Terraform infrastructure files.

```bash
mkdir dcos-installer
cd dcos-installer
```

Run this command below to have Terraform initialized from this repository. There is **no git clone of this repo required** as Terraform performs this for you.

```
terraform init -from-module github.com/dcos/terraform-dcos/aws
cp desired_cluster_profile.tfvars.example desired_cluster_profile.tfvars
```

## Configure AWS SSH Keys

You can either upload your existing SSH keys or use an SSH key already created on AWS. 

* **Upload existing key**:
    To upload your own key not stored on AWS, read [how to import your own key](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws)  
    
* **Create new key**:
    To create a new key via AWS, read [how to create a key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair) 
    
When complete, retrieve the key pair name and ensure that it matches the `ssh_key_name` in your [desired_cluster_profile.tfvars](/aws/desired_cluster_profile.tfvars.example). 

**Note**: The [desired_cluster_profile.tfvars](/aws/desired_cluster_profile.tfvars.example) always takes precedence over the [variables.tf](/aws/variables.tf) and is **best practice** for any variable changes that are specific to your cluster. 

When you have your key available, you can use ssh-add.

```bash
ssh-add ~/.ssh/path_to_you_key.pem
```

**Note**: When using an SSH agent it is best to add the command above to your `~/.bash_profile`. Next time your terminal gets reopened, it will reload your keys automatically.

## Configure IAM AWS Keys

You will need your AWS `aws_access_key_id` and `aws_secret_access_key`. If you don't have one yet, you can get them from the [AWS access keys documentation](
http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html). 

When you get them, you can install it in your home directory. The default location is `$HOME/.aws/credentials` on Linux and macOS, or `"%USERPROFILE%\.aws\credentials"` for Windows users.

Here is an example of the output when you're done:

```bash
$ cat ~/.aws/credentials
[default]
aws_access_key_id = ACHEHS71DG712w7EXAMPLE
aws_secret_access_key = /R8SHF+SHFJaerSKE83awf4ASyrF83sa471DHSEXAMPLE
```

**Note**: `[default]` is the name of the `aws_profile`. You may select a different profile to use in Terraform by adding it to your `desired_cluster_profile.tfvars` as `aws_profile = "<INSERT_CREDENTIAL_PROFILE_NAME_HERE>"`.

## Deploy DC/OS

### Deploying with Custom Configuration

The default variables are tracked in the [variables.tf](/aws/variables.tf) file. Since this file can be overwritten during updates when you may run `terraform get --update` when you fetch new releases of DC/OS to upgrade to, it's best to use the [desired_cluster_profile.tfvars](/aws/desired_cluster_profile.tfvars.example) and set your custom Terraform and DC/OS flags there. This way you can keep track of a single file that you can use manage the lifecycle of your cluster.

#### Supported Operating Systems

Here is the [list of operating systems supported](/aws/modules/dcos-tested-aws-oses/platform/cloud/aws).

#### Supported DC/OS Versions

Here is the [list of DC/OS versions supported](https://github.com/dcos/tf_dcos_core/tree/master/dcos-versions).

**Note**: Master DC/OS version is not meant for production use. It is only for CI/CD testing.

To apply the configuration file, you can use this command below.

```bash
terraform apply -var-file desired_cluster_profile.tfvars
```

## Advanced YAML Configuration

We have designed this project to be flexible. Here are the example working variables that allows very deep customization by using a single `tfvars` file.

For advanced users with stringent requirements, here are DC/OS flag examples you can simply paste in `desired_cluster_profile.tfvars`.

```bash
$ cat desired_cluster_profile.tfvars
dcos_version = "1.11.1"
os = "centos_7.3"
num_of_masters = "3"
num_of_private_agents = "2"
num_of_public_agents = "1"
ssh_key_name = "default" 
dcos_cluster_name = "DC/OS Cluster"
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
 - "169.254.169.254"
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
```
**Note**: The YAML comment is required for the DC/OS specific YAML settings.

## Upgrading DC/OS  

You can upgrade your DC/OS cluster with a single command. This Terraform script was built to perform installs and upgrades from the inception of this project. 

With the upgrade procedures below, you can also have finer control on how masters or agents upgrade at a given time. This will give you the ability to change the parallelism of master or agent upgrades.

###  Rolling Upgrade

#### Masters Sequentially, Agents Parellel

Supported upgraded by dcos.io.

```bash
terraform apply -var-file desired_cluster_profile.tfvars -var state=upgrade -target null_resource.bootstrap -target null_resource.master -parallelism=1
terraform apply -var-file desired_cluster_profile.tfvars -var state=upgrade
```

#### All Roles Simultaniously

Not supported by dcos.io but it works without dcos_skip_checks enabled.

```bash
terraform apply -var-file desired_cluster_profile.tfvars -var state=upgrade
```

## Maintenance

If you would like to add more or remove agents from your cluster, you can do so by telling Terraform your desired state and it will make sure it gets you there. 

For example, if I have 2 private agents and 1 public agent in my `-var-file` I can override that flag by specifying the `-var` flag. It has higher priority than the `-var-file`.

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

## Redeploy an Existing Master

If you wanted to redeploy a problematic master (ie. storage filled up, not responsive, etc), you can tell Terraform to redeploy during the next cycle.

**Note:** This only applies to DC/OS clusters that have set their `dcos_master_discovery` to `master_http_loadbalancer` and not `static`.

### Master Node

Taint master node:

```bash
terraform taint aws_instance.master.0 # The number represents the agent in the list
```

Redeploy master node:

```bash
terraform apply -var-file desired_cluster_profile
```

## Redeploy an Existing Agent

If you wanted to redeploy a problematic agent, (ie. storage filled up, not responsive, etc), you can tell terraform to redeploy during the next cycle.


### Private Agents

Taint private agent:

```bash
terraform taint aws_instance.agent.0 # The number represents the agent in the list
```

Redeploy agent:

```bash
terraform apply -var-file desired_cluster_profile
```


### Public Agents

Taint private agent:

```bash
terraform taint aws_instance.public-agent.0 # The number represents the agent in the list
```

Redeploy agent:

```bash
terraform apply -var-file desired_cluster_profile
```

## Experimental

### Adding GPU Private Agents

**Note: Best used with DC/OS 1.9 and above**

As of Mesos 1.0, which now supports GPU agents, you can experiment with them immediately by simply removing `.disabled` from `dcos-gpu-agents.tf.disabled`. Once you do that, you can simply perform `terraform apply` and the agents will be deployed and configure and automatically join your mesos cluster. The default of `num_of_gpu_agents` is `1`. You can also remove GPU agents by simply adding `.disabled` and it will exit as well.



#### Add GPU Private Agents

```bash
mv dcos-gpu-agents.tf.disabled dcos-gpu-agents.tf
terraform get
terraform apply -var-file desired_cluster_profile --var num_of_gpu_agents=3
```

#### Remove GPU Private Agents

```bash
mv dcos-gpu-agents.tf dcos-gpu-agents.tf.disabled
terraform apply -var-file desired_cluster_profile
```


## Destroy Cluster

You can shutdown/destroy all resources from your environment by running this command below:

```bash
terraform destroy -var-file desired_cluster_profile
```

  ## Roadmap

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
