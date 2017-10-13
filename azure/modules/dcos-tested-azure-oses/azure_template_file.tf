## Azure Data Templates
#

data "template_file" "traditional_os_user" {
  template = "$${aws_user_result}"

  vars {
    aws_user_result = "${lookup(var.traditional_default_os_user, element(split("_",var.os),0))}"
  }
}

data "template_file" "azure_offer" {
  template = "$${result}"

  vars {
    result = "${element(var.azure_os_image_version[format("%s_%s",var.os,var.region)], 0)}"
  }
}

data "template_file" "azure_publisher" {
  template = "$${result}"

  vars {
    result = "${element(var.azure_os_image_version[format("%s_%s",var.os,var.region)], 1)}"
  }
}

data "template_file" "azure_sku" {
  template = "$${result}"

  vars {
    result = "${element(var.azure_os_image_version[format("%s_%s",var.os,var.region)], 2)}"
  }
}

data "template_file" "azure_version" {
  template = "$${result}"

  vars {
    result = "${element(var.azure_os_image_version[format("%s_%s",var.os,var.region)], 3)}"
  }
}
