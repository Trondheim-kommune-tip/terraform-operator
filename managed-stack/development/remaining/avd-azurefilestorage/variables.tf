variable "deploy_location" {
  type        = string
  default     = "northeurope"
  description = "The Azure Region in which all resources in this example should be created."
}

variable "rg_stor" {
  type        = string
  default     = "rg-avd-storage"
  description = "Name of the Resource group in which to deploy storage"
}

variable "avd_users" {
  description = "AVD users"
  default = [
    "Mikal.Rekdal@avoconsulting.no",
    "sarumathy.soosaipillai@avoconsulting.no",
    "Sebastian.S.Eide@avoconsulting.no"
  ]
}

variable "aad_group_name" {
  type        = string
  default     = "AVDUsers"
  description = "Azure Active Directory Group for AVD users"
}