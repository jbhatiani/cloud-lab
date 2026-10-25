package azure.declaration

import rego.v1

allowed_regions := {"westus", "eastus2", "centralus"}

forbidden_usernames := {"admin", "root", "administrator", "system"}