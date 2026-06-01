// ============================================================
// MAIN: getsink Monitoring Deployment
//
// THIS IS WHERE YOU CONTROL EVERYTHING:
// - All workbook queries are defined here
// - Alert query is defined here
// - All settings are here
//
// The modules (workbook, alert-rule, action-group) are just
// engines that render whatever you pass them.
// You never need to edit the modules.
//
// TO ADD A NEW WORKBOOK QUERY: add an item to workbookQueries
// TO CHANGE ALERT QUERY: edit the alertQuery variable
// TO ADD A NEW ALERT: call the alert-rule module again
// ============================================================

// ── PARAMETERS ───────────────────────────────────────────────

@description('Environment: prd, trn, dev')
param environment string

@description('Azure region')
param location string = 'uksouth'

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string

@description('Resource group of the Log Analytics workspace')
param logAnalyticsResourceGroup string

@description('getsink app names to monitor')
param appNames array

@description('Email recipients for alerts')
param alertEmailAddresses array

@description('Failure threshold for alert')
param failureThreshold int = 50

@description('How often alert checks. ISO 8601.')
param evaluationFrequency string = 'PT5M'

@description('Time window per evaluation. ISO 8601.')
param windowSize string = 'PT1H'

@description('Alert severity 0-4')
@minValue(0)
@maxValue(4)
param alertSeverity int = 2

@description('Auto resolve alert')
param autoMitigate bool = true

@description('Key Vault names, resource groups, and their Log Analytics workspaces to monitor')
param keyVaults array = [
  { name: 'kv-name-1', resourceGroup: 'rg-one', logAnalyticsWorkspaceName: 'law-one', logAnalyticsResourceGroup: 'rg-law-one' }
  { name: 'kv-name-2',              resourceGroup: 'rg-two', logAnalyticsWorkspaceName: 'law-two', logAnalyticsResourceGroup: 'rg-law-two' }
  { name: 'kv-name-3',              resourceGroup: 'rg-three', logAnalyticsWorkspaceName: 'law-three', logAnalyticsResourceGroup: 'rg-law-three' }
]

@description('Days before expiry to alert')
param daysBeforeExpiry int = 30

// ── VARIABLES ────────────────────────────────────────────────

var env = toUpper(environment)

var workbookDisplayName = 'getsink Application Monitoring - ${env}'
var actionGroupName     = 'ag-getsink-monitoring-${environment}'
var actionGroupShortName = 'getsink${env}'
var alertRuleName       = 'alrt-getsink-failed-requests-${environment}'
var emailSubject        = 'getsink-Failed-Request-${env}'

var tags = {
  environment: environment
  application: 'getsink'
  purpose: 'monitoring'
  managedBy: 'bicep'
}

var logAnalyticsWorkspaceId = resourceId(
  logAnalyticsResourceGroup,
  'Microsoft.OperationalInsights/workspaces',
  logAnalyticsWorkspaceName
)

// Build KQL app name filter from the array
// Turns ['app1','app2'] into "app1", "app2"
var appNamesKql = join(map(appNames, name => '"${name}"'), ', ')

// ============================================================
// ── WORKBOOK QUERIES ─────────────────────────────────────────
// ============================================================
// ADD, REMOVE OR CHANGE QUERIES HERE FREELY
// Each object = one panel in the dashboard
//
// Fields:
//   name           = unique ID, no spaces
//   title          = heading shown on panel
//   query          = your KQL (use {TimeRange} for time filter)
//   visualization  = table / timechart / barchart / piechart
//   size           = 0=large 1=medium 2=small 3=tiny
// ============================================================

