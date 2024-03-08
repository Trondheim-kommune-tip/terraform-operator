

###################
###################
###################
#########
# RBac 
#########
data "azurerm_role_definition" "role" { # access an existing built-in role
  name = "Desktop Virtualization Contributor"
}

data "azurerm_role_definition" "role_session_host" { # access an existing built-in role
  name = "Virtual Machine Contributor"
}

# resource "azuread_group" "aad_group" was earlier
data "azuread_group" "aad_group" {
  display_name     = var.aad_group_name
  security_enabled = true
}

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

resource "azurerm_role_assignment" "role_sessionhost" {
  count              = var.rdsh_count
  scope              = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  role_definition_id = data.azurerm_role_definition.role_session_host.id
  principal_id       = data.azuread_group.aad_group.object_id
}