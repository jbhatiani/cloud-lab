targetScope = 'tenant'

param subscriptionName string = 'sub-prod-landingzone'
param billingScope string
param targetManagementGroupId string = 'mg-enterprise-landing-zones'

resource subAlias 'Microsoft.Subscription/aliases@2021-10-01' = {
  name: subscriptionName
  properties: {
    workload: 'Production'
    displayName: subscriptionName
    billingScope: billingScope
    additionalProperties: {
      managementGroupId: targetManagementGroupId
    }
  }
}

output subscriptionId string = subAlias.properties.subscriptionId