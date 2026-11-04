output "management_group_id" {
description = "The ID of the existing target Management Group."
value       = data.azurerm_management_group.elz.id
}

output "subscription_id" {
description = "The ID of the existing target Subscription."
value       = data.azurerm_subscription.target.id
}

output "resource_group_id" {
description = "The ID of the existing target Resource Group."
value       = data.azurerm_resource_group.target.id
}

output "initiative_id" {
description = "Resource ID of the newly created policy initiative."
value       = azurerm_policy_set_definition.elz_governance_initiative.id
}

output "mg_policy_assignment_id" {
description = "Resource ID of the Management Group policy assignment."
value       = azurerm_management_group_policy_assignment.mg_assignment.id
}