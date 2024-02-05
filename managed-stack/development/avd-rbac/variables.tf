variable "avd_users" {
  description = "AVD users"
  default = [
    "Mikal.Rekdal@trondheim.kommune.no",
    "sarumathy.soosaipillai@trondheim.kommune.no",
    "Sebastian.S.Eide@trondheim.kommune.no",
    "josefine.jornsen@avoconsulting.no",
    "alok.hom@trondheim.kommune.no"
  ]
}

variable "aad_group_name" {
  type        = string
  default     = "AVDUsers"
  description = "Azure Active Directory Group for AVD users"
}

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