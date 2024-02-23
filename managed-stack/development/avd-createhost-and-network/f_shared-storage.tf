

########################
#######################
#### shared storage 
## Create a Resource Group for Storage
#resource "azurerm_resource_group" "rg_storage" {
#  location = var.deploy_location
#  name     = var.rg_stor
#}


resource "azurerm_subnet" "subnet-storage" {
  name                 = "default-storage"
  resource_group_name  = "${var.azure_virtual_desktop_compute_resource_group}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.storage_subnet_range
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.AzureActiveDirectory"]
  depends_on           = [azurerm_resource_group.rg]    #### rg-avd-compute
}

resource "azurerm_network_security_group" "nsg-storage" {
  name                = "${var.prefix}-storage-NSG"
  location            = var.deploy_location
  resource_group_name = "${var.azure_virtual_desktop_compute_resource_group}"
  security_rule {
    name                       = "vm2smbstorage"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["445"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "smbstorageoutbound2internet"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
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
## add permits to 7b0a46b0-b657-422a-9e03-fb6818021ff6 App registration id in rpa subs Contributor and User Access Administrator roles / Storage Blob Data  Owner
## Create a File Storage Account 
resource "azurerm_storage_account" "storage" {
  name                     = "stor${random_string.random_SS.id}"
  resource_group_name      = "${var.azure_virtual_desktop_compute_resource_group}"
  location                 = var.deploy_location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
  allow_nested_items_to_be_public = false
  public_network_access_enabled = false
}

resource "azurerm_storage_share" "FSShare" {
  name                 = "fslogix"
  storage_account_name = azurerm_storage_account.storage.name
  depends_on           = [azurerm_storage_account.storage]
  quota                = 500
  acl {
    id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI"

    access_policy {
      permissions = "rwdl"
      start       = "2024-02-23T17:02:21.0000000Z"
      expiry      = "2024-12-23T10:38:21.0000000Z"
    }
  }
}

resource "azurerm_storage_account_network_rules" "storage" {
  storage_account_id         = azurerm_storage_account.storage.id
  ip_rules                  = ["127.0.0.1"]
  virtual_network_subnet_ids = [azurerm_subnet.subnet-storage.id]
  default_action             = "Allow"
  bypass                     = ["AzureServices", "Logging", "Metrics"]
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
