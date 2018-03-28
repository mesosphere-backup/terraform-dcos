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

# GCP Images
variable "gcp_os_image_version" {
 type = "map"

 # GCP Image Schema # image family   /   image name
 #                                  V                  V
 default = {
  "centos_7.2"                = ["centos-cloud","centos-7-v20170523"]
  "centos_7.3"                = ["centos-cloud","centos-7-v20170719"]
  "coreos_1235.9.0"           = ["coreos-cloud", "coreos-stable-1235-9-0-v20170202"]
  "coreos_1235.12.0"          = ["coreos-cloud", "coreos-stable-1235-12-0-v20170223"]
  "rhel_7.3"                  = ["rhel-cloud", "rhel-7-v20170523"]
 }
}
