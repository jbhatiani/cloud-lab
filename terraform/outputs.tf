output "management_group_id" {
  description = "The ID of the target Management Group."
  value       = data.azurerm_management_group.elz.id
}

output "subscription_id" {
  description = "The ID of the Subscription."
  value       = data.azurerm_subscription.landing_zone.id
}

output "resource_group_id" {
  description = "The ID of the provisioned Resource Group."
  value       = azurerm_resource_group.rg.id
}