var workbookQueries = [

  // ── PANEL 1: Request Volume by App ─────────────────────────
  // Shows total requests per app - traffic overview
  {
    name: 'request-volume'
    title: 'Request Volume by App'
    visualization: 'table'
    size: 1
    query: '''
      AppRequests
      | where TimeGenerated {TimeRange}
      | where AppRoleName in (${appNamesKql})
      | summarize Requests = sum(ItemCount) by AppRoleName
      | order by Requests desc
    '''
  }

  // ── PANEL 2: Health Summary ─────────────────────────────────
  // One row: total, failed, failure rate, P95 response time
  {
    name: 'health-summary'
    title: 'Health Summary - Total | Failed | Failure Rate % | P95 Response Time ms'
    visualization: 'table'
    size: 1
    query: '''
      AppRequests
      | where TimeGenerated {TimeRange}
      | where AppRoleName in (${appNamesKql})
      | summarize
          TotalRequests   = sum(ItemCount),
          FailedRequests  = sumif(ItemCount, Success == false),
          FailureRatePct  = round(100.0 * sumif(ItemCount, Success == false) / max_of(sum(ItemCount), 1), 2),
          P95DurationMs   = round(percentile(DurationMs, 95), 0)
    '''
  }

  // ── PANEL 3: Requests vs Failures Timeline ──────────────────
  // Time chart - good for spotting when problems happen
  {
    name: 'requests-timeline'
    title: 'Requests vs Failures Over Time (5 minute buckets)'
    visualization: 'timechart'
    size: 0
    query: '''
      AppRequests
      | where TimeGenerated {TimeRange}
      | where AppRoleName in (${appNamesKql})
      | summarize
          Requests       = sum(ItemCount),
          FailedRequests = sumif(ItemCount, Success == false)
          by bin(TimeGenerated, 5m)
      | render timechart
    '''
  }

  // ── PANEL 4: Top Failed Endpoints ──────────────────────────
  // Bar chart - which pages/APIs fail most
  {
    name: 'top-failed-endpoints'
    title: 'Top 10 Failed Endpoints'
    visualization: 'barchart'
    size: 1
    query: '''
      AppRequests
      | where TimeGenerated {TimeRange}
      | where AppRoleName in (${appNamesKql})
      | where Success == false
      | summarize FailedCount = sum(ItemCount) by Name, ResultCode
      | top 10 by FailedCount desc
    '''
  }

  // ── PANEL 5: Dependency Health ──────────────────────────────
  // Database and external service calls
  {
    name: 'dependency-health'
    title: 'Dependency Health - Database and External Services'
    visualization: 'table'
    size: 1
    query: '''
      AppDependencies
      | where TimeGenerated {TimeRange}
      | where AppRoleName in (${appNamesKql})
      | summarize
          FailedDependencies = sumif(ItemCount, Success == false),
          P95DurationMs      = round(percentile(DurationMs, 95), 0)
          by DependencyType, Target
      | top 10 by FailedDependencies desc
    '''
  }

  // ── ADD MORE PANELS HERE ────────────────────────────────────
  // Just copy any block above and modify it
  // Example - Exceptions panel:
  // {
  //   name: 'exceptions'
  //   title: 'Top Exceptions'
  //   visualization: 'table'
  //   size: 1
  //   query: '''
  //     AppExceptions
  //     | where TimeGenerated {TimeRange}
  //     | where AppRoleName in (${appNamesKql})
  //     | summarize Count = sum(ItemCount) by ExceptionType, OuterMessage
  //     | top 10 by Count desc
  //   '''
  // }
]

// ============================================================
// ── ALERT QUERY ──────────────────────────────────────────────
// ============================================================
// THIS IS YOUR ALERT QUERY
// Change this to monitor anything you want
//
// RULES:
// 1. Must end with summarize producing ONE numeric column
// 2. Column name must match metricMeasureColumn in alert module
//    (default is FailedCount - change both if you rename)
// 3. Use ago(1h) not {TimeRange} - alert runs on fixed windows
//
// EXAMPLES OF OTHER QUERIES YOU COULD USE:
//
// -- Alert on slow requests (P95 > 5 seconds):
// AppRequests
// | where TimeGenerated > ago(1h)
// | where AppRoleName in (${appNamesKql})
// | summarize FailedCount = percentile(DurationMs, 95)
//
// -- Alert on exceptions:
// AppExceptions
// | where TimeGenerated > ago(1h)
// | where AppRoleName in (${appNamesKql})
// | summarize FailedCount = sum(ItemCount)
//
// -- Alert on specific error code:
// AppRequests
// | where TimeGenerated > ago(1h)
// | where AppRoleName in (${appNamesKql})
// | where ResultCode == "500"
// | summarize FailedCount = sum(ItemCount)
// ============================================================

var alertQuery = '''
  AppRequests
  | where TimeGenerated > ago(1h)
  | where AppRoleName in (${appNamesKql})
  | where Success == false
  | summarize FailedCount = sum(ItemCount)
'''

// ── MODULE 1: ACTION GROUP ────────────────────────────────────

module actionGroup 'action-group.bicep' = {
  name: 'deploy-action-group-${environment}'
  params: {
    actionGroupName: actionGroupName
    actionGroupShortName: actionGroupShortName
    emailReceivers: alertEmailAddresses
    tags: tags
  }
}

// ── MODULE 2: WORKBOOK ────────────────────────────────────────

module workbook 'workbook.bicep' = {
  name: 'deploy-workbook-${environment}'
  params: {
    location: location
    workbookDisplayName: workbookDisplayName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    workbookQueries: workbookQueries   // ← passing all queries in
    tags: tags
  }
}

