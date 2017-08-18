# Upgrade from Open DC/OS to Enterprise DC/OS Using Module Only 
_To use terraform version prior to v0.10.0 remove `-from-module` from the commands._

## High Level Procedure

In order for an administrator to go from Open DC/OS to Enterprise, one must take the steps below for a successful and safe upgrade path.

1. Install DC/OS Open as usual using the open documentation at https://dcos.io/docs/1.9/installing/custom/advanced/
2. Perform the DC/OS EE Upgrade instructions but with `security: disabled` using the enterprise documentation here: https://docs.mesosphere.com/1.9/installing/custom/advanced/.
3. Once DC/OS EE Upgrade is complete, you will now follow all the DC/OS EE instruction going forward.

## terraform-dcos Default Install and Upgrade Procedure 

_Step assumes you have deployed github.com/bernadinm/terraform-dcos and now you want to go to Mesosphere's enterprise repo using github.com/mesosphere/enterprise-terraform-dcos._

### Current Desired Cluster Config

Here is an example config that was deployed using bernadinm/terraform-dcos. 

```bash
cat > desired_cluster_profile << EOF
dcos_version = "1.9.2"
num_of_masters = "3"
num_of_private_agents = "2"
num_of_public_agents = "1"
expiration = "3h"
EOF
```

### Steps used to initialize and deploy bernadinm/terraform-dcos (if starting anew)

```bash
terraform init -from-module github.com/bernadinm/terraform-dcos//aws
terraform apply -var-file desired_cluster_profile
```

### Pull down enterprise-terraform-dcos and initialize (Open To Enterprise: Start Here)

Change your source of your community module to our enterprise module that contains the DC/OS download bits.

i.e Change `source = "./modules/dcos-core"` or `source = "github.com/bernadinm/tf_dcos_core"` into this below:

 ```bash
 source = "git@github.com:mesosphere/terraform-dcos-enterprise//aws/modules/dcos-core"
 ````


### Modify your terraform script to include disabled security and state as upgrade

Add `dcos_security = "disabled"` and `state = "upgrade"` your upgrade_cluster_profile. We will add this to our desired_cluster_profile to only just include `dcos_security = "disabled"`.

```bash
cat > upgrade_cluster_profile << EOF
# -------------------
state = "upgrade"
# -------------------
dcos_version = "1.9.2"
num_of_masters = "3"
num_of_private_agents = "2"
num_of_public_agents = "1"
expiration = "3h"
dcos_security = "disabled"
EOF
```

### Update the desired_cluster_profile

```bash
echo 'dcos_security = "disabled"' >> desired_cluster_profile
```
```bash
more desired_cluster_profile
dcos_version = "1.9.2"
num_of_masters = "3"
num_of_private_agents = "2"
num_of_public_agents = "1"
expiration = "3h"
dcos_security = "disabled"
```

### Upgrade from Open to Enterprise

Now we can upgrade the cluster. When you do a terraform plan, you can see bootstrap will be triggered to do an update as it sees that there is now an enteprise trigger. Go ahead and confirm the changes then perform a terraform apply.

```bash
terraform get
terraform plan -var-file upgrade_cluster_profile # Confirm changes (bootstrap node should see security "disabled" trigger change)
terraform apply -var-file upgrade_cluster_profile  # Apply upgrade
```
### Post upgrade

You continue to use your _desired_cluster_profile_ which now includes your `dcos_security` and if we plan to upgrade this security, you can follow standard procedure. 

```bash
terraform apply -var-file desired_cluster_profile
```
