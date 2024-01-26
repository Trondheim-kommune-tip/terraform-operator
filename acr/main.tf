resource "azurerm_resource_group" "acr-rg" {
  name     = "acr-resources"
  location = "Norway East"
}

resource "azurerm_container_registry" "acr" {
  name                = "avd-containerRegistry"
  resource_group_name = azurerm_resource_group.acr-rg.name
  location            = azurerm_resource_group.acr-rg.location
  sku                 = "Premium"

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.acr-uai.id
    ]
  }

  encryption {
    enabled            = true
    key_vault_key_id   = data.azurerm_key_vault_key.kv-key.id
    identity_client_id = azurerm_user_assigned_identity.acr-uai.client_id
  }

}

resource "azurerm_user_assigned_identity" "acr-uai" {
  resource_group_name = azurerm_resource_group.acr-uai.name
  location            = azurerm_resource_group.acr-uai.location
  name = "registry-uai"
}

data "azurerm_key_vault_key" "kv-key" {
  name         = "super-secret"
  key_vault_id = data.azurerm_key_vault.kv.id
}