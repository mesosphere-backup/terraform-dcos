&#x1F4D9; **Disclaimer: Community supported repository. Not supported by Mesosphere directly.**

# Open DC/OS on OpenStack with Terraform

## Things to Know

The current implemenetation ...

* Does setup a working DC/OS cluster on OpenStack
* Does not setup or use OpenStack load balancers
* Does apply floating IPs on the bootstrap and master nodes
* Does create separate security groups for bootstrap, master, public agent, and private agent.  Currently, all the security groups are the same and very open.
* Does not use OpenStack compute server groups.  Should we?
* Does use cloud init to partially provision servers and not via remote ssh execution
* Has been tested with CoreOS
* Has not been tested with CentOS
* Defaults to static DC/OS master discovery
* Has not been tested with exhibitor 

Was tested with OpenStack Mirantis for DC/OS version 1.11.

## Getting Started

### Configure your Cloud Provider Credentials

[Source your OpenStack RC file](https://docs.openstack.org/zh_CN/user-guide/common/cli-set-environment-variables-using-openstack-rc.html) and activate it by running the shell script.

### Pull down the DC/OS terraform scripts below

There is a module called `dcos-tested-openstack-oses` that contains all the tested scripts per operating system. The deployment strategy is based on a bare image coupled with a prereq `script.sh` to get it ready to install dcos-core components.

OS | Version | Tested
---|---------|-------
CoreOS | 1576.4.0 | Yes

NOTE: The default value for the variable `os` is `coreos`.

### Quick Start

We've provided sensible defaults that you would want to play around with DC/OS for setting up DC/OS.  The default will setup a multi-master deployment. Three agents will be deployed for you. Two private agents, one public agent.

There are several OpenStack related [variables](/openstack/variables.tf) that must be provided because these are unique to the OpenStack install that is being used:

* `master_instance_flavor`
* `bootstrap_instance_flavor`
* `private_agent_instance_flavor`
* `public_agent_instance_flavor`
* `os_floating_ip_pool`
* `os_image_name`
* `os_external_network_id`

You can create a [tfvars file](https://www.terraform.io/intro/getting-started/variables.html) to store the appropriate values for the required variables above.  Assume that your tfvars file is called `desired_cluster_profile.tfvars`.

- There is no git clone of this repo required. Terraform does this for you under the hood.

_*Note:* Create a new directory before the command below as terraform will write its files within the current directory._

```bash
mkdir dcos-installer
cd dcos-installer
terraform init -from-module github.com/dcos/terraform-dcos//openstack
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

If you would like to add more or remove (private) agents or public agents from your cluster, you can do so by telling terraform your desired state and it will make sure it gets you there.

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
terraform taint openstack_compute_instance_v2.masters.0 # The number represents the agent in the list
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
terraform taint openstack_compute_instance_v2.agent.0 # The number represents the agent in the list
```

#### Redeploy Agent

```bash
terraform apply -var-file desired_cluster_profile.tfvars
```


### Public Agents

#### Taint Private Agent

```bash
terraform taint openstack_compute_instance_v2.public-agent.0 # The number represents the agent in the list
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
