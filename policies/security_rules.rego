package azure.security_rules

import rego.v1
import data.azure.declaration
import data.azure.helpers

# 1. Check for forbidden usernames
deny contains msg if {
    params := object.get(input, "parameters", {})
    username := helpers.get_param_default(params, "adminUsername", "")
    declaration.forbidden_usernames[username]
    msg := sprintf("Security Violation: Username '%v' is forbidden.", [username])
}

# 2. Explicitly catch missing, null, or empty admin passwords first
deny contains msg if {
    params := object.get(input, "parameters", {})
    # Safely retrieve password, defaulting to an empty string if missing
    password := helpers.get_param_default(params, "adminPassword", "")

    # Check if the password is missing, null, or empty string
    password == ""
    msg := "Security Violation: Admin password is required and cannot be missing or null."
}

# 3. Check minimum length requirements (only runs if password is provided)
deny contains msg if {
    params := object.get(input, "parameters", {})
    password := helpers.get_param_default(params, "adminPassword", "")

    # Ensure it's not empty first so count() doesn't misbehave
    count(password) < 18
    msg := "Security Violation: Admin password does not meet the minimum requirement of 18 characters."
}

# 4. Check infrastructure encryption configuration
deny contains msg if {
    params := object.get(input, "parameters", {})
    enc := helpers.get_param_default(params, "enableInfrastructureEncryption", true)
    enc == false
    msg := "Security Violation: Infrastructure encryption must be enabled."
}
