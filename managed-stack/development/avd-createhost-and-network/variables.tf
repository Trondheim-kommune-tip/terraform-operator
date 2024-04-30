
####################
####################
## Create a host : NIC creation and session host VM, join domain, register with avd
###################

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
  default     = 5
}

variable "prefix" {
  type        = string
  default     = "avdtf"
  description = "Prefix of the name of the AVD machine(s)"
}

variable "domain_name" {
  type        = string
  default     = "tk.local"
  description = "Name of the domain to join"
}

variable "domain_user_upn" {
  type        = string
  default     = "testcifs" # do not include domain name as this is appended
  description = "Username for domain join (do not include domain name as this is appended)"
}

variable "domain_password" {
  type        = string
  default     = "tk1234"
  description = "Password of the user to authenticate with the domain"
  sensitive   = true
}

variable "azure_virtual_desktop_host_pool_name" {
  type        = string
  default     = "poolname"
  description = "VD hostpool name"
}

// run this command on Powershell to know the types and SKU available 
// Get-AzVmImageSku -Location 'North Europe' -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-11'
variable "vm_size" {
  description = "Size of the machine to deploy"
  // default     = "Standard_DS2_v2"
  // default     = "Standard_D4s_v5"
  default     = "Standard_D4ls_v5"
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

######
## avd configure
######
variable "workspace" {
  type        = string
  description = "Name of the Azure Virtual Desktop workspace"
  default     = "AVD-TF-Workspace"
}

variable "hostpool" {
  type        = string
  description = "Name of the Azure Virtual Desktop host pool"
  default     = "AVD-TF-HP"
}

variable "rfc3339" {
  type        = string
  default     = "2024-04-05T12:43:13Z"
  description = "Registration token expiration"
}


########################
### avd desktop vnet, NIC, session host
########################

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

variable "session_deploy_location" {
  type        = string
  default     = "norwayeast"
  description = "The Azure Region IPs for vm"
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
  default     = ["10.1.1.0/24"]
  description = "Address range for session host subnet"
}


#############
# storage
##############
variable "storage_subnet_range" {
  type        = list(string)
  default     = ["10.1.2.0/24"]
  description = "Address range for storage subnet"
}

variable "storage_key" {
  type        = string
  default     = "dummy"
  description = "storage key in tf vars for azure storage"
}

#### sql_db
variable "sql_db_name" {
  type        = string
  default     = "BluePrismProduction"
  description = "rpa mssql db"
}



####################
####################
####################
# RBAC
variable "arm_client_id" {
  type = string
  description = "azure RPA client id"
  default = "id"
}

variable "arm_client_secret" {
  type = string
  description = "azure RPA client secret"
  default = "id"
}

variable "arm_tenant_id" {
  type = string
  description = "azure RPA tenant id"
  default = "id"
}

variable "arm_subscription_id" {
  type = string
  description = "azure AD subs id"
  default = "id"
}

variable "ad_arm_subscription_id" {
  type = string
  description = "azure AD subs id for peering"
  default = "id"
}

variable "aad_group_name" {
  type        = string
  default     = "Terraform-RPA"
  description = "Azure Active Directory Group for AVD users"
}

variable "aad_group_name_avd" {
  type        = string
  default     = "AVDUsers"
  description = "Azure Active Directory Group for AVD users"
}

#variable "avd_users" {
#  description = "AVD users"
#  default = [
#    "fn.ln@avoconsulting.no",
#    "fn.ln@trondheim.kommune.no"
#  ]
#}

variable "avd_users" {
  description = "AVD users"
  default = []
}



####
# RPA
variable "itcon01_rpa_adhub_secret" {
  type = string
  description = "azure RPA-AD client secret"
  default = "id"
}

#### avd configure rg-avd-resources
variable "azure_virtual_desktop_compute_resource_group" {
  type = string
  description = "rg-avd-resources"
  default = "id"
}