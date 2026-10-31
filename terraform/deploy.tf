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
}

# 1. Target your existing Enterprise Landing Zones Management Group
data "azurerm_management_group" "enterprise_lz" {
  name = "mg-enterprise-landing-zones"
}

# 2. Assign Region Governance (Matches constraints in declaration.rego)
resource "azurerm_management_group_policy_assignment" "region_governance" {
  name                 = "enforce-approved-regions"
  management_group_id  = data.azurerm_management_group.enterprise_lz.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  description          = "Enforces allowed deployment regions matching enterprise declarations."
  display_name         = "Enterprise Region Policy"

  parameters = jsonencode({
    "listOfAllowedLocations": {
      "value": ["westus", "eastus2", "centralus"]
    }
  })
}

# 3. Assign Mandatory Tagging Governance (Matches rules in infrastructure_rules.rego)
resource "azurerm_management_group_policy_assignment" "tagging_governance" {
  name                 = "enforce-mandatory-tags"
  management_group_id  = data.azurerm_management_group.enterprise_lz.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-46ce-a736-aeb78fe0d484"
  description          = "Enforces mandatory cost-allocation tags across all child subscriptions."
  display_name         = "Enterprise Mandatory Tagging"

  parameters = jsonencode({
    "tagName": { "value": "CostCenter" }
  })
}