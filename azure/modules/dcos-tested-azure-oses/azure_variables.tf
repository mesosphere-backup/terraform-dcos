# Standard Default OS Users
variable "traditional_default_os_user" {
 type = "map"
 default = {
 coreos = "core"
 centos = "centos"
 ubuntu = "ubuntu"
 rhel   = "ec2-user"
 }
}

# Azure Images
variable "azure_os_image_version" {
 type = "map"

 # Azure Cloud Image Schema # Offer  / Publisher / SKU  / Version
 #                              V          V        V         V
 default = {
  "centos_7.2_West US"        = ["CentOS","OpenLogic","7.2","7.2.20170517"]
  "centos_7.3_West US"        = ["CentOS","OpenLogic","7.3","7.3.20170707"]
  "coreos_835.13.0_West US"   = ["CoreOS", "CoreOS", "Stable", "835.13.0"]
  "coreos_1235.9.0_West US"   = ["CoreOS", "CoreOS", "Stable", "1235.9.0"]
  "rhel_7.3_West US"          = ["RHEL", "RedHat", "7.3", "7.3.2017053118"]
 }
}
