variable "key_name" {
  description = "Key name assicated with your instances for login"
  default = "default"
}

variable "user" {
  description = "Username of the OS"
  default = "core"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}

variable "os" {
  default = "coreos_1235.9.0"
  description = "Recommended DC/OS OSs are centos_7.2, coreos_1235.9.0, coreos_835.13.0"
}

variable "aws_instance_type" {
  description = "AWS default instance type"
  default = "m3.xlarge"
}

variable "num_of_private_agents" {
  description = "DC/OS Private Agents Count"
  default = 2
}

variable "num_of_public_agents" {
  description = "DC/OS Private Agents Count"
  default = 1
}

variable "num_of_masters" {
  description = "DC/OS Master Nodes Count (Odd only)"
  default = 3
}

variable "owner" {
  description = "Paired with Cloud Cluster Cleaner will notify on expiration via slack. Default is whoami. Can be overwritten by setting the value here"
  default = ""
}

variable "expiration" {
  description = "Paired with Cloud Cluster Cleaner will notify on expiration via slack"
  default = "1h"
}

variable "ip-detect" {
 description = "Used to determine the private IP address of instances"
 type = "map"

 default = {
  aws = "scripts/cloud/aws/ip-detect.aws.sh"
 }
}

variable "os-init-script" {
 description = "Init Scripts that runs post-AMI deployment and pre-DC/OS install" 
 type = "map"

 default = {
  coreos = "scripts/os/coreos/coreos-init.aws.sh"
  centos = "scripts/os/centos/centos-init.aws.sh"
 }
}

variable "instance_disk_size" {
 description = "Default size of the root disk (GB)"
 default = "128"
}

variable "custom_dcos_bootstrap_port" {
 default = "80"
 description = "Nginx Port for serving bootstrap files"
}

variable "custom_dcos_download_path" {
 default = ""
 description = "Custom DC/OS version path"
}

variable "dcos_security" {
 default = ""
 description = "DC/OS EE security mode: either disabled, permissive, or strict."
}

variable "dcos_resolvers" {
 default = [ "8.8.8.8", "8.8.4.4" ]
 description = "DNS Resolver for external name resolution"
}

variable "dcos_oauth_enabled" {
 default = ""
 description = "DC/OS Open Flag for Open Auth"
}

variable "dcos_master_discovery" {
 default = "static"
 description = "Ability to use an ELB or a static list for master descovery"
}

variable "dcos_aws_template_storage_bucket" {
 default = ""
 description = "This parameter specifies the name of your S3 bucket"
}

variable "dcos_aws_template_storage_bucket_path" {
 default = ""
 description = "This parameter specifies the S3 bucket storage path"
}

variable "dcos_aws_template_storage_region_name" {
 default = ""
 description = "This parameter specifies the S3 region"
}

variable "dcos_aws_template_upload" {
 default = ""
 description = "This parameter specifies whether to automatically upload the customized advanced templates to your S3 bucket"
}

variable "dcos_aws_template_storage_access_key_id" {
 default = ""
 description = "This parameters specifies the AWS Access Key ID"
}

variable "dcos_aws_template_storage_secret_access_key" {
 default = ""
 description = "This parameter specifies the AWS Secret Access Key"
}

variable "dcos_exhibitor_storage_backend" {
 default = "static"
 description = "specify an external storage system (static, zookeeper, azure, and aws_s3)"
}

variable "dcos_exhibitor_zk_hosts" {
 default = ""
 description = "This parameter specifies a comma-separated list (<ZK_IP>:<ZK_PORT>, <ZK_IP>:<ZK_PORT>, <ZK_IP:ZK_PORT>) of one or more ZooKeeper node IP and port addresses to use for configuring the internal Exhibitor instances"
}

variable "dcos_exhibitor_zk_path" {
 default = ""
 description = "This parameter specifies the filepath that Exhibitor uses to store data"
}

variable "dcos_aws_access_key_id" {
 default = ""
 description = "This parameter specifies AWS key ID"
}

variable "dcos_aws_region" {
 default = ""
 description = "This parameter specifies AWS region for your S3 bucket."
}

variable "dcos_aws_secret_access_key" {
 default = ""
 description = "This parameter specifies AWS secret access key"
}

