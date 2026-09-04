{{ config(materialized='table', schema='audit') }}

WITH null_key_errors AS (
    SELECT
        'silver_patient_demographics' AS source_table,
        _source_file,
        'NULL_OR_EMPTY_PATIENT_ID' AS error_reason,
        patient_id,
        CAST(NULL AS STRING) AS hospital_id,
        record_date,
        CURRENT_TIMESTAMP() AS logged_at
    FROM {{ ref('silver_patient_demographics') }}
    WHERE patient_id IS NULL OR TRIM(patient_id) = ''

    UNION ALL

    SELECT
        'silver_hospital_info',
        _source_file,
        'NULL_OR_EMPTY_HOSPITAL_ID',
        CAST(NULL AS STRING),
        hospital_id,
        record_date,
        CURRENT_TIMESTAMP()
    FROM {{ ref('silver_hospital_info') }}
    WHERE hospital_id IS NULL OR TRIM(hospital_id) = ''

    UNION ALL

    SELECT
        'silver_patient_diagnosis',
        _source_file,
        'NULL_KEY_AFTER_CLEANSING',
        patient_id,
        hospital_id,
        record_date,
        CURRENT_TIMESTAMP()
    FROM {{ ref('silver_patient_diagnosis') }}
    WHERE patient_id IS NULL OR hospital_id IS NULL

    UNION ALL

    SELECT
        'silver_lab_results',
        _source_file,
        'NULL_KEY_AFTER_CLEANSING',
        patient_id,
        hospital_id,
        record_date,
        CURRENT_TIMESTAMP()
    FROM {{ ref('silver_lab_results') }}
    WHERE patient_id IS NULL OR hospital_id IS NULL

    UNION ALL

    SELECT
        'silver_patient_vitals',
        _source_file,
        'NULL_KEY_AFTER_CLEANSING',
        patient_id,
        hospital_id,
        record_date,
        CURRENT_TIMESTAMP()
    FROM {{ ref('silver_patient_vitals') }}
    WHERE patient_id IS NULL OR hospital_id IS NULL
)

SELECT *
FROM null_key_errors
