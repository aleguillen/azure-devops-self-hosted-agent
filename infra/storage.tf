############################################
# SETTING BOOT DIAGNOSTICS STORAGE ACCOUNT #
############################################

# CREATE: Storage Account for Boot Diagnostics
resource "azurerm_storage_account" "diag" {
  name                     = "diag${substr(md5(azurerm_resource_group.ado.id),0,15)}sa"
  resource_group_name      = azurerm_resource_group.ado.name
  location                 = azurerm_resource_group.ado.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = merge(
      local.common_tags, 
      {
          display_name = "Diagnostics Storage Account"
      }
  )
}

# CREATE: Private Endpoint to Blob Storage for Diagnostics
resource "azurerm_private_endpoint" "diag" {
  name                = "${azurerm_storage_account.diag.name}-pe"
  location            = azurerm_resource_group.ado.location
  resource_group_name = azurerm_resource_group.ado.name
  subnet_id           = azurerm_subnet.ado.id

  private_service_connection {
    name                           = "${azurerm_storage_account.diag.name}-pecon"
    private_connection_resource_id = azurerm_storage_account.diag.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = merge(
      local.common_tags, 
      {
          display_name = "Private Endpoint to connect to Diagnostics Storage Account"
      }
  )
}

################################################
# SETTING TERRAFORM STATE FILE STORAGE ACCOUNT #
################################################

# CREATE: Storage Account for Terraform State file
resource "azurerm_storage_account" "ado" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.ado.name
  location                 = azurerm_resource_group.ado.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = merge(
      local.common_tags, 
      {
          display_name = "Terraform Storage Account"
      }
  )
}

# CREATE: Storage Account Container for Terraform State file
resource "azurerm_storage_container" "ado" {
  name                  = local.tf_container_name
  storage_account_name  = azurerm_storage_account.ado.name
  container_access_type = "private"
}

# CREATE: Private Endpoint to Terraform Blob Storage
resource "azurerm_private_endpoint" "ado" {
  name                = "pe-${azurerm_storage_account.ado.name}"
  location            = azurerm_resource_group.ado.location
  resource_group_name = azurerm_resource_group.ado.name
  subnet_id           = azurerm_subnet.ado.id

  private_service_connection {
    name                           = "pecon-${azurerm_storage_account.ado.name}"
    private_connection_resource_id = azurerm_storage_account.ado.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = merge(
      local.common_tags, 
      {
          display_name = "Private Endpoint to connect to Storage Account"
      }
  )
}

# CREATE: Private DNS zone to blob endpoint
resource "azurerm_private_dns_zone" "blob" {
  name                = local.blob_private_dns_name 
  resource_group_name = azurerm_resource_group.ado.name
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Private DNS zone to resolve storage private endpoint."
      }
  )
}

# CREATE: A record to Terraform Blob Storage.
resource "azurerm_private_dns_a_record" "tf" {
  name                = azurerm_storage_account.ado.name
  zone_name           = azurerm_private_dns_zone.blob.name
  resource_group_name = azurerm_resource_group.ado.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.ado.private_service_connection.0.private_ip_address]
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Private DNS record to Blob endpoint."
      }
  )
}

# CREATE: A record to Diagnostics Blob Storage.
resource "azurerm_private_dns_a_record" "diag" {
  name                = azurerm_storage_account.diag.name
  zone_name           = azurerm_private_dns_zone.blob.name
  resource_group_name = azurerm_resource_group.ado.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.diag.private_service_connection.0.private_ip_address]
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Private DNS record to Diagnostics Blob endpoint."
      }
  )
}

# CREATE: Link Private DNS zone with Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "ado" {
  name                  = local.blob_private_dns_link_name
  resource_group_name   = azurerm_resource_group.ado.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.ado.id
  registration_enabled  = false
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Private DNS zone Link to VNET."
      }
  )
}