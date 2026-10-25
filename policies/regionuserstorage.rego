package azure.deployment

import rego.v1

# Approved enterprise regions
allowed_regions := {"westus", "eastus2", "centralus"}

# Forbidden generic usernames
forbidden_usernames := {"admin", "administrator", "root", "user"}

# Rule 1: Validate Region
deny contains msg if {
    params := object.get(input, "parameters", {})
    loc_obj := object.get(params, "location", {})
    loc := object.get(loc_obj, "defaultValue", "")
    
    not allowed_regions[loc]
    msg := sprintf("Compliance Violation: Region '%v' is not an approved deployment location.", [loc])
}

# Rule 2: Validate Username
deny contains msg if {
    params := object.get(input, "parameters", {})
    user_obj := object.get(params, "adminUsername", {})
    user := object.get(user_obj, "defaultValue", "")
    
    forbidden_usernames[user]
    msg := sprintf("Security Violation: Username '%v' is a forbidden default value.", [user])
}

# Rule 3: Validate Password Length (NIST 800-63B standard: 18+ chars)
deny contains msg if {
    params := object.get(input, "parameters", {})
    pwd_obj := object.get(params, "adminPassword", {})
    pwd := object.get(pwd_obj, "defaultValue", "")
    
    count(pwd) < 18
    msg := sprintf("Security Violation: Password length is %v characters. Minimum required is 18.", [count(pwd)])
}

# Rule 4: Validate Storage Encryption Best Practices
deny contains msg if {
    params := object.get(input, "parameters", {})
    storage_param := object.get(params, "enableInfrastructureEncryption", {})
    storage_enabled := object.get(storage_param, "defaultValue", false)
    
    storage_enabled == false
    msg := "Security Violation: Infrastructure-level storage encryption must be explicitly enabled."
}

# Approved cost-allocation tags required on resources
required_tags := {"CostCenter", "Environment", "Owner", "Project"}

# Rule 5: Validate Mandatory Cost Tags
deny contains msg if {
    tags_obj := object.get(object.get(input.parameters, "tags", {}), "defaultValue", {})
    missing := [tag | tag := required_tags[_]; not tags_obj[tag]]
    count(missing) > 0
    
    msg := sprintf("FinOps Violation: Missing mandatory cost-allocation tags: %v", [missing])
}