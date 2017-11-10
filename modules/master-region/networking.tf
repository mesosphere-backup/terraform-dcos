resource "aws_vpc" "master-region-vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = "true"

  tags {
    Name = "${var.cluster_id}-vpc"
  }
}

resource "aws_subnet" "master-subnet" {
  cidr_block = "${var.master_subnet_cidr}"

  vpc_id = "${aws_vpc.master-region-vpc.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.cluster_id}-master-subnet"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_subnet" "public-subnet" {
  cidr_block = "${var.public_subnet_cidr}"

  vpc_id = "${aws_vpc.master-region-vpc.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.cluster_id}-public-subnet"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_subnet" "private-subnet" {
  cidr_block = "${var.private_subnet_cidr}"

  vpc_id = "${aws_vpc.master-region-vpc.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.cluster_id}-private-subnet"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_internet_gateway" "master-region-igw" {
  vpc_id = "${aws_vpc.master-region-vpc.id}"

  tags {
    Name = "${var.cluster_id}-master-region-igw"
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

resource "aws_route" "master-region-internet-access" {
  destination_cidr_block = "0.0.0.0/0"

  route_table_id = "${aws_vpc.master-region-vpc.main_route_table_id}"
  gateway_id = "${aws_internet_gateway.master-region-igw.id}"
}
