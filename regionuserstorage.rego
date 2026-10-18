package azure.deployment

import rego.v1

# Approved enterprise regions
allowed_regions := {"westus", "eastus2", "centralus"}

# Forbidden generic usernames
forbidden_usernames := {"admin", "administrator", "root", "user"}

# Rule 1: Validate Region
deny contains msg if {
    loc := input.parameters.location.defaultValue
    not allowed_regions[loc]
    msg := sprintf("Compliance Violation: Region '%v' is not an approved deployment location.", [loc])
}

# Rule 2: Validate Username
deny contains msg if {
    user := input.parameters.adminUsername.defaultValue
    forbidden_usernames[user]
    msg := sprintf("Security Violation: Username '%v' is a forbidden default value.", [user])
}

# Rule 3: Validate Password Length (NIST 800-63B standard: 18+ chars)
deny contains msg if {
    pwd := input.parameters.adminPassword.defaultValue
    count(pwd) < 18
    msg := sprintf("Security Violation: Password length is %v characters. Minimum required is 18.", [count(pwd)])
}

# Rule 4: Validate Storage Encryption Best Practices
deny contains msg if {
    # Safely extract the encryption property using object.get() 
    # If any parent object or the target key is missing, it defaults safely to false
    params := object.get(input, "parameters", {})
    storage_param := object.get(params, "enableInfrastructureEncryption", {})
    storage_enabled := object.get(storage_param, "defaultValue", false)
    
    # Trigger a violation if encryption is disabled or missing
    storage_enabled == false
    
    msg := "Security Violation: Infrastructure-level storage encryption must be explicitly enabled."
}

# Approved cost-allocation tags required on resources
required_tags := {"CostCenter", "Environment", "Owner", "Project"}

# Rule 5: Validate Mandatory Cost Tags
deny contains msg if {
    # Safely extract tags from parameters (adjust path based on your ARM/Bicep schema)
    tags := object.get(object.get(input.parameters, "tags", {}), "defaultValue", {})
    
    # Find any required tags that are missing
    missing := [tag | tag := required_tags[_]; not tags[tag]]
    count(missing) > 0
    
    msg := sprintf("FinOps Violation: Missing mandatory cost-allocation tags: %v", [missing])
}