variable "billing_scope_id" {
  type        = string
  description = "The MCA Billing Scope ID for provisioning new subscriptions."
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
  description = "The name of the target Resource Group inside the new subscription."
  default     = "rg-prod-landingzone"
}

variable "location" {
  type        = string
  description = "The Azure region for deploying resources."
  default     = "eastus"
}