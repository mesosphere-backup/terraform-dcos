# Private Agents
resource "azurerm_managed_disk" "agent_managed_disk" {
  count                = "${var.num_of_private_agents}"
  name                 = "${data.template_file.cluster-name.rendered}-agent-${count.index + 1}"
  location             = "${var.azure_region}"
  resource_group_name  = "${azurerm_resource_group.dcos.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.instance_disk_size}"
}

# Public IP addresses
resource "azurerm_public_ip" "agent_public_ip" {
  count                        = "${var.num_of_private_agents}"
  name                         = "${data.template_file.cluster-name.rendered}-agent-pub-ip-${count.index + 1}"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.dcos.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label = "${data.template_file.cluster-name.rendered}-agent-${count.index + 1}"

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

# Agent Security Groups for NICs
resource "azurerm_network_security_group" "agent_security_group" {
    name = "${data.template_file.cluster-name.rendered}-agent-security-group"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.dcos.name}"

    tags {
      Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
      expiration = "${var.expiration}"
  }
}

resource "azurerm_network_security_rule" "agent-sshRule" {
    name                        = "sshRule"
    priority                    = 100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.agent_security_group.name}"
}


resource "azurerm_network_security_rule" "agent-internalEverything" {
    name                        = "allOtherInternalTraffric"
    priority                    = 160
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.agent_security_group.name}"
}

resource "azurerm_network_security_rule" "agent-everythingElseOutBound" {
    name                        = "allOtherTrafficOutboundRule"
    priority                    = 170
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.agent_security_group.name}"
}
# End of Agent NIC Security Group

# Agent NICs with Security Group
resource "azurerm_network_interface" "agent_nic" {
  name                      = "${data.template_file.cluster-name.rendered}-private-agent-${count.index}-nic"
  location                  = "${var.azure_region}"
  resource_group_name       = "${azurerm_resource_group.dcos.name}"
  network_security_group_id = "${azurerm_network_security_group.agent_security_group.id}"
  count                     = "${var.num_of_private_agents}"

  ip_configuration {
   name                                    = "${data.template_file.cluster-name.rendered}-${count.index}-ipConfig"
   subnet_id                               = "${azurerm_subnet.public.id}"
   private_ip_address_allocation           = "dynamic"
   public_ip_address_id                    = "${element(azurerm_public_ip.agent_public_ip.*.id, count.index)}"
  }

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

# Create an availability set
resource "azurerm_availability_set" "agent_av_set" {
  name                         = "${data.template_file.cluster-name.rendered}-agent-avset"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.dcos.name}"
  platform_fault_domain_count  = 3
  platform_update_domain_count = 1
  managed                      = true
}

# Agent VM Coniguration
resource "azurerm_virtual_machine" "agent" {
    name                             = "${data.template_file.cluster-name.rendered}-agent-${count.index + 1}"
    location                         = "${var.azure_region}"
    resource_group_name              = "${azurerm_resource_group.dcos.name}"
    network_interface_ids            = ["${azurerm_network_interface.agent_nic.*.id[count.index]}"]
    availability_set_id              = "${azurerm_availability_set.agent_av_set.id}"
    vm_size                          = "${var.azure_agent_instance_type}"
    count                            = "${var.num_of_private_agents}"
    delete_os_disk_on_termination    = true
    delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${module.azure-tested-oses.azure_publisher}"
    offer     = "${module.azure-tested-oses.azure_offer}"
    sku       = "${module.azure-tested-oses.azure_sku}"
    version   = "${module.azure-tested-oses.azure_version}"
  }

  storage_os_disk {
    name              = "os-disk-agent-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.agent_managed_disk.*.name[count.index]}"
    managed_disk_id = "${azurerm_managed_disk.agent_managed_disk.*.id[count.index]}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.agent_managed_disk.*.disk_size_gb[count.index]}"
  }

  os_profile {
    computer_name  = "agent-${count.index + 1}"
    admin_username = "${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path     = "/home/${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}/.ssh/authorized_keys"
        key_data = "${var.ssh_pub_key}"
    }
  }

  # OS init script
  provisioner "file" {
   content = "${module.azure-tested-oses.os-setup}"
   destination = "/tmp/os-setup.sh"

   connection {
    type = "ssh"
    user = "${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}"
    host = "${element(azurerm_public_ip.agent_public_ip.*.fqdn, count.index)}"
    }
 }

 # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
    provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/os-setup.sh",
      "sudo bash /tmp/os-setup.sh",
    ]

   connection {
    type = "ssh"
    user = "${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}"
    host = "${element(azurerm_public_ip.agent_public_ip.*.fqdn, count.index)}"
   }
 }

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
 }
}

# Create DCOS Mesos Agent Scripts to execute
module "dcos-mesos-agent" {
  source               = "github.com/dcos/tf_dcos_core"
  bootstrap_private_ip = "${azurerm_network_interface.bootstrap_nic.private_ip_address}"
  # Only allow upgrade and install as installation mode
  dcos_install_mode = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version         = "${var.dcos_version}"
  role                 = "dcos-mesos-agent"
}

resource "null_resource" "agent" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : var.num_of_private_agents}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_virtual_machine_id = "${azurerm_virtual_machine.agent.*.id[count.index]}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(azurerm_public_ip.agent_public_ip.*.fqdn, count.index)}"
    user = "${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}"
  }

  count = "${var.num_of_private_agents}"

  # Generate and upload Agent script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-agent.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
     "until $(curl --output /dev/null --silent --head --fail http://${azurerm_network_interface.bootstrap_nic.private_ip_address}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
    ]
  }

  # Install Agent Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }
}
