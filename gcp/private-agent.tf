# Target Pool for external load balancing access
resource "google_compute_target_pool" "agent-pool" {
  name = "${data.template_file.cluster-name.rendered}-agent-pool"

  instances = ["${google_compute_instance.agent.*.self_link}"]
}

resource "google_compute_instance_group" "agent" {
  name        = "${data.template_file.cluster-name.rendered}-agent-cluster"
  description = "DC/OS Agent Instance Group"

  instances = [
    "${google_compute_instance.agent.*.self_link}"
  ]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }

  named_port {
    name = "mesos-agent"
    port = "5051"
  }

  named_port {
    name = "ssh"
    port = "22"
  }

  zone = "${local.gcp_zone}"
}

# deploy image
resource "google_compute_instance" "agent" {
   name         = "${data.template_file.cluster-name.rendered}-agent-${count.index + 1}"
   machine_type = "${var.gcp_agent_instance_type}"
   zone         = "${local.gcp_zone}"
   count        = "${var.num_of_private_agents}"

  labels {
   owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
   name = "${data.template_file.cluster-name.rendered}-agent-${count.index + 1}"
   cluster = "${data.template_file.cluster-name.rendered}"
  }

  boot_disk {
    initialize_params {
      image = "${module.dcos-tested-gcp-oses.gcp_image_family}/${module.dcos-tested-gcp-oses.gcp_image_name}"
      size  = "${var.instance_disk_size}"
    }
  }

  connection {
    user = "${coalesce(var.gcp_ssh_user, module.dcos-tested-gcp-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.private.name}"
    access_config {
    }
  }

  metadata {
    sshKeys = "${coalesce(var.gcp_ssh_user, module.dcos-tested-gcp-oses.user)}:${file(var.gcp_ssh_pub_key_file)}"
  }

  # OS init script
  provisioner "file" {
   content = "${module.dcos-tested-gcp-oses.os-setup}"
   destination = "/tmp/os-setup.sh"
   }

 # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
    provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/os-setup.sh",
      "sudo bash /tmp/os-setup.sh",
    ]
  }

  lifecycle {
    ignore_changes = ["labels.Name", "labels.cluster"]
  }

  scheduling {
    preemptible = "${var.gcp_scheduling_preemptible}"
    automatic_restart = "${var.gcp_scheduling_preemptible == "true" ? false : true}"
  }

  service_account {
      scopes = "${var.gcp_sa_scopes}"
 }
}

# Create DCOS Mesos Agent Scripts to execute
module "dcos-mesos-agent" {
  source               = "github.com/dcos/tf_dcos_core"
  bootstrap_private_ip = "${google_compute_instance.bootstrap.network_interface.0.address}"
  dcos_bootstrap_port  = "${var.custom_dcos_bootstrap_port}"
  # Only allow upgrade and install as installation mode
  dcos_install_mode    = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version         = "${var.dcos_version}"
  dcos_skip_checks     = "${var.dcos_skip_checks}"
  role                 = "dcos-mesos-agent"
  dcos_dns_search = "${var.dcos_dns_search}"
}

resource "null_resource" "agent" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : var.num_of_private_agents}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_ec2_instance_id = "${google_compute_instance.agent.*.id[count.index]}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(google_compute_instance.agent.*.network_interface.0.access_config.0.assigned_nat_ip, count.index)}"
    user = "${coalesce(var.gcp_ssh_user, module.dcos-tested-gcp-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
  }

  count = "${var.num_of_private_agents}"

  # Generate and upload Agent script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-agent.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
     "until $(curl --output /dev/null --silent --head --fail http://${google_compute_instance.bootstrap.network_interface.0.address}:${var.custom_dcos_bootstrap_port}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
    ]
  }

  # Install Agent Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }
}

output "Private Agent Public IPs" {
  value = ["${google_compute_instance.agent.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}
