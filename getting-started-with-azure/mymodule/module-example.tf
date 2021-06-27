# Resource Group demo
resource "azurerm_resource_group" "resource_gp" {
  name = "Terraform-Demo"
  location = "eastus"

  tags = {
    Owner = "Rich S"
  }
}