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

# Provider alias configured to target the subscription dynamically via variable
provider "azurerm" {
  features {}
  alias           = "sub_target"
  subscription_id = var.subscription_id
}

# 1. Reference existing Management Group
data "azurerm_management_group" "elz" {
  name = "mg-enterprise-landing-zones"
}

# 2. Reference existing Subscription dynamically
data "azurerm_subscription" "landing_zone" {
  subscription_id = var.subscription_id
}

# 3. Associate/Move the existing subscription into the Enterprise Landing Zones Management Group
resource "azurerm_management_group_subscription_association" "mg_sub_association" {
  management_group_id = data.azurerm_management_group.elz.id
  subscription_id     = data.azurerm_subscription.landing_zone.id
}

# 4. Provision or adopt the Resource Group inside the subscription using the provider alias
resource "azurerm_resource_group" "rg" {
  provider = azurerm.sub_target
  name     = var.resource_group_name
  location = var.location

  depends_on = [azurerm_management_group_subscription_association.mg_sub_association]
}

# 5. Grant GitHub OIDC App Contributor Permissions on the Subscription
resource "azurerm_role_assignment" "oidc_app_permissions" {
  provider             = azurerm.sub_target
  scope                = data.azurerm_subscription.landing_zone.id
  role_definition_name = "Contributor"
  principal_id         = var.github_service_principal_object_id

  depends_on = [azurerm_management_group_subscription_association.mg_sub_association]
}