output "user" {
  value = "${var.user}"
}

output "aws_ami" {
  value = "${data.aws_ami.operating-system-ami.id}"
}
