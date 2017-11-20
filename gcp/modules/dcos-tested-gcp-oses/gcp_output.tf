# Output
output "user" {
 value = "${data.template_file.traditional_os_user.rendered}"
}

output "gcp_image_family" {
  value = "${data.template_file.gcp_image_family.rendered}"
}

output "gcp_image_name" {
  value = "${data.template_file.gcp_image_name.rendered}"
}
