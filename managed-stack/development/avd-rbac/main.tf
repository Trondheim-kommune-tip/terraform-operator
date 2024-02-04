terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}

data "azuread_user" "aad_user" {
  for_each            = toset(var.avd_users)
  user_principal_name = format("%s", each.key)
}

data "azurerm_role_definition" "role" { # access an existing built-in role
  name = "Desktop Virtualization Contributor"
}

data "azurerm_role_definition" "role_session_host" { # access an existing built-in role
  name = "	Virtual Machine Contributor"
}

resource "azuread_group" "aad_group" {
  display_name     = var.aad_group_name
  security_enabled = true
}

resource "azuread_group_member" "aad_group_member" {
  for_each         = data.azuread_user.aad_user
  group_object_id  = azuread_group.aad_group.id
  member_object_id = each.value["id"]
}

resource "azurerm_role_assignment" "role_dag" {
  scope              = azurerm_virtual_desktop_application_group.dag.id
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = azuread_group.aad_group.id
}

resource "azurerm_role_assignment" "role_workspace" {
  scope              = azurerm_virtual_desktop_workspace.workspace.id
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = azuread_group.aad_group.id
}

resource "azurerm_role_assignment" "role_hostpool" {
  scope              = azurerm_virtual_desktop_host_pool.hostpool.id
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = azuread_group.aad_group.id
}

resource "azurerm_role_assignment" "role_sessionhost" {
  scope              = azurerm_windows_virtual_machine.avd_vm.id
  role_definition_id = data.azurerm_role_definition.role_session_host.id
  principal_id       = azuread_group.aad_group.id
}
