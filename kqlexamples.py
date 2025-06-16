# Save the 10 KQL examples as a .kql query set file (plain text with comments for context)

kql_queries = """
// 1. Filter and Summarize by Time Interval
AzureActivity
| where ActivityStatus == "Failed"
| summarize Count = count() by bin(TimeGenerated, 1h)
| order by TimeGenerated desc

// 2. Top N Values by Count
SecurityEvent
| where EventID == 4625
| summarize Attempts = count() by Account
| top 10 by Attempts desc

// 3. Join Two Tables
Heartbeat
| where TimeGenerated > ago(1h)
| join kind=inner (
    Perf
    | where ObjectName == "Processor" and CounterName == "% Processor Time"
) on Computer

// 4. Compute Moving Average
Perf
| where CounterName == "% Processor Time"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
| extend MovingAvg = series_fir(avg_CounterValue, dynamic([0.25, 0.5, 0.25]))

// 5. Pivot Table with evaluate pivot
SecurityEvent
| where EventID in (4624, 4625)
| summarize Count = count() by EventID, Account
| evaluate pivot(EventID, sum(Count))

// 6. Parse JSON Data
AppTraces
| where Message has "userLogin"
| extend data = parse_json(CustomDimensions)
| project UserId = tostring(data.UserId), Action = tostring(data.Action)

// 7. Calculate Time Difference Between Events
let logins = SecurityEvent | where EventID == 4624 | project Account, TimeGenerated;
let logoffs = SecurityEvent | where EventID == 4634 | project Account, TimeGenerated;
logins
| join kind=inner logoffs on Account
| extend SessionDuration = logoffs.TimeGenerated - logins.TimeGenerated

// 8. Detect Outliers Using Percentile
Perf
| where CounterName == "% Processor Time"
| summarize avgCPU = avg(CounterValue), p95 = percentile(CounterValue, 95) by Computer
| where avgCPU > p95

// 9. Generate a Time Series Chart
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize avg_CPU = avg(CounterValue) by bin(TimeGenerated, 15m), Computer
| render timechart

// 10. Detect Duplicate Events
AppEvents
| summarize EventCount = count() by Name, bin(TimeGenerated, 5m)
| where EventCount > 10
"""

# Save to file
kql_file_path = "/mnt/data/Intermediate_KQL_Examples.kql"
with open(kql_file_path, "w") as f:
    f.write(kql_queries)

kql_file_path