data "aws_instance" "bastion-host" {
  instance_id = "${var.bastion_host_id}"
}
