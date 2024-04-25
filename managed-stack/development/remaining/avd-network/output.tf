output "location" {
  description = "The Azure region"
  value       = azurerm_resource_group.rg.location
}

output "dnsservers" {
  description = "Custom DNS configuration"
  value       = azurerm_virtual_network.vnet.dns_servers
}

output "vnetrange" {
  description = "Address range for deployment vnet"
  value       = azurerm_virtual_network.vnet.address_space
}