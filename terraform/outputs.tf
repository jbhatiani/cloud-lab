output "subscription_id" {
  description = "The GUID of the newly created subscription."
  value       = azurerm_subscription.new_landing_zone.subscription_id
}

output "resource_group_name" {
  description = "The name of the deployed resource group."
  value       = azurerm_resource_group.rg.name
}