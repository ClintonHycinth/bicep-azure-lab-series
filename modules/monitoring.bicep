targetScope = 'resourceGroup'

@description('Environment name')
param environment string

@description('Azure region for deployment')
param location string

@description('Email address to receive alerts')
param alertEmailAddress string

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string = 'law-lab-${environment}'

@description('Log Analytics workspace resource group')
param logAnalyticsRgName string = 'rg-networking-dev'

@description('Compute resource group name')
param computeRgName string = 'rg-compute-${environment}'

var actionGroupName = 'ag-lab-${environment}'
var cpuAlertName = 'alert-cpu-${environment}'
var storageDeleteAlertName = 'alert-storage-delete-${environment}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsRgName)
}

resource vm1 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: 'vm-lb1-${environment}'
  scope: resourceGroup(computeRgName)
}

resource vm2 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: 'vm-lb2-${environment}'
  scope: resourceGroup(computeRgName)
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: 'lab-alerts'
    enabled: true
    emailReceivers: [
      {
        name: 'admin-email'
        emailAddress: alertEmailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: cpuAlertName
  location: 'global'
  properties: {
    description: 'Alert when CPU exceeds 80% for 5 minutes on lab VMs'
    severity: 2
    enabled: true
    scopes: [
      vm1.id
      vm2.id
    ]
    targetResourceRegion: location
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'cpu-condition'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'Percentage CPU'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

resource storageDeleteAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: storageDeleteAlertName
  location: location
  properties: {
    description: 'Alert when storage delete operations are detected'
    severity: 3
    enabled: true
    scopes: [
      logAnalyticsWorkspace.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'StorageBlobLogs | where OperationName == "DeleteBlob" | summarize count() by bin(TimeGenerated, 5m)'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

output actionGroupId string = actionGroup.id
output cpuAlertId string = cpuAlert.id
output storageDeleteAlertId string = storageDeleteAlert.id
