# ==============================================================================
# 1. PROVIDER & DATA SOURCES
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
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

# Target Management Group Scope
data "azurerm_management_group" "target" {
  name = "mg-enterprise-landing-zones"
}

# ==============================================================================
# 2. TARGET RESOURCE GROUP
# ==============================================================================

resource "azurerm_resource_group" "target" {
  name     = "rg-webapp-prod-cus"
  location = "centralus"

  tags = {
    Environment = "Production"
    Project     = "LandingZone"
    Owner       = "SysEng"
    CostCenter  = "IT-101"
  }
}

# ==============================================================================
# 3. AZURE POLICY DEFINITIONS (Rego Policy Translations)
# ==============================================================================

# Custom Policy 1: Mandatory Environment Tag
resource "azurerm_policy_definition" "require_tag" {
  name                = "require-environment-tag"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Require Environment Tag"
  description         = "Enforces the mandatory Environment tag on all resources."
  management_group_id = data.azurerm_management_group.target.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "tags['Environment']",
    "exists": "false"
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Custom Policy 2: Allowed Locations
resource "azurerm_policy_definition" "allowed_locations" {
  name                = "allowed-locations-policy"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Allowed Azure Locations"
  description         = "Restricts resource deployments to approved Azure regions."
  management_group_id = data.azurerm_management_group.target.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "location",
    "notIn": ["westus", "eastus2", "centralus"]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Custom Policy 3: Forbidden Admin Usernames
resource "azurerm_policy_definition" "forbidden_usernames" {
  name                = "forbidden-admin-usernames"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Audit Forbidden Admin Usernames"
  description         = "Audits virtual machines using common forbidden administrative usernames."
  management_group_id = data.azurerm_management_group.target.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "field": "Microsoft.Compute/virtualMachines/osProfile.adminUsername",
        "in": ["admin", "root", "administrator", "system"]
      }
    ]
  },
  "then": {
    "effect": "audit"
  }
}
POLICY_RULE
}

# Custom Policy 4: Minimum Admin Password Length
resource "azurerm_policy_definition" "min_password_length" {
  name                = "min-admin-password-length"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Enforce Minimum Admin Password Length (18 chars)"
  description         = "Ensures VM admin passwords meet the 18-character minimum length requirement."
  management_group_id = data.azurerm_management_group.target.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "value": "[string(length(parameters('adminPassword')))]",
        "less": 18
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Custom Policy 5: Infrastructure Encryption
resource "azurerm_policy_definition" "infrastructure_encryption" {
  name                = "require-infrastructure-encryption"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Require Infrastructure Encryption for Storage"
  description         = "Ensures storage accounts enable infrastructure double-encryption."
  management_group_id = data.azurerm_management_group.target.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Storage/storageAccounts"
      },
      {
        "field": "Microsoft.Storage/storageAccounts/requireInfrastructureEncryption",
        "notEquals": "true"
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Custom Policy 6: Standard SKU & Static Public IP
resource "azurerm_policy_definition" "network_standard_sku" {
  name                = "require-standard-sku-public-ip"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Require Standard SKU and Static Allocation for Public IPs"
  description         = "Enforces Standard SKU and Static allocation for Public IP resources."
  management_group_id = data.azurerm_management_group.target.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Network/publicIPAddresses"
      },
      {
        "anyOf": [
          {
            "field": "Microsoft.Network/publicIPAddresses/publicIPAllocationMethod",
            "notEquals": "Static"
          },
          {
            "field": "Microsoft.Network/publicIPAddresses/sku.name",
            "notEquals": "Standard"
          }
        ]
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# ==============================================================================
# 4. AZURE POLICY SET DEFINITION (GOVERNANCE INITIATIVE)
# ==============================================================================

resource "azurerm_policy_set_definition" "elz_governance_initiative" {
  name                = "elz-governance-baseline"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "ELZ Governance Baseline Initiative"
  description         = "Bundles core security, networking, FinOps, and location guardrails across landing zones."
  management_group_id = data.azurerm_management_group.target.id

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag.id
    reference_id         = "require-tag-ref"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.allowed_locations.id
    reference_id         = "allowed-locations-ref"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.forbidden_usernames.id
    reference_id         = "forbidden-usernames-ref"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.min_password_length.id
    reference_id         = "min-password-length-ref"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.infrastructure_encryption.id
    reference_id         = "infra-encryption-ref"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.network_standard_sku.id
    reference_id         = "network-standard-sku-ref"
  }
}

# ==============================================================================
# 5. POLICY ASSIGNMENTS
# ==============================================================================

# Management Group Initiative Assignment
resource "azurerm_management_group_policy_assignment" "mg_assignment" {
  name                 = "elz-mg-gov-baseline"
  management_group_id  = data.azurerm_management_group.target.id
  policy_definition_id = azurerm_policy_set_definition.elz_governance_initiative.id
  display_name         = "ELZ Management Group Baseline Assignment"
  description          = "Assigns the baseline governance initiative across the Management Group hierarchy."
}

# Subscription Level Location Assignment
resource "azurerm_subscription_policy_assignment" "sub_assignment" {
  name                 = "elz-sub-location-check"
  subscription_id      = "/subscriptions/399e8de6-c59b-4cd5-80fe-41eef17c3aad"
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  display_name         = "Subscription Location Restriction Assignment"
}

# Resource Group Scope Tag Assignment
resource "azurerm_resource_group_policy_assignment" "rg_assignment" {
  name                 = "elz-rg-tag-audit"
  resource_group_id    = azurerm_resource_group.target.id
  policy_definition_id = azurerm_policy_definition.require_tag.id
  display_name         = "Resource Group Scope Tag Audit Assignment"
}

# ==============================================================================
# 6. DECLARATIVE STATE IMPORT BLOCKS
# ==============================================================================

import {
  to = azurerm_resource_group.target
  id = "/subscriptions/399e8de6-c59b-4cd5-80fe-41eef17c3aad/resourceGroups/rg-webapp-prod-cus"
}

import {
  to = azurerm_policy_definition.require_tag
  id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones/providers/Microsoft.Authorization/policyDefinitions/require-environment-tag"
}

import {
  to = azurerm_policy_definition.allowed_locations
  id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones/providers/Microsoft.Authorization/policyDefinitions/allowed-locations-policy"
}

import {
  to = azurerm_policy_set_definition.elz_governance_initiative
  id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones/providers/Microsoft.Authorization/policySetDefinitions/elz-governance-baseline"
}

import {
  to = azurerm_management_group_policy_assignment.mg_assignment
  id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones/providers/Microsoft.Authorization/policyAssignments/elz-mg-gov-baseline"
}

import {
  to = azurerm_subscription_policy_assignment.sub_assignment
  id = "/subscriptions/399e8de6-c59b-4cd5-80fe-41eef17c3aad/providers/Microsoft.Authorization/policyAssignments/elz-sub-location-check"
}

import {
  to = azurerm_resource_group_policy_assignment.rg_assignment
  id = "/subscriptions/399e8de6-c59b-4cd5-80fe-41eef17c3aad/resourceGroups/rg-webapp-prod-cus/providers/Microsoft.Authorization/policyAssignments/elz-rg-tag-audit"
}