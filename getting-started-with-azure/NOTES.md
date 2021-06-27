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

### Modules Registry

Terraform [Modules Registry](https://registry.terraform.io/)

Create a `registry-demo.tf` file in `mymodules` folder and enter the `azurerm compute` [example](https://registry.terraform.io/modules/Azure/compute/azurerm/latest):

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

module "linuxservers" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.example.name
  vm_os_simple        = "UbuntuServer"
  public_ip_dns       = ["linsimplevmips"] // change to a unique name per datacenter region
  vnet_subnet_id      = module.network.vnet_subnets[0]

  depends_on = [azurerm_resource_group.example]
}

module "windowsservers" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.example.name
  is_windows_image    = true
  vm_hostname         = "mywinvm" // line can be removed if only one VM module per resource group
  admin_password      = "ComplxP@ssw0rd!"
  vm_os_simple        = "WindowsServer"
  public_ip_dns       = ["winsimplevmips"] // change to a unique name per datacenter region
  vnet_subnet_id      = module.network.vnet_subnets[0]

  depends_on = [azurerm_resource_group.example]
}

module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.example.name
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  depends_on = [azurerm_resource_group.example]
}

output "linux_vm_public_name" {
  value = module.linuxservers.public_ip_dns_name
}

output "windows_vm_public_name" {
  value = module.windowsservers.public_ip_dns_name
}
```

*These modules require the `Azure CLI` client to be installed and logged in*

After running `terraform init` to initialise the new modules, `terraform plan` provides the following error:

>  terraform plan
>
>  Error: Invalid function argument on .terraform\modules\mymodule.linuxservers\main.tf line 109, in resource "azurerm_virtual_machine" "vm-linux":
>   109:         key_data = file(ssh_keys.value)
>      ├────────────────
>      │ ssh_keys.value is "~/.ssh/id_rsa.pub"
>
> Invalid value for "path" parameter: no file exists at ~/.ssh/id_rsa.pub; this function works only with files that are distributed as part of the configuration source code, so if this file will be created by a resource in this configuration you must instead obtain this result from an attribute of that resource.

Which simply means I had yet to run `ssh-keygen` on this laptop.  Complete instructions on this and OpenSSH Client installation can be found [here](https://www.onmsft.com/how-to/how-to-generate-an-ssh-key-in-windows-10).

