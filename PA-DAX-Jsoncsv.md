
# Power Automate Walkthrough: Export Power BI Data to SharePoint as JSON and CSV

This guide walks you through setting up a Power Automate flow that connects to a Power BI dataset and exports the data into both a JSON and CSV file format in SharePoint.

---

## Prerequisites

- Access to **Power BI Service** (with a published dataset)
- Access to **Power Automate**
- Access to a **SharePoint site** with permissions to create files
- The **"Execute Queries against a dataset"** permission in Power BI

---

## Step 1: Create a New Power Automate Flow

1. Navigate to [Power Automate](https://flow.microsoft.com).
2. Click on **Create** > **Automated cloud flow** or **Instant cloud flow** (e.g., manually triggered).
3. Name your flow (e.g., `Export_PBI_to_SharePoint`).

---

## Step 2: Add a Trigger

Use a suitable trigger, such as:

- **Manual trigger** (for testing)
- **Recurrence trigger** (for scheduled export)

Example:
```plaintext
Trigger: Recurrence
Interval: 1
Frequency: Day
```

---

## Step 3: Add "Run a query against a dataset" Action

1. Click **New Step**
2. Search for `Power BI`
3. Select **Run a query against a dataset**

### Fill in the details:

- **Workspace**: Select your Power BI workspace
- **Dataset**: Choose the dataset to query
- **Query**: Write a DAX query using `EVALUATE` or use `SummarizeColumns`, e.g.:
  ```DAX
  EVALUATE
  TOPN(100, Sales)
  ```

> â ï¸ The result is returned as a JSON object with a `tables` array.

---

## Step 4: Parse JSON (Optional but Recommended)

1. Add **"Parse JSON"** action
2. Content: `@body('Run_a_query_against_a_dataset')?['results']?['tables'][0]?['rows']`
3. Use the **Generate from sample** option to paste in a sample record from Power BI.

---

## Step 5: Create JSON File in SharePoint

1. Add **"Create file"** action from **SharePoint**
2. Configure:
   - **Site Address**: Your SharePoint site
   - **Folder Path**: Target document library or folder
   - **File Name**: `data.json`
   - **File Content**: Use:
     ```expression
     json(string(body('Run_a_query_against_a_dataset')?['results']?['tables'][0]?['rows']))
     ```

> ð If you parsed the JSON earlier, use the output of that instead.

---

## Step 6: Create CSV File in SharePoint

Power Automate doesnât natively convert JSON to CSV, so:

### Option 1: Use a "Select" + "Join" Trick

1. **Add "Select"** action:
   - From: Parsed JSON array
   - Map the fields you want:
     ```json
     {
       "Date": item()?['Date'],
       "Sales": item()?['Sales']
     }
     ```

2. **Add "Join"** action:
   - From: Output of Select
   - Join with `\n` to simulate CSV rows

3. **Compose CSV Header + Rows**:
   - Add a **"Compose"** action:
     ```plaintext
     Date,Sales
     @{outputs('Join')}
     ```

4. **Create CSV File** in SharePoint (same as JSON step), using the Compose output as content.

---

## Step 7: Save and Test the Flow

- Save your flow
- Run the trigger
- Verify the JSON and CSV files are created in SharePoint

---

## Troubleshooting Tips

- Ensure dataset permissions are correctly set
- Use **Run history** to debug data formatting or errors
- Use **Compose** actions to inspect data at each step

---

## Optional Enhancements

- Add email notification upon success
- Automatically timestamp filenames (e.g., `data_2025-07-10.csv`)
- Filter the dataset dynamically with parameters

---

## Sample Output Structure

### JSON Sample
```json
[
  {
    "Date": "2025-07-01",
    "Sales": 12000
  },
  {
    "Date": "2025-07-02",
    "Sales": 14000
  }
]
```

### CSV Sample
```csv
Date,Sales
2025-07-01,12000
2025-07-02,14000
```

---

## References

- [Power BI REST API](https://learn.microsoft.com/en-us/rest/api/power-bi/)
- [Power Automate Docs](https://learn.microsoft.com/en-us/power-automate/)
- [SharePoint Connector](https://learn.microsoft.com/en-us/connectors/sharepointonline/)