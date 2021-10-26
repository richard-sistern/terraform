data "azurerm_virtual_network" "vnet" {
  name                = "vnet-name"
  resource_group_name = "vnet-rg-name"
}

data "azurerm_subnet" "all" {
    name                 = data.azurerm_virtual_network.vnet.subnets[count.index]
    virtual_network_name = data.azurerm_virtual_network.vnet.name
    resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
    count                = length(data.azurerm_virtual_network.vnet.subnets)
} # https://stackoverflow.com/questions/54027756/retrieve-azure-vnet-subnet-ids-with-terraform

 output "subnet_names" {
    value = data.azurerm_virtual_network.vnet.subnets
 }

 output "subnet_ids" {
    value = data.azurerm_subnet.all.*.id
 }
