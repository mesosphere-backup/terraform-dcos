# Reserving the Public IP Address of the External Load Balancer for the Public Agent
resource "google_compute_address" "public-agent" {
  name = "external-dcos-public-agent-address"
}

resource "google_compute_forwarding_rule" "external-public-agent-forwarding-rule-http" {
  name   = "${data.template_file.cluster-name.rendered}-public-agent-external-lb-forwarding-rule-http"
  load_balancing_scheme = "EXTERNAL"
  target = "${google_compute_target_pool.public-agent-pool.self_link}"
  port_range = "80"
  ip_address = "${google_compute_address.public-agent.address}"
  depends_on = ["google_compute_http_health_check.public-agent-adminrouter-healthcheck"]
}

resource "google_compute_forwarding_rule" "external-public-agent-forwarding-rule-https" {
  name   = "${data.template_file.cluster-name.rendered}-public-agent-external-lb-forwarding-rule-https"
  load_balancing_scheme = "EXTERNAL"
  target = "${google_compute_target_pool.public-agent-pool.self_link}"
  port_range = "443"
  ip_address = "${google_compute_address.public-agent.address}"
  depends_on = ["google_compute_http_health_check.public-agent-adminrouter-healthcheck"]
}

# Target Pool for external load balancing access
resource "google_compute_target_pool" "public-agent-pool" {
  name = "${data.template_file.cluster-name.rendered}-public-agent-pool"

  instances = ["${google_compute_instance.public-agent.*.self_link}"]

  health_checks = [
    "${google_compute_http_health_check.public-agent-adminrouter-healthcheck.name}"
  ]
}

# Used for the internal load balancer. The external load balancer only supports google_compute_http_health_check resource.
resource "google_compute_health_check" "public-agent-healthcheck" {
  name               = "${data.template_file.cluster-name.rendered}-mesos-public-agent-healthcheck"
  check_interval_sec = 30
  timeout_sec        = 5
  healthy_threshold = 2
  unhealthy_threshold = 2

  http_health_check {
    port = "5050"
  }
}

# Used for the external load balancer. The external load balancer only supports google_compute_http_health_check resource.
resource "google_compute_http_health_check" "public-agent-adminrouter-healthcheck" {
  name                = "${data.template_file.cluster-name.rendered}-external-mesos-http-public-agent-healthcheck"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  port                = "80"
}

resource "google_compute_instance_group" "public-agent" {
  name        = "${data.template_file.cluster-name.rendered}-public-agent-cluster"
  description = "DC/OS Public Agent Instance Group"

  instances = [
    "${google_compute_instance.public-agent.*.self_link}"
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
    name = "mesos-public-agent"
    port = "5051"
  }

  named_port {
    name = "ssh"
    port = "22"
  }

  zone = "${data.google_compute_zones.available.names[0]}"
}

# deploy image
resource "google_compute_instance" "public-agent" {
   name         = "${data.template_file.cluster-name.rendered}-public-agent-${count.index + 1}"
   machine_type = "${var.gcp_public_agent_instance_type}"
   zone         = "${data.google_compute_zones.available.names[0]}"
   count        = "${var.num_of_public_agents}"

  labels {
   owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
   name = "${data.template_file.cluster-name.rendered}-public-agent-${count.index + 1}"
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
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.public.name}"
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
      scopes = ["https://www.googleapis.com/auth/compute.readonly"]
 }
}

# Create DCOS Mesos Public Agent Scripts to execute
module "dcos-mesos-public-agent" {
  source               = "git@github.com:mesosphere/enterprise-terraform-dcos//tf_dcos_core"
  bootstrap_private_ip = "${google_compute_instance.bootstrap.network_interface.0.address}"
  dcos_install_mode    = "${var.state}"
  dcos_version         = "${var.dcos_version}"
  dcos_skip_checks     = "${var.dcos_skip_checks}"
  role                 = "dcos-mesos-agent-public"
}

resource "null_resource" "public-agent" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_ec2_instance_id = "${google_compute_instance.public-agent.*.id[count.index]}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(google_compute_instance.public-agent.*.network_interface.0.access_config.0.assigned_nat_ip, count.index)}"
    user = "${coalesce(var.gcp_ssh_user, module.dcos-tested-gcp-oses.user)}"
  }

  count = "${var.num_of_public_agents}"

  # Generate and upload Public Agent script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-public-agent.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
     "until $(curl --output /dev/null --silent --head --fail http://${google_compute_instance.bootstrap.network_interface.0.address}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
    ]
  }

  # Install Public Agent Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }
}

output "Public Agent ELB Address" {
  value = "${google_compute_forwarding_rule.external-public-agent-forwarding-rule-http.ip_address}"
}

output "Mesos Public Agent Public IP" {
  value = ["${google_compute_instance.public-agent.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}
