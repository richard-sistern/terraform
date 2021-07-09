# Implementing Terraform on Microsoft Azure

*Notes from [Pluralsight course](https://www.pluralsight.com/courses/implementing-terraform-microsoft-azure) by [Ned Bellavance](https://twitter.com/Ned1313)*

**Azure Cloud Shell** - already has Terraform installed and uses logged in credentials automatically

## Terraform for the Azure Admin

| ARM                               | Terraform                        |
| --------------------------------- | -------------------------------- |
| JSON                              | HCL                              |
| Parameters                        | Variables                        |
| Variables                         | Local variables                  |
| Resources                         | Resources                        |
| Functions                         | Functions                        |
| Nested templates                  | Modules                          |
| Explicit dependency               | Automatic dependency             |
| Refer by reference or resource id | Refer by resource or data source |

## Azure Providers

- Azure (azurerm)
- Azure Stack (as above but onprem)
- Azure Active Directory

Providers are:

- Versioned (fix to specific)
- Have data sources (info about target environment)
- Resources (created in the target environment)
- Modules (most have these associated)
- Authentication 

Authentication:

- Azure CLI (az login)
- Managed Service Identity
- Service principal with client secret
- Service principal with client certificate

AzureRM provider:

```hcl
provider "azurerm" {
	version			= "~> 1.0"	# Use version 1.x
	alias			= "networking" # Used to create additional providers
	subscription_id	= var.subscription_id
	client_id		= var.client_id
	client_secret	= var.client_secret
}
```

The authentication values can be specified in environment variables:

- ARM_CLIENT_ID (Service principal ID)
- ARM_CLIENT_SECRET (Service principal secret)
- ARM_ENVIRONMENT (Azure environment, public, gov, etc)
- ARM_SUBSCRIPTION_ID (Azure subscription ID)
- ARM_TENANT_ID (Azure AD tenant ID for service principal)
- ARM_USE_MSI (Use Managed Service Identity)



## Multiple Provider Instances

- Work with more than one subscription
- Multiple authentication sources

Use an *alias* to have multiple providers:
```hcl
provider "azurerm" {
	alias			= "network"
	# Credentials

	# If credentials limited to task only, may want to disable the following to avoid an error
	skip_provider_registration 	= true
	skip_credentials_validation = true
}
```

These are then called in resources with:
```hcl
resource "azurerm_virtual_network_peering" "sec" {
	provider		= "azurerm.network 
}
```