// ============================================================
// MODULE: Alert Rule
// Purpose: Creates a log search alert
//
// FULLY REUSABLE:
// - Pass ANY KQL query via alertQuery parameter
// - Change threshold, frequency, severity per environment
// - Completely decoupled from what the query does
// - Just needs a query that returns a numeric column
// ============================================================

@description('Azure region for deployment')
param location string

@description('Name of the alert rule')
param alertRuleName string

@description('Human readable description')
param alertDescription string

@description('Full resource ID of Log Analytics workspace')
param logAnalyticsWorkspaceId string

@description('The KQL query to run. Must return a column named FailedCount (or match metricMeasureColumn)')
param alertQuery string
// ── HOW TO WRITE YOUR QUERY ────────────────────────────────
// Your query MUST end with a summarize that produces
// one row with one numeric column.
//
// The column name must match metricMeasureColumn below.
// Default column name expected: FailedCount
//
// GOOD EXAMPLE:
// AppRequests
// | where TimeGenerated > ago(1h)
// | where Success == false
// | summarize FailedCount = sum(ItemCount)
//
// BAD EXAMPLE (no summarize - returns many rows):
// AppRequests
// | where Success == false
//
// WHY: Azure needs ONE number to compare against threshold.
// The summarize produces that single number.

@description('Column name in your query that holds the count to compare')
param metricMeasureColumn string = 'FailedCount'
// Change this if your query uses a different column name
// e.g. 'ErrorCount' or 'SlowRequests'

@description('Resource ID of action group to notify')
param actionGroupId string

@description('Email subject line')
param emailSubject string

@description('Alert severity: 0=Critical 1=Error 2=Warning 3=Info 4=Verbose')
@minValue(0)
@maxValue(4)
param severity int = 2

@description('Fire when metric is GreaterThan threshold')
param operator string = 'GreaterThan'
// Options: GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual, Equal

@description('The threshold value to compare against')
param failureThreshold int = 50

@description('How to aggregate the metric value')
param timeAggregation string = 'Maximum'
// Options: Count, Average, Minimum, Maximum, Total
// Use Maximum when query returns one summarized row

@description('How often Azure runs the query. ISO 8601 format.')
param evaluationFrequency string = 'PT5M'
// PT5M=5min PT15M=15min PT1H=1hour PT6H=6hours P1D=1day

@description('Time window each evaluation covers. ISO 8601 format.')
param windowSize string = 'PT1H'
// Must be >= evaluationFrequency
// PT5M=5min PT15M=15min PT1H=1hour PT6H=6hours P1D=1day

@description('How many consecutive violations before firing')
param numberOfEvaluationPeriods int = 1
// 1 = fire immediately on first breach
// 3 = only fire if bad for 3 consecutive periods

@description('Auto resolve when condition clears')
param autoMitigate bool = true

@description('Tags to apply to the resource')
param tags object = {}

// ── RESOURCE ─────────────────────────────────────────────────

resource alertRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: alertRuleName
  location: location
  properties: {
    displayName: alertRuleName
    description: alertDescription
    enabled: true
    severity: severity
    evaluationFrequency: evaluationFrequency
    windowSize: windowSize

    scopes: [
      logAnalyticsWorkspaceId
    ]

    criteria: {
      allOf: [
        {
          query: alertQuery              // ← Your query passed in from outside
          metricMeasureColumn: metricMeasureColumn
          timeAggregation: timeAggregation
          operator: operator
          threshold: failureThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: numberOfEvaluationPeriods
            minFailingPeriodsToAlert: numberOfEvaluationPeriods
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroupId
      ]
      customProperties: {
        'Email.Subject': emailSubject
      }
    }

    autoMitigate: autoMitigate
    checkWorkspaceAlertsStorageConfigured: false
  }
  tags: tags
}

// ── OUTPUTS ──────────────────────────────────────────────────

output alertRuleId string = alertRule.id
output alertRuleName string = alertRule.name
