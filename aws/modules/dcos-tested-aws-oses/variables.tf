variable "aws_default_os_user" {
 type = "map"
 default = {
 coreos = "core"
 centos = "centos"
 ubuntu = "ubuntu"
 rhel   = "ec2-user"
 }
}

variable "aws_ami" {
 type = "map"
 default = {
 centos_7.2_us-west-2      = "ami-d2c924b2"
 coreos_835.13.0_us-west-2 = "ami-4f00e32f"
 coreos_1235.9.0_us-west-2 = "ami-4c49f22c"
 }
}

