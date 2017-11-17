variable "public_key" {
 type = "string"
 description = "The public ssh key to that will be used to authenticate against."
}

variable "region" {
 type = "string"
 description = "The region to launch the new cluster in."
}

variable "admin_cidr" {
 type = "string"
 description = "The CIDR for which security policies are less strict."
}

variable "operating_system" {
 type = "string"
 description = "The operating system to use for the DC/OS instances. An AMI lookup will be done for the region to launch the instances in."

 default = "CoreOS-stable-1465.8.0-hvm"
}

variable "master_instance_type" {
 type = "string"
}

variable "master_number_of_instances" {
 type = "string"
}

variable "public_slave_instance_type" {
 type = "string"
}

variable "public_slave_number_of_instances" {
 type = "string"
}

variable "private_slave_instance_type" {
 type = "string"
}

variable "private_slave_number_of_instances" {
 type = "string"
}
