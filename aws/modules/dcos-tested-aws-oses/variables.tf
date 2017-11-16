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
 coreos_835.13.0_eu-west-1 = "ami-4b18aa38"
 coreos_1235.9.0_eu-west-1 = "ami-188dd67e"
 coreos_1465.8.0_eu-west-1 = "ami-1a589463"
 centos_7.2_us-west-2      = "ami-d2c924b2"
 centos_7.3_us-west-2      = "ami-f4533694"
 coreos_835.13.0_us-west-2 = "ami-4f00e32f"
 coreos_1235.9.0_us-west-2 = "ami-4c49f22c"
 coreos_1465.8.0_us-west-2 = "ami-82bd41fa" # HVM
 rhel_7.3_us-west-2        = "ami-b55a51cc"
 }
}
