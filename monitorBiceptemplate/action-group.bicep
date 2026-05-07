// ============================================================
// MODULE: Action Group
// Purpose: Creates email notification contact list
// Reusable: Pass different emails per environment
// ============================================================

@description('Name of the action group')
param actionGroupName string

@description('Short name shown in emails - max 12 characters')
@maxLength(12)
param actionGroupShortName string

@description('List of email recipients')
param emailReceivers array
// Expected format:
// [
//   { name: 'Person1', emailAddress: 'person1@company.com' }
//   { name: 'Person2', emailAddress: 'person2@company.com' }
// ]

@description('Tags to apply to the resource')
param tags object = {}

// ── RESOURCE ─────────────────────────────────────────────────

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: [for email in emailReceivers: {
      name: email.name
      emailAddress: email.emailAddress
      useCommonAlertSchema: true
    }]
  }
  tags: tags
}

// ── OUTPUTS ──────────────────────────────────────────────────

output actionGroupId string = actionGroup.id
output actionGroupName string = actionGroup.name