variable "dcos_exhibitor_explicit_keys" {
 default = ""
 description = "This parameter specifies whether you are using AWS API keys to grant Exhibitor access to S3."
}

variable "dcos_s3_bucket" {
 default = ""
 description = "This parameter specifies name of your S3 bucket."
}

variable "dcos_s3_prefix" {
 default = ""
 description = "This parameter specifies S3 prefix to be used within your S3 bucket to be used by Exhibitor."
}

variable "dcos_exhibitor_azure_account_name" {
 default = ""
 description = "This parameter specifies the Azure Storage Account Name. If you specify azure for exhibitor backed set this value."
}

variable "dcos_exhibitor_azure_account_key" {
 default = ""
 description = "This parameter specifies a secret key to access the Azure Storage Account. If you specify azure for exhibitor backed set this value."
}

variable "dcos_exhibitor_azure_prefix" {
 default = ""
 description = "This parameter specifies the blob prefix to be used within your Storage Account to be used by Exhibitor. If you specify azure for exhibitor backed set this value."
}

variable "dcos_exhibitor_address" {
 default = ""
 description = "This required parameter specifies the location (preferably an IP address) of the load balancer in front of the masters."
}

variable "dcos_num_masters" {
 default = ""
 description = "This parameter specifies the number of Mesos masters in your DC/OS cluster. If master_discovery: static, do not use the num_masters parameter"
}

variable "dcos_customer_key" {
 default = ""
 description = "This parameter specifies the Enterprise DC/OS customer key."
}

variable "dcos_rexray_config_method" {
 default = ""
 description = "This parameter specifies the REX-Ray configuration method for enabling external persistent volumes in Marathon. "
}

variable "dcos_rexray_config_filename" {
 default = ""
 description = "Specify the path to a REX-Ray configuration file with rexray_config_filename"
}

variable "dcos_auth_cookie_secure_flag" {
 default = ""
 description = "This parameter specifies whether to allow web browsers to send the DC/OS authentication cookie through a non-HTTPS connection. Because the DC/OS authentication cookie allows access to the DC/OS cluster, it should be sent over an encrypted connection to prevent man-in-the-middle attacks."
}

variable "dcos_bouncer_expiration_auth_token_days" {
 default = ""
 description = "This parameter sets the auth token time-to-live (TTL) for Identity and Access Management."
}

variable "ssh_port" {
 default = "22"
 description = "This parameter specifies the port to SSH to"
}

variable "dcos_superuser_password_hash" {
 default = ""
 description = "This required parameter specifies the hashed superuser password. (EE only)"
}

variable "dcos_cluster_name" {
 default = ""
 description = "Name of the DC/OS Cluster"
}

variable "dcos_superuser_username" {
 default = ""
 description = "This required parameter specifies the Admin username. (EE only)"
}

variable "dcos_telemetry_enabled" {
 default = ""
 description = "This parameter specifies whether to enable sharing of anonymous data for your cluster."
}

variable "dcos_zk_super_credentials" {
 default = ""
 description = "This parameter specifies the ZooKeeper superuser credentials. (EE only)"
}

variable "dcos_zk_master_credentials" {
 default = ""
 description = "This parameter specifies the ZooKeeper master credentials."
}

variable "dcos_zk_agent_credentials" {
 default = ""
 description = "This parameter specifies the ZooKeeper agent credentials. "
}

variable "dcos_overlay_enable" {
 default = ""
 description = "Enable the DC/OS virtual network. "
}

variable "dcos_overlay_config_attempts" {
 default = ""
 description = "This parameter specifies how many failed configuration attempts are allowed before the overlay configuration modules stop trying to configure an virtual network."
}

variable "dcos_overlay_mtu" {
 default = ""
 description = "This parameter specifies the maximum transmission unit (MTU) of the Virtual Ethernet (vEth) on the containers that are launched on the overlay."
}

# Example how to set an overlay network below
# default = "{\"vtep_mac_oui\": \"70:B3:D5:00:00:00\", \"overlays\": [{\"name\": \"dcos\", \"subnet\": \"9.0.0.0/8\", \"prefix\": 26}], \"vtep_subnet\": \"44.128.0.0/20\"}"

