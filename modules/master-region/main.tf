provider "aws" {
  region = "${var.region}"
}

module "ami" {
  source = "../ami"

  operating_system = "${var.operating_system}"
  region = "${var.region}"
}

resource "aws_key_pair" "dcos-key" {
  key_name = "${var.cluster_id}"
  public_key = "${var.public_key}"
}

module "bootstrap-node" {
  source = "../bootstrap"

  bootstrap_user = "${module.ami.user}"
  cluster_id = "${var.cluster_id}"
  master_list = ["${module.master-instances.instances}"]
}

module "master-instances" {
  source = "../master-instance"

  cluster_id = "${var.cluster_id}"

  subnet_id = "${aws_subnet.master-subnet.id}"
  key_name = "${aws_key_pair.dcos-key.key_name}"

  instance_type = "${var.master_instance_type}"
  instance_ami = "${module.ami.aws_ami}"
  instance_ami_user = "${module.ami.user}"

  number_of_instances = "${var.master_number_of_instances}"

  security_groups = [
    "${aws_security_group.internet-access.id}",
    "${aws_security_group.admin-ssh-access.id}",
    "${aws_security_group.internal-access-full.id}"
  ]

  bootstrap_url = "${module.bootstrap-node.bootstrap_serve_ip}"
  bootstrap_port = "${module.bootstrap-node.bootstrap_serve_port}"
}

module "public-slave-instances" {
  source = "../public-slave-instance"

  cluster_id = "${var.cluster_id}"

  subnet_id = "${aws_subnet.public-subnet.id}"
  key_name = "${aws_key_pair.dcos-key.key_name}"

  instance_type = "${var.public_slave_instance_type}"
  instance_ami = "${module.ami.aws_ami}"
  instance_ami_user = "${module.ami.user}"

  number_of_instances = "${var.public_slave_number_of_instances}"

  security_groups = [
    "${aws_security_group.internet-access.id}",
    "${aws_security_group.admin-ssh-access.id}",
    "${aws_security_group.internal-access-full.id}",
    "${aws_security_group.public-slave-full-admin-access.id}",
    "${aws_security_group.public-slave-public-access.id}"
  ]

  region = "${var.region}"

  bootstrap_url = "${module.bootstrap-node.bootstrap_serve_ip}"
  bootstrap_port = "${module.bootstrap-node.bootstrap_serve_port}"
}

module "private-slave-instances" {
  source = "../private-slave-instance"

  cluster_id = "${var.cluster_id}"

  subnet_id = "${aws_subnet.private-subnet.id}"
  key_name = "${aws_key_pair.dcos-key.key_name}"

  instance_type = "${var.private_slave_instance_type}"
  instance_ami = "${module.ami.aws_ami}"
  instance_ami_user = "${module.ami.user}"

  number_of_instances = "${var.private_slave_number_of_instances}"

  security_groups = [
    "${aws_security_group.internet-access.id}",
    "${aws_security_group.admin-ssh-access.id}",
    "${aws_security_group.internal-access-full.id}"
  ]

  region = "${var.region}"

  bootstrap_url = "${module.bootstrap-node.bootstrap_serve_ip}"
  bootstrap_port = "${module.bootstrap-node.bootstrap_serve_port}"

  bastion_host_id = "${element(module.master-instances.instances, 0)}"
}
