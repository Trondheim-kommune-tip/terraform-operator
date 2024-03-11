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
    #sku       = "win10-22h2-avd-m365-g2"
  }
}

data "azurerm_image" "win11image" {
  name                = "myPackerImage"
  resource_group_name = azurerm_resource_group.sigrg.name
}

#Creates image definition
resource "azurerm_shared_image_version" "win11version" {
  name                = "0.0.1"
  gallery_name        = azurerm_shared_image_gallery.sig.name
  image_name          = azurerm_shared_image.win11.name
  resource_group_name = azurerm_resource_group.sigrg.name
  location            = azurerm_resource_group.sigrg.location
  managed_image_id    = data.azurerm_image.win11image.id

  target_region {
    name                   = azurerm_resource_group.sigrg.location
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }
}

data "azurerm_shared_image" "win11" {
  name                = "avd-image"
  gallery_name        = "sig${random_string.random.id}"
  resource_group_name = azurerm_resource_group.sigrg.name
}