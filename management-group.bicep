targetScope = 'tenant'

@description('The unique identifier (name) for the Management Group')
param managementGroupId string = 'mg-enterprise-landing-zones'

@description('The friendly display name for the Management Group')
param managementGroupDisplayName string = 'Enterprise Landing Zones'

// Automatically creates the management group below the root tenant level
resource mg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroupId
  properties: {
    displayName: managementGroupDisplayName
  }
}

// Outputs the ID so subsequent steps or future pipeline jobs can reference it
output managementGroupId string = managementGroup.id