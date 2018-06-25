# Runs a local script to return the current user in bash
data "external" "whoami" {
  program = ["scripts/local/whoami.sh"]
}

locals {
  private_key = "${file(var.ssh_private_key_filename)}"
  agent = "${var.ssh_private_key_filename == "/dev/null" ? true : false}"
}

# Privdes a unique ID thoughout the livespan of the cluster
resource "random_id" "cluster" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    id = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
  }

  byte_length = 8
}

# Allow overrides of the owner variable or default to whoami.sh
data "template_file" "cluster-name" {
 template = "$${username}-tf$${uuid}"

  vars {
    uuid     = "${substr(md5(random_id.cluster.id),0,4)}"
    username = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
  }
}


# Grab the image to use, just grab the latest
data "openstack_images_image_v2" "selected_image" {
  name          = "${var.os_image_name}"
  most_recent   = true
}


provider "openstack" {
  # Expects the connection information to be provided via environment variables
  # See README for reference on OpenStack RC file
}


# Setup the networking: single virtual network with two subnets that go through the same router
# REVIEW: Do I need to setup security groups?
resource "openstack_networking_network_v2" "vnet" {
  name = "vnet-${data.template_file.cluster-name.rendered}"
}

resource "openstack_networking_subnet_v2" "public" {
  name              = "public"
  network_id        = "${openstack_networking_network_v2.vnet.id}"
  cidr              = "10.100.1.0/24"
  ip_version        = 4
  dns_nameservers   = "${var.dcos_resolvers}"
}

resource "openstack_networking_subnet_v2" "private" {
  name              = "private"
  network_id        = "${openstack_networking_network_v2.vnet.id}"
  cidr              = "10.100.2.0/24"
  ip_version        = 4
  dns_nameservers   = "${var.dcos_resolvers}"
}

resource "openstack_networking_router_v2" "router" {
  name                  = "router-${data.template_file.cluster-name.rendered}"
  external_network_id   = "${var.os_external_network_id}"
}

# REVIEW: Nameservers are sourced from the same place for public and private. May want to separate.
resource "openstack_networking_router_interface_v2" "router_interface_public" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.public.id}"
}
resource "openstack_networking_router_interface_v2" "router_interface_private" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.private.id}"
}


resource "openstack_compute_keypair_v2" "keypair" {
  name          = "${data.template_file.cluster-name.rendered}-keypair"
  public_key    = "${var.ssh_pub_key}"
}


module "openstack-tested-oses" {
  source        = "./modules/dcos-tested-openstack-oses"
  provider      = "openstack"
  os            = "${var.os}"
  region        = "${var.region}"
  ntp_servers   = "${var.ntp_servers}"
}


output "ssh_user" {
 value = "${module.openstack-tested-oses.user}"
}
