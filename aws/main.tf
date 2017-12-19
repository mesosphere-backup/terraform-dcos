# Specify the provider and access details
provider "aws" {
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
}

# Runs a local script to return the current user in bash
data "external" "whoami" {
  program = ["scripts/local/whoami.sh"]
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = "true"

tags {
   Name = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
  }
}

# Allow overrides of the owner variable or default to whoami.sh
data "template_file" "cluster-name" {
 template = "$${username}-tf$${uuid}"

  vars {
    uuid = "${substr(md5(aws_vpc.default.id),0,4)}"
    username = "${format("%.10s", coalesce(var.owner, data.external.whoami.result["owner"]))}"
  }
}

# Create DCOS Bucket regardless of what exhibitor backend was chosen
resource "aws_s3_bucket" "dcos_bucket" {
  bucket = "${data.template_file.cluster-name.rendered}-bucket"
  acl    = "private"
  force_destroy = "true"

  tags {
   Name = "${data.template_file.cluster-name.rendered}-bucket"
   cluster = "${data.template_file.cluster-name.rendered}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch public nodes into
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.0.0/22"
  map_public_ip_on_launch = true
}

# Create a subnet to launch slave private node into
resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.4.0/22"
  map_public_ip_on_launch = true
}

# A security group that allows all port access to internal vpc
resource "aws_security_group" "any_access_internal" {
  name        = "cluster-security-group"
  description = "Manage all ports cluster level"
  vpc_id      = "${aws_vpc.default.id}"

 # full access internally
 ingress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["${aws_vpc.default.cidr_block}"]
  }

 # full access internally
 egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["${aws_vpc.default.cidr_block}"]
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "elb-security-group"
  description = "A security group for the elb"
  vpc_id      = "${aws_vpc.default.id}"

  # http access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A security group for Admins to control access
resource "aws_security_group" "admin" {
  name        = "admin-security-group"
  description = "Administrators can manage their machines"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.admin_cidr}"]
  }

  # http access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.admin_cidr}"]
  }

  # httpS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.admin_cidr}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A security group for the ELB so it is accessible via the web
# with some master ports for internal access only
resource "aws_security_group" "master" {
  name        = "master-security-group"
  description = "Security group for masters"
  vpc_id      = "${aws_vpc.default.id}"

 # Mesos Master access from within the vpc
 ingress {
   to_port = 5050
   from_port = 5050
   protocol = "tcp"
   cidr_blocks = ["${aws_vpc.default.cidr_block}"]
 }

 # Adminrouter access from within the vpc
 ingress {
   to_port = 80
   from_port = 80
   protocol = "tcp"
   cidr_blocks = ["${var.admin_cidr}"]
 }

 # Adminrouter SSL access from anywhere
 ingress {
   to_port = 443
   from_port = 443
   protocol = "tcp"
   cidr_blocks = ["${var.admin_cidr}"]
 }

 # Marathon access from within the vpc
 ingress {
   to_port = 8080
   from_port = 8080
   protocol = "tcp"
   cidr_blocks = ["${aws_vpc.default.cidr_block}"]
 }

 # Exhibitor access from within the vpc
 ingress {
   to_port = 8181
   from_port = 8181
   protocol = "tcp"
   cidr_blocks = ["${aws_vpc.default.cidr_block}"]
 }

 # Zookeeper Access from within the vpc
 ingress {
   to_port = 2181
   from_port = 2181
   protocol = "tcp"
   cidr_blocks = ["${aws_vpc.default.cidr_block}"]
 }

 # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A security group for public slave so it is accessible via the web
resource "aws_security_group" "public_slave" {
  name        = "public-slave-security-group"
  description = "security group for slave public"
  vpc_id      = "${aws_vpc.default.id}"

  # Allow ports within range
  ingress {
    to_port = 21
    from_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ports within range
  ingress {
    to_port = 5050
    from_port = 23
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ports within range
  ingress {
    to_port = 32000
    from_port = 5052
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ports within range
  ingress {
    to_port = 21
    from_port = 0
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ports within range
  ingress {
    to_port = 5050
    from_port = 23
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ports within range
  ingress {
    to_port = 32000
    from_port = 5052
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A security group for private slave so it is accessible internally
resource "aws_security_group" "private_slave" {
  name        = "private-slave-security-group"
  description = "security group for slave private"
  vpc_id      = "${aws_vpc.default.id}"

  # full access internally
  ingress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["${aws_vpc.default.cidr_block}"]
   }

  # full access internally
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["${aws_vpc.default.cidr_block}"]
   }
}

# Provide tested AMI and user from listed region startup commands
  module "aws-tested-oses" {
      source        = "./modules/dcos-tested-aws-oses"
      os            = "${var.os}"
      region        = "${var.aws_region}"
      user_aws_ami  = "${var.user_aws_ami}"
}
