# Main Variables
variable "bootstrap_private_ip" {
   default = ""
}

variable "dcos_install_mode" {
   default = "install"
}

variable "dcos_version" {
   default = "1.9.0"
}

variable "role" {
   default = ""
}

# DCOS bootstrap node variables
variable "dcos_security" {
   default = ""
}

variable "dcos_resolvers" {
   default = ""
}

variable "dcos_skip_checks" {
   default = "true"
}

variable "dcos_oauth_enabled" {
   default = ""
}

variable "dcos_master_external_loadbalancer" {
   default = ""
}

variable "dcos_master_discovery" {
   default = ""
}

variable "dcos_aws_template_storage_bucket" {
   default = ""
}

variable "dcos_aws_template_storage_bucket_path" {
   default = ""
}

variable "dcos_aws_template_storage_region_name" {
   default = ""
}

variable "dcos_aws_template_upload" {
   default = ""
}

variable "dcos_aws_template_storage_access_key_id" {
   default = ""
}

variable "dcos_aws_template_storage_secret_access_key" {
   default = ""
}

variable "dcos_exhibitor_storage_backend" {
   default = ""
}

variable "dcos_exhibitor_zk_hosts" {
   default = ""
}

variable "dcos_exhibitor_zk_path" {
   default = ""
}

variable "dcos_aws_access_key_id" {
   default = ""
}

variable "dcos_aws_region" {
   default = ""
}

variable "dcos_aws_secret_access_key" {
   default = ""
}

variable "dcos_exhibitor_explicit_keys" {
   default = ""
}

variable "dcos_s3_bucket" {
   default = ""
}

variable "dcos_s3_prefix" {
   default = ""
}

variable "dcos_exhibitor_azure_account_name" {
   default = ""
}

variable "dcos_exhibitor_azure_account_key" {
   default = ""
}

variable "dcos_exhibitor_azure_prefix" {
   default = ""
}

variable "dcos_exhibitor_address" {
   default = ""
}

variable "num_of_public_agents" {
   default = ""
}

variable "num_of_private_agents" {
   default = ""
}

variable "dcos_num_masters" {
   default = ""
}

variable "dcos_customer_key" {
   default = ""
}

variable "dcos_rexray_config_method" {
   default = ""
}

variable "dcos_rexray_config_filename" {
   default = ""
}

variable "dcos_auth_cookie_secure_flag" {
   default = ""
}

variable "dcos_bouncer_expiration_auth_token_days" {
   default = ""
}

variable "dcos_superuser_password_hash" {
   default = ""
}

variable "dcos_cluster_name" {
   default = ""
}

variable "dcos_superuser_username" {
   default = ""
}

variable "dcos_telemetry_enabled" {
   default = ""
}

variable "dcos_zk_super_credentials" {
   default = ""
}

variable "dcos_zk_master_credentials" {
   default = ""
}

variable "dcos_zk_agent_credentials" {
   default = ""
}

variable "dcos_overlay_enable" {
   default = ""
}

variable "dcos_overlay_config_attempts" {
   default = ""
}

variable "dcos_overlay_mtu" {
   default = ""
}

variable "dcos_overlay_network" {
   default = ""
}

variable "dcos_dns_search" {
   default = ""
}

variable "dcos_master_dns_bindall" {
   default = ""
}

variable "dcos_use_proxy" {
   default = ""
}

variable "dcos_http_proxy" {
   default = ""
}

variable "dcos_https_proxy" {
   default = ""
}

variable "dcos_no_proxy" {
   default = ""
}

variable "dcos_check_time" {
   default = ""
}

variable "dcos_docker_remove_delay" {
   default = ""
}

variable "dcos_audit_logging" {
   default = ""
}

variable "dcos_gc_delay" {
   default = ""
}

variable "dcos_log_directory" {
   default = ""
}

variable "dcos_process_timeout" {
   default = ""
}

variable "dcos_cluster_docker_credentials" {
   default = ""
}

variable "dcos_cluster_docker_credentials_dcos_owned" {
   default = ""
}

variable "dcos_cluster_docker_credentials_write_to_etc" {
   default = ""
}

variable "dcos_cluster_docker_credentials_enabled" {
   default = ""
}

variable "dcos_master_list" {
   default = ""
}

variable "dcos_public_agent_list" {
   default = ""
}

variable "dcos_previous_version" {
   default = ""
}

variable "dcos_agent_list" {
   default = ""
}

variable "dcos_bootstrap_port" {
   default = "80"
}

variable "dcos_ip_detect_public_filename" {
   default = ""
}

variable "dcos_ip_detect_public_contents" {
  default = ""
}

variable "dcos_ip_detect_contents" {
  default = ""
}

variable "dcos_rexray_config" {
  default = ""
}

variable "dcos_cluster_docker_registry_url" {
  default = ""
}

variable "custom_dcos_download_path" {
   default = ""
}

variable "dcos_cluster_docker_registry_enabled" {
  default = ""
}

variable "dcos_enable_docker_gc" {
 default = ""
}

variable "dcos_staged_package_storage_uri" {
 default = ""
}

variable "dcos_package_storage_uri" {
 default = ""
}
