# Runs a local script to return the current user in bash
data "external" "whoami" {
  program = ["scripts/local/whoami.sh"]
}

# Provides a unique ID thoughout the livespan of the cluster
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

# Configure the Google Cloud provider
provider "google" {
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
}

data "google_compute_zones" "available" {}

 # Create google network
resource "google_compute_network" "default" {
   name                    = "${data.template_file.cluster-name.rendered}-dcos-network"
   auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "public" {
    name          = "${data.template_file.cluster-name.rendered}-public"
    ip_cidr_range = "${var.gcp_compute_subnetwork_public}"
    network       = "${google_compute_network.default.self_link}"
    region        = "${var.gcp_region}"
}

resource "google_compute_subnetwork" "private" {
    name          = "${data.template_file.cluster-name.rendered}-internal"
    ip_cidr_range = "${var.gcp_compute_subnetwork_private}"
    network       = "${google_compute_network.default.self_link}"
    region        = "${var.gcp_region}"
}

resource "google_compute_firewall" "internal-any-any" {
    name = "${data.template_file.cluster-name.rendered}-internal-any-any"
    network = "${google_compute_network.default.name}"

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "udp"
    }

    allow {
        protocol = "tcp"
    }

    source_ranges = ["10.0.0.0/8"]
    description   = "Used to allow internal access to all servers within the VPC 10.0.0.0/8 CIDR block range."
}

resource "google_compute_firewall" "adminrouter" {
    name = "${data.template_file.cluster-name.rendered}-adminrouter-firewall"
    network = "${google_compute_network.default.name}"
    allow {
        protocol = "tcp"
        ports = ["80", "443"]
    }

    source_ranges = ["${var.admin_cidr}"]
    description   = "Used to allow HTTP and HTTPS access to DC/OS Adminrouter from the outside world specified by the user source range."
}

resource "google_compute_firewall" "ssh" {
    name = "${data.template_file.cluster-name.rendered}-ssh"
    network = "${google_compute_network.default.name}"
    allow {
        protocol = "tcp"
        ports = ["22"]
    }

    source_ranges = ["${var.admin_cidr}"]
    description   = "Used to allow SSH access to any instance from the outside world specified by the user source range."
}
