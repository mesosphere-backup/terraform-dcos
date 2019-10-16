# Reserving the Public IP Address of the External Load Balancer for the Public Agent
resource "google_compute_address" "public-agent" {
  name = "${data.template_file.cluster-name.rendered}-external-dcos-public-agent-address"
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

  zone = "${local.gcp_zone}"
}

# deploy image
resource "google_compute_instance" "public-agent" {
   name         = "${data.template_file.cluster-name.rendered}-public-agent-${count.index + 1}"
   machine_type = "${var.gcp_public_agent_instance_type}"
   zone         = "${local.gcp_zone}"
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
    private_key = "${local.private_key}"
    agent = "${local.agent}"
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
   destination = "${var.enable_os_setup_script ? "/usr/local/sbin/os-setup.sh" : "/dev/null"}"
   }

 # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
    provisioner "remote-exec" {
    inline = [
      "if [ -f ~/os-setup.sh ]; then sudo chmod +x ~/os-setup.sh && sudo bash ~/os-setup.sh; fi"
    ]
    connection {
      script_path = "~/tmp_provision.sh"
    }
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
  source               = "github.com/dcos/tf_dcos_core"
  bootstrap_private_ip = "${google_compute_instance.bootstrap.network_interface.0.address}"
  dcos_bootstrap_port  = "${var.custom_dcos_bootstrap_port}"
  # Only allow upgrade and install as installation mode
  dcos_install_mode    = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version         = "${var.dcos_version}"
  dcos_skip_checks     = "${var.dcos_skip_checks}"
  role                 = "dcos-mesos-agent-public"
}

resource "null_resource" "public-agent" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : var.num_of_public_agents}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_ec2_instance_id = "${element(google_compute_instance.public-agent.*.id, count.index)}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(google_compute_instance.public-agent.*.network_interface.0.access_config.0.assigned_nat_ip, count.index)}"
    user = "${coalesce(var.gcp_ssh_user, module.dcos-tested-gcp-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
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
     "until $(curl --output /dev/null --silent --head --fail http://${google_compute_instance.bootstrap.network_interface.0.address}:${var.custom_dcos_bootstrap_port}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
    ]
    connection {
      script_path = "~/tmp_provision.sh"
    }
  }

  # Install Public Agent Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
    connection {
      script_path = "~/tmp_provision.sh"
    }
  }
}

output "public_agent_elb_public_ip" {
  value = "${google_compute_forwarding_rule.external-public-agent-forwarding-rule-http.ip_address}"
}

output "public_agent_public_ip" {
  value = ["${google_compute_instance.public-agent.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}
