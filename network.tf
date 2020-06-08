
# CREATE: Network Security Group - prevent inbound internet connection.
resource "azurerm_network_security_group" "ado" {
  name                = local.nsg_name
  location            = azurerm_resource_group.ado.location
  resource_group_name = azurerm_resource_group.ado.name

  tags = merge(
    local.common_tags, 
    {
        display_name = "ADO Network Security Group - Default Subnet"
    }
  )
}

# CREATE: Virtual Network
resource "azurerm_virtual_network" "ado" {
  name                = local.vnet_name
  location            = azurerm_resource_group.ado.location
  resource_group_name = azurerm_resource_group.ado.name
  address_space       = ["10.0.0.0/16"]

  tags = merge(
    local.common_tags, 
    {
        display_name = "ADO Virtual Network"
    }
  )
}

# CREATE: Subnet
resource "azurerm_subnet" "ado" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.ado.name
  virtual_network_name = azurerm_virtual_network.ado.name
  address_prefixes     = ["10.0.1.0/24"]

  enforce_private_link_endpoint_network_policies = true

}

# UPDATE: Assign Network Security Group to Subnet
resource "azurerm_subnet_network_security_group_association" "ado" {
  subnet_id                 = azurerm_subnet.ado.id
  network_security_group_id = azurerm_network_security_group.ado.id
}