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
variable "gcp_os_image_version" {
 type = "map"

 # Azure Cloud Image Schema # image family   /   image name  
 #                                  V                  V        
 default = {
  "centos_7.2"                = ["centos-cloud","centos-7-v20170523"]
  "centos_7.3"                = ["centos-cloud","centos-7-v20170719"]
  "coreos_1235.9.0"           = ["coreos-cloud", "coreos-stable-1235-9-0-v20170202"]
  "rhel_7.3"                  = ["rhel-cloud", "rhel-7-v20170523"]
 }
}
