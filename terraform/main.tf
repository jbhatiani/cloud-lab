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

provider "azurerm" {
  features {}
  alias           = "sub_target"
  subscription_id = var.subscription_id
}

# 1. Management Group
resource "azurerm_management_group" "elz" {
  name         = "mg-enterprise-landing-zones"
  display_name = "Enterprise Landing Zones"
}

# 2. Subscription Data Source
data "azurerm_subscription" "landing_zone" {
  subscription_id = var.subscription_id
}

# 3. Move/Associate Subscription into Management Group
resource "azurerm_management_group_subscription_association" "mg_sub_association" {
  management_group_id = azurerm_management_group.elz.id
  subscription_id     = data.azurerm_subscription.landing_zone.id
}

# 4. Resource Group inside Target Subscription
resource "azurerm_resource_group" "rg" {
  provider = azurerm.sub_target
  name     = var.resource_group_name
  location = var.location

  depends_on = [azurerm_management_group_subscription_association.mg_sub_association]
}

# 5. Role Assignment
resource "azurerm_role_assignment" "oidc_app_permissions" {
  provider             = azurerm.sub_target
  scope                = data.azurerm_subscription.landing_zone.id
  role_definition_name = "Contributor"
  principal_id         = var.github_service_principal_object_id

  depends_on = [azurerm_management_group_subscription_association.mg_sub_association]
}