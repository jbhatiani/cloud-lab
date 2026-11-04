output "initiative_id" {
  description = "Resource ID of the newly created policy initiative."
  value       = azurerm_policy_set_definition.elz_governance_initiative.id
}

output "mg_policy_assignment_id" {
  description = "Resource ID of the Management Group policy assignment."
  value       = azurerm_management_group_policy_assignment.mg_assignment.id
}