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
  "centos_7.5"                = ["centos-cloud","centos-7-v20180815"]
  "coreos_stable"             = ["coreos-cloud", "coreos-stable"]
  "coreos_1576.5.0"           = ["coreos-cloud", "coreos-stable-1576-5-0-v20180105"]
  "coreos_1855.5.0"           = ["coreos-cloud", "coreos-stable-1855-5-0-v20181024"]
  "rhel_7.3"                  = ["rhel-cloud", "rhel-7-v20170523"]
 }
}
