# Terraform

## [Getting Started with Terraform for Azure](https://www.youtube.com/playlist?list=PLD7svyKaquTlE9dErhMazFhWbSSCfMP_4)

### Key Terraform Features

- Infrastructure as Code - blueprint of datacentre in version control to be shared and reused
- Execution Plans - planning step which generates an execution plan which shows what Terraform will do when applying changes
- Resource Graph - allows parallelisation and modification of non-dependent resources
- Change Automation - complex change sets applied with minimal human intervention 

### Terraform and Configuration Management

There is some overlap between tools, however the key areas of focus for each are:

| Terraform                                       | Configuration Management (Chef/Puppet) |
| ----------------------------------------------- | -------------------------------------- |
| Infrastructure Automation                       | OS configuration                       |
| VM and Cloud provisioning                       | Application installation               |
| Declarative like configuration management tools | Declarative                            |
| Limited OS configuration management             | Limited infrastructure automation      |

### Terraform Use Cases

- Infrastructure Deploy - network, storage, compute, etc.
- Multi-tier Application Install 
- Self-Service - perhaps part of a service request workflow
- Disposable Environments - demo, test, etc.
- Multi-cloud

### Terraform Execution Lifecycle

#### Plan

*What things will Terraform do*

#### Apply

*Create the things*

#### Destroy

*Remove the things*

### Authenticating with Azure

Terraform requires a [Service Principal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret) (other options exist) to access Azure resources:

1. Create Azure AD Application Registration
2. Create key
3. Assign application to role
4. Login as application (Terraform)
5. Execute tasks (deploy, etc.)

Create the Service Principal:

```shell
az login

az ad sp create-for-rbac -n "Terraform" --role="Contributor" --scope="/subscriptions/<subscription id>"
```

Record the output:

```json
{
  "appId": "<app id>",
  "displayName": "Terraform",
  "name": "<app id>",
  "password": "<password>",
  "tenant": "<tenant id>"
}
```

Create Terraform scaffold:

- main.tf
- terraform.tfvars
- variables.tf

Add Azure scaffold to `main.tf`:

```hcl
provider "azurerm" {
  subscription_id = "<subscription id>"
  client_id = "<application id>"
  client_secret = "<password>"
  tenant_id = "<tenant id>"
}
```

Run `terraform init` to download the Azure provider plugin.  After which running `terraform plan` gives the following error:

> Error: Insufficient features blocks
>
> on  line 0:
> (source code not available)
>
> At least 1 "features" blocks are required.

The [Azure provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret) provides a clue:

```hcl
# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "00000000-0000-0000-0000-000000000000"
  client_id       = "00000000-0000-0000-0000-000000000000"
  client_secret   = "0000000000000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000000"
}
```

The tutorial appears to be for an older version of Terraform.  Time to rework and attempt to fix things...

Lets start by removing any Azure secrets from `.gitignore` :

```shell
...
# Ignore any .tfvars files that are generated automatically for each Terraform run. Most
# .tfvars files are managed as part of configuration and so should be included in
# version control.
#
# example.tfvars
terraform.tfvars
...
```

Edit `main.tf`:

```hcl
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
```

Edit `variables.tf`:

```hcl
provider "azurerm" {
    features {}

    subscription_id = "${var.subscription_id}"
    client_id = "${var.client_id}"
    client_secret = "${var.client_secret}"
    tenant_id = "${var.tenant_id}"
}

variable "subscription_id" {
    type = string
    description = "Enter Subscription ID for provisioning resources in Azure"
}

variable "client_id" {
    type = string
    description = "Enter Client ID for Application created in Azure AD"
}

variable "client_secret" {
    type = string
    sensitive = true
    description = "Enter Client secret for Application in Azure AD"
}

variable "tenant_id" {
    type = string
    description = "Enter Tenent ID for Azure subscription"
}
```

Edit `terraform.tfvars`:

```hcl
subscription_id = "<subscription id"
client_id = "<client id>"
client_secret = "<client secret>"
tenant_id = "<tenant id>"
```

Running `terraform apply` now creates a resource group in Azure

### Create a VM

The [Terraform documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) for `azurerm virtual machine` has an example to get started:

```hcl
variable "prefix" {
  default = "tfvmex"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
```

### Modules

Terraform [modules documentation](https://www.terraform.io/docs/language/modules/index.html)

Move the following into `./mymodules/modules-example.tf`:

```hcl
# Resource Group demo
resource "azurerm_resource_group" "resource_gp" {
  name = "Terraform-Demo"
  location = "eastus"

  tags = {
    Owner = "Rich S"
  }
}
```

This is the referenced in `main.tf` with:

```hcl
module "mymodule" {
  source = "./mymodule"
}
```

Run `terraform init` to initialise the module:

```shell
terraform init

# Initializing modules...
# - mymodule in mymodule
```

