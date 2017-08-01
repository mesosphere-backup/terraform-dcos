# Open DC/OS on AWS with Terraform

## Getting Started

### Install Terraform

If you're on a mac environment with homebrew installed, run this command.

```bash
brew install terraform
```

If you want to leverage the terraform installer, feel free to check out https://www.terraform.io/downloads.html.

### Configure your Cloud Provider Credentials

**Configure your AWS ssh Keys**

In the `variable.tf` there is a `key_name` variable. This key must be added to your host machine running your terraform script as it will be used to log into the machines to run setup scripts. The default is `default`. You can find aws documentation that talks about this [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws).

When you have your key available, you can use ssh-add.

```bash
ssh-add ~/.ssh/path_to_you_key.pem
```
**Configure your IAM AWS Keys**

You will need your AWS aws_access_key_id and aws_secret_access_key. If you dont have one yet, you can get them from the AWS documetnation [here](
http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html). When you finally get them, you can install it in your home directory. The default location is `$HOME/.aws/credentials` on Linux and OS X, or `"%USERPROFILE%\.aws\credentials"` for Windows users.

Here is an example of the output when you're done:

```bash
$ cat ~/.aws/credentials
[default]
aws_access_key_id = ACHEHS71DG712w7EXAMPLE
aws_secret_access_key = /R8SHF+SHFJaerSKE83awf4ASyrF83sa471DHSEXAMPLE
```

### Example Terraform Deployments

**Pull down the DC/OS terraform scripts below**

