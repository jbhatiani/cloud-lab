# ==============================================================================
# PROVIDER CONFIGURATION
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

# ==============================================================================
# 1. ALLOWED REGIONS POLICY
# ==============================================================================

resource "azurerm_policy_definition" "allowed_locations" {
  name         = "policy-allowed-locations"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Allowed Azure Locations"
  description  = "Restricts resource deployment to specified approved regions."

  management_group_id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"

  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        {
          "field"  = "location",
          "notIn"  = ["westus", "eastus2", "centralus"]
        },
        {
          "field"     = "location",
          "notEquals" = "global"
        }
      ]
    },
    "then" = {
      "effect" = "deny"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "assign_allowed_locations" {
  name                 = "assign-allowed-locations"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  display_name         = "Enterprise Landing Zones - Allowed Regions Assignment"
}

# ==============================================================================
# 2. FORBIDDEN USERNAMES POLICY
# ==============================================================================

resource "azurerm_policy_definition" "forbidden_usernames" {
  name         = "policy-forbidden-usernames"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny Forbidden Admin Usernames"
  description  = "Blocks Virtual Machines from using default or high-risk administrator usernames."

  management_group_id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"

  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        {
          "field" = "type",
          "in"    = [
            "Microsoft.Compute/virtualMachines",
            "Microsoft.Compute/virtualMachineScaleSets"
          ]
        },
        {
          "anyOf" = [
            {
              "field" = "Microsoft.Compute/virtualMachines/osProfile.adminUsername",
              "in"    = ["admin", "root", "administrator", "system"]
            },
            {
              "field" = "Microsoft.Compute/virtualMachineScaleSets/osProfile.adminUsername",
              "in"    = ["admin", "root", "administrator", "system"]
            }
          ]
        }
      ]
    },
    "then" = {
      "effect" = "deny"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "assign_forbidden_usernames" {
  name                 = "assign-forbidden-usernames"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"
  policy_definition_id = azurerm_policy_definition.forbidden_usernames.id
  display_name         = "Enterprise Landing Zones - Forbidden Usernames Assignment"
}

# ==============================================================================
# 3. MANDATORY TAGS POLICY
# ==============================================================================

resource "azurerm_policy_definition" "mandatory_tags" {
  name         = "policy-mandatory-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Enforce Mandatory Cost-Allocation Tags"
  description  = "Denies resource creation if CostCenter, Environment, Owner, or Project tags are missing."

  management_group_id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"

  policy_rule = jsonencode({
    "if" = {
      "anyOf" = [
        {
          "field"  = "tags['CostCenter']",
          "exists" = "false"
        },
        {
          "field"  = "tags['Environment']",
          "exists" = "false"
        },
        {
          "field"  = "tags['Owner']",
          "exists" = "false"
        },
        {
          "field"  = "tags['Project']",
          "exists" = "false"
        }
      ]
    },
    "then" = {
      "effect" = "deny"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "assign_mandatory_tags" {
  name                 = "assign-mandatory-tags"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"
  policy_definition_id = azurerm_policy_definition.mandatory_tags.id
  display_name         = "Enterprise Landing Zones - Mandatory Tags Assignment"
}

# ==============================================================================
# 4. PUBLIC IP STATIC ALLOCATION POLICY
# ==============================================================================

resource "azurerm_policy_definition" "public_ip_allocation" {
  name         = "policy-public-ip-allocation"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Enforce Static Public IP Allocation"
  description  = "Denies Public IP addresses that do not use an explicit 'Static' allocation method."

  management_group_id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"

  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        {
          "field"  = "type",
          "equals" = "Microsoft.Network/publicIPAddresses"
        },
        {
          "field"     = "Microsoft.Network/publicIPAddresses/publicIPAllocationMethod",
          "notEquals" = "Static"
        }
      ]
    },
    "then" = {
      "effect" = "deny"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "assign_public_ip_allocation" {
  name                 = "assign-public-ip-allocation"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"
  policy_definition_id = azurerm_policy_definition.public_ip_allocation.id
  display_name         = "Enterprise Landing Zones - Static Public IP Assignment"
}

# ==============================================================================
# 5. STANDARD SKU ENFORCEMENT POLICY
# ==============================================================================

resource "azurerm_policy_definition" "standard_sku" {
  name         = "policy-standard-sku"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Enforce Standard SKU for Load Balancers and Public IPs"
  description  = "Denies Load Balancers and Public IP addresses configured with Basic or missing SKUs."

  management_group_id = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"

  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        {
          "field" = "type",
          "in"    = [
            "Microsoft.Network/loadBalancers",
            "Microsoft.Network/publicIPAddresses"
          ]
        },
        {
          "field"     = "sku.name",
          "notEquals" = "Standard"
        }
      ]
    },
    "then" = {
      "effect" = "deny"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "assign_standard_sku" {
  name                 = "assign-standard-sku"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/mg-enterprise-landing-zones"
  policy_definition_id = azurerm_policy_definition.standard_sku.id
  display_name         = "Enterprise Landing Zones - Standard SKU Assignment"
}
