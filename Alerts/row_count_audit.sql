{{ config(materialized='table', schema='audit') }}

SELECT 'silver_patient_demographics' AS table_name, COUNT(*) AS row_count, CURRENT_TIMESTAMP() AS audit_timestamp
FROM {{ ref('silver_patient_demographics') }}

UNION ALL
SELECT 'silver_hospital_info', COUNT(*), CURRENT_TIMESTAMP()
FROM {{ ref('silver_hospital_info') }}

UNION ALL
SELECT 'silver_patient_diagnosis', COUNT(*), CURRENT_TIMESTAMP()
FROM {{ ref('silver_patient_diagnosis') }}

UNION ALL
SELECT 'silver_lab_results', COUNT(*), CURRENT_TIMESTAMP()
FROM {{ ref('silver_lab_results') }}

UNION ALL
SELECT 'silver_patient_vitals', COUNT(*), CURRENT_TIMESTAMP()
FROM {{ ref('silver_patient_vitals') }}

UNION ALL
SELECT 'fact_health_metrics', COUNT(*), CURRENT_TIMESTAMP()
FROM {{ ref('fact_health_metrics') }}
