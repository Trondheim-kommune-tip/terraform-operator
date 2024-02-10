variable "resource_group_location" {
  default     = "northeurope"
  description = "Location of the resource group."
}

variable "rg" {
  type        = string
  default     = "rg-avd-compute"
  description = "Name of the Resource group in which to deploy session host"
}

variable "rdsh_count" {
  description = "Number of AVD machines to deploy"
  //default     = 2
  default     = 3
}

variable "prefix" {
  type        = string
  default     = "avdtf"
  description = "Prefix of the name of the AVD machine(s)"
}

variable "domain_name" {
  type        = string
  default     = "infra.local"
  description = "Name of the domain to join"
}

variable "domain_user_upn" {
  type        = string
  default     = "domainjoineruser" # do not include domain name as this is appended
  description = "Username for domain join (do not include domain name as this is appended)"
}

variable "domain_password" {
  type        = string
  default     = "ChangeMe123!"
  description = "Password of the user to authenticate with the domain"
  sensitive   = true
}

variable "azure_virtual_desktop_host_pool_name" {
  type        = string
  default     = "poolname"
  description = "VD hostpool name"
}

// run this command on Powershell to know the types and SKU available 
// Get-AzVmImageSku -Location 'Norway East' -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-11'
variable "vm_size" {
  description = "Size of the machine to deploy"
  // default     = "Standard_DS2_v2"
  default     = "Standard_D4s_v5"
}

variable "ou_path" {
  default = ""
}

variable "local_admin_username" {
  type        = string
  default     = "localadm"
  description = "local admin username"
}

variable "local_admin_password" {
  type        = string
  default     = "ChangeMe123!"
  description = "local admin password"
  sensitive   = true
}

variable "rg_name" {
  type        = string
  default     = "rg-avd-resources"
  description = "Name of the Resource group in which to deploy service objects"
}

variable "rg_shared_name" {
  type        = string
  default     = "rg-shared-resources"
  description = "Name of the Resource group in which to deploy shared resources"
}

variable "deploy_location" {
  type        = string
  default     = "norwayeast"
  description = "The Azure Region in which all resources in this example should be created."
}

variable "ad_vnet" {
  type        = string
  default     = "infra-network"
  description = "Name of domain controller vnet"
}

variable "ad_rg" {
  type        = string
  default     = "infra-rg"
  description = "Name of domain controller rg"
}

variable "dns_servers" {
  type        = list(string)
  default     = ["10.0.1.4", "168.63.129.16"]
  description = "Custom DNS configuration"
}

variable "vnet_range" {
  type        = list(string)
  default     = ["10.2.0.0/16"]
  description = "Address range for deployment VNet"
}
variable "subnet_range" {
  type        = list(string)
  default     = ["10.2.0.0/24"]
  description = "Address range for session host subnet"
}

variable "azurerm_virtual_desktop_host_pool_registration_info_registrationinfo_token" {
  type        = string
  default     = "reg_info_token"
  description = "value of host pool reg info token"
}

variable "azure_virtual_desktop_host_pool_hostpool_id" {
  type        = string
  default     = "id"
  description = "value of host pool id"
}


# RBAC
variable "arm_client_id" {
  type = string
  description = "azure AD client id"
}

variable "arm_client_secret" {
  type = string
  description = "azure AD client secret"
}

variable "arm_tenant_id" {
  type = string
  description = "azure AD tenant id"
}

variable "arm_subscription_id" {
  type = string
  description = "azure AD subs id"
}

variable "azurerm_virtual_desktop_application_group_dag_id" {
  type = string
  description = "azure AD azurerm_virtual_desktop_application_group_dag_id id"
}

variable "azurerm_virtual_desktop_workspace_workspace_id" {
  type = string
  description = "azure AD azurerm_virtual_desktop_workspace_workspace_id id"
}

variable "azure_virtual_desktop_host_pool_hostpool_id" {
  type = string
  description = "azure AD azure_virtual_desktop_host_pool_hostpool_id id"
}

variable "aad_group_name" {
  type        = string
  default     = "Terraform-RPA"
  description = "Azure Active Directory Group for AVD users"
}
