# Runs a local script to return the current user in bash
data "external" "whoami" {
  program = ["scripts/local/whoami.sh"]
}

# Privdes a unique ID thoughout the livespan of the cluster
resource "random_id" "cluster" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    id = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
  }

  byte_length = 8
}

# Allow overrides of the owner variable or default to whoami.sh
data "template_file" "cluster-name" {
 template = "$${username}-tf$${uuid}"

  vars {
    uuid     = "${substr(md5(random_id.cluster.id),0,4)}"
    username = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
  }
}

# Create a resource group
resource "azurerm_resource_group" "dcos" {
  name     = "dcos-${data.template_file.cluster-name.rendered}"
  location = "${var.azure_region}"

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

# Create a virtual network in the web_servers resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${data.template_file.cluster-name.rendered}"
  address_space       = ["10.32.0.0/16"]
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  address_prefix       = "10.32.0.0/22"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.dcos.name}"
}

resource "azurerm_subnet" "private" {
  name                 = "private"
  address_prefix       = "10.32.4.0/22"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.dcos.name}"
}

resource "azurerm_storage_account" "dcos-exhibitor-account" {
  name                = "tf${substr(md5(random_id.cluster.id),0,4)}exhibitor"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  location            = "${azurerm_resource_group.dcos.location}"
  account_type        = "Standard_LRS"

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

resource "azurerm_storage_container" "dcos-exhibitor-container" {
  name                  = "sc-dcos-exhibitor"
  resource_group_name   = "${azurerm_resource_group.dcos.name}"
  storage_account_name  = "${azurerm_storage_account.dcos-exhibitor-account.name}"
  container_access_type = "private"
}
