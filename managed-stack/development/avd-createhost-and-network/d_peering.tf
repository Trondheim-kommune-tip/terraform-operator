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