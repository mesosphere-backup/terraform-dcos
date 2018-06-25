# Private Agents

data "openstack_compute_flavor_v2" "private_agent" {
  name = "${var.private_agent_instance_flavor}"
}


resource "openstack_networking_secgroup_v2" "private_agent" {
  name = "${data.template_file.cluster-name.rendered}-private-agent"
}

resource "openstack_networking_secgroup_rule_v2" "ingress_private_agent" {
  direction = "ingress"
  ethertype = "IPv4"
  security_group_id = "${openstack_networking_secgroup_v2.private_agent.id}"
}


resource "openstack_networking_port_v2" "private_agents" {
  count                 = "${var.num_of_private_agents}"
  name                  = "${data.template_file.cluster-name.rendered}-private-agent-${count.index}"
  network_id            = "${openstack_networking_network_v2.vnet.id}"
  admin_state_up        = "true"
  security_group_ids    = ["${openstack_networking_secgroup_v2.private_agent.id}"]

  fixed_ip {
    # REVIEW: Should this be the public subnet or private?
    subnet_id           = "${openstack_networking_subnet_v2.public.id}"
  }
}


resource "openstack_compute_instance_v2" "private_agents" {
  count             = "${var.num_of_private_agents}"
  name              = "${data.template_file.cluster-name.rendered}-private-agents-${count.index}"
  image_id          = "${data.openstack_images_image_v2.selected_image.id}"
  flavor_id         = "${data.openstack_compute_flavor_v2.private_agent.id}"
  key_pair          = "${openstack_compute_keypair_v2.keypair.name}"
  user_data         = "${module.openstack-tested-oses.os_user_data}"

  metadata {
    Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
    expiration = "${var.expiration}"
  }

  network {
    port = "${openstack_networking_port_v2.private_agents.*.id[count.index]}"
  }

}


# Create DCOS Mesos Agent Scripts to execute
module "dcos-mesos-agent" {
  source               = "github.com/dcos/tf_dcos_core"
  bootstrap_private_ip = "${openstack_compute_instance_v2.bootstrap.access_ip_v4}"
  dcos_bootstrap_port  = "${var.custom_dcos_bootstrap_port}"
  # Only allow upgrade and install as installation mode
  dcos_install_mode = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version         = "${var.dcos_version}"
  role                 = "dcos-mesos-agent"
}

resource "null_resource" "agent" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : var.num_of_private_agents}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_virtual_machine_id = "${openstack_compute_instance_v2.private_agents.*.id[count.index]}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    bastion_host = "${openstack_networking_floatingip_v2.bootstrap.address}"
    host = "${element(openstack_compute_instance_v2.private_agents.*.access_ip_v4, count.index)}"
    user = "${coalesce(var.admin_username, module.openstack-tested-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
  }

  # Generate and upload Agent script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-agent.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
     "until $(curl --output /dev/null --silent --head --fail http://${openstack_compute_instance_v2.bootstrap.access_ip_v4}:${var.custom_dcos_bootstrap_port}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
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
  value = ["${openstack_compute_instance_v2.private_agents.*.access_ip_v4}"]
}
