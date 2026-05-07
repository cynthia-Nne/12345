# getsink Monitoring - Modular Bicep

## Folder Structure

```
getsink-monitoring/
│
├── main.bicep                     ← WHERE YOU MAKE ALL CHANGES
│
├── modules/
│   ├── action-group.bicep         ← Never edit this
│   ├── workbook.bicep             ← Never edit this
│   └── alert-rule.bicep          ← Never edit this
│
└── environments/
    ├── prd.parameters.json        ← PRD settings
    ├── trn.parameters.json        ← TRN settings
    └── dev.parameters.json        ← DEV settings
```

---

## The Key Concept

The modules are dumb engines - they just render what you pass them.
All your queries and settings live in main.bicep and parameters files.
You never need to touch the modules.

---

## How to Add a New Workbook Panel

Open main.bicep, find the workbookQueries array, add a new block:

```bicep
{
  name: 'my-new-panel'
  title: 'My New Panel Title'
  visualization: 'table'        // table, timechart, barchart, piechart
  size: 1                       // 0=large 1=medium 2=small 3=tiny
  query: '''
    AppExceptions
    | where TimeGenerated {TimeRange}
    | where AppRoleName in (${appNamesKql})
    | summarize Count = sum(ItemCount) by ExceptionType
    | top 10 by Count desc
  '''
}
```

Save and redeploy - new panel appears in workbook immediately.

---

## How to Change the Alert Query

Open main.bicep, find the alertQuery variable, replace the KQL:

```bicep
var alertQuery = '''
  AppRequests
  | where TimeGenerated > ago(1h)
  | where AppRoleName in (${appNamesKql})
  | where ResultCode == "500"
  | summarize FailedCount = sum(ItemCount)
'''
```

Rules:
- Always end with summarize producing ONE number
- Column must be named FailedCount (or update metricMeasureColumn)
- Use ago(1h) not {TimeRange} in alert queries

---

## How to Add a Second Alert

Open main.bicep, copy the alertRuleFailures module block, uncomment and modify:

```bicep
module alertRuleSlowRequests 'modules/alert-rule.bicep' = {
  name: 'deploy-alert-slow-${environment}'
  params: {
    alertRuleName: 'alrt-getsink-slow-requests-${environment}'
    alertDescription: 'P95 response time exceeded 5000ms'
    alertQuery: '''
      AppRequests
      | where TimeGenerated > ago(1h)
      | where AppRoleName in (${appNamesKql})
      | summarize FailedCount = percentile(DurationMs, 95)
    '''
    failureThreshold: 5000
    // ... other params
  }
}
```

---

## How to Deploy

### Step 1 - Update email addresses
Edit environments/prd.parameters.json
Replace member1@yourcompany.com with real emails

### Step 2 - Login to Azure
```bash
az login
az account set --subscription "P166nk"
```

### Step 3 - Deploy your environment

PRD:
```bash
az deployment group create \
  --resource-group rggetsink \
  --template-file main.bicep \
  --parameters @environments/prd.parameters.json
```

TRN:
```bash
az deployment group create \
  --resource-group rggetsink \
  --template-file main.bicep \
  --parameters @environments/trn.parameters.json
```

DEV:
```bash
az deployment group create \
  --resource-group rggetsink \
  --template-file main.bicep \
  --parameters @environments/dev.parameters.json
```

### Via Azure Cloud Shell (no CLI install)
1. Go to portal.azure.com
2. Click >_ icon top right
3. Upload all files
4. Run the command above

---

## Environment Differences

| Setting          | PRD        | TRN      | DEV      |
|------------------|------------|----------|----------|
| Threshold        | 50         | 1        | 1        |
| Check frequency  | 5 minutes  | 1 hour   | 1 hour   |
| Severity         | 2-Warning  | 3-Info   | 3-Info   |
| Email recipients | 3          | 1        | 1        |

---

## Timing Reference (ISO 8601)

| Code  | Meaning    |
|-------|------------|
| PT5M  | 5 minutes  |
| PT15M | 15 minutes |
| PT1H  | 1 hour     |
| PT6H  | 6 hours    |
| P1D   | 1 day      |

---

## Safe to Redeploy

Bicep is idempotent - safe to run multiple times.
Only changes what is different. Nothing gets deleted or recreated.
