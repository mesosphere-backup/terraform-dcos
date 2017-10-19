# Cloud Image Instruction
data "template_file" "os-setup" {
  template = "${file("${path.module}/platform/cloud/${var.provider}/${var.os}/setup.sh")}"
}
