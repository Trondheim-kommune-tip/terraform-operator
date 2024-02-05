terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.90"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

provider "azurerm" {
  features {}
}


# Configure the Azure Active Directory Provider
provider "azuread" {
  client_id     = var.arm_client_id
  client_secret = var.arm_client_secret
  tenant_id     = var.arm_tenant_id
}