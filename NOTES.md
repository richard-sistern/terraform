# Terraform

## Commands

```shell
terraform init
terraform validate
terraform plan -out bla.tfplan
terraform apply "bla.tfplan"
terraform destroy
```

## Importing

When importing with a var file, the order is important:

```shell
terraform import -var-file="file.tfvars" azurerm_key_vault_secret.example "https://example-keyvault.vault.azure.net/secrets/example/fdf067c93bbb4b22bff4d8b7a9a56217"
```
