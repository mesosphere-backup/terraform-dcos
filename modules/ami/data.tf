data "aws_ami" "operating-system-ami" {
  most_recent = true

  filter {
    name = "name"
    values = ["${var.operating_system}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
