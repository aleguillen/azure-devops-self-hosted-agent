output "key_vault_name" {
  value = azurerm_key_vault.ado.name
}

output "pe_rg_name" {
  value = azurerm_resource_group.ado.name
}

output "pe_vnet_name" {
  value = azurerm_virtual_network.ado.name
}

output "pe_subnet_name" {
  value = azurerm_subnet.ado.name
}

output "terraformstoragerg" {
  value = azurerm_resource_group.ado.name
}

output "terraformstorageaccount" {
  value = azurerm_storage_account.ado.name
}

output "terraformstoragecontainer" {
  value = azurerm_storage_container.ado.name
}