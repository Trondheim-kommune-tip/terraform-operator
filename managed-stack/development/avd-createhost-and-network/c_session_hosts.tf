#################################################
## Configure Azure Virtual Desktop session hosts
#######################
# NIC for AVD VMs in rg-avd-compute rg
# Use Terraform to create NIC for each session host
# Use Terraform to create VM for session host
# Join VM to domain
# Register VM with Azure Virtual Desktop
# Use variables file
###############
locals {
  registration_token = var.azurerm_virtual_desktop_host_pool_registration_info_registrationinfo_token
}

resource "random_string" "AVD_local_password" {
  count            = var.rdsh_count
  length           = 16
  special          = true
  min_special      = 2
  override_special = "*!@#?"
}

# RG for session host is rg-avd-compute
resource "azurerm_resource_group" "rg" {
  name     = var.rg                                # rg-avd-compute
  location = var.resource_group_location
}


resource "azurerm_public_ip" "avd_ext_ip" {
  count                   = var.rdsh_count
  name                    = "avd-ip-${count.index + 1}"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "avd IPs"
  }
}

###### NIC
resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.rdsh_count
  name                = "${var.prefix}-${count.index + 1}-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = "${azurerm_virtual_network.vnet.subnet.*.id[0]}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.avd_ext_ip.*.id[count.index]}"
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_capacity_reservation_group" "avd_vm_cap_group" {
  name                = "avd-capacity-reservation-group"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_capacity_reservation" "avd_vm_cap_res" {
  name                          = "avd-capacity-reservation"
  capacity_reservation_group_id = azurerm_capacity_reservation_group.avd_vm_cap_group.id
  sku {
    name     = var.vm_size # "Standard_D4ls_v5"
    capacity = 3
  }
}

# access mssql
data "azurerm_user_assigned_identity" "mssql" {
  name                = "mssql-admin"
  resource_group_name = "${var.azure_virtual_desktop_compute_resource_group}"
}

#virtual machine
# VMs
resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                 = var.rdsh_count
  name                  = "${var.prefix}-${count.index + 1}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent    = true
  admin_username        = var.local_admin_username
  admin_password        = var.local_admin_password
  capacity_reservation_group_id = azurerm_capacity_reservation_group.avd_vm_cap_group.id

  os_disk {
    name                 = "${lower(var.prefix)}-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "150"
  }

  #source_image_reference {
  #  publisher = "MicrosoftWindowsDesktop"
  #  offer     = "office-365"
  #  sku       = "win11-23h2-avd-m365"
  #  version   = "latest"
  #}
  source_image_id = data.azurerm_shared_image.win11.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mssql.id]
  }

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_network_interface.avd_vm_nic,
    azurerm_shared_image.win11,
    azurerm_mssql_server.mssql
  ]
}



# get AD tenant domain name 
# retrieves your primary Azure AD tenant domain. 
# Terraform will use this to create user principal names for your users.
# refer to provider "azuread"
data "azuread_domains" "avd_domain" {
  only_initial = true
}

# EXT-1 domain join ( see output)
#resource "azurerm_virtual_machine_extension" "domain_join" {
#  count                      = var.rdsh_count
#  name                       = "${var.prefix}-${count.index + 1}-domainJoin"
#  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
#  publisher                  = "Microsoft.Compute"
#  type                       = "JsonADDomainExtension"
#  type_handler_version       = "1.3"
#  auto_upgrade_minor_version = true

#  settings = <<SETTINGS
#    {
#      "Name": "${var.domain_name}",
#      "OUPath": "${var.ou_path}",
#      "User": "${var.domain_name}\\${var.domain_user_upn}",
#      "Restart": "true",
#      "Options": "3"
#    }
#SETTINGS

#  protected_settings = <<PROTECTED_SETTINGS
#    {
#      "Password": "${var.domain_password}"
#    }
#PROTECTED_SETTINGS

#  lifecycle {
#    ignore_changes = [settings, protected_settings]
#  }

#  depends_on = [
#    azurerm_virtual_network_peering.peer1,
#    azurerm_virtual_network_peering.peer2
#  ]
#}

# EXT-2 vm ext Number of AVD machines to deploy
# to provide post deployment configuration and run automated tasks
# associated VMs to hostpool
resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count                      = var.rdsh_count
  name                       = "${var.prefix}${count.index + 1}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  lifecycle {
    precondition {
      condition     = var.azure_virtual_desktop_host_pool_hostpool_id != ""
      error_message = "azure_virtual_desktop_host_pool_hostpool_id is empty and needs to be created"
    }
  }

  settings = <<SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${var.azure_virtual_desktop_host_pool_name}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.registration_token}"
    }
  }
PROTECTED_SETTINGS

  #depends_on = [
  #  azurerm_virtual_machine_extension.domain_join
  #]
}

