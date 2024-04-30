
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
  location            = var.session_deploy_location
  resource_group_name = azurerm_resource_group.rg.name  #### rg-avd-compute
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
  location            = var.session_deploy_location
  resource_group_name = azurerm_resource_group.rg.name
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
    name                       = "appserver2clients"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["8181","10000","1001-1002"]
    source_address_prefix      = "10.1.1.0/24"
    destination_address_prefix = "10.1.1.0/24"
  }
  security_rule {
    name                       = "clients2appserver"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["8196-8198","443","10000-10002","135","49152-65535"]
    source_address_prefix      = "10.1.1.0/24"
    destination_address_prefix = "10.1.1.0/24"
  }
  security_rule {
    name                       = "appserver2sqlnortheurope"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["11000-11999"]
    source_address_prefix      = "10.1.1.0/24"
    destination_address_prefixes = ["13.69.224.0/26","13.69.224.192/26","13.69.225.0/26","13.69.225.192/26","13.69.233.136/29","13.69.239.128/26","13.74.104.64/26","13.74.104.128/26","13.74.105.0/26","13.74.105.128/26","13.74.105.192/29","20.50.73.32/27","20.50.73.64/26","20.50.81.0/26","20.166.43.0/25","20.166.45.0/24","23.102.16.130/32","23.102.52.155/32","40.85.102.50/32","40.113.14.53/32","40.113.16.190/32","40.113.93.91/32","40.127.128.10/32","40.127.137.209/32","40.127.141.194/32","40.127.177.139/32","52.138.224.0/26","52.138.224.128/26","52.138.225.0/26","52.138.225.128/26","52.138.229.72/29","52.146.133.128/25","65.52.225.245/32","65.52.226.209/32","68.219.193.128/25","104.41.202.30/32","191.235.193.75/32","191.235.193.139/32","191.235.193.140/31"]
  }
  security_rule {
    name                       = "appserver2sqlnortheuropegW"
    priority                   = 1005
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1433-1434"]
    source_address_prefix      = "10.1.1.0/24"
    destination_address_prefixes = ["52.138.224.1/32","13.74.104.113/32"]
  }
  security_rule {
    name                       = "avooffice2vms"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3389"]
    source_address_prefixes    = ["213.239.96.0/24","185.176.215.252/32","84.52.224.184/32"]
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "domainjointcp"
    priority                   = 1007
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["88","135","139","636","389","445","53","49152-65535"]
    source_address_prefix      = "10.1.1.0/24"
    destination_address_prefixes = ["10.68.0.0/16"]
  }
  security_rule {
    name                       = "domainjoinudp"
    priority                   = 1008
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = ["53","389","636"]
    source_address_prefix      = "10.1.1.0/24"
    destination_address_prefixes = ["10.68.0.0/16"]
  }
  depends_on = [azurerm_resource_group.rg]               #### rg-avd-compute
}


resource "azurerm_route_table" "rpa" {
  name                  = "rpa-route-table"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.session_deploy_location
  disable_bgp_route_propagation = false

  route {
    name           = "rpa2internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = {
    environment = "rpa"
  }
  depends_on = [azurerm_resource_group.rg] 
}

resource "azurerm_subnet_route_table_association" "rpa" {
  subnet_id      = "${azurerm_virtual_network.vnet.subnet.*.id[0]}"
  route_table_id = azurerm_route_table.rpa.id
  depends_on = [azurerm_route_table.rpa]
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
  resource_group_name          = azurerm_resource_group.rg.name           # rg-avd-compute
  virtual_network_name         = azurerm_virtual_network.vnet.name        # avdtf-VNet  vnet fir RPA/AVD subs
  remote_virtual_network_id    = data.azurerm_virtual_network.ad_vnet_data.id   # vnet-hub-noe-prod of AD
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit        = false
  use_remote_gateways          = true
  depends_on = [azurerm_resource_group.rg] 
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

