
# Implementing SCD Type 2 in a Translytical Task Flow (Power BI / Microsoft Fabric)

## 🧭 Use Case Overview

- **Entity**: `Asset`
- **SCD Type**: Type 2 (keep historical versions)
- **Changing Attribute**: `State` (e.g., upgrade from `C` → `B`)
- **Task Metadata**: `Commentary` describing the upgrade reason
- **Goal**: Track each version of an asset's state, and store a new row when it changes, along with commentary.

---

## 🔄 High-Level Architecture

| Layer | Tool | Role |
|-------|------|------|
| Ingestion | Dataflow / Event stream | Bring in asset state updates |
| Transformation | **Notebook** (Spark) | SCD Type 2 logic: detect changes, update old rows, insert new rows |
| Storage | **Lakehouse (Delta table)** | Store historical asset state records |
| Reporting | Power BI Semantic Model | Track current & historical asset states, commentary |
| Orchestration | **Pipeline** *(optional)* | Schedule notebook/dataflow execution |

---

## 🔧 STEP-BY-STEP: Building the SCD Type 2 Workflow

### 1. Design the SCD Table Structure (Delta Table in Lakehouse)

```sql
-- Table: asset_state_history

| AssetID | State | Commentary           | ValidFrom   | ValidTo     | IsCurrent | SurrogateKey |
|---------|-------|----------------------|-------------|-------------|-----------|---------------|
| A001    | C     | Initial deployment   | 2024-01-01  | 2024-06-01  | false     | 1001          |
| A001    | B     | Upgraded to B        | 2024-06-01  | NULL        | true      | 1002          |
```

### 2. Create a Lakehouse in Microsoft Fabric

- Create a **Lakehouse** in your Data Engineering workspace.
- Create the `asset_state_history` Delta table with the schema shown above.

### 3. Set Up an Incoming Source

- Use Dataflow Gen2, CSV, or streaming input.
- Example input schema:

```csv
AssetID, State, Commentary, EventDate
A001, B, "Upgraded after inspection", 2024-06-01
```

- Store this in a **staging table** called `stg_asset_updates`.

### 4. Create a Notebook to Implement SCD Type 2 Logic

Use a PySpark notebook to compare `stg_asset_updates` with `asset_state_history`.

```python
from pyspark.sql.functions import col, lit, current_timestamp

# Load existing history
history_df = spark.read.format("delta").load("Tables/asset_state_history")

# Load incoming updates
updates_df = spark.read.format("delta").load("Tables/stg_asset_updates")

# Join and detect changed records
changed_df = updates_df.alias("new").join(
    history_df.filter("IsCurrent = true").alias("old"),
    on="AssetID"
).filter(col("new.State") != col("old.State"))

# Expire old records
expired_df = changed_df.select(
    col("old.AssetID"),
    col("old.State"),
    col("old.Commentary"),
    col("old.ValidFrom"),
    current_timestamp().alias("ValidTo"),
    lit(False).alias("IsCurrent"),
    col("old.SurrogateKey")
)

# Insert new records
from pyspark.sql.functions import monotonically_increasing_id

new_version_df = changed_df.select(
    col("new.AssetID"),
    col("new.State"),
    col("new.Commentary"),
    current_timestamp().alias("ValidFrom"),
    lit(None).cast("timestamp").alias("ValidTo"),
    lit(True).alias("IsCurrent"),
    monotonically_increasing_id().alias("SurrogateKey")
)

# Combine and save
final_df = expired_df.unionByName(new_version_df)
final_df.write.format("delta").mode("append").save("Tables/asset_state_history")
```

### 5. Create a Power BI Report or Semantic Model

- Connect Power BI to the Lakehouse.
- Build visuals for:
  - Current asset states (`IsCurrent = true`)
  - Historical asset changes
  - Upgrade commentaries

### 6. Optional: Use a Pipeline for Orchestration

- Use a pipeline to automate:
  1. Dataflow execution
  2. Notebook run
  3. Notifications or logging

---

## ✅ Best Practices

- Use `AssetID + ValidFrom` as a unique key.
- Validate uniqueness of `IsCurrent = true` per AssetID.
- Compact and vacuum Delta tables periodically.

---

## ✅ Final Result

Each time an asset's state changes:
- A **new row** is inserted with `IsCurrent = true`
- The **old row** is marked `IsCurrent = false`, with `ValidTo` set
- **Commentary** is preserved for auditing
- Everything is stored in a **Delta Lakehouse table**, enabling full visibility into asset history