resource "aws_security_group" "internal-access-full" {
  vpc_id = "${aws_vpc.master-region-vpc.id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"

    cidr_blocks = [
      "${var.vpc_cidr}"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"

    cidr_blocks = [
      "${var.vpc_cidr}"
    ]
  }

  tags {
    Name = "${var.cluster_id}-internal-access-full"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_security_group" "public-slave-public-access" {
  vpc_id = "${aws_vpc.master-region-vpc.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.cluster_id}-public-slave-public-access"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_security_group" "public-slave-full-admin-access" {
  vpc_id = "${aws_vpc.master-region-vpc.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"

    cidr_blocks = [
      "${var.admin_cidr}",
      "77.249.14.211/32"
    ]
  }

  tags {
    Name = "${var.cluster_id}-public-slave-full-admin-access"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_security_group" "admin-ssh-access" {
  vpc_id = "${aws_vpc.master-region-vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"

    cidr_blocks = [
      "${var.admin_cidr}",
      "77.249.14.211/32"
    ]
  }

  tags {
    Name = "${var.cluster_id}-admin-ssh-access"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_security_group" "internet-access" {
  vpc_id = "${aws_vpc.master-region-vpc.id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name ="${var.cluster_id}-internet-access"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}
