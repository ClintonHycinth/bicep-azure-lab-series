targetScope = 'resourceGroup'

@description('Environment name')
param environment string

@description('Azure region for deployment')
param location string

@description('VNet address space')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Web subnet address prefix')
param webSubnetPrefix string = '10.0.1.0/24'

@description('App subnet address prefix')
param appSubnetPrefix string = '10.0.2.0/24'

@description('Data subnet address prefix')
param dataSubnetPrefix string = '10.0.3.0/24'

var vnetName = 'vnet-lab-${environment}'
var nsgWebName = 'nsg-web-${environment}'
var nsgAppName = 'nsg-app-${environment}'
var nsgDataName = 'nsg-data-${environment}'

resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsgWebName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-Inbound'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Allow-HTTPS-Inbound'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

resource nsgApp 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsgAppName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Web-Inbound'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.0.1.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8080'
        }
      }
      {
        name: 'Deny-Internet-Inbound'
        properties: {
          priority: 200
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource nsgData 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsgDataName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-App-Inbound'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.0.2.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
      {
        name: 'Deny-Internet-Inbound'
        properties: {
          priority: 200
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-web'
        properties: {
          addressPrefix: webSubnetPrefix
          networkSecurityGroup: {
            id: nsgWeb.id
          }
        }
      }
      {
        name: 'snet-app'
        properties: {
          addressPrefix: appSubnetPrefix
          networkSecurityGroup: {
            id: nsgApp.id
          }
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: dataSubnetPrefix
          networkSecurityGroup: {
            id: nsgData.id
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output webSubnetId string = vnet.properties.subnets[0].id
output appSubnetId string = vnet.properties.subnets[1].id
output dataSubnetId string = vnet.properties.subnets[2].id
