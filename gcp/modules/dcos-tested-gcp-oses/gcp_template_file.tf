## Azure Data Templates
#

data "template_file" "traditional_os_user" {
  template = "$${aws_user_result}"

  vars {
    aws_user_result = "${lookup(var.traditional_default_os_user, element(split("_",var.os),0))}"
  }
}

data "template_file" "gcp_image_family" {
  template = "$${result}"

  vars {
    result = "${element(var.gcp_os_image_version[var.os], 0)}"
  }
}

data "template_file" "gcp_image_name" {
  template = "$${result}"

  vars {
    result = "${element(var.gcp_os_image_version[var.os], 1)}"
  }
}
