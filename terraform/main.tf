terraform {
  required_version = ">= 1.8.0"

  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
  subscription_id = var.bootstrap_subscription_id
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias           = "new_sub"
  features        {}
  use_oidc        = true
  subscription_id = var.target_subscription_id != "" ? var.target_subscription_id : var.bootstrap_subscription_id
  resource_provider_registrations = "none"
}

variable "billing_account_name" {
  type      = string
  sensitive = true
}

variable "billing_profile_name" {
  type      = string
  sensitive = true
}

variable "invoice_section_name" {
  type      = string
  sensitive = true
}

variable "oidc_sp_object_id" {
  type      = string
  sensitive = true
}

variable "bootstrap_subscription_id" {
  type = string
}

variable "target_subscription_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "location" {
  type    = string
  default = "centralus"
}

data "azurerm_billing_mca_account_scope" "scope" {
  billing_account_name = var.billing_account_name
  billing_profile_name = var.billing_profile_name
  invoice_section_name = var.invoice_section_name
}

data "azurerm_management_group" "mg" {
  name = "mg-enterprise-landing-zones"
}

resource "azurerm_subscription" "landing_zone" {
  subscription_name = "landing-zone"
  billing_scope_id  = data.azurerm_billing_mca_account_scope.scope.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "time_sleep" "wait_sub" {
  create_duration = "120s"
  depends_on      = [azurerm_subscription.landing_zone]
}

resource "azurerm_management_group_subscription_association" "mg" {
  management_group_id = data.azurerm_management_group.mg.id
  subscription_id     = "/subscriptions/${azurerm_subscription.landing_zone.subscription_id}"
  depends_on          = [time_sleep.wait_sub]
}

resource "azurerm_role_assignment" "rbac" {
  scope                = "/subscriptions/${azurerm_subscription.landing_zone.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = var.oidc_sp_object_id
  depends_on           = [azurerm_management_group_subscription_association.mg]
}

resource "time_sleep" "wait_rbac" {
  create_duration = "120s"
  depends_on = [azurerm_role_assignment.rbac]
}

resource "azurerm_resource_group" "rg" {
  provider   = azurerm.new_sub
  name       = "rg-prod-app-cus"
  location   = var.location
  depends_on = [time_sleep.wait_rbac]
}

output "subscription_id" {
  value     = azurerm_subscription.landing_zone.subscription_id
  sensitive = true
}

output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}