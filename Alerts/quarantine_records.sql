{{ config(materialized='table', schema='audit') }}

SELECT
    'silver_patient_diagnosis' AS source_table,
    patient_id,
    hospital_id,
    hospital_name,
    record_date,
    data_quality_flag,
    _source_file,
    CURRENT_TIMESTAMP() AS quarantined_at
FROM {{ ref('silver_patient_diagnosis') }}
WHERE data_quality_flag LIKE '%orphan%'

UNION ALL

SELECT
    'silver_lab_results',
    patient_id,
    hospital_id,
    hospital_name,
    record_date,
    data_quality_flag,
    _source_file,
    CURRENT_TIMESTAMP()
FROM {{ ref('silver_lab_results') }}
WHERE data_quality_flag LIKE '%orphan%'

UNION ALL

SELECT
    'silver_patient_vitals',
    patient_id,
    hospital_id,
    hospital_name,
    record_date,
    data_quality_flag,
    _source_file,
    CURRENT_TIMESTAMP()
FROM {{ ref('silver_patient_vitals') }}
WHERE data_quality_flag LIKE '%orphan%'
