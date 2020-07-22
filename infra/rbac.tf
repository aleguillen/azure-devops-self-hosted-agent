# CREATE: Role Assignment to Subscriptions using Managed Identity of the Agent
resource "azurerm_role_assignment" "ado" {
  count             = length(var.ado_subscription_ids)
  
  scope                = "/subscriptions/${element(var.ado_subscription_ids, count.index)}"
  role_definition_name = "Contributor"
  principal_id         = var.ado_vmss_enabled ? azurerm_linux_virtual_machine_scale_set.ado.0.identity.0.principal_id : azurerm_linux_virtual_machine.ado.0.identity.0.principal_id
}


# CREATE: Role Assignment to Key Vault using Current Client Configuration
resource "azurerm_role_assignment" "kv" {
  scope                = azurerm_key_vault.ado.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}