terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Reference existing Management Group (Prevents "already exists" creation error)
data "azurerm_management_group" "elz" {
  name = "mg-enterprise-landing-zones"
}

# 2. Reference existing Subscription
data "azurerm_subscription" "landing_zone" {
  subscription_id = "399e8de6-c59b-4cd5-80fe-41eef17c3aad"
}

# 3. Reference existing Resource Group in Central US
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 4. Grant GitHub OIDC App Contributor Permissions on the Subscription
resource "azurerm_role_assignment" "oidc_app_permissions" {
  scope                = data.azurerm_subscription.landing_zone.id
  role_definition_name = "Contributor"
  principal_id         = var.github_service_principal_object_id
}