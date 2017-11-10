# Reattach the internal ELBs to the master if they change
resource "aws_elb_attachment" "internal-master-elb" {
  count    = "${var.num_of_masters}"
  elb      = "${aws_elb.internal-master-elb.id}"
  instance = "${aws_instance.master.*.id[count.index]}"
}

# Internal Load Balancer Access
# Mesos Master, Zookeeper, Exhibitor, Adminrouter, Marathon
resource "aws_elb" "internal-master-elb" {
  name = "${data.template_file.cluster-name.rendered}-int-master-elb"
  internal = "true"

  subnets         = ["${aws_subnet.public.id}"]
  security_groups = ["${aws_security_group.master.id}","${aws_security_group.public_slave.id}", "${aws_security_group.private_slave.id}"]
  instances       = ["${aws_instance.master.*.id}"]

  listener {
    lb_port	      = 5050
    instance_port     = 5050
    lb_protocol       = "http"
    instance_protocol = "http"
  }

  listener {
    lb_port           = 2181
    instance_port     = 2181
    lb_protocol       = "tcp"
    instance_protocol = "tcp"
  }

  listener {
    lb_port           = 8181
    instance_port     = 8181
    lb_protocol       = "http"
    instance_protocol = "http"
  }

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

  listener {
    lb_port           = 8080
    instance_port     = 8080
    lb_protocol       = "http"
    instance_protocol = "http"
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

# Reattach the public ELBs to the master if they change
resource "aws_elb_attachment" "public-master-elb" {
  count    = "${var.num_of_masters}"
  elb      = "${aws_elb.public-master-elb.id}"
  instance = "${aws_instance.master.*.id[count.index]}"
}

# Public Master Load Balancer Access
# Adminrouter Only
resource "aws_elb" "public-master-elb" {
  name = "${data.template_file.cluster-name.rendered}-pub-mas-elb"

  subnets         = ["${aws_subnet.public.id}"]
  security_groups = ["${aws_security_group.public_slave.id}"]
  instances       = ["${aws_instance.master.*.id}"]

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
    timeout = 5
    target = "TCP:5050"
    interval = 30
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_instance" "master" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "${module.aws-tested-oses.user}"

    # The connection will use the local SSH agent for authentication.
  }

  root_block_device {
    volume_size = "${var.instance_disk_size}"
  }

  count = "${var.num_of_masters}"
  instance_type = "${var.aws_master_instance_type}"

  ebs_optimized  = "true"

  tags {
   owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
   Name = "${data.template_file.cluster-name.rendered}-master-${count.index + 1}"
   cluster = "${data.template_file.cluster-name.rendered}"
  }

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${module.aws-tested-oses.aws_ami}"

  # The name of our SSH keypair we created above.
  key_name = "${var.key_name}"

  # Our Security group to allow http and SSH access
  vpc_security_group_ids = ["${aws_security_group.master.id}","${aws_security_group.admin.id}","${aws_security_group.any_access_internal.id}"]

  # OS init script
  provisioner "file" {
   content = "${module.aws-tested-oses.os-setup}"
   destination = "/tmp/os-setup.sh"
   }

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.public.id}"

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
    ignore_changes = ["tags.Name", "tags.cluster"]
  }
}

# Create DCOS Mesos Master Scripts to execute
module "dcos-mesos-master" {
  source               = "github.com/bernadinm/tf_dcos_core"
  bootstrap_private_ip = "${aws_instance.bootstrap.private_ip}"
  dcos_install_mode    = "${var.state}"
  dcos_version         = "${var.dcos_version}"
  role                 = "dcos-mesos-master"
}

resource "null_resource" "master" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_ec2_instance_id = "${aws_instance.master.*.id[count.index]}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(aws_instance.master.*.public_ip, count.index)}"
    user = "${module.aws-tested-oses.user}"
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
     "until $(curl --output /dev/null --silent --head --fail http://${aws_instance.bootstrap.private_ip}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
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
      "until $(curl --output /dev/null --silent --head --fail http://${element(aws_instance.master.*.public_ip, count.index)}/); do printf 'loading DC/OS...'; sleep 10; done"
    ]
  }
}

output "Master ELB Address" {
  value = "${aws_elb.public-master-elb.dns_name}"
}

output "Mesos Master Public IP" {
  value = ["${aws_instance.master.*.public_ip}"]
}
