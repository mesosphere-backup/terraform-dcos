resource "aws_instance" "master" {
  count = "${var.number_of_instances}"

  connection {
    user = "${var.instance_ami_user}"
    agent = true
  }

  root_block_device {
    volume_size = "${var.disk_size}"
  }

  instance_type = "${var.instance_type}"

  subnet_id = "${var.subnet_id}"

  ami = "${var.instance_ami}"

  key_name = "${var.key_name}"

  security_groups = ["${var.security_groups}"]

  # We update by updating the AMI used, so disable
  # the default updating mechanism in CoreOS.
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl disable locksmithd",
      "sudo systemctl stop locksmithd",
      "sudo systemctl disable update-engine",
      "sudo systemctl stop update-engine",
      "sudo systemctl restart docker"
    ]
  }

  tags {
    Name = "${var.cluster_id}-master-${count.index}"
  }

  volume_tags {
    Name = "${var.cluster_id}-master-${count.index}"
  }

  lifecycle {
    ignore_changes = [
      "tags.Name",
      "volume_tags.Name"
    ]
  }
}

resource "null_resource" "master-provision" {

  count = "${aws_instance.master.count}"

  connection {
    host = "${aws_instance.master.*.public_ip}"
    user = "${var.instance_ami_user}"
  }

  provisioner "remote-exec" {
    inline = [
      "until $(curl --output /dev/null --silent --head --fail http://${var.bootstrap_url}:${var.bootstrap_port}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 10; done"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir /tmp/dcos && cd /tmp/dcos",
      "/usr/bin/curl -O dcos_install.sh http://${var.bootstrap_url}:${var.bootstrap_port}/dcos_install.sh",
      "sudo bash dcos_install.sh master"
    ]
  }

}
