output "subnet_id" {
  value = azurerm_subnet.ado.id
}

output "ado_vm_id" {
  value = azurerm_linux_virtual_machine.ado.*.id
}

output "ado_vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.ado.*.id
}

output "storage_id" {
  value = azurerm_storage_account.ado.id
}

output "storage_pe_ip_address" {
  value = azurerm_private_endpoint.ado.private_service_connection.0.private_ip_address
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