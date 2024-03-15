data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "mssql" {
  name                = "mssql-admin"
  location            = var.deploy_location
  resource_group_name = "${var.azure_virtual_desktop_compute_resource_group}"
}

resource "azurerm_mssql_server" "mssql" {
  name                         = "mssql-resource"
  resource_group_name          = "${var.azure_virtual_desktop_compute_resource_group}"
  location                     = var.deploy_location
  version                      = "12.0"
  administrator_login          = "admin"
  administrator_login_password = "Admin123!"
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username = azurerm_user_assigned_identity.mssql.name
    object_id      = azurerm_user_assigned_identity.mssql.principal_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mssql.id]
  }

  primary_user_assigned_identity_id            = azurerm_user_assigned_identity.mssql.id
  transparent_data_encryption_key_vault_key_id = azurerm_key_vault_key.mssql.id
}

# Create a key vault with access policies which allow for the current user to get, list, create, delete, update, recover, purge and getRotationPolicy for the key vault key and also add a key vault access policy for the Microsoft Sql Server instance User Managed Identity to get, wrap, and unwrap key(s)
resource "azurerm_key_vault" "mssql" {
  name                        = "mssqltde"
  location                    = var.deploy_location
  resource_group_name         = "${var.azure_virtual_desktop_compute_resource_group}"
  enabled_for_disk_encryption = true
  tenant_id                   = azurerm_user_assigned_identity.mssql.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = ["Get", "List", "Create", "Delete", "Update", "Recover", "Purge", "GetRotationPolicy"]
  }

  access_policy {
    tenant_id = azurerm_user_assigned_identity.mssql.tenant_id
    object_id = azurerm_user_assigned_identity.mssql.principal_id

    key_permissions = ["Get", "WrapKey", "UnwrapKey"]
  }
}

resource "azurerm_key_vault_key" "mssql" {
  depends_on = [azurerm_key_vault.mssql]

  name         = "mssql-key"
  key_vault_id = azurerm_key_vault.mssql.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = ["unwrapKey", "wrapKey"]
}