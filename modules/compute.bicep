targetScope = 'resourceGroup'

@description('Environment name')
param environment string

@description('Azure region for deployment')
param location string

@description('Admin username for the VM')
param adminUsername string

@description('SSH public key for VM access')
@secure()
param adminPublicKey string

@description('VM size')
param vmSize string = 'Standard_B1s'

@description('Availability zone')
param availabilityZone string = '1'

@description('Virtual network name')
param vnetName string = 'vnet-lab-${environment}'

@description('Networking resource group name')
param networkingRgName string = 'rg-networking-dev'

@description('Storage account name for boot diagnostics')
param storageAccountName string

var vmName = 'vm-web-${environment}'
var nicName = 'nic-web-${environment}'
var publicIpName = 'pip-web-${environment}'
var osDiskName = 'osdisk-web-${environment}'

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    availabilityZone
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetName
  scope: resourceGroup(networkingRgName)
}

resource webSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnet
  name: 'snet-web'
}

resource nic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: webSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: vmName
  location: location
  zones: [
    availabilityZone
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'https://${storageAccountName}.blob.core.windows.net'
      }
    }
  }
}

output vmName string = vm.name
output vmId string = vm.id
output publicIpAddress string = publicIp.properties.ipAddress
output nicId string = nic.id
