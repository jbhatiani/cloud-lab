#Configure Terraform Provider Requirements

terraform {
required_version = ">= 1.5.0"
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

#==============================================================================

#DATA SOURCES: Reference EXISTING Azure Scopes (Read-Only)

#Terraform will NOT attempt to create, modify, or delete these scopes.

#==============================================================================

#1. Existing Management Group

data "azurerm_management_group" "elz" {
name = var.management_group_id
}

#2. Existing Target Subscription

data "azurerm_subscription" "target" {
subscription_id = var.subscription_id
}

#3. Target Resource Group Scope (Managed Resource)

resource "azurerm_resource_group" "target" {
  name     = var.resource_group_name
  location = "centralus" # Matches the region where your RG currently lives
}

#==============================================================================

#NEW POLICY DEFINITIONS (Created at Management Group level)

#==============================================================================

#Custom Policy Definition 1: Require Environment Tag

resource "azurerm_policy_definition" "require_tag" {
name                = "require-environment-tag"
policy_type         = "Custom"
mode                = "Indexed"
display_name        = "Require Environment Tag on Resources"
description         = "Enforces the presence of an Environment tag on resources."
management_group_id = data.azurerm_management_group.elz.id

metadata = jsonencode({
category = "Governance"
version  = "1.0.0"
})

policy_rule = jsonencode({
if = {
field  = "[concat('tags[', parameters('tagName'), ']')]"
exists = "false"
}
then = {
effect = "[parameters('effect')]"
}
})

parameters = jsonencode({
tagName = {
type         = "String"
defaultValue = "Environment"
}
effect = {
type          = "String"
allowedValues = ["Audit", "Deny", "Disabled"]
defaultValue  = "Audit"
}
})
}

#Custom Policy Definition 2: Restrict Allowed Locations

resource "azurerm_policy_definition" "allowed_locations" {
name                = "allowed-locations-policy"
policy_type         = "Custom"
mode                = "Indexed"
display_name        = "Allowed Azure Locations"
description         = "Restricts resource deployments to specified Azure regions."
management_group_id = data.azurerm_management_group.elz.id

metadata = jsonencode({
category = "Governance"
version  = "1.0.0"
})

policy_rule = jsonencode({
if = {
field    = "location"
notIn    = "[parameters('allowedLocations')]"
}
then = {
effect = "Deny"
}
})

parameters = jsonencode({
allowedLocations = {
type         = "Array"
defaultValue = ["eastus", "eastus2"]
}
})
}

#==============================================================================

#NEW POLICY SET DEFINITION (Initiative)

#==============================================================================

resource "azurerm_policy_set_definition" "elz_governance_initiative" {
name                = "elz-governance-baseline"
policy_type         = "Custom"
display_name        = "Enterprise Landing Zones Governance Baseline"
description         = "Baseline governance initiative containing required compliance policies."
management_group_id = data.azurerm_management_group.elz.id

metadata = jsonencode({
category = "Governance"
version  = "1.0.0"
})

#Referencing Definition 1

policy_definition_reference {
policy_definition_id = azurerm_policy_definition.require_tag.id
parameter_values = jsonencode({
tagName = { value = "Environment" }
effect  = { value = "[parameters('tagEffect')]" }
})
}

#Referencing Definition 2

policy_definition_reference {
policy_definition_id = azurerm_policy_definition.allowed_locations.id
parameter_values = jsonencode({
allowedLocations = { value = "[parameters('allowedLocationsList')]" }
})
}

parameters = jsonencode({
tagEffect = {
type          = "String"
allowedValues = ["Audit", "Deny", "Disabled"]
defaultValue  = "Audit"
}
allowedLocationsList = {
type         = "Array"
defaultValue = ["eastus", "eastus2"]
}
})
}

#==============================================================================

#NEW POLICY ASSIGNMENTS AT EXISTING SCOPES

#==============================================================================

#1. Primary Assignment at Management Group Scope (Inherits to all child Subs & RGs)

resource "azurerm_management_group_policy_assignment" "mg_assignment" {
name                 = "elz-mg-gov-baseline"
display_name         = "ELZ Management Group Baseline Assignment"
description          = "Applies baseline governance initiative at existing Management Group scope."
management_group_id  = data.azurerm_management_group.elz.id
policy_definition_id = azurerm_policy_set_definition.elz_governance_initiative.id
location             = var.location

identity {
type = "SystemAssigned"
}

parameters = jsonencode({
tagEffect            = { value = var.policy_effect }
allowedLocationsList = { value = ["eastus", "eastus2"] }
})
}

#2. Targeted Assignment at Existing Subscription Scope (Optional Specific Enforcement)

resource "azurerm_subscription_policy_assignment" "sub_assignment" {
name                 = "elz-sub-location-check"
display_name         = "Subscription Location Restriction"
description          = "Applies direct location policy assignment to existing Subscription scope."
subscription_id      = data.azurerm_subscription.target.id
policy_definition_id = azurerm_policy_definition.allowed_locations.id

parameters = jsonencode({
allowedLocations = { value = ["eastus", "eastus2"] }
})
}

#3. Granular Assignment at Existing Resource Group Scope (Optional Specific Enforcement)

resource "azurerm_resource_group_policy_assignment" "rg_assignment" {
name                 = "elz-rg-tag-audit"
display_name         = "Resource Group Tag Requirement"
description          = "Applies direct tag policy assignment to existing Resource Group scope."
resource_group_id    = azurerm_resource_group.target.id
policy_definition_id = azurerm_policy_definition.require_tag.id

parameters = jsonencode({
tagName = { value = "Environment" }
effect  = { value = "Audit" }
})
}

# --- Complete Import Block Set for Pre-existing Azure Resources ---

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