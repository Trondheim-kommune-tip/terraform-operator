
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
  name                = "${var.prefix}-VNet"  # avdtf-Vnet
  address_space       = var.vnet_range
  dns_servers         = var.dns_servers
  location            = var.deploy_location
  resource_group_name = "${var.azure_virtual_desktop_compute_resource_group}"           #### rg-avd-resources 

  subnet {
    name           = "default"
    address_prefix = "10.1.1.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }

  tags = {
    environment = "Production"
  }
  depends_on          = [azurerm_resource_group.rg]     #### rg-avd-compute
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


############
########
## IT-con-01 hub vnet of AD domain network controller (remote) to peer to the local vnet
# Azure resource group for site b which is AD
data "azurerm_resource_group" "sitead" {
  name     = var.ad_rg
  provider = azurerm.siteAD
}

data "azurerm_virtual_network" "ad_vnet_data" {
  name                = var.ad_vnet
  resource_group_name = data.azurerm_resource_group.sitead.name
  provider = azurerm.siteAD
}

# Jannik has added peering by enabling himself a Network Contributor role for RPA sub and it-con-01 subscription

# Peering the Azure Virtual Desktop vnet with hub vnet of AAD DC 
# avdtf-Vnet  ==> vnet-hub-noe-prod (AD vnet)
resource "azurerm_virtual_network_peering" "peer1" {
  #name                         = "peer_avdspoke_ad"
  name                         = "peer-rpa-avdtfvnet-to-itcon1-vnethubnoeprod"
  resource_group_name          = var.rg_name                              # rg-avd-resources
  virtual_network_name         = azurerm_virtual_network.vnet.name        # avdtf-VNet  vnet fir RPA/AVD subs
  remote_virtual_network_id    = data.azurerm_virtual_network.ad_vnet_data.id   # vnet-hub-noe-prod of AD
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

# Peering the AD hub vnet to AVD network
# vnet-hub-noe-prod ==> avdtf-Vnet (rpa net)
resource "azurerm_virtual_network_peering" "peer2" {
  #name                          = "peer_ad_avdspoke"
  name                          = "peer-itcon1-vnethubnoeprod-to-rpa-avdtfvnet"
  #resource_group_name           = var.ad_rg                                      # Rg-hubvnet-noe-prod of AD onprem/azure
  resource_group_name           = data.azurerm_resource_group.sitead.name
  #virtual_network_name          = var.ad_vnet                                    # vnet-hub-noe-prod of AD
  virtual_network_name          = data.azurerm_virtual_network.ad_vnet_data.name
  remote_virtual_network_id     = azurerm_virtual_network.vnet.id                # local network vnet
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  provider = azurerm.siteAD
  depends_on = [azurerm_virtual_network_peering.peer1]
}


#### 




##### external IP app gateway with features on

resource "azurerm_subnet" "extaccess-appgw" {
  name                 = "extaccess-subnet"
  resource_group_name  = "${var.azure_virtual_desktop_compute_resource_group}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_public_ip" "rpaexternalip" {
  name                = "pip"
  resource_group_name = "${var.azure_virtual_desktop_compute_resource_group}"
  location            = var.deploy_location
  allocation_method   = "Dynamic"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
  probe_name_app1                = "${azurerm_virtual_network.vnet.name}-probe"
}


resource "azurerm_application_gateway" "gw-network" {
  name                = "rpa-appgateway"
  resource_group_name = "${var.azure_virtual_desktop_compute_resource_group}"
  location            = var.deploy_location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "rpa-ip-configuration"
    subnet_id = azurerm_subnet.extaccess-appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 3389
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.rpaexternalip.id
  }
  
  backend_address_pool {
    name = local.backend_address_pool_name
    ip_addresses = ["10.1.1.5"]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 3389
    protocol              = "Tcp"
    request_timeout       = 60
    probe_name            = local.probe_name_app1
  }
  probe {
    name                = local.probe_name_app1
    interval            = 60
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Tcp"
    port                = 3389
    path                = "/"
  }   

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Tcp"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 104
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}