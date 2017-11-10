resource "aws_elb" "master-elb" {

  name = "${var.cluster_id}-master-elb"
  subnets = ["${aws_subnet.master-subnet.id}"]

  listener {
    instance_port = 22
    instance_protocol = "tcp"
    lb_port = 22
    lb_protocol = "tcp"
  }

  security_groups = [
    "${aws_security_group.admin-ssh-access.id}"
  ]

  tags {
    Name = "${var.cluster_id}-master-elb"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_elb_attachment" "master-elb-attachment" {
  elb = "${aws_elb.master-elb.id}"
  count = "${var.master_number_of_instances}"
  instance = "${module.master-instances.instances[count.index]}"
}

resource "aws_elb" "public-slave-elb" {

  name = "${var.cluster_id}-public-slave-elb"
  subnets = ["${aws_subnet.public-subnet.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  security_groups = [
    "${aws_security_group.public-slave-public-access.id}"
  ]

  tags {
    Name = "${var.cluster_id}-public-slave-elb"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_elb_attachment" "public-slave-elb-attachment" {
  elb = "${aws_elb.public-slave-elb.id}"
  count = "${var.public_slave_number_of_instances}"
  instance = "${module.public-slave-instances.instances[count.index]}"
}
