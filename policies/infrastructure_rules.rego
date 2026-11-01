package azure.infrastructure_rules

import rego.v1
import data.azure.declaration
import data.azure.helpers

deny contains msg if {
    params := object.get(input, "parameters", {})
    loc := helpers.get_param_default(params, "location", "")
    not declaration.allowed_regions[loc]
    msg := sprintf("Compliance Violation: Region '%v' is not an approved deployment location.", [loc])
}

deny contains msg if {
    params := object.get(input, "parameters", {})
    tags := helpers.get_param_default(params, "tags", {})
    required_tags := {"CostCenter", "Environment", "Owner", "Project"}
    some req_tag in required_tags
    not tags[req_tag]
    msg := sprintf("FinOps Violation: Missing mandatory cost-allocation tag '%v'.", [req_tag])
}