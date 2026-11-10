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
  description = "Object ID of the GitHub OIDC Enterprise App / Service Principal in Entra ID."
  default     = "" 
}