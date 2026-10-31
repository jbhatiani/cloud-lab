terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Reference your existing Management Group ("Enterprise Landing Zones")
data "azurerm_management_group" "existing_mg" {
  name = "mg-enterprise-landing-zones"
}

# 2. Reference your existing Subscription ("sub-prod-landingzone")
data "azurerm_subscription" "sub_prod_landingzone" {
  subscription_id = "399e8de6-c59b-4cd5-80fe-41eef17c3aad"
}

# 3. Point the provider directly to the existing subscription ID
provider "azurerm" {
  alias           = "target_sub"
  subscription_id = data.azurerm_subscription.sub_prod_landingzone.subscription_id

  features {}
}

# 4. Create the Resource Group inside that existing subscription
resource "azurerm_resource_group" "workload_rg" {
  provider = azurerm.target_sub

  name     = "rg-webapp-prod-cus"
  location = "centralus"
  tags = {
    Environment      = "Production"
    Workload         = "Core Web Application"
    ManagedBy        = "Terraform"
    ManagementGroup  = "Enterprise Landing Zones"
    Subscription     = "sub-prod-landingzone"
  }
}