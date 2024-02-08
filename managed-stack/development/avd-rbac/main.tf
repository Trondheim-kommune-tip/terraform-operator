output "tenantid" {
  value = "${var.arm_tenant_id}"
}

output "clientid" {
  value = "${var.arm_client_id}"
}

output "subsid" {
  value = "${var.arm_subscription_id}"
}

#data "azuread_user" "aad_user" {
#  for_each            = toset(var.avd_users)
#  #tenant_domain = "trondheim.onmicrosoft.com"
#  #mail = format("%s", each.key)
#  #user_principal_name = "${replace(format("%s", each.key), "@", "_")}#EXT#@${local.tenant_domain}"
#  user_principal_name = format("%s", each.key)
#}

data "azurerm_role_definition" "role" { # access an existing built-in role
  name = "Desktop Virtualization Contributor"
}

data "azurerm_role_definition" "role_session_host" { # access an existing built-in role
  name = "Virtual Machine Contributor"
}

# resource "azuread_group" "aad_group" was earlier
data "azuread_group" "aad_group" {
  #display_name = var.aad_group_name
  display_name = "Terraform-RPA"
  security_enabled = true
  #mail_enabled = false
  #object_id = "dfd11606-0864-4376-b688-e3a577151a43"
}

#resource "azuread_group_member" "aad_group_member" {
#  for_each         = data.azuread_user.aad_user
#  group_object_id  = azuread_group.aad_group.id
#  member_object_id = each.value["id"]
#}

resource "azurerm_role_assignment" "role_dag" {
  scope              = "${var.azurerm_virtual_desktop_application_group_dag_id}"
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = data.azuread_group.aad_group.object_id
}

resource "azurerm_role_assignment" "role_workspace" {
  scope              = "${var.azurerm_virtual_desktop_workspace_workspace_id}"
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = data.azuread_group.aad_group.object_id
}

resource "azurerm_role_assignment" "role_hostpool" {
  scope              = "${var.azure_virtual_desktop_host_pool_hostpool_id}"
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = data.azuread_group.aad_group.object_id
}

#resource "azurerm_role_assignment" "role_sessionhost" {
#  scope              = "azurerm_windows_virtual_machine.avd_vm.id"
#  role_definition_id = data.azurerm_role_definition.role_session_host.id
#  principal_id       = data.azuread_group.aad_group.object_id
#}
