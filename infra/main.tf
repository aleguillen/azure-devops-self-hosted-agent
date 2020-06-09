# CREATE: Resource Group
resource "azurerm_resource_group" "ado" {
  name      = local.rg_name
  location  = var.location
  tags = merge(
    local.common_tags, 
    {
        display_name = "ADO Resource Group",
        created  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )
  
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

# GET: ADO Configuration cloudinit file. This can be converted to use an image.
data "template_file" "cloudinit" {
  template = file("${path.module}/scripts/cloudinit.tpl")

  vars = {
    server_url = var.ado_server_url
    pat_token = var.ado_pat_token
    pool_name = var.ado_pool_name
    vm_admin = var.ado_vm_username
    proxy_url = length(var.ado_proxy_url) > 0 ? var.ado_proxy_url : ""
    proxy_username = length(var.ado_proxy_username) > 0 ? var.ado_proxy_username : ""
    proxy_password = length(var.ado_proxy_password) > 0 ? var.ado_proxy_password : ""
    proxy_bypass = length(var.ado_proxy_bypass_list) > 0 ? join("\\n", var.ado_proxy_bypass_list) : ""
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content = data.template_file.cloudinit.rendered
  }
}

# CREATE: Private/Public SSH Key for Linux Virtual Machine or VMSS
resource "tls_private_key" "ado" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
