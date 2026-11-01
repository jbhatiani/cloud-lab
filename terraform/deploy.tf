terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "399e8de6-c59b-4cd5-80fe-41eef17c3aad"
}

# ==============================================================================
# VARIABLES & DATA SOURCES
# ==============================================================================

variable "mg_id" {
  type    = string
  default = "mg-enterprise-landing-zones"
}

variable "subscription_id" {
  type    = string
  default = "399e8de6-c59b-4cd5-80fe-41eef17c3aad"
}

# Target existing Management Group
data "azurerm_management_group" "enterprise_lz" {
  name = var.mg_id
}

# Explicit Azure Scope Resource ID for Management Group Assignments
locals {
  mg_scope = "/providers/Microsoft.Management/managementGroups/${var.mg_id}"
}

# ==============================================================================
# SUBSCRIPTION ASSOCIATION
# ==============================================================================

resource "azurerm_management_group_subscription_association" "prod_lz_assoc" {
  management_group_id = data.azurerm_management_group.enterprise_lz.id
  subscription_id     = "/subscriptions/${var.subscription_id}"
}

# ==============================================================================
# CUSTOM POLICY DEFINITIONS (Scoped to Management Group)
# ==============================================================================

resource "azurerm_policy_definition" "allowed_locations" {
  name                = "enforce-allowed-locations"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Enforce Approved Deployment Locations"
  description         = "Enforces deployment in approved regions (westus, eastus2, centralus)."
  management_group_id = data.azurerm_management_group.enterprise_lz.name

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = "[parameters('allowedLocations')]"
      }
    }
    then = {
      effect = "deny"
    }
  })

  parameters = jsonencode({
    allowedLocations = {
      type         = "Array"
      defaultValue = ["westus", "eastus2", "centralus"]
    }
  })
}

resource "azurerm_policy_definition" "required_tags" {
  name                = "enforce-required-tags"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Enforce Mandatory Cost Allocation Tags"
  description         = "Enforces mandatory tags: CostCenter, Environment, Owner, Project."
  management_group_id = data.azurerm_management_group.enterprise_lz.name

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['CostCenter']", exists = "false" },
        { field = "tags['Environment']", exists = "false" },
        { field = "tags['Owner']", exists = "false" },
        { field = "tags['Project']", exists = "false" }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_policy_definition" "lb_public_ip_sku" {
  name                = "enforce-lb-publicip-standard-sku"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Enforce Standard SKU and Static Allocation"
  description         = "Requires Public IPs to use Static allocation and Standard SKU for Load Balancers/Public IPs."
  management_group_id = data.azurerm_management_group.enterprise_lz.name

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "type", equals = "Microsoft.Network/publicIPAddresses" },
        { field = "type", equals = "Microsoft.Network/loadBalancers" }
      ]
      anyOf = [
        { field = "Microsoft.Network/publicIPAddresses/publicIPAllocationMethod", notEquals = "Static" },
        { field = "Microsoft.Network/publicIPAddresses/sku.name", notEquals = "Standard" },
        { field = "Microsoft.Network/loadBalancers/sku.name", notEquals = "Standard" }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_policy_definition" "forbidden_admin_usernames" {
  name                = "enforce-forbidden-usernames"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Disallow Forbidden Admin Usernames"
  description         = "Disallows standard administrative usernames (admin, root, administrator, system)."
  management_group_id = data.azurerm_management_group.enterprise_lz.name

  policy_rule = jsonencode({
    if = {
      field = "Microsoft.Compute/virtualMachines/osProfile.adminUsername"
      in    = ["admin", "root", "administrator", "system"]
    }
    then = {
      effect = "deny"
    }
  })
}

# ==============================================================================
# POLICY ASSIGNMENTS AT MANAGEMENT GROUP SCOPE
# ==============================================================================

resource "azurerm_management_group_policy_assignment" "assign_allowed_locations" {
  name                 = "assign-allowed-locs"
  display_name         = "Enterprise Region Governance"
  management_group_id  = local.mg_scope
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
}

resource "azurerm_management_group_policy_assignment" "assign_required_tags" {
  name                 = "assign-required-tags"
  display_name         = "Enterprise Mandatory Tagging"
  management_group_id  = local.mg_scope
  policy_definition_id = azurerm_policy_definition.required_tags.id
}

resource "azurerm_management_group_policy_assignment" "assign_lb_sku" {
  name                 = "assign-lb-sku"
  display_name         = "Enterprise Load Balancer & Public IP SKU"
  management_group_id  = local.mg_scope
  policy_definition_id = azurerm_policy_definition.lb_public_ip_sku.id
}

resource "azurerm_management_group_policy_assignment" "assign_forbidden_usernames" {
  name                 = "assign-forbidden-users"
  display_name         = "Enterprise Forbidden Usernames"
  management_group_id  = local.mg_scope
  policy_definition_id = azurerm_policy_definition.forbidden_admin_usernames.id
}

resource "azurerm_management_group_policy_assignment" "builtin_region_governance" {
  name                 = "enforce-approved-regions"
  display_name         = "Enterprise Region Policy (BuiltIn)"
  management_group_id  = local.mg_scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  description          = "Enforces allowed deployment regions matching enterprise declarations."

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["westus", "eastus2", "centralus"]
    }
  })
}