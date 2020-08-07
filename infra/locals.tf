locals {
  # Following Azure Naming Conventions: 
  # https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging

  # General
  naming_conv = "${var.prefix}-${var.environment_name}"
  
  unique_rg_string = md5(azurerm_resource_group.ado.id)
  
  rg_name   = "rg-${local.naming_conv}"

  vnet_name   = "vnet-${local.naming_conv}"

  nsg_name   = "nsg-${local.naming_conv}-default"
  
  kv_name = "kv-${local.naming_conv}"
  
  kv_private_dns_name = "privatelink.vaultcore.azure.net" 

  kv_private_dns_link_name = "dnslink-${local.kv_private_dns_name}-${azurerm_virtual_network.ado.name}"

  common_tags = merge(
    var.common_tags, 
    {
      environment = var.environment_name
      last_modified  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )
  
  # ADO Agent Pool - Agents details
  ado_vm_name   = "vm-${local.naming_conv}-ado"
  
  ado_vmss_name   = "vmss-${local.naming_conv}-ado"
  
  ado_vm_computer_name   = "${local.naming_conv}-ado"
  
  ado_vm_os_name   = "disk-os-${local.naming_conv}-ado"

  ado_nic_name   = "nic-vm-${local.naming_conv}-ado"

  # Terraform
  storage_account_name = "tf${substr(local.unique_rg_string,0,15)}sa"
  
  tf_container_name = "terraform"

  blob_private_dns_name = "privatelink.blob.core.windows.net"  
  
  blob_private_dns_link_name = "dnslink-${local.blob_private_dns_name}-${azurerm_virtual_network.ado.name}"

}
