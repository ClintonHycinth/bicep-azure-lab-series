targetScope = 'resourceGroup'

@description('Environment name')
param environment string

@description('Azure region for deployment')
param location string

@description('Admin username for the VMs')
param adminUsername string

@description('SSH public key for VM access')
@secure()
param adminPublicKey string

@description('VM size')
param vmSize string = 'Standard_B1s'

@description('Virtual network name')
param vnetName string = 'vnet-lab-${environment}'

@description('Networking resource group name')
param networkingRgName string = 'rg-networking-dev'

@description('Storage account name for boot diagnostics')
param storageAccountName string

var lbName = 'lb-web-${environment}'
var lbPublicIpName = 'pip-lb-${environment}'

var vmConfigs = [
  {
    vmName: 'vm-lb1-${environment}'
    nicName: 'nic-lb1-${environment}'
    osDiskName: 'osdisk-lb1-${environment}'
    zone: '1'
  }
  {
    vmName: 'vm-lb2-${environment}'
    nicName: 'nic-lb2-${environment}'
    osDiskName: 'osdisk-lb2-${environment}'
    zone: '2'
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetName
  scope: resourceGroup(networkingRgName)
}

resource webSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnet
  name: 'snet-web'
}

resource lbPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: lbPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2022-07-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontend-config'
        properties: {
          publicIPAddress: {
            id: lbPublicIp.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backend-pool'
      }
    ]
    probes: [
      {
        name: 'health-probe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'lb-rule-http'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'frontend-config')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'backend-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'health-probe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 4
        }
      }
    ]
  }
}

resource nics 'Microsoft.Network/networkInterfaces@2022-07-01' = [
  for config in vmConfigs: {
    name: config.nicName
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
            loadBalancerBackendAddressPools: [
              {
                id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'backend-pool')
              }
            ]
          }
        }
      ]
    }
    dependsOn: [
      loadBalancer
    ]
  }
]

resource vms 'Microsoft.Compute/virtualMachines@2022-11-01' = [
  for (config, i) in vmConfigs: {
    name: config.vmName
    location: location
    zones: [
      config.zone
    ]
    properties: {
      hardwareProfile: {
        vmSize: vmSize
      }
      osProfile: {
        computerName: config.vmName
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
          name: config.osDiskName
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: nics[i].id
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
]

output loadBalancerName string = loadBalancer.name
output lbPublicIpAddress string = lbPublicIp.properties.ipAddress
output vm1Name string = vms[0].name
output vm2Name string = vms[1].name