// ── MODULE 3: ALERT RULE (Failed Requests) ────────────────────
// This is your main failure alert
// To add a SECOND alert (e.g. slow requests), copy this block
// and change the name, query and settings

module alertRuleFailures 'alert-rule.bicep' = {
  name: 'deploy-alert-failures-${environment}'
  params: {
    location: location
    alertRuleName: alertRuleName
    alertDescription: 'Triggers when getsink apps exceed ${failureThreshold} failures in evaluation window'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    alertQuery: alertQuery             // ← passing query in from above
    metricMeasureColumn: 'FailedCount' // ← must match column in query
    actionGroupId: actionGroup.outputs.actionGroupId
    emailSubject: emailSubject
    severity: alertSeverity
    operator: 'GreaterThan'
    failureThreshold: failureThreshold
    timeAggregation: 'Maximum'
    evaluationFrequency: evaluationFrequency
    windowSize: windowSize
    autoMitigate: autoMitigate
    tags: tags
  }
  dependsOn: [ actionGroup ]
}

// ── EXAMPLE: SECOND ALERT (uncomment to add slow request alert)
// module alertRuleSlowRequests 'modules/alert-rule.bicep' = {
//   name: 'deploy-alert-slow-${environment}'
//   params: {
//     location: location
//     alertRuleName: 'alrt-getsink-slow-requests-${environment}'
//     alertDescription: 'Triggers when P95 response time exceeds 5000ms'
//     logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
//     alertQuery: '''
//       AppRequests
//       | where TimeGenerated > ago(1h)
//       | where AppRoleName in (${appNamesKql})
//       | summarize FailedCount = percentile(DurationMs, 95)
//     '''
//     metricMeasureColumn: 'FailedCount'
//     actionGroupId: actionGroup.outputs.actionGroupId
//     emailSubject: 'getsink-Slow-Requests-${env}'
//     severity: 2
//     operator: 'GreaterThan'
//     failureThreshold: 5000
//     timeAggregation: 'Maximum'
//     evaluationFrequency: evaluationFrequency
//     windowSize: windowSize
//     autoMitigate: autoMitigate
//     tags: tags
//   }
//   dependsOn: [ actionGroup ]
// }

// -- MODULE 4: ALERT RULES (Key Vault Key Expiry — one per vault/workspace) ----
module kvExpiryAlerts 'alert-rule.bicep' = [for kv in keyVaults: {
  name: 'deploy-alert-kv-expiry-${kv.name}-${environment}'
  params: {
    location: location
    alertRuleName: 'alrt-keyvault-expiring-keys-${kv.name}-${environment}'
    alertDescription: 'Triggers when Key Vault ${kv.name} has keys expiring within ${daysBeforeExpiry} days'
    logAnalyticsWorkspaceId: resourceId(kv.logAnalyticsResourceGroup, 'Microsoft.OperationalInsights/workspaces', kv.logAnalyticsWorkspaceName)
    alertQuery: 'AzureDiagnostics\n| where ResourceType == "VAULTS"\n| where ResourceId has "${kv.name}"\n| where isnotempty(properties_attributes_exp_t)\n| extend ExpiryDate = todatetime(properties_attributes_exp_t)\n| where ExpiryDate between (now() .. now() + ${daysBeforeExpiry}d)\n| summarize FailedCount = count() by bin(TimeGenerated, 1h)'
    metricMeasureColumn: 'FailedCount'
    actionGroupId: actionGroup.outputs.actionGroupId
    emailSubject: 'Key Vault Key Expiry Alert - ${kv.name} - ${env}'
    severity: alertSeverity
    operator: 'GreaterThan'
    failureThreshold: 0
    windowSize: windowSize
    evaluationFrequency: evaluationFrequency
    autoMitigate: autoMitigate
    tags: tags
  }
  dependsOn: [ actionGroup ]
}]

// ── OUTPUTS ──────────────────────────────────────────────────

output deploymentSummary object = {
  environment: environment
  workbook: workbook.outputs.workbookDisplayName
  actionGroup: actionGroup.outputs.actionGroupName
  alertRule: alertRuleFailures.outputs.alertRuleName
  failureThreshold: failureThreshold
  evaluationFrequency: evaluationFrequency
  panelCount: length(workbookQueries)
  emailCount: length(alertEmailAddresses)
  appCount: length(appNames)
}

output kvExpiryAlertIds array = [for i in range(0, length(keyVaults)): kvExpiryAlerts[i].outputs.alertRuleId]
