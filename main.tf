terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# 1. Default Provider
provider "azurerm" {
  features {}
}

# Variable receiving the billing scope securely from GitHub Action environment
variable "billing_scope_id" {
  type        = string
  description = "The Resource ID of your EA Enrollment Account or MCA Billing Profile"
  sensitive   = true
}

# 2. Management Group
resource "azurerm_management_group" "workload_mg" {
  name         = "mg-webapp-prod"
  display_name = "Production Web Applications"
}

# 3. Subscription (Fresh subscription creation request)
resource "azurerm_subscription" "workload_sub" {
  alias             = "sub-webapp-prod-eus-v2"
  subscription_name = "Production WebApp Subscription"
  billing_scope_id  = var.billing_scope_id
  workload          = "Production"
}

# 4. Association (Pulls the newly vended subscription into your MG)
resource "azurerm_management_group_subscription_association" "sub_assoc" {
  management_group_id = azurerm_management_group.workload_mg.id
  subscription_id     = "/subscriptions/${azurerm_subscription.workload_sub.subscription_id}"

  depends_on = [
    azurerm_subscription.workload_sub,
    azurerm_management_group.workload_mg
  ]
}

# 5. Aliased Provider (Points directly to the newly vended subscription)
provider "azurerm" {
  alias           = "new_sub"
  subscription_id = azurerm_subscription.workload_sub.subscription_id

  features {}
}

# 6. Resource Group (Created inside the new subscription)
resource "azurerm_resource_group" "workload_rg" {
  provider = azurerm.new_sub

  name     = "rg-webapp-prod-eus"
  location = "eastus"
  tags = {
    Environment = "Production"
    Workload    = "Core Web Application"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    azurerm_management_group_subscription_association.sub_assoc
  ]
}

# ==========================================================
# IMPORT EXISTING RESOURCES
# ==========================================================

# Adopt existing Management Group into state (prevents "already exists" error)
import {
  to = azurerm_management_group.workload_mg
  id = "/providers/Microsoft.Management/managementGroups/mg-webapp-prod"
}