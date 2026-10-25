package azure.deployment

import rego.v1
import data.azure.loadbalancer_rules
import data.azure.infrastructure_rules
import data.azure.security_rules

deny contains msg if {
    some msg in infrastructure_rules.deny
}

deny contains msg if {
    some msg in security_rules.deny
}

deny contains msg if {
    msg := loadbalancer_rules.deny[_]
}