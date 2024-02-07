output "AVD_user_groupname" {
  description = "Azure Active Directory Group for AVD users"
  value       = data.azuread_group.aad_group.display_name
}