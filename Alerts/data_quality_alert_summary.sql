{{ config(materialized='table', schema='audit') }}

WITH dq_flags AS (
    SELECT 'silver_patient_demographics' AS table_name, data_quality_flag
    FROM {{ ref('silver_patient_demographics') }}
    WHERE data_quality_flag IS NOT NULL

    UNION ALL
    SELECT 'silver_hospital_info', data_quality_flag
    FROM {{ ref('silver_hospital_info') }}
    WHERE data_quality_flag IS NOT NULL

    UNION ALL
    SELECT 'silver_patient_diagnosis', data_quality_flag
    FROM {{ ref('silver_patient_diagnosis') }}
    WHERE data_quality_flag IS NOT NULL

    UNION ALL
    SELECT 'silver_lab_results', data_quality_flag
    FROM {{ ref('silver_lab_results') }}
    WHERE data_quality_flag IS NOT NULL

    UNION ALL
    SELECT 'silver_patient_vitals', data_quality_flag
    FROM {{ ref('silver_patient_vitals') }}
    WHERE data_quality_flag IS NOT NULL
)

SELECT
    table_name,
    data_quality_flag,
    COUNT(*) AS issue_count,
    CASE
        WHEN COUNT(*) >= 1000 THEN 'HIGH'
        WHEN COUNT(*) >= 100 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS alert_severity,
    CURRENT_TIMESTAMP() AS alert_generated_at
FROM dq_flags
GROUP BY table_name, data_quality_flag
