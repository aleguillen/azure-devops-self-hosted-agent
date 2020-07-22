
# CREATE: Key Vault
resource "azurerm_key_vault" "ado" {
  name                        = local.kv_name
  location                    = azurerm_resource_group.ado.location
  resource_group_name         = azurerm_resource_group.ado.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = false
  soft_delete_enabled         = true
  purge_protection_enabled    = false

  sku_name = "standard"

  # Access policy for current object id
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "get",
      "list",
      "set",
      "restore"
    ]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = merge(
    local.common_tags,
    {
      display_name = "Key Vault"
    }
  )
}

# CREATE: Private Endpoint to Key Vault
resource "azurerm_private_endpoint" "kv" {
  name                = "pe-${azurerm_key_vault.ado.name}"
  location            = azurerm_resource_group.ado.location
  resource_group_name = azurerm_resource_group.ado.name
  subnet_id           = azurerm_subnet.ado.id

  private_service_connection {
    name                           = "pecon-${azurerm_key_vault.ado.name}"
    private_connection_resource_id = azurerm_key_vault.ado.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = merge(
      local.common_tags, 
      {
          display_name = "Private Endpoint to Key Vault"
      }
  )
}

# CREATE: Private DNS zone to Key Vault
resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"  
  resource_group_name = azurerm_resource_group.ado.name
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Private DNS zone to Key Vault."
      }
  )
}

# CREATE: A record to Key Vault.
resource "azurerm_private_dns_a_record" "kv" {
  name                = azurerm_key_vault.ado.name
  zone_name           = azurerm_private_dns_zone.kv.name
  resource_group_name = azurerm_resource_group.ado.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.kv.private_service_connection.0.private_ip_address]
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Private DNS record to Key Vault."
      }
  )
}

# CREATE: Link Private DNS zone with Virtual Network - Key Vault
resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "dnslink-${azurerm_private_dns_zone.kv.name}"
  resource_group_name   = azurerm_resource_group.ado.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = azurerm_virtual_network.ado.id
  registration_enabled  = false
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Key Vault Private DNS zone Link to VNET."
      }
  )
}