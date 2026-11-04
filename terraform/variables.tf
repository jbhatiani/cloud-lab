variable "management_group_id" {
type        = string
description = "The ID of the existing target Management Group."
default     = "mg-enterprise-landing-zones"
}

variable "subscription_id" {
type        = string
description = "The ID of the existing target Subscription."
default     = "399e8de6-c59b-4cd5-80fe-41eef17c3aad"
}

variable "resource_group_name" {
type        = string
description = "The name of the existing target Resource Group."
default     = "rg-enterprise-governance"
}

variable "location" {
type        = string
description = "Primary Azure region for policy identity metadata."
default     = "eastus"
}

variable "policy_effect" {
type        = string
description = "Enforcement effect for policy assignment (Audit, Deny, or Disabled)."
default     = "Audit"

validation {
condition     = contains(["Audit", "Deny", "Disabled"], var.policy_effect)
error_message = "Allowed values for policy_effect are Audit, Deny, or Disabled."
}
}