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

# 1. Management Group (Idempotent: Adopts safely if it already exists)
resource "azurerm_management_group" "elz" {
  name         = "mg-enterprise-landing-zones"
  display_name = "Enterprise Landing Zones"
}

# 2. Reference existing subscription via Data Source to prevent creation/import errors
data "azurerm_subscription" "landing_zone" {
  subscription_id = "399e8de6-c59b-4cd5-80fe-41eef17c3aad"
}

# 3. Resource Group (Idempotent in Central US: Adopts safely if it already exists)
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 4. Grant GitHub OIDC App Contributor Permissions on the Subscription
resource "azurerm_role_assignment" "oidc_app_permissions" {
  scope                = data.azurerm_subscription.landing_zone.id
  role_definition_name = "Contributor"
  principal_id         = var.github_service_principal_object_id
}