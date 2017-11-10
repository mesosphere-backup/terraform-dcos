data "aws_instance" "bootstrap-node" {
  instance_id = "${element(var.master_list, 0)}"
}
