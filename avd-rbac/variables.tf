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