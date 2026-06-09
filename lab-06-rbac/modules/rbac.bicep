targetScope = 'resourceGroup'

@description('Object ID of the user or service principal')
param principalId string

@description('Principal type')
param principalType string

@description('Role definition ID to assign')
param roleDefinitionId string

@description('Resource group name for guid generation')
param resourceGroupName string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroupName, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

output roleAssignmentId string = roleAssignment.id
