# Specify the provider and access details
provider "aws" {
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
}

locals {
  private_key = "${file(var.ssh_private_key_filename)}"
  agent = "${var.ssh_private_key_filename == "/dev/null" ? true : false}"
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

# Addressable Cluster UUID
data "template_file" "cluster_uuid" {
 template = "tf$${uuid}"

 vars {
    uuid = "${substr(md5(aws_vpc.default.id),0,4)}"
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

# Get the list of availability zones for the region
data "aws_availability_zones" "available" {}

# Create subnets to launch public nodes into
resource "aws_subnet" "public" {
  count                   = "${var.num_of_masters}"
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true
}

# Create subnets to launch slave private node into
resource "aws_subnet" "private" {
  count                   = "${var.num_of_masters}"
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.default.cidr_block, 8, count.index + 3)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
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
resource "aws_security_group" "http" {
  name        = "http-security-group"
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

# A security group for SSH only access
resource "aws_security_group" "ssh" {
  name        = "ssh-security-group"
  description = "SSH only access for terraform and administrators"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.admin_cidr}"]
  }
}

# A security group for Admins to control access
resource "aws_security_group" "http-https" {
  name        = "http-https-security-group"
  description = "Administrators can manage their machines"
  vpc_id      = "${aws_vpc.default.id}"

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
}

# A security group for any machine to download artifacts from the web
# without this, an agent cannot get internet access to pull containers
# This does not expose any ports locally, just external access.
resource "aws_security_group" "internet-outbound" {
  name        = "internet-outbound-only-access"
  description = "Security group to control outbound internet access only."
  vpc_id      = "${aws_vpc.default.id}"

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

  tags {
    KubernetesCluster = "${var.kubernetes_cluster}"
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

  tags {
    KubernetesCluster = "${var.kubernetes_cluster}"
  }
}

# Provide tested AMI and user from listed region startup commands
  module "aws-tested-oses" {
      source   = "./modules/dcos-tested-aws-oses"
      os       = "${var.os}"
      region   = "${var.aws_region}"
}

output "ssh_user" {
   value = "${module.aws-tested-oses.user}"
}
