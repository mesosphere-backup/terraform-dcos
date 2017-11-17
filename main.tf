terraform {
  required_version = ">= 0.10.3"
}

resource "random_id" "cluster-identifier" {
  prefix = "dcos-"
  byte_length = 4
}

module "eu-west-1-master-region" {
  source = "./modules/master-region"

  cluster_id = "${random_id.cluster-identifier.hex}"

  admin_cidr = "${var.admin_cidr}"
  region = "${var.region}"

  master_instance_type = "${var.master_instance_type}"
  master_number_of_instances = "${var.master_number_of_instances}"

  public_slave_instance_type = "${var.public_slave_instance_type}"
  public_slave_number_of_instances = "${var.public_slave_number_of_instances}"

  private_slave_instance_type = "${var.private_slave_instance_type}"
  private_slave_number_of_instances = "${var.private_slave_number_of_instances}"

  public_key = "${var.public_key}"
  operating_system = "${var.operating_system}"
}
