# Reattach the public ELBs to the agents if they change
resource "aws_elb_attachment" "public-agent-elb" {
  count    = "${var.num_of_public_agents}"
  elb      = "${aws_elb.public-agent-elb.id}"
  instance = "${aws_instance.public-agent.*.id[count.index]}"
}

# Public Agent Load Balancer Access
# Adminrouter Only
resource "aws_elb" "public-agent-elb" {
  name = "${data.template_file.cluster-name.rendered}-pub-agt-elb"

  subnets         = ["${aws_subnet.public.id}"]
  security_groups = ["${aws_security_group.http-https.id}", "${aws_security_group.internet-outbound.id}"]
  instances       = ["${aws_instance.public-agent.*.id}"]

  listener {
    lb_port           = 80
    instance_port     = 80
    lb_protocol       = "tcp"
    instance_protocol = "tcp"
  }

  listener {
    lb_port           = 443
    instance_port     = 443
    lb_protocol       = "tcp"
    instance_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 2
    target = "HTTP:9090/_haproxy_health_check"
    interval = 5
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_instance" "public-agent" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "${coalesce(var.ssh_user, module.aws-tested-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"

    # The connection will use the local SSH agent for authentication.
  }

  root_block_device {
    volume_size = "${var.aws_public_agent_instance_disk_size}"
  }

  count = "${var.num_of_public_agents}"
  instance_type = "${var.aws_public_agent_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.agent.name}"

  ebs_optimized = "true"

  tags {
   owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
   Name =  "${data.template_file.cluster-name.rendered}-pubagt-${count.index + 1}"
   cluster = "${data.template_file.cluster-name.rendered}"
   KubernetesCluster = "${var.kubernetes_cluster}"
  }

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${coalesce(var.aws_ami, module.aws-tested-oses.aws_ami)}"

  # The name of our SSH keypair we created above.
  key_name = "${var.ssh_key_name}"

  # Our Security group to allow http, SSH, and outbound internet access only for pulling containers from the web
  vpc_security_group_ids = ["${aws_security_group.public_slave.id}", "${aws_security_group.http-https.id}", "${aws_security_group.any_access_internal.id}", "${aws_security_group.ssh.id}", "${aws_security_group.internet-outbound.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.public.id}"

  # OS init script
  provisioner "file" {
   content = "${module.aws-tested-oses.os-setup}"
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
    ignore_changes = ["tags.Name"]
  }
}

# Create DCOS Mesos Public Agent Scripts to execute
module "dcos-mesos-agent-public" {
  source               = "github.com/dcos/tf_dcos_core"
  bootstrap_private_ip = "${aws_instance.bootstrap.private_ip}"
  dcos_bootstrap_port  = "${var.custom_dcos_bootstrap_port}"
  # Only allow upgrade and install as installation mode
  dcos_install_mode = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version         = "${var.dcos_version}"
  role                 = "dcos-mesos-agent-public"
}

# Execute generated script on agent
resource "null_resource" "public-agent" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : var.num_of_public_agents}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_ec2_instance_id = "${element(aws_instance.public-agent.*.id, count.index)}"
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(aws_instance.public-agent.*.public_ip, count.index)}"
    user = "${coalesce(var.ssh_user, module.aws-tested-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
  }

  count = "${var.num_of_public_agents}"

  # Generate and upload Agent script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-agent-public.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
     "until $(curl --output /dev/null --silent --head --fail http://${aws_instance.bootstrap.private_ip}:${var.custom_dcos_bootstrap_port}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
    ]
    connection {
      script_path = "~/tmp_provision.sh"
    }
  }

  # Install Slave Node
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

output "Public Agent ELB Public IP" {
  value = "${aws_elb.public-agent-elb.dns_name}"
}

output "Public Agent Public IPs" {
  value = ["${aws_instance.public-agent.*.public_ip}"]
}
