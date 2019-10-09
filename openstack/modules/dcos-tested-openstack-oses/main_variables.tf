variable "provider" {
 default = "openstack"
}

variable "os" {}
variable "region" {}

variable "traditional_default_os_user" {
 type = "map"
 default = {
 coreos = "core"
 centos = "centos"
 ubuntu = "ubuntu"
 }
}

variable "ntp_servers" {
  type = "list"
  description = "Set custom NTP servers. DC/OS poststart checks desires time to by synchronized."
}
