locals {
  # Following Azure Naming Conventions: 
  # https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging

  # General
  rg_name   = "rg-${var.prefix}-${var.environment_name}"

  vnet_name   = "vnet-${var.prefix}-${var.environment_name}"

  nsg_name   = "nsg-${var.prefix}-${var.environment_name}-default"

  kv_name = "kv-${var.prefix}-${var.environment_name}"

  common_tags = merge(
    var.common_tags, 
    {
      environment = var.environment_name
      last_modified  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )
  
  # ADO Agent Pool - Agents details
  ado_vm_name   = "vm-${var.prefix}-${var.environment_name}-ado"
  
  ado_vmss_name   = "vmss-${var.prefix}-${var.environment_name}-ado"
  
  ado_vm_computer_name   = "${var.prefix}-${var.environment_name}-ado"
  
  ado_vm_os_name   = "disk-os-${var.prefix}-${var.environment_name}-ado"

  ado_nic_name   = "nic-vm-${var.prefix}-${var.environment_name}-ado"

  # Terraform
  tf_container_name = "terraform"
  
  blob_private_dns_link_name = "dnslink-${var.prefix}-${var.environment_name}-blob"
}
