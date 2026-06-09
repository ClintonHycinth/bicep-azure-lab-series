targetScope = 'subscription'

@description('Environment name')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Object ID of the user or service principal to assign roles to')
param principalId string

@description('Principal type')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param principalType string = 'User'

var networkingRgName = 'rg-networking-${environment}'
var computeRgName = 'rg-compute-${environment}'

var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

module networkingRbac 'modules/rbac.bicep' = {
  name: 'networking-rbac'
  scope: resourceGroup(networkingRgName)
  params: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: readerRoleId
    resourceGroupName: networkingRgName
  }
}

module computeRbac 'modules/rbac.bicep' = {
  name: 'compute-rbac'
  scope: resourceGroup(computeRgName)
  params: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: contributorRoleId
    resourceGroupName: computeRgName
  }
}

output networkingRoleAssignmentId string = networkingRbac.outputs.roleAssignmentId
output computeRoleAssignmentId string = computeRbac.outputs.roleAssignmentId
