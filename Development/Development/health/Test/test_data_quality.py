import os
from databricks import sql

CATALOG = "databricks_healthcare_ws_7405614041790072"
SILVER_SCHEMA = "dbt_partner_connect_2026_09_01_09_0914_silver"
GOLD_SCHEMA = "dbt_partner_connect_2026_09_01_09_0914_gold"

def get_connection():
    return sql.connect(
        server_hostname=os.environ["DATABRICKS_SERVER_HOSTNAME"],
        http_path=os.environ["DATABRICKS_HTTP_PATH"],
        access_token=os.environ["DATABRICKS_TOKEN"],
    )

def fetch_one(query):
    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query)
            return cursor.fetchone()[0]

def test_fact_health_metrics_has_rows():
    count = fetch_one(f"""
        SELECT COUNT(*)
        FROM {CATALOG}.{GOLD_SCHEMA}.fact_health_metrics
    """)
    assert count > 0

def test_fact_health_metrics_no_null_keys():
    count = fetch_one(f"""
        SELECT COUNT(*)
        FROM {CATALOG}.{GOLD_SCHEMA}.fact_health_metrics
        WHERE patient_key IS NULL
           OR hospital_key IS NULL
           OR date_key IS NULL
    """)
    assert count == 0

def test_fact_health_metrics_no_duplicate_keys():
    count = fetch_one(f"""
        SELECT COUNT(*)
        FROM (
            SELECT health_metric_key
            FROM {CATALOG}.{GOLD_SCHEMA}.fact_health_metrics
            GROUP BY health_metric_key
            HAVING COUNT(*) > 1
        )
    """)
    assert count == 0

def test_patient_risk_score_valid_range():
    count = fetch_one(f"""
        SELECT COUNT(*)
        FROM {CATALOG}.{GOLD_SCHEMA}.fact_health_metrics
        WHERE patient_risk_score < 0
           OR patient_risk_score > 1.05
    """)
    assert count == 0

def test_silver_patient_demographics_no_duplicate_records():
    count = fetch_one(f"""
        SELECT COUNT(*)
        FROM (
            SELECT patient_id, record_date
            FROM {CATALOG}.{SILVER_SCHEMA}.silver_patient_demographics
            GROUP BY patient_id, record_date
            HAVING COUNT(*) > 1
        )
    """)
    assert count == 0

def test_silver_hospital_info_no_duplicate_records():
    count = fetch_one(f"""
        SELECT COUNT(*)
        FROM (
            SELECT hospital_id, record_date
            FROM {CATALOG}.{SILVER_SCHEMA}.silver_hospital_info
            GROUP BY hospital_id, record_date
            HAVING COUNT(*) > 1
        )
    """)
    assert count == 0

def test_gold_marts_have_rows():
    marts = [
        "gold_patient_risk_summary",
        "gold_hospital_performance_scorecard",
        "gold_vitals_trend_analysis",
        "gold_cost_analysis",
        "gold_readmission_risk_distribution",
        "gold_lifestyle_health_correlation",
        "gold_lab_abnormality_rate",
        "gold_monthly_quarterly_trend",
    ]

    for mart in marts:
        count = fetch_one(f"""
            SELECT COUNT(*)
            FROM {CATALOG}.{GOLD_SCHEMA}.{mart}
        """)
        assert count > 0, f"{mart} has no rows"
