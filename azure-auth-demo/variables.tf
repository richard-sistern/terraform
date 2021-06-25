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