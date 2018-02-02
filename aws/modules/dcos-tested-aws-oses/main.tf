variable "provider" {
 default = "aws"
}
variable "os" {}
variable "region" {}

data "template_file" "os-setup" {
template = "${file("${path.module}/platform/cloud/${var.provider}/${var.os}/setup.sh")}"
}

data "template_file" "aws_ami" {
  template = "$${aws_ami_result}"

  vars {
    aws_ami_result = "${lookup(merge(var.aws_ami, var.user_aws_ami), format("%s_%s",var.os, var.region))}"
  }
}

data "template_file" "aws_ami_user" {
  template = "$${aws_user_result}"

  vars {
    aws_user_result = "${lookup(var.aws_default_os_user, element(split("_",var.os),0))}"
  }
}
