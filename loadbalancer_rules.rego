package azure.loadbalancer_rules

import rego.v1

# Helper: safely get resources from input
resources := object.get(input, "resources", [])

# Rule 1: Public Load Balancers and Public IPs must use explicit 'Static' allocation and cannot have missing allocation methods
deny contains msg if {
    some resource in resources
    resource.type == "Microsoft.Network/publicIPAddresses"
    
    # Safely retrieve properties object
    properties := object.get(resource, "properties", {})
    
    # Check if publicIPAllocationMethod is missing entirely
    not object.get(properties, "publicIPAllocationMethod", null)
    msg := sprintf("Load Balancer Compliance: Public IP resource '%v' is missing 'publicIPAllocationMethod'. It must be explicitly set to 'Static'.", [resource.name])
}

deny contains msg if {
    some resource in resources
    resource.type == "Microsoft.Network/publicIPAddresses"
    
    properties := object.get(resource, "properties", {})
    allocation_method := object.get(properties, "publicIPAllocationMethod", "")
    
    # Check if allocation method is set to something other than Static (e.g., Dynamic or empty)
    allocation_method != "Static"
    msg := sprintf("Load Balancer Compliance: Public IP resource '%v' must use static allocation, found '%v'.", [resource.name, allocation_method])
}

# Rule 2: Load Balancers and Public IPs must explicitly define a Standard SKU (cannot have missing SKU or Basic SKU)
deny contains msg if {
    some resource in resources
    lb_types := {"Microsoft.Network/loadBalancers", "Microsoft.Network/publicIPAddresses"}
    lb_types[resource.type]
    
    # Check if the sku block itself is missing
    not object.get(resource, "sku", null)
    msg := sprintf("Load Balancer Compliance: Resource '%v' of type '%v' is missing the 'sku' block. A 'Standard' SKU is required.", [resource.name, resource.type])
}

deny contains msg if {
    some resource in resources
    lb_types := {"Microsoft.Network/loadBalancers", "Microsoft.Network/publicIPAddresses"}
    lb_types[resource.type]
    
    sku := object.get(resource, "sku", {})
    sku_name := object.get(sku, "name", "")
    
    # Check if SKU name is missing or not Standard
    sku_name != "Standard"
    msg := sprintf("Load Balancer Compliance: Resource '%v' of type '%v' must use the 'Standard' SKU, found '%v'.", [resource.name, resource.type, sku_name])
}

# Rule 3: Internal/Private Load Balancers must have valid frontend configurations without missing references
deny contains msg if {
    some resource in resources
    resource.type == "Microsoft.Network/loadBalancers"
    
    properties := object.get(resource, "properties", {})
    frontend_configs := object.get(properties, "frontendIPConfigurations", [])
    
    # Ensure frontend configurations aren't completely empty/missing
    count(frontend_configs) == 0
    msg := sprintf("Load Balancer Compliance: Load balancer '%v' lacks any 'frontendIPConfigurations'.", [resource.name])
}

deny contains msg if {
    some resource in resources
    resource.type == "Microsoft.Network/loadBalancers"
    
    properties := object.get(resource, "properties", {})
    frontend_configs := object.get(properties, "frontendIPConfigurations", [])
    some frontend in frontend_configs
    
    frontend_props := object.get(frontend, "properties", {})
    has_public_ip := object.get(frontend_props, "publicIPAddress", null) != null
    has_subnet := object.get(frontend_props, "subnet", null) != null
    
    # An internal/public frontend config must define at least one valid routing target (subnet or public IP reference)
    not has_subnet
    not has_public_ip
    
    msg := sprintf("Load Balancer Compliance: Frontend IP configuration '%v' in load balancer '%v' has missing or null subnet/public IP associations.", [frontend.name, resource.name])
}