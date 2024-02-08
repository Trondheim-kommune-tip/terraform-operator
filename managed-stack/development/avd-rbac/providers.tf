terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.90.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.47.0"
    }
  }
}

provider "azurerm" {
  features {}
  client_id     = "${var.arm_client_id}"
  client_secret = "${var.arm_client_secret}"
  tenant_id     = "${var.arm_tenant_id}"
  subscription_id = "${var.arm_subscription_id}"
}


# Configure the Azure Active Directory Provider
provider "azuread" {
  tenant_id = "${var.arm_tenant_id}"
  client_id     = "${var.arm_client_id}"
  client_secret = "${var.arm_client_secret}"
}