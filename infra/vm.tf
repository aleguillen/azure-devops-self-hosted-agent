################################################################
# CREATE: Linux VM or VMSS Agent - for Azure DevOps Agent Pool #
################################################################

# CREATE: Network Interface for Azure Linux VM as Azure DevOps Agent
# CREATE IF: ado_vmss_enabled is FALSE
resource "azurerm_network_interface" "ado" {
  count                 = var.ado_vmss_enabled ? 0 : 1
  name                = local.ado_nic_name
  location            = azurerm_resource_group.ado.location
  resource_group_name = azurerm_resource_group.ado.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.ado.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = merge(
    local.common_tags, 
    {
        display_name = "NIC for ADO VM"
    }
  )
}

# CREATE: Azure Linux VM as Azure DevOps Agent
# CREATE IF: ado_vmss_enabled is FALSE
resource "azurerm_linux_virtual_machine" "ado" {
  count                 = var.ado_vmss_enabled ? 0 : 1

  name                  = local.ado_vm_name
  location              = azurerm_resource_group.ado.location
  resource_group_name   = azurerm_resource_group.ado.name
  network_interface_ids = [azurerm_network_interface.ado.0.id]
  size               = var.ado_vm_size

  computer_name  = local.ado_vm_computer_name
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

  os_disk {
    name              = local.ado_vm_os_name
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

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

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag.primary_blob_endpoint
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "Azure DevOps VM"
    }
  )
}

