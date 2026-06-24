targetScope = 'subscription'

@description('Environment name')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Azure region for deployment')
param location string = 'southafricanorth'

@description('Admin username for VMs')
param adminUsername string

@description('SSH public key for VM access')
@secure()
param adminPublicKey string

@description('VM size')
param vmSize string = 'Standard_B1s'

@description('Storage account name')
param storageAccountName string

@description('Email address for alerts')
param alertEmailAddress string

@description('Principal ID for RBAC assignments')
param principalId string

var networkingRgName = 'rg-networking-${environment}'
var computeRgName = 'rg-compute-${environment}'
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource networkingRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkingRgName
  location: location
  tags: {
    environment: environment
    owner: adminUsername
    costCentre: 'xenrex-cloud-team'
  }
}

resource computeRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: computeRgName
  location: location
  tags: {
    environment: environment
    owner: adminUsername
    costCentre: 'xenrex-cloud-team'
  }
}

module networking 'modules/networking.bicep' = {
  name: 'networking'
  scope: resourceGroup(networkingRgName)
  params: {
    environment: environment
    location: location
  }
  dependsOn: [
    networkingRg
  ]
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  scope: resourceGroup(networkingRgName)
  params: {
    environment: environment
    location: location
    storageAccountName: storageAccountName
  }
  dependsOn: [
    networkingRg
  ]
}

module compute 'modules/compute.bicep' = {
  name: 'compute'
  scope: resourceGroup(computeRgName)
  params: {
    environment: environment
    location: location
    adminUsername: adminUsername
    adminPublicKey: adminPublicKey
    vmSize: vmSize
    storageAccountName: storageAccountName
    networkingRgName: networkingRgName
  }
  dependsOn: [
    computeRg
    networking
    storage
  ]
}

module loadbalancer 'modules/loadbalancer.bicep' = {
  name: 'loadbalancer'
  scope: resourceGroup(computeRgName)
  params: {
    environment: environment
    location: location
    adminUsername: adminUsername
    adminPublicKey: adminPublicKey
    vmSize: vmSize
    storageAccountName: storageAccountName
    networkingRgName: networkingRgName
  }
  dependsOn: [
    computeRg
    networking
    storage
  ]
}

module networkingRbac 'modules/rbac.bicep' = {
  name: 'networking-rbac'
  scope: resourceGroup(networkingRgName)
  params: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: readerRoleId
    resourceGroupName: networkingRgName
  }
  dependsOn: [
    networkingRg
  ]
}

module computeRbac 'modules/rbac.bicep' = {
  name: 'compute-rbac'
  scope: resourceGroup(computeRgName)
  params: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: contributorRoleId
    resourceGroupName: computeRgName
  }
  dependsOn: [
    computeRg
  ]
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup(networkingRgName)
  params: {
    environment: environment
    location: location
    alertEmailAddress: alertEmailAddress
    logAnalyticsRgName: networkingRgName
    computeRgName: computeRgName
  }
  dependsOn: [
    networkingRg
    storage
    loadbalancer
  ]
}

output networkingRgName string = networkingRg.name
output computeRgName string = computeRg.name
output vnetName string = networking.outputs.vnetName
output storageAccountName string = storage.outputs.storageAccountName
output lbPublicIpAddress string = loadbalancer.outputs.lbPublicIpAddress
