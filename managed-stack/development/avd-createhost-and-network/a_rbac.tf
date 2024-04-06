#########
# RBac 
#########
# The Desktop Virtualization Contributor role allows managing all your Azure Virtual Desktop resources.
data "azurerm_role_definition" "role_dvc" { # access an existing built-in role
  name = "Desktop Virtualization Contributor"
}

# The Desktop Virtualization User role allows users to use an application on a session host from an application group as a non-administrative user.
data "azurerm_role_definition" "role_dvu" { 
  name = "Desktop Virtualization User"
}

# access an existing built-in role
data "azurerm_role_definition" "role_session_host" { 
  name = "Virtual Machine Contributor"
}


# View Virtual Machines in the portal and login as a regular user.
data "azurerm_role_definition" "role_viewonportal_nd_login" { 
  name = "Virtual Machine User Login"
}


######### aad group
# resource "azuread_group" "aad_group" was earlier
data "azuread_group" "aad_group" {
  display_name     = var.aad_group_name
  security_enabled = true
}

#data "azuread_user" "aad_user" {
#  for_each            = toset(var.avd_users)
#  user_principal_name = format("%s", each.key)
#  password            = "Avdaccess123@"
#}

#data "azuread_user" "robot" {
#  user_principal_name = "robot.roger.robot.roger@trondheim.kommune.no"
#}

#resource "azuread_group" "aad_group" {
#  display_name     = var.aad_group_name_avd
#  security_enabled = true
#  provider = azuread.rpa
#}

# later remove this section
#resource "azuread_user" "aad_user" {
#  for_each            = toset(var.avd_users)
#  display_name        = format("%s", each.key)
#  user_principal_name = format("%s", each.key)
#  password            = "Avdaccess123@"
#  force_password_change = true
#}

#data "azuread_user" "robot" {
#  user_principal_name = "robot.roger.robot.roger@trondheim.kommune.no"
#}

#resource "azuread_group_member" "aad_group_member" {
#  for_each         = azuread_user.aad_user
#  group_object_id  = data.azuread_group.aad_group.id
#  member_object_id = each.value["id"]
#}

#resource "azurerm_role_assignment" "role_useraccount" {
#  scope              = data.azuread_user.aad_user.object_id
#  role_definition_id = data.azurerm_role_definition.role_viewonportal_nd_login.id
#  principal_id       = data.azuread_group.aad_group.object_id
#}


# roles 
# https://learn.microsoft.com/en-us/azure/virtual-desktop/tutorial-try-deploy-windows-11-desktop?tabs=windows-client#prerequisites
resource "azurerm_role_assignment" "role_dag" {
  scope              = "${var.azurerm_virtual_desktop_application_group_dag_id}"
  role_definition_id = data.azurerm_role_definition.role_dvc.id
  principal_id       = data.azuread_group.aad_group.object_id
}

resource "azurerm_role_assignment" "role_workspace" {
  scope              = "${var.azurerm_virtual_desktop_workspace_workspace_id}"
  role_definition_id = data.azurerm_role_definition.role_dvc.id
  principal_id       = data.azuread_group.aad_group.object_id
}

resource "azurerm_role_assignment" "role_hostpool" {
  scope              = "${var.azure_virtual_desktop_host_pool_hostpool_id}"
  role_definition_id = data.azurerm_role_definition.role_dvc.id
  principal_id       = data.azuread_group.aad_group.object_id
}

resource "azurerm_role_assignment" "role_sessionhost" {
  count              = var.rdsh_count
  scope              = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  role_definition_id = data.azurerm_role_definition.role_session_host.id
  principal_id       = data.azuread_group.aad_group.object_id
}

# dvu 
#resource "azurerm_role_assignment" "role_dag_dvu" {
#  scope              = "${var.azurerm_virtual_desktop_application_group_dag_id}"
#  role_definition_id = data.azurerm_role_definition.role_dvu.id
#  principal_id       = data.azuread_group.aad_group.object_id
#}


