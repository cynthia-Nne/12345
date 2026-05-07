// ============================================================
// MODULE: Azure Monitor Workbook
// Purpose: Creates monitoring dashboard
//
// FULLY REUSABLE:
// - Pass ANY queries you want via the workbookQueries parameter
// - Each query is an object you define in main.bicep
// - Add/remove/change queries without touching this module
// - This module just renders whatever you pass in
// ============================================================

@description('Azure region for deployment')
param location string

@description('Display name shown in Azure portal')
param workbookDisplayName string

@description('Full resource ID of Log Analytics workspace')
param logAnalyticsWorkspaceId string

@description('List of query panels to show in the workbook')
param workbookQueries array
// ── HOW TO DEFINE A QUERY ──────────────────────────────────
// Each item becomes one panel in the workbook
// Define these in main.bicep and pass them in
//
// {
//   name: 'unique-panel-name'            <- Internal ID, no spaces
//   title: 'Title shown on panel'        <- Panel heading
//   query: '''
//     AppRequests
//     | where Success == false
//   '''                                  <- Your KQL (multiline ok)
//   visualization: 'table'               <- Display type:
//                                           'table'
//                                           'timechart'
//                                           'barchart'
//                                           'piechart'
//   size: 1                              <- Panel size:
//                                           0 = large
//                                           1 = medium
//                                           2 = small
//                                           3 = tiny
// }

@description('Tags to apply to the resource')
param tags object = {}

// ── VARIABLES ────────────────────────────────────────────────

var workbookUniqueName = guid(workbookDisplayName, resourceGroup().id)

// Title panel - always first
var titleItem = {
  type: 1
  content: {
    json: '# ${workbookDisplayName}\n---'
  }
  name: 'title'
}

// Time range picker - always second
var timeRangeItem = {
  type: 9
  content: {
    version: 'KqlParameterItem/1.0'
    parameters: [
      {
        id: 'timeRange'
        version: 'KqlParameterItem/1.0'
        name: 'TimeRange'
        type: 4
        isRequired: true
        value: { durationMs: 86400000 }
        typeSettings: {
          selectableValues: [
            { durationMs: 3600000 }
            { durationMs: 14400000 }
            { durationMs: 43200000 }
            { durationMs: 86400000 }
            { durationMs: 172800000 }
            { durationMs: 604800000 }
          ]
          allowCustom: true
        }
        label: 'Time Range'
      }
    ]
    style: 'pills'
    queryType: 0
    resourceType: 'microsoft.operationalinsights/workspaces'
  }
  name: 'time-range-picker'
}

// Convert each query object into a workbook panel
// This loops over whatever queries you passed in
var queryItems = [for q in workbookQueries: {
  type: 3
  content: {
    version: 'KqlItem/1.0'
    query: q.query
    size: q.size
    title: q.title
    timeContextFromParameter: 'TimeRange'
    queryType: 0
    resourceType: 'microsoft.operationalinsights/workspaces'
    visualization: q.visualization
  }
  name: q.name
}]

// Combine title + time picker + all your queries
var workbookContent = {
  version: 'Notebook/1.0'
  items: concat([titleItem, timeRangeItem], queryItems)
  styleSettings: {}
  '$schema': 'https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json'
}

// ── RESOURCE ─────────────────────────────────────────────────

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: workbookUniqueName
  location: location
  kind: 'shared'
  properties: {
    displayName: workbookDisplayName
    serializedData: string(workbookContent)
    version: '1.0'
    category: 'workbook'
    sourceId: logAnalyticsWorkspaceId
  }
  tags: tags
}

// ── OUTPUTS ──────────────────────────────────────────────────

output workbookId string = workbook.id
output workbookDisplayName string = workbook.properties.displayName
