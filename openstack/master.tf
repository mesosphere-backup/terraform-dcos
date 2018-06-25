# Master Node


# REVIEW: Giving master nodes public floating ips to access web UI
resource "openstack_networking_floatingip_v2" "masters" {
  count = "${var.num_of_masters}"
  pool  = "${var.os_floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "masters" {
  count         = "${var.num_of_masters}"
  floating_ip   = "${openstack_networking_floatingip_v2.masters.*.address[count.index]}"
  instance_id   = "${openstack_compute_instance_v2.masters.*.id[count.index]}"
}


data "openstack_compute_flavor_v2" "master" {
  name = "${var.master_instance_flavor}"
}


resource "openstack_networking_secgroup_v2" "master" {
  name = "${data.template_file.cluster-name.rendered}-master"
}

resource "openstack_networking_secgroup_rule_v2" "ingress_master" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}


resource "openstack_networking_port_v2" "masters" {
  count                 = "${var.num_of_masters}"
  name                  = "${data.template_file.cluster-name.rendered}-master-${count.index}"
  network_id            = "${openstack_networking_network_v2.vnet.id}"
  admin_state_up        = "true"
  security_group_ids    = ["${openstack_networking_secgroup_v2.master.id}"]

  fixed_ip {
    subnet_id           = "${openstack_networking_subnet_v2.public.id}"
  }
}


resource "openstack_compute_instance_v2" "masters" {
  count             = "${var.num_of_masters}"
  name              = "${data.template_file.cluster-name.rendered}-master-${count.index}"
  image_id          = "${data.openstack_images_image_v2.selected_image.id}"
  flavor_id         = "${data.openstack_compute_flavor_v2.master.id}"
  key_pair          = "${openstack_compute_keypair_v2.keypair.name}"
  user_data         = "${module.openstack-tested-oses.os_user_data}"

  metadata {
    Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
    expiration = "${var.expiration}"
  }

  network {
    port = "${openstack_networking_port_v2.masters.*.id[count.index]}"
  }

}


# Create DCOS Mesos Master Scripts to execute
module "dcos-mesos-master" {
  source               = "github.com/dcos/tf_dcos_core"
  bootstrap_private_ip = "${openstack_compute_instance_v2.bootstrap.access_ip_v4}"
  dcos_bootstrap_port  = "${var.custom_dcos_bootstrap_port}"
  # Only allow upgrade and install as installation mode
  dcos_install_mode = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version         = "${var.dcos_version}"
  role                 = "dcos-mesos-master"
}

resource "null_resource" "master" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : var.num_of_masters}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_virtual_machine_id = "${openstack_compute_instance_v2.masters.*.id[count.index]}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    bastion_host = "${openstack_networking_floatingip_v2.bootstrap.address}"
    host = "${element(openstack_compute_instance_v2.masters.*.access_ip_v4, count.index)}"
    user = "${coalesce(var.admin_username, module.openstack-tested-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
  }

  # Generate and upload Master script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-master.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
     "until $(curl --output /dev/null --silent --head --fail http://${openstack_compute_instance_v2.bootstrap.access_ip_v4}:${var.custom_dcos_bootstrap_port}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
    ]
  }

  # Install Master Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }

  # Watch Master Nodes Start
  provisioner "remote-exec" {
    inline = [
      "until $(curl --output /dev/null --silent --head --fail http://${element(openstack_compute_instance_v2.masters.*.access_ip_v4, count.index)}/); do printf 'loading DC/OS...'; sleep 10; done"
    ]
  }
}


output "Master Public IPs" {
  value = ["${openstack_compute_instance_v2.masters.*.access_ip_v4}"]
}

output "Master Floating IPs" {
  value = ["${openstack_networking_floatingip_v2.masters.*.address}"]
}
