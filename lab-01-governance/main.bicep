targetScope = 'subscription'

@description('Environment name')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Owner of the resources')
param owner string

@description('Cost centre for billing')
param costCentre string

@description('Azure region for deployment')
param location string = 'southafricanorth'

var networkingRgName = 'rg-networking-${environment}'
var computeRgName = 'rg-compute-${environment}'

var commonTags = {
  environment: environment
  owner: owner
  costCentre: costCentre
}

resource networkingRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkingRgName
  location: location
  tags: commonTags
}

resource computeRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: computeRgName
  location: location
  tags: commonTags
}

output networkingRgName string = networkingRg.name
output computeRgName string = computeRg.name
