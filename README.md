# Healthcare P2 Project

# Healthcare Patient Analytics Pipeline (Azure Databricks + dbt)

## Project Overview
The Healthcare Patient Analytics Pipeline is a scalable data engineering solution designed to ingest, transform, and analyze patient healthcare data for hospital and clinical analytics. This project leverages modern Lakehouse architecture using Azure Databricks, Delta Lake, Unity Catalog, and Azure Data Factory to build an end-to-end pipeline that processes hospital, patient, diagnosis, lab, and vitals data efficiently. Source data is ingested via Azure Data Factory, converted to Parquet, and processed across Bronze, Silver, and Gold layers in Delta Lake for structured healthcare analytics.

The pipeline ensures:
- Reliable ingestion of raw patient and hospital data
- Data cleansing, deduplication, and validation
- Computation of key healthcare metrics (patient risk score, readmission risk)
- Scalable storage and optimized querying via Unity Catalog
- Automated CI/CD and failure alerting

## Project Objective
- Build a scalable healthcare analytics pipeline to process multi-source patient data
- Ingest raw source files using Azure Data Factory (ADF) and land them as Parquet in ADLS Gen2
- Store and transform data in Azure Databricks Delta Lake using Medallion Architecture (Bronze/Silver/Gold)
- Ensure high data quality through deduplication, type casting, and range/anomaly validation
- Compute business-ready metrics such as patient risk score and readmission risk category
- Orchestrate and automate pipeline runs with monitoring and Slack failure alerts
- Enable CI/CD for notebooks and pipeline code via Azure DevOps

## Dataset

### Dataset Source
Simulated Healthcare Patient Data (based on Kaggle Heart Disease Dataset)

### Datasets Used
- **Hospital Info** → Bed capacity, ICU beds, staff count, utilization rate
- **Patient Demographics** → Age, gender, lifestyle risk, health score
- **Patient Diagnosis** → Diagnosis code, severity score, risk probability, readmission risk
- **Lab Results** → Hemoglobin, platelets, WBC/RBC count, creatinine
- **Patient Vitals** → Heart rate, blood pressure, oxygen level, BMI

These datasets simulate a real-world hospital patient analytics system across multiple hospitals.

## Technologies Used
| Technology | Purpose |
|---|---|
| Python / SQL | Data processing & transformation |
| Azure Databricks | Data engineering platform (Lakehouse) |
| Unity Catalog | Data governance, external tables, access control |
| Azure Data Lake Storage Gen2 | Data lake storage (raw + Parquet containers) |
| Azure Data Factory | Source ingestion & Parquet conversion |
| dbt (Cloud) | Silver & Gold layer transformations |
| Delta Lake | Bronze/Silver/Gold structured storage |
| Apache Airflow | Workflow orchestration |
| Azure DevOps | CI/CD for notebooks and pipeline code |
| Slack | Pipeline failure alerts & notifications |

## Lakehouse Architecture
Source CSVs → Azure Data Factory (ingest + convert to Parquet) → ADLS Gen2 (`parquetcontainer`) → Databricks Unity Catalog External Tables (Bronze) → dbt transformations (Silver) → Gold aggregates & star schema → Analytics/BI consumption

## ETL Pipeline Design

### Bronze Layer (Raw Data)
**Purpose**
- Store raw data exactly as ingested from source
- Preserve data lineage from ADF ingestion
- Enable traceability of raw records

**Tables**
- `bronze.hospital_info`
- `bronze.lab_results`
- `bronze.patient_demographics`
- `bronze.patient_diagnosis`
- `bronze.patient_vitals`

**Operations**
- Raw CSV ingestion via Azure Data Factory pipeline
- Conversion to Parquet, landed in a dedicated ADLS container
- Registered as Unity Catalog external tables via an External Location + Storage Credential

### Silver Layer (Cleaned Data)
**Purpose**
- Clean, standardize, and deduplicate datasets
- Prepare consistent, typed data for downstream analytics

**Transformations**
- Cast raw string columns to correct data types (INT, DOUBLE, DATE)
- Deduplicate records using `ROW_NUMBER()` over patient/hospital + date keys
- Standardize categorical fields (e.g., gender → M/F/Other)
- Bucket `readmission_risk` into Low/Medium/High categories
- Flag physically-impossible negative values via a `data_quality_flag` column
- Built entirely as dbt models on top of Bronze external tables

**Output Tables**
- `silver.silver_hospital_info`
- `silver.silver_lab_results`
- `silver.silver_patient_demographics`
- `silver.silver_patient_diagnosis`
- `silver.silver_patient_vitals`

### Gold Layer (Analytics Data)
**Star Schema**
- Fact table: `FACT_HEALTH_METRICS`
- Dimension tables: `DIM_PATIENT`, `DIM_HOSPITAL`, `DIM_DATE`, `DIM_OBSERVATION`

**Purpose**
Generate business-ready datasets for healthcare analytics and reporting.

**Features Generated**
- **Patient Risk Score** — composite score computed from `risk_probability`, `severity_score`, `comorbidity_score`, `lifestyle_risk`, and smoking/alcohol index
- **Readmission Risk Category** — Low / Medium / High, derived from numeric `readmission_risk` score
- **Hospital Utilization Metrics** — bed capacity vs. patient load, ICU utilization
- **Diagnosis & Treatment Aggregates** — treatment cost, medication count, recovery days by diagnosis
- **Lab Result Trends** — abnormal lab value tracking by patient/hospital
- **Vitals-Based Risk Indicators** — blood pressure, glucose, and BMI-based flags
- **Time-Based Aggregations** — metrics by day/month via `DIM_DATE`
- **Data Quality & Error Handling** — anomalies logged to an `etl_errors` table with alerting

## Orchestration (Pipeline Automation)
The pipeline is designed to be orchestrated using Databricks Workflows / Apache Airflow.

**Planned/In-Progress Tasks**
- Task 1: Bronze ingestion pipeline
- Task 2: Silver transformation pipeline (dbt)
- Task 3: Gold aggregation pipeline

**Scheduling**
Daily batch job (target: 2 AM UTC) for automated end-to-end processing.

## Alerts
- Slack app **"Databricks Alerts"** integrated via an Incoming Webhook
- Configured as a Databricks notification destination (`slack-databricks-alerts`)
- Attached to job **"On failure"** notifications to alert on ETL task failures
- Verified working via a test job with an intentionally-failing SQL task

## CI/CD (Azure DevOps)
- Databricks workspace linked to Azure Repos via a Databricks Git folder
- Notebooks/scripts committed and pushed to the linked Azure DevOps repo
- Azure Pipeline configured (Python setup, pytest install, repo validation, build artifact publishing)
- Service principal (`Databricks-SP`) registered in Microsoft Entra ID for secure, non-interactive deployment access from Azure DevOps to Databricks

## Data Quality Checks
Implemented checks include:
- Null value validation
- Duplicate detection and removal (via `ROW_NUMBER()` dedup pattern)
- Data type casting and schema validation
- Negative/invalid value flagging
- Range sanity checks on numeric score fields

## Monitoring
- Databricks job run history and logs
- dbt Cloud run logs
- Slack failure notifications
- (Planned) Centralized `etl_errors` log table for anomaly tracking

## Author

Harshini Maddi
Shanmuga Sundaram
Rakesh Akurathi
Saritha
Srinadh

*Built as part of the Revature Readiness Program capstone project.*
