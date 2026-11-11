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

# 1. Management Group (Creates new, or adopted via import)
resource "azurerm_management_group" "elz" {
  name         = "mg-enterprise-landing-zones"
  display_name = "Enterprise Landing Zones"
}

# 2. Dynamically CREATE a New Subscription
resource "azurerm_subscription" "new_landing_zone" {
  subscription_name = "sub-prod-landingzone"
  billing_scope_id  = var.billing_scope_id
}

# 3. Automatically Move/Associate Subscription into the Management Group
resource "azurerm_management_group_subscription_association" "mg_sub_association" {
  management_group_id = azurerm_management_group.elz.id
  subscription_id     = azurerm_subscription.new_landing_zone.subscription_id
}

# Dynamic provider alias targeting the newly created subscription ID
provider "azurerm" {
  features {}
  alias           = "sub_target"
  subscription_id = azurerm_subscription.new_landing_zone.subscription_id
}

# 4. Resource Group inside the New Subscription
resource "azurerm_resource_group" "rg" {
  provider = azurerm.sub_target
  name     = var.resource_group_name
  location = var.location

  depends_on = [azurerm_management_group_subscription_association.mg_sub_association]
}