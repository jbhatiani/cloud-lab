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

# 3. Subscription (Adopts or references the existing vended subscription alias)
resource "azurerm_subscription" "workload_sub" {
  alias             = "sub-webapp-prod-cus-v3"
  subscription_name = "Production WebApp Subscription"
  billing_scope_id  = var.billing_scope_id
  workload          = "Production"

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

# 4. Association (Pulls the subscription into your MG)
resource "azurerm_management_group_subscription_association" "sub_assoc" {
  management_group_id = azurerm_management_group.workload_mg.id
  subscription_id     = "/subscriptions/${azurerm_subscription.workload_sub.subscription_id}"

  depends_on = [
    azurerm_subscription.workload_sub,
    azurerm_management_group.workload_mg
  ]
}

# 4b. Handle GitHub Actions CI/CD context where az account clear wipes the login cache
resource "null_resource" "refresh_az_cli" {
  triggers = {
    subscription_id = azurerm_subscription.workload_sub.subscription_id
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Ensuring Azure CLI is logged in and accounting for runner cleanup..."
      az account set --subscription ${azurerm_subscription.workload_sub.subscription_id} || \
      (az login --identity --allow-no-subscriptions && az account set --subscription ${azurerm_subscription.workload_sub.subscription_id})
    EOT
  }

  depends_on = [
    azurerm_management_group_subscription_association.sub_assoc
  ]
}

# 5. Aliased Provider (Points directly to the subscription ID)
provider "azurerm" {
  alias           = "new_sub"
  subscription_id = azurerm_subscription.workload_sub.subscription_id

  features {}
}

# 6. Resource Group (Created inside the new subscription)
resource "azurerm_resource_group" "workload_rg" {
  provider = azurerm.new_sub

  name     = "rg-webapp-prod-cus"
  location = "centralus"
  tags = {
    Environment = "Production"
    Workload    = "Core Web Application"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    null_resource.refresh_az_cli
  ]
}

# ==========================================================
# IMPORT EXISTING RESOURCES (MANDATORY FOR STATE SYNC)
# ==========================================================

# Adopt existing Management Group into state
import {
  to = azurerm_management_group.workload_mg
  id = "/providers/Microsoft.Management/managementGroups/mg-webapp-prod"
}

# Adopt existing Subscription Alias into state (Prevents the "already exists" error)
import {
  to = azurerm_subscription.workload_sub
  id = "/providers/Microsoft.Subscription/aliases/sub-webapp-prod-cus-v3"
}