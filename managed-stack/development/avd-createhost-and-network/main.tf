
#### pre req ####
# create workspace/hostpool/dag/ws-dag in rg-avd-resources in avd-configure branch
#######


############# config network settings for VMs ###################
#### avd network settings and security groups
# Use Terraform to create a virtual network
# Use Terraform to create a subnet
# Use Terraform to create an NSG
# Peering the Azure Virtual Desktop vnet with hub vnet
############################################# 

#########################################################################################
### avd desktop vnet. the Idea is to peer the Azure Virtual Desktop vnet with hub vnet
##############################################################
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-VNet"
  address_space       = var.vnet_range
  dns_servers         = var.dns_servers
  location            = var.deploy_location
  resource_group_name = "${var.azure_virtual_desktop_compute_resource_group}"           #### rg-avd-resources 
  depends_on          = [azurerm_resource_group.rg]     #### rg-avd-compute
}

# subnet for VMs
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = "${var.azure_virtual_desktop_compute_resource_group}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_range
  depends_on           = [azurerm_resource_group.rg]    #### rg-avd-compute
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-NSG"
  location            = var.deploy_location
  resource_group_name = "${var.azure_virtual_desktop_compute_resource_group}"
  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "appserver2dbnclients"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["1433-1434","8181","10000","1001-1002"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "clients2appserver"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["8196-8198","443","10000-10002","135","49152-65535"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.rg]               #### rg-avd-compute
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}





########
## IT-cont-01 hub vnet of AD domain network controller (remote) to peer to the local vnet
########
# Azure resource group for site b which is AD
data "azurerm_resource_group" "siteAD" {
  name     = var.ad_rg
  provider = azurerm.siteAD
}

data "azurerm_virtual_network" "ad_vnet_data" {
  name                = var.ad_vnet
  resource_group_name = data.azurerm_resource_group.siteAD.name
  provider = azurerm.siteAD
}

# Azure virtual network deployment for site b (AD)
#resource "azurerm_virtual_network" "vnetAD" {
#  name                = "peering-vnet-AD"
#  resource_group_name = data.azurerm_resource_group.siteAD.name
#  location            = data.azurerm_resource_group.siteAD.location
#  address_space       = ["10.20.0.0/16"]
#  provider = azurerm.siteAD
#}
#########

# Peering the Azure Virtual Desktop vnet with hub vnet of AAD DC 
resource "azurerm_virtual_network_peering" "peer1" {
  name                         = "peer_avdspoke_ad"
  resource_group_name          = var.rg_name                              # rg-avd-resources
  virtual_network_name         = azurerm_virtual_network.vnet.name        # ${var.prefix}-VNet  vnet fir RPA/AVD subs
  remote_virtual_network_id    = data.azurerm_virtual_network.ad_vnet_data.id   # AD vnet 
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit        = false
}

# Peering the AD hub vnet to AVD network 
resource "azurerm_virtual_network_peering" "peer2" {
  name                          = "peer_ad_avdspoke"
  resource_group_name           = var.ad_rg                                      # Rg-hubvnet-noe-prod of AD onprem/azure
  virtual_network_name          = var.ad_vnet                                    # vnet-hub-noe-prodx of AD
  remote_virtual_network_id     = azurerm_virtual_network.vnet.id                # local network vnet
}




################################################
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

###### NIC
resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.rdsh_count
  name                = "${var.prefix}-${count.index + 1}-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
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

  os_disk {
    name                 = "${lower(var.prefix)}-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "100"
  }

  #source_image_reference {
  #  publisher = "MicrosoftWindowsDesktop"
  #  offer     = "office-365"
  #  sku       = "win11-23h2-avd-m365"
  #  version   = "latest"
  #}
  source_image_id = data.azurerm_shared_image.win11.id

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_network_interface.avd_vm_nic,
    azurerm_shared_image.win11
  ]
}


# get AD tenant domain name 
# retrieves your primary Azure AD tenant domain. 
# Terraform will use this to create user principal names for your users.
data "azuread_domains" "avd_domain" {
  only_initial = true
}

######################
# EXT-2 domain join ( see output)
resource "azurerm_virtual_machine_extension" "domain_join" {
  count                      = var.rdsh_count
  name                       = "${var.prefix}-${count.index + 1}-domainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "Name": "${var.domain_name}",
      "OUPath": "${var.ou_path}",
      "User": "${var.domain_user_upn}@${var.domain_name}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.domain_password}"
    }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [
    azurerm_virtual_network_peering.peer1,
    azurerm_virtual_network_peering.peer2
  ]
}

#############
# EXT-2 vm ext Number of AVD machines to deploy
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

  depends_on = [
    azurerm_virtual_machine_extension.domain_join
  ]
}




