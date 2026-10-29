terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# 1. Default Provider (Authenticates via the App User logged in through GitHub Actions)
provider "azurerm" {
  features {}
}

# Variable receiving the billing scope securely from the GitHub Action environment
variable "billing_scope_id" {
  type        = string
  description = "The Resource ID of your EA Enrollment Account or MCA Billing Profile"
  sensitive   = true
}

# 2. Management Group (Organizes your hierarchy)
resource "azurerm_management_group" "workload_mg" {
  name         = "mg-webapp-prod"
  display_name = "Production Web Applications"
}

# 3. Subscription (Vends the new subscription under your billing scope)
resource "azurerm_subscription" "workload_sub" {
  alias             = "sub-webapp-prod-eus"
  subscription_name = "Production WebApp Subscription"
  billing_scope_id  = var.billing_scope_id
  workload          = "Production"
}

# 4. Association with explicit dependency enforcement
resource "azurerm_management_group_subscription_association" "sub_assoc" {
  management_group_id = azurerm_management_group.workload_mg.id
  subscription_id     = "/subscriptions/${azurerm_subscription.workload_sub.subscription_id}"

  # Forces Terraform to wait until the subscription is fully vended before running the move
  depends_on = [
    azurerm_subscription.workload_sub,
    azurerm_management_group.workload_mg
  ]
}

# 5. Aliased Provider (Points specifically to the newly vended subscription)
provider "azurerm" {
  alias           = "new_sub"
  subscription_id = azurerm_subscription.workload_sub.subscription_id

  features {}
}

# 6. Resource Group (Created inside the new subscription using the aliased provider)
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

# Automatically adopt the existing Management Group into Terraform state
import {
  to = azurerm_management_group.workload_mg
  id = "/providers/Microsoft.Management/managementGroups/mg-webapp-prod"
}

# Automatically adopt the existing Subscription alias into Terraform state
import {
  to = azurerm_subscription.workload_sub
  id = "/providers/Microsoft.Subscription/aliases/sub-webapp-prod-eus"
}

# Triggering fresh run