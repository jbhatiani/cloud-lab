variable "subscription_id" {
  type        = string
  description = "The Target Subscription ID for the landing zone."
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
  description = "Name of the target Resource Group."
  default     = "rg-webapp-prod-cus"
}

variable "location" {
  type        = string
  description = "Azure region for resources."
  default     = "centralus"
}

variable "github_service_principal_object_id" {
  type        = string
  description = "Object ID of the Enterprise Application Service Principal in Entra ID."
  sensitive   = true
  default     = "" 
}