###################
###################
###################
#########
# RBac 
#########
data "azurerm_role_definition" "role" { # access an existing built-in role
  name = "Desktop Virtualization Contributor"
}

data "azurerm_role_definition" "role_session_host" { # access an existing built-in role
  name = "Virtual Machine Contributor"
}

# resource "azuread_group" "aad_group" was earlier
data "azuread_group" "aad_group" {
  display_name     = var.aad_group_name
  security_enabled = true
}

resource "azurerm_role_assignment" "role_dag" {
  scope              = "${var.azurerm_virtual_desktop_application_group_dag_id}"
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = data.azuread_group.aad_group.object_id
}

resource "azurerm_role_assignment" "role_workspace" {
  scope              = "${var.azurerm_virtual_desktop_workspace_workspace_id}"
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = data.azuread_group.aad_group.object_id
}

resource "azurerm_role_assignment" "role_hostpool" {
  scope              = "${var.azure_virtual_desktop_host_pool_hostpool_id}"
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = data.azuread_group.aad_group.object_id
}

resource "azurerm_role_assignment" "role_sessionhost" {
  count              = var.rdsh_count
  scope              = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  role_definition_id = data.azurerm_role_definition.role_session_host.id
  principal_id       = data.azuread_group.aad_group.object_id
}


########################
#######################
#### shared storage 
## Create a Resource Group for Storage
#resource "azurerm_resource_group" "rg_storage" {
#  location = var.deploy_location
#  name     = var.rg_stor
#}


resource "azurerm_subnet" "subnet-storage" {
  name                 = "default"
  resource_group_name  = "${var.azure_virtual_desktop_compute_resource_group}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_range
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.AzureActiveDirectory", "Microsoft.Storage.Global"]
  depends_on           = [azurerm_resource_group.rg]    #### rg-avd-compute
}

resource "azurerm_network_security_group" "nsg-storage" {
  name                = "${var.prefix}-NSG"
  location            = var.deploy_location
  resource_group_name = "${var.azure_virtual_desktop_compute_resource_group}"
  security_rule {
    name                       = "vm2smbstorage"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges     = ["445"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "smbstorageoutbound2internet"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges     = ["*"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.rg]               #### rg-avd-compute
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc_subnet_storage" {
  subnet_id                 = azurerm_subnet.subnet-storage.id
  network_security_group_id = azurerm_network_security_group.nsg-storage.id
}

# generate a random string (consisting of four characters)
# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "random_SS" {
  length  = 4
  upper   = false
  special = false
}

## Azure Storage Accounts requires a globally unique names
## https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview
## Create a File Storage Account 
resource "azurerm_storage_account" "storage" {
  name                     = "stor${random_string.random_SS.id}"
  resource_group_name      = "${var.azure_virtual_desktop_compute_resource_group}"
  location                 = var.deploy_location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
}

resource "azurerm_storage_share" "FSShare" {
  name                 = "fslogix"
  storage_account_name = azurerm_storage_account.storage.name
  depends_on           = [azurerm_storage_account.storage]
  quota                = 500
}

## Azure built-in roles
## https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
data "azurerm_role_definition" "storage_role" {
  name = "Storage File Data SMB Share Contributor"
}

resource "azurerm_role_assignment" "af_role" {
  scope              = azurerm_storage_account.storage.id
  role_definition_id = data.azurerm_role_definition.storage_role.id
  principal_id       = data.azuread_group.aad_group.object_id
}




#######
##################
# compute gallery
resource "azurerm_resource_group" "sigrg" {
  location = var.deploy_location
  name     = var.rg_shared_name
}

# generate a random string (consisting of four characters)
# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "random" {
  length  = 4
  upper   = false
  special = false
}


# Creates Shared Image Gallery
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image_gallery
resource "azurerm_shared_image_gallery" "sig" {
  name                = "sig${random_string.random.id}"
  resource_group_name = azurerm_resource_group.sigrg.name
  location            = azurerm_resource_group.sigrg.location
  description         = "Shared images"

  tags = {
    Environment = "Demo"
    Tech        = "Terraform"
  }
}

#Creates image definition
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image
resource "azurerm_shared_image" "win11" {
  name                = "avd-image"
  gallery_name        = azurerm_shared_image_gallery.sig.name
  resource_group_name = azurerm_resource_group.sigrg.name
  location            = azurerm_resource_group.sigrg.location
  os_type             = "Windows"

  identifier {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "office-365"
    #sku       = "20h2-evd-o365pp"
    sku       = "win11-23h2-avd-m365"                    # win11 ent
  }
}

data "azurerm_shared_image" "win11" {
  name                = "avd-image"
  gallery_name        = "sig${random_string.random.id}"
  resource_group_name = azurerm_resource_group.sigrg.name
}