variable "dcos_overlay_network" {
 default = ""
 description = "Specify this in line in a new line (\\n) fashion. See https://docs.mesosphere.com/1.8/administration/installing/custom/configuration-parameters/ for more information"
}

variable "dcos_dns_search" {
 default = ""
 description = "This parameter specifies a space-separated list of domains that are tried when an unqualified domain is entered"
} 

variable "dcos_master_dns_bindall" {
 default = ""
 description = "This parameter specifies whether the master DNS port is open. An open master DNS port listens publicly on the masters."
}

variable "dcos_use_proxy" {
 default = ""
 description = "This parameter specifies whether to enable the DC/OS proxy."
}

variable "dcos_http_proxy" {
 default = ""
 description = "This parameter specifies the HTTP proxy."
}

variable "dcos_https_proxy" {
 default = ""
 description = "This parameter specifies the HTTPS proxy"
}

variable "dcos_no_proxy" {
 default = ""
 description = "This parameter specifies YAML nested list (-) of addresses to exclude from the proxy."
}

variable "dcos_check_time" {
 default = ""
 description = "This parameter specifies whether to check if Network Time Protocol (NTP) is enabled during DC/OS startup. It recommended that NTP is enabled for a production environment."
}

variable "dcos_docker_remove_delay" {
 default = ""
 description = "This parameter specifies the amount of time to wait before removing stale Docker images stored on the agent nodes and the Docker image generated by the installer. "
}

variable "dcos_audit_logging" {
 default = ""
 description = "This parameter specifies whether security decisions (authentication, authorization) are logged for Mesos, Marathon, and Jobs."
}

variable "dcos_gc_delay" {
 default = ""
 description = "This parameter specifies the maximum amount of time to wait before cleaning up the executor directories. It is recommended that you accept the default value of 2 days."
}

variable "dcos_log_directory" {
 default = ""
 description = "This parameter specifies the path to the installer host logs from the SSH processes. By default this is set to /genconf/logs."
}

variable "dcos_process_timeout" {
 default = ""
 description = "This parameter specifies the allowable amount of time, in seconds, for an action to begin after the process forks. This parameter is not the complete process time. The default value is 120 seconds."
}

variable "dcos_version" {
 default = "1.8.8"
 description = "DCOS Version"
}

variable "dcos-type" {
 default = "open"
 description = "DCOS type, either ee or open."
}

variable "dcos_cluster_docker_credentials" {
 default = ""
 description = "This parameter specifies a dictionary of Docker credentials to pass."
}

variable "dcos_cluster_docker_credentials_dcos_owned" {
 default = ""
 description = "This parameter specifies whether to store the credentials file in /opt/mesosphere or /etc/mesosphere/docker_credentials. A sysadmin cannot edit /opt/mesosphere directly."
}

variable "dcos_cluster_docker_credentials_write_to_etc" {
 default = ""
 description = "This parameter specifies whether to write a cluster credentials file."
}

variable "dcos_cluster_docker_credentials_enabled" {
 default = ""
 description = "This parameter specifies whether to pass the Mesos --docker_config option to Mesos."
}

variable "dcos_cluster_docker_registry_enabled" {
 default = ""
 description = "This parameter specifies whether to pass the Mesos --docker_config option to Mesos."
}

variable "dcos_cluster_docker_registry_url" {
 default = ""
 description = "This parameter specifies a custom URL that Mesos uses to pull Docker images from. If set, it will configure the Mesos’ --docker_registry flag to the specified URL. This changes the default URL Mesos uses for pulling Docker images. By default https://registry-1.docker.io is used."
}


# Example value on how to configure rexray below
# default = "{\"rexray\": {\"modules\": {\"default-docker\": {\"disabled\": true}, \"default-admin\": {\"host\": \"tcp://127.0.0.1:61003\"}}, \"loglevel\": \"info\"}}"

variable "dcos_rexray_config" {
 default = ""
}

variable "state" {
 default = "install"
 description = "Support installing or Upgrading DC/OS"
}

# Core OS
variable "aws_amis" {
  default = {
    eu-west-1 = "ami-163e7e65"
    us-east-1 = "ami-21732036"
    us-west-1 = "ami-161a5176"
    us-west-2 = "ami-078d5367"
  }
}
