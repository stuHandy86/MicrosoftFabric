
# Enable Change Data Capture (CDC) in SQL Server

This document outlines the steps to enable Change Data Capture (CDC) on a SQL Server database and table.

---

## 🟦 Step 1: Enable CDC on the Database

Run the following command in the context of your target database:

```sql
EXEC sys.sp_cdc_enable_db;
```

📌 This:
- Creates CDC metadata tables.
- Must be run **once per database**.
- Requires `sysadmin` or `db_owner` role.

---

## 🟦 Step 2: Enable CDC on a Table (Create Capture Instance)

```sql
EXEC sys.sp_cdc_enable_table  
    @source_schema = N'dbo',  
    @source_name   = N'YourTableName',  
    @role_name     = NULL;
```

📌 This:
- Creates a change table: `cdc.dbo_YourTableName_CT`.
- Creates a capture instance and two SQL Agent jobs:
  - `cdc.<capture_job>`
  - `cdc.<cleanup_job>`
- Starts capturing changes made to the table.

If `@role_name` is not `NULL`, CDC access is limited to users in that role.

---

## 🟦 Step 3: Grant Privileges to Users

Give users permission to query CDC tables:

```sql
EXEC sp_addrolemember N'cdc_reader', N'YourUserName';
```

📌 Ensure the user also has:
- SELECT permissions on the source table.
- Membership in the database.

---

## 🟨 Step 4: Monitor and Query Changes

You can now query changes using system functions:

```sql
-- Get changes between two log sequence numbers (LSNs)
SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_YourTableName (
    @from_lsn, 
    @to_lsn, 
    N'all'
);
```

or

```sql
-- Get net changes only
SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_YourTableName (
    @from_lsn, 
    @to_lsn, 
    N'all'
);
```

To get LSN values:
```sql
SELECT sys.fn_cdc_get_min_lsn('dbo_YourTableName');
SELECT sys.fn_cdc_get_max_lsn();
```

---

## 🔄 Maintenance

- **SQL Agent must be running** for CDC jobs to function.
- Retention period and job schedules can be configured using:
  ```sql
  EXEC sys.sp_cdc_change_job;
  ```

---

## 🧹 Disable CDC (if needed)

```sql
-- Disable CDC on the table
EXEC sys.sp_cdc_disable_table  
    @source_schema = N'dbo',  
    @source_name   = N'YourTableName',  
    @capture_instance = N'dbo_YourTableName';

-- Disable CDC on the database
EXEC sys.sp_cdc_disable_db;
```

---

## ✅ Done!

You now have CDC configured to track changes in SQL Server for auditing, ETL, or analytics use cases.