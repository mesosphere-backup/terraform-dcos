# Cloud Image Instruction

data "template_file" "os_setup" {
  template = "${file("${path.module}/platform/cloud/${var.provider}/${var.os}/setup.sh")}"
}

data "template_file" "os_user_data" {
  template = "${file("${path.module}/platform/cloud/${var.provider}/${var.os}/user-data.yaml")}"

  vars {
    # NOTE: indent doesn't apply to the first line for some reason.
    os_setup_script = "    ${indent(4, data.template_file.os_setup.rendered)}"
    ntp_servers     = "${join(" ", var.ntp_servers)}"
  }
}

data "template_file" "traditional_os_user" {
  template = "$${user_result}"

  vars {
    user_result = "${lookup(var.traditional_default_os_user, element(split("_",var.os),0))}"
  }
}
