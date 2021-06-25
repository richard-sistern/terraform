# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "registry.terraform.io/hashicorp/azurerm"
      version = "=2.65.0"
    }
  }
}

resource "azurerm_resource_group" "resource_gp" {
  name = "Terraform-Demo"
  location = "eastus"

  tags = {
    Owner = "Rich S"
  }
}



