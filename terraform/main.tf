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

# ==============================================================================
# IMPORT BLOCKS (Safely adopts pre-existing resources created via scripts)
# ==============================================================================

import {
  to = azurerm_management_group.elz
  id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"
}

import {
  to = azurerm_subscription.landing_zone
  id = "/subscriptions/399e8de6-c59b-4cd5-80fe-41eef17c3aad"
}

import {
  to = azurerm_resource_group.rg
  id = "/subscriptions/399e8de6-c59b-4cd5-80fe-41eef17c3aad/resourceGroups/rg-webapp-prod-cus"
}

# ==============================================================================
# INFRASTRUCTURE RESOURCES
# ==============================================================================

# 1. Management Group Creation / Management
resource "azurerm_management_group" "elz" {
  name         = "mg-enterprise-landing-zones"
  display_name = "Enterprise Landing Zones"
}

# 2. Subscription Provisioning
resource "azurerm_subscription" "landing_zone" {
  alias             = "landing-zone-alias"
  subscription_name = "landing zone"
  workload          = "Production"
}

# 3. Resource Group Creation
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 4. Grant GitHub OIDC App Contributor Permissions on the Subscription
resource "azurerm_role_assignment" "oidc_app_permissions" {
  scope                = azurerm_subscription.landing_zone.id
  role_definition_name = "Contributor"
  principal_id         = var.github_service_principal_object_id
}