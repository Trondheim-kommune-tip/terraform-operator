output "azure_virtual_desktop_compute_resource_group" {
  description = "Name of the Resource group in which to deploy session host"
  value       = azurerm_resource_group.sh.name
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

output "location" {
  description = "The Azure region"
  value       = azurerm_resource_group.sh.location
}

output "azure_virtual_desktop_host_pool_hostpool_id" {
  description = "ID of the Azure Virtual Desktop host pool"
  value       = azurerm_virtual_desktop_host_pool.hostpool.id
}

output "azurerm_virtual_desktop_application_group_dag_id" {
  description = "Name of the Azure Virtual Desktop DAG id"
  value       = azurerm_virtual_desktop_application_group.dag.id
}

output "azurerm_virtual_desktop_workspace_workspace_id" {
  description = "id of the Azure Virtual Desktop workspace"
  value       = azurerm_virtual_desktop_workspace.workspace.id
}

output "azurerm_virtual_desktop_host_pool_registration_info_registrationinfo_token" {
  description = "token for hostpool reg info"
  value       = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
  sensitive   = true
}