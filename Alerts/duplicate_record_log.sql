{{ config(materialized='table', schema='audit') }}

SELECT
    'silver_patient_demographics' AS source_table,
    patient_id,
    CAST(NULL AS STRING) AS hospital_id,
    CAST(NULL AS STRING) AS hospital_name,
    record_date,
    CAST(NULL AS STRING) AS observation_code,
    COUNT(*) AS duplicate_count,
    CURRENT_TIMESTAMP() AS logged_at
FROM {{ ref('silver_patient_demographics') }}
GROUP BY patient_id, record_date
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'silver_hospital_info',
    CAST(NULL AS STRING),
    hospital_id,
    hospital_name,
    record_date,
    CAST(NULL AS STRING),
    COUNT(*),
    CURRENT_TIMESTAMP()
FROM {{ ref('silver_hospital_info') }}
GROUP BY hospital_id, hospital_name, record_date
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'silver_patient_diagnosis',
    patient_id,
    hospital_id,
    hospital_name,
    record_date,
    diagnosis_code,
    COUNT(*),
    CURRENT_TIMESTAMP()
FROM {{ ref('silver_patient_diagnosis') }}
GROUP BY patient_id, hospital_id, hospital_name, record_date, diagnosis_code
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'silver_lab_results',
    patient_id,
    hospital_id,
    hospital_name,
    record_date,
    lab_test_name,
    COUNT(*),
    CURRENT_TIMESTAMP()
FROM {{ ref('silver_lab_results') }}
GROUP BY patient_id, hospital_id, hospital_name, record_date, lab_test_name
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'silver_patient_vitals',
    patient_id,
    hospital_id,
    hospital_name,
    record_date,
    CAST(NULL AS STRING),
    COUNT(*),
    CURRENT_TIMESTAMP()
FROM {{ ref('silver_patient_vitals') }}
GROUP BY patient_id, hospital_id, hospital_name, record_date
HAVING COUNT(*) > 1
