output "location" {
  description = "The Azure region"
  value       = azurerm_resource_group.rg.location
}

output "session_host_count" {
  description = "The number of VMs created"
  value       = var.rdsh_count
}

output "dnsservers" {
  description = "Custom DNS configuration"
  value       = azurerm_virtual_network.vnet.dns_servers
}

output "vnetrange" {
  description = "Address range for deployment vnet"
  value       = azurerm_virtual_network.vnet.address_space
}

output "domain_name" {
  value = data.azuread_domains.avd_domain.domains.0.domain_name
}

output "tenantid" {
  value = "${var.arm_tenant_id}"
}

output "clientid" {
  value = "${var.arm_client_id}"
}

output "subsid" {
  value = "${var.arm_subscription_id}"
}

output "AVD_user_groupname" {
  description = "Azure Active Directory Group for AVD users"
  value       = data.azuread_group.aad_group.display_name
}

output "storage_account" {
  description = "Storage account for Profiles"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_share" {
  description = "Name of the Azure File Share created for FSLogix"
  value       = azurerm_storage_share.FSShare.name
}

output "Compute_Gallery" {
  description = "Azure Compute Gallery"
  value       = azurerm_shared_image_gallery.sig.name
}

output "azure_virtual_desktop_host_pool" {
  description = "Name of the Azure Virtual Desktop host pool"
  value       = azurerm_virtual_desktop_host_pool.hostpool.name
}

output "azurerm_virtual_desktop_application_group" {
  description = "Name of the Azure Virtual Desktop DAG"
  value       = azurerm_virtual_desktop_application_group.dag.name
}

output "azurerm_virtual_desktop_workspace" {
  description = "Name of the Azure Virtual Desktop workspace"
  value       = azurerm_virtual_desktop_workspace.workspace.name
}

