# Reserving the Public IP Address of the External Load Balancer for the master
resource "google_compute_address" "master" {
  name = "${data.template_file.cluster-name.rendered}-external-dcos-master-address"
}

resource "google_compute_firewall" "master-internal" {
    name = "${data.template_file.cluster-name.rendered}-master-internal-firewall"
    network = "${google_compute_network.default.name}"
    allow {
        protocol = "tcp"
        ports = ["5050", "2181", "8181", "8080"]
    }

    source_ranges = ["10.0.0.0/8"]
}

resource "google_compute_firewall" "allow-health-checks" {
    name = "${data.template_file.cluster-name.rendered}-allow-health-checks"
    network = "${google_compute_network.default.name}"
    allow {
        protocol = "tcp"
    }

    # The health check probes to your load balanced instances come from addresses in range 130.211.0.0/22 and 35.191.0.0/16.
    source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}


resource "google_compute_forwarding_rule" "internal-master-forwarding-rule" {
  name   = "${data.template_file.cluster-name.rendered}-master-internal-lb-forwarding-rule"
  load_balancing_scheme = "INTERNAL"
  backend_service = "${google_compute_region_backend_service.internal-master-region-service.self_link}"
  ports = ["5050", "2181", "8181", "8080"]
  subnetwork = "${google_compute_subnetwork.private.self_link}"
}

resource "google_compute_forwarding_rule" "external-master-forwarding-rule-http" {
  name   = "${data.template_file.cluster-name.rendered}-master-external-lb-forwarding-rule-http"
  load_balancing_scheme = "EXTERNAL"
  target = "${google_compute_target_pool.master-pool.self_link}"
  port_range = "80"
  ip_address = "${google_compute_address.master.address}"
  depends_on = ["google_compute_http_health_check.master-adminrouter-healthcheck"]
}

resource "google_compute_forwarding_rule" "external-master-forwarding-rule-https" {
  name   = "${data.template_file.cluster-name.rendered}-master-external-lb-forwarding-rule-https"
  load_balancing_scheme = "EXTERNAL"
  target = "${google_compute_target_pool.master-pool.self_link}"
  port_range = "443"
  ip_address = "${google_compute_address.master.address}"
  depends_on = ["google_compute_http_health_check.master-adminrouter-healthcheck"]
}

# Target Pool for external load balancing access
resource "google_compute_target_pool" "master-pool" {
  name = "${data.template_file.cluster-name.rendered}-master-pool"

  instances = ["${google_compute_instance.master.*.self_link}"]

  health_checks = [
    "${google_compute_http_health_check.master-adminrouter-healthcheck.name}"
  ]

}

resource "google_compute_region_backend_service" "internal-master-region-service" {
  name             = "${data.template_file.cluster-name.rendered}-master-internal-backend-service"
  protocol         = "TCP"
  timeout_sec      = 10
  session_affinity = "NONE"

  backend {
    group = "${google_compute_instance_group.master.self_link}"
  }

  health_checks = ["${google_compute_health_check.master-healthcheck.self_link}"]
}

# Used for the internal load balancer. The external load balancer only supports google_compute_http_health_check resource.
resource "google_compute_health_check" "master-healthcheck" {
  name               = "${data.template_file.cluster-name.rendered}-mesos-master-healthcheck"
  check_interval_sec = 30
  timeout_sec        = 5
  healthy_threshold = 2
  unhealthy_threshold = 2

  http_health_check {
    port = "5050"
  }
}

# Used for the external load balancer. The external load balancer only supports google_compute_http_health_check resource.
resource "google_compute_http_health_check" "master-adminrouter-healthcheck" {
  name                = "${data.template_file.cluster-name.rendered}-external-mesos-http-master-healthcheck"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  port                = "80"
}



# Provide tested AMI and user from listed region startup commands
module "dcos-tested-gcp-oses" {
   source   = "./modules/dcos-tested-gcp-oses"
   os       = "${var.os}"
}

resource "google_compute_instance_group" "master" {
  name        = "${data.template_file.cluster-name.rendered}-master-cluster"
  description = "DC/OS Master Instance Group"

  instances = [
    "${google_compute_instance.master.*.self_link}"
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
    name = "mesos-master"
    port = "5050"
  }

  named_port {
    name = "marathon"
    port = "8080"
  }

  named_port {
    name = "zookeeper"
    port = "2181"
  }

  named_port {
    name = "exhibitor"
    port = "8181"
  }

  named_port {
    name = "ssh"
    port = "22"
  }

  zone = "${local.gcp_zone}"
}

# deploy image
resource "google_compute_instance" "master" {
   name         = "${data.template_file.cluster-name.rendered}-master-${count.index + 1}"
   machine_type = "${var.gcp_master_instance_type}"
   zone         = "${local.gcp_zone}"
   count        = "${var.num_of_masters}"

  labels {
   owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
   name = "${data.template_file.cluster-name.rendered}-master-${count.index + 1}"
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
      "if [ -f /usr/local/sbin/os-setup.sh ]; then sudo chmod +x /usr/local/sbin/os-setup.sh && sudo bash /usr/local/sbin/os-setup.sh; fi"
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

# Create DCOS Mesos Master Scripts to execute
module "dcos-mesos-master" {
  source               = "github.com/dcos/tf_dcos_core"
  bootstrap_private_ip = "${google_compute_instance.bootstrap.network_interface.0.address}"
  dcos_bootstrap_port  = "${var.custom_dcos_bootstrap_port}"
  # Only allow upgrade and install as installation mode
  dcos_install_mode    = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version         = "${var.dcos_version}"
  dcos_skip_checks     = "${var.dcos_skip_checks}"
  role                 = "dcos-mesos-master"
}

resource "null_resource" "master" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : var.num_of_masters}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_ec2_instance_id = "${element(google_compute_instance.master.*.id, count.index)}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(google_compute_instance.master.*.network_interface.0.access_config.0.assigned_nat_ip, count.index)}"
    user = "${coalesce(var.gcp_ssh_user, module.dcos-tested-gcp-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
  }

  count = "${var.num_of_masters}"

  # Generate and upload Master script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-master.script}"
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

  # Install Master Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
    connection {
      script_path = "~/tmp_provision.sh"
    }
  }

  # Watch Master Nodes Start
  provisioner "remote-exec" {
    inline = [
      "until $(curl --output /dev/null --silent --head --fail http://${element(google_compute_instance.master.*.network_interface.0.address, count.index)}/); do printf 'loading DC/OS...'; sleep 10; done"
    ]
    connection {
      script_path = "~/tmp_provision.sh"
    }
  }
}

output "Master ELB Public IP" {
  value = "${google_compute_forwarding_rule.external-master-forwarding-rule-http.ip_address}"
}

output "Master Public IPs" {
  value = ["${google_compute_instance.master.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}