There is a module called `dcos-tested-aws-oses` that contains all the tested scripts per operating system. The deployment strategy is a base AMI coupled with a prereq `script.sh` to get it ready to install dcos-core components. Its simple to add other operating systems by adding the ami, region, and install scripts to meet the dcos specifications that can be found [here](https://dcos.io/docs/1.9/installing/custom/system-requirements/) and [here](https://dcos.io/docs/1.9/installing/custom/system-requirements/install-docker-centos/) as an example.


For CoreOS 1235.9.0:
```bash
terraform init github.com/bernadinm/terraform-dcos/aws
terraform plan --var os=coreos_1235.9.0
```

For CoreOS 835.13.0:

```bash
terraform init github.com/bernadinm/terraform-dcos/aws
terraform plan --var os=coreos_835.13.0 --var dcos_overlay_enable=disable # This OS cannot support docker networking
```

For Centos 7.2:

```bash
terraform init github.com/bernadinm/terraform-dcos/aws
terraform plan --var os=centos_7.2
```

## Pro-tip: Use Terraform’s -var-file

When reading the commands below relating to installing and upgrading, it may be easier for you to keep all these flags in a file instead. This way you can make a change to the file and it will persist when you do other commands to your cluster in the future.

For example:

This command below already has the flags on what I need to install such has:
* DC/OS Version 1.8.8
* Masters 3
* Private Agents 2
* Public Agents 1

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

You can modify all the DC/OS config.yaml flags via terraform. Here is an example of using the master_http_loadbalancer for cloud deployments. **master_http_loadbalancer is recommended for production**. You will be able to replace your masters in a multi master environment. Using the default static backend will not give you this option. 

Here is an example default profile that will allow you to do this. 

```bash
$ cat desired_cluster_profile
num_of_masters = "3"
num_of_private_agents = "2"
num_of_public_agents = "1"
dcos_security = "permissive"
dcos_version = "1.8.8"
dcos_aws_access_key_id = "ACHEHS71DG712w7EXAMPLE"
dcos_aws_secret_access_key = "/R8SHF+SHFJaerSKE83awf4ASyrF83sa471DHSEXAMPLE"
dcos_master_discovery = "master_http_loadbalancer"
dcos_exhibitor_storage_backend = "aws_s3"
dcos_exhibitor_explicit_keys = "true"
```

**NOTE:** This will append your aws_access_key_id and aws_secret_access_key key in your config.yaml on your bootstrap node so DC/OS will know how to upload its state to the aws_s3 bucket. 

## Upgrading DC/OS  

You can upgrade your DC/OS cluster with a single command. This terraform script was built to perform installs and upgrade from the inception of this project. With the upgrade procedures below, you can also have finer control on how masters or agents upgrade at a given time. This will give you the ability to change the parallelism of master or agent upgrades.

### DC/OS 1.8 Upgrades

#### Upgrading DC/OS 1.7 to DC/OS 1.8 Disabled

**Important**: DC/OS will is not designed to upgrade directly from disabled to strict. Please be responsible when using automation tools.

This command below will upgrade your masters and agents one at a time. It takes roughly 5 minutes per node, so depending on how many nodes, you may want to consider changing your parallelism to change the speed of your upgrade. 

**Prioritise Master Upgrades First**

If you take this route, you can use a few more commands but this will allow you upgrade your master nodes first, one at a time, then upgrade the agents simuanioustly with the next. Terraforms parallel algorithm will walk the graph in any order. It may do one agent first, a master second, etc. You would need to target your master resource so you can upgrade the masters first then change the parallelism back to any number for the agents. 

**Master upgrade sequentially one at a time**
```bash
terraform apply \
--var os=coreos_1235.9.0 \
--var dcos_version=1.8.8 \
--var state=upgrade \
--var dcos_security=disabled \
-parallelism=1 \
-target=null_resource.master
 ```

**Upgrade everything else in parallel**
 ```bash
terraform apply \
--var os=coreos_1235.9.0 \
--var dcos_version=1.8.8 \
--var state=upgrade \
--var dcos_security=disabled
  ```
  
  *NOTE: the default for parallelism is 10. You can change this value to control how many nodes you want upgraded at any given time*


  ### Upgrading with DC/OS 1.8 Security Changes

  **Important**: DC/OS will is not designed to upgrade directly from disabled to strict. Please be responsible when using automation tools.

  #### Upgrading DC/OS 1.8 Disabled to DC/OS 1.8 Permissive

  On DC/OS 1.8 clusters, testing shows that you can actually upgrade the masters simultaneously from DC/OS 1.8 and 1.9, (not 1.7). So going forward, we can drop the `--parallelism=1` entirely. If this changes on a new version, I will be sure to call this out. To go from DC/OS 1.8 Disbaled to DC/OS 1.8 Permissive, you can upgrade by running this command below. Notice the `state` is still upgrade, because we're still doing an inplace upgrade to the same version. This allows you to make DC/OS cluster-wide changes on your cluster.

  ```bash
  terraform apply \
  --var dcos_version=1.8.8 \
  --var state=upgrade \
  --var dcos_security=permissive
  ```

  #### Upgrading DC/OS 1.8 Permissive to DC/OS 1.8 Strict

  This command below will upgrade you from DC/OS permissive to DC/OS strict mode

  ```bash
  terraform apply \
  --var dcos_version=1.8.8 \
  --var state=upgrade \
  --var dcos_security=strict
  ```

  ### DC/OS 1.9 Upgrades

  **Important**: DC/OS documentation says that you cannot upgrade directly from 1.8 disabled to 1.9 while changing the version. We will err on the side of caution by following the instructions below as well.

  #### Upgrading DC/OS 1.8 Disabled to DC/OS 1.9 Disabled

  ```bash
  terraform apply \
  --var dcos_version=1.9.0 \
  --var state=upgrade \
  --var dcos_security=disabled
  ```

  #### Upgrading DC/OS 1.8 Permissive to DC/OS 1.9 Permissive

  ```bash
  terraform apply \
  --var dcos_version=1.9.0 \
  --var state=upgrade \
  --var dcos_security=permissive
  ```

  #### Upgrading DC/OS 1.8 Strict to DC/OS 1.9 Strict

  ```bash
  terraform apply \
  --var dcos_version=1.9.0 \
  --var state=upgrade \
  --var dcos_security=strict
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

### Experimental

#### Adding GPU Private Agents

*NOTE: Best used with DC/OS 1.9*

As of Mesos 1.0, which now supports GPU agents, you can experiment with them immediately by simply removing `.disabled` from `dcos-gpu-agents.tf.disabled`. Once you do that, you can simply perform `terraform apply` and the agents will be deployed and configure and automatically join your mesos cluster. The default of `num_of_gpu_agents` is `1`. You can also remove GPU agents by simply adding `.disabled` and it will exit as well.



##### Add GPU Private Agents

```bash
mv dcos-gpu-agents.tf.disabled dcos-gpu-agents.tf
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
terraform destroy
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


