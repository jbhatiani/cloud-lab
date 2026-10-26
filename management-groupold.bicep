targetScope = 'tenant'

@description('The unique identifier (name) for the Management Group')
<<<<<<< HEAD
param managementGroupId string = 'mg-enterprise-landing-zones-v3'
=======
param managementGroupId string = 'mg-enterprise-landing-zones-v2'
>>>>>>> 66453a429260850d0306b8a0f160bcef5ccc1422

@description('The friendly display name for the Management Group')
param managementGroupDisplayName string = 'Enterprise Landing Zones v3'

// Automatically creates the management group below the root tenant level
resource mg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroupId
  properties: {
    displayName: managementGroupDisplayName
  }
}

// Outputs the ID so subsequent steps or future pipeline jobs can reference it
output managementGroupId string = mg.id
