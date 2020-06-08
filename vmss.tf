################################################################
# CREATE: Linux VM or VMSS Agent - for Azure DevOps Agent Pool #
################################################################

# CREATE: Azure Linux VMSS as Azure DevOps Agent
# CREATE IF: ado_vmss_enabled is TRUE
resource "azurerm_linux_virtual_machine_scale_set" "ado" {
  count                 = var.ado_vmss_enabled ? 1 : 0

  name                  = local.ado_vmss_name
  location              = azurerm_resource_group.ado.location
  resource_group_name   = azurerm_resource_group.ado.name
  sku                   = var.ado_vm_size

  instances             = var.ado_vmss_instances
  upgrade_mode          = "Manual"
  overprovision = false 

  zones = [1, 2, 3]

  computer_name_prefix  = local.ado_vm_computer_name
  admin_username = var.ado_vm_username
  disable_password_authentication = length(var.ado_vm_password) > 0 ? false : true
  admin_password =  length(var.ado_vm_password) > 0 ? var.ado_vm_password : null

  dynamic "admin_ssh_key" {
    for_each = length(var.ado_vm_password) > 0 ? [] : [var.ado_vm_username]
    content {
      username   = var.ado_vm_username
      public_key = tls_private_key.ado["public_key_openssh"]
    }
  }

  # Cloud Init Config file
  custom_data = data.template_cloudinit_config.config.rendered

  # If vm_image_id is specified will use this instead of source_image_reference default settings
  source_image_id =  length(var.vm_image_id) > 0 ? var.vm_image_id : null
  
  dynamic "source_image_reference" {
    for_each = length(var.vm_image_id) > 0 ? [] : [var.vm_image_ref]
    content {
      publisher = lookup(var.vm_image_ref, "publisher", "Canonical")
      offer     = lookup(var.vm_image_ref, "offer", "UbuntuServer")
      sku       = lookup(var.vm_image_ref, "sku", "18.04-LTS")
      version   = lookup(var.vm_image_ref, "version", "latest")
    }
  }

  os_disk {
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  network_interface {
    name    = local.ado_nic_name
    primary = true

    ip_configuration {
      name      = "ipconfig1"
      primary   = true
      subnet_id = azurerm_subnet.ado.id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag.primary_blob_endpoint
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "Azure DevOps VMSS"
    }
  )
}