# Output
output "user" {
 value = "${data.template_file.traditional_os_user.rendered}"
}

output "azure_offer" {
  value = "${data.template_file.azure_offer.rendered}"
}

output "azure_publisher" {
  value = "${data.template_file.azure_publisher.rendered}"
}

output "azure_sku" {
  value = "${data.template_file.azure_sku.rendered}"
}

output "azure_version" {
  value = "${data.template_file.azure_version.rendered}"
}
