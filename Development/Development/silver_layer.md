**silver\_hospital\_info.sql**



{{ config(materialized='table', schema='silver') }}



WITH source\_data AS (

&#x20;   SELECT

&#x20;       NULLIF(TRIM(hospital\_id), '') AS hospital\_id,

&#x20;       INITCAP(TRIM(hospital\_name)) AS hospital\_name,

&#x20;       INITCAP(TRIM(city)) AS city,

&#x20;       INITCAP(TRIM(state)) AS state,

&#x20;       TRY\_CAST(record\_date AS DATE) AS record\_date,



&#x20;       TRY\_CAST(bed\_capacity AS INT) AS bed\_capacity,

&#x20;       TRY\_CAST(icu\_beds AS INT) AS icu\_beds,

&#x20;       TRY\_CAST(staff\_count AS INT) AS staff\_count,

&#x20;       TRY\_CAST(infection\_rate AS DOUBLE) AS infection\_rate,

&#x20;       TRY\_CAST(utilization\_rate AS DOUBLE) AS utilization\_rate,

&#x20;       TRY\_CAST(avg\_wait\_time AS DOUBLE) AS avg\_wait\_time,

&#x20;       TRY\_CAST(equipment\_score AS DOUBLE) AS equipment\_score,

&#x20;       TRY\_CAST(patient\_load AS DOUBLE) AS patient\_load,

&#x20;       TRY\_CAST(surgery\_count AS INT) AS surgery\_count,

&#x20;       TRY\_CAST(emergency\_cases AS INT) AS emergency\_cases,



&#x20;       CURRENT\_TIMESTAMP() AS \_ingested\_at,

&#x20;       'hospital\_info.parquet' AS \_source\_file



&#x20;   FROM {{ source('bronze', 'hospital\_info') }}

),



validated AS (

&#x20;   SELECT

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       city,

&#x20;       state,

&#x20;       record\_date,



&#x20;       CASE WHEN bed\_capacity >= 0 THEN bed\_capacity ELSE NULL END AS bed\_capacity,

&#x20;       CASE WHEN icu\_beds >= 0 AND icu\_beds <= bed\_capacity THEN icu\_beds ELSE NULL END AS icu\_beds,

&#x20;       CASE WHEN staff\_count >= 0 THEN staff\_count ELSE NULL END AS staff\_count,

&#x20;       CASE WHEN infection\_rate BETWEEN 0 AND 100 THEN infection\_rate ELSE NULL END AS infection\_rate,

&#x20;       CASE WHEN utilization\_rate BETWEEN 0 AND 100 THEN utilization\_rate ELSE NULL END AS utilization\_rate,

&#x20;       CASE WHEN avg\_wait\_time >= 0 THEN avg\_wait\_time ELSE NULL END AS avg\_wait\_time,

&#x20;       CASE WHEN equipment\_score BETWEEN 0 AND 100 THEN equipment\_score ELSE NULL END AS equipment\_score,

&#x20;       CASE WHEN patient\_load >= 0 THEN patient\_load ELSE NULL END AS patient\_load,

&#x20;       CASE WHEN surgery\_count >= 0 THEN surgery\_count ELSE NULL END AS surgery\_count,

&#x20;       CASE WHEN emergency\_cases >= 0 THEN emergency\_cases ELSE NULL END AS emergency\_cases,



&#x20;       DAY(record\_date) AS day,

&#x20;       MONTH(record\_date) AS month,

&#x20;       DATE\_FORMAT(record\_date, 'MMMM') AS month\_name,

&#x20;       QUARTER(record\_date) AS quarter,

&#x20;       YEAR(record\_date) AS year,



&#x20;       CONCAT\_WS(', ',

&#x20;           CASE WHEN bed\_capacity IS NOT NULL AND bed\_capacity < 0 THEN 'invalid\_bed\_capacity\_nulled' END,

&#x20;           CASE WHEN icu\_beds IS NOT NULL AND (icu\_beds < 0 OR icu\_beds > bed\_capacity) THEN 'invalid\_icu\_beds\_nulled' END,

&#x20;           CASE WHEN staff\_count IS NOT NULL AND staff\_count < 0 THEN 'invalid\_staff\_count\_nulled' END,

&#x20;           CASE WHEN infection\_rate IS NOT NULL AND NOT infection\_rate BETWEEN 0 AND 100 THEN 'invalid\_infection\_rate\_nulled' END,

&#x20;           CASE WHEN utilization\_rate IS NOT NULL AND NOT utilization\_rate BETWEEN 0 AND 100 THEN 'invalid\_utilization\_rate\_nulled' END,

&#x20;           CASE WHEN avg\_wait\_time IS NOT NULL AND avg\_wait\_time < 0 THEN 'invalid\_avg\_wait\_time\_nulled' END,

&#x20;           CASE WHEN equipment\_score IS NOT NULL AND NOT equipment\_score BETWEEN 0 AND 100 THEN 'invalid\_equipment\_score\_nulled' END,

&#x20;           CASE WHEN patient\_load IS NOT NULL AND patient\_load < 0 THEN 'invalid\_patient\_load\_nulled' END,

&#x20;           CASE WHEN surgery\_count IS NOT NULL AND surgery\_count < 0 THEN 'invalid\_surgery\_count\_nulled' END,

&#x20;           CASE WHEN emergency\_cases IS NOT NULL AND emergency\_cases < 0 THEN 'invalid\_emergency\_cases\_nulled' END

&#x20;       ) AS data\_quality\_flag,



&#x20;       \_ingested\_at,

&#x20;       \_source\_file



&#x20;   FROM source\_data

&#x20;   WHERE hospital\_id IS NOT NULL

&#x20;     AND hospital\_name IS NOT NULL

&#x20;     AND record\_date IS NOT NULL

),



deduped AS (

&#x20;   SELECT

&#x20;       \*,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY hospital\_id, record\_date

&#x20;           ORDER BY \_ingested\_at DESC

&#x20;       ) AS rn

&#x20;   FROM validated

)



SELECT

&#x20;   hospital\_id,

&#x20;   hospital\_name,

&#x20;   city,

&#x20;   state,

&#x20;   record\_date,

&#x20;   day,

&#x20;   month,

&#x20;   month\_name,

&#x20;   quarter,

&#x20;   year,

&#x20;   bed\_capacity,

&#x20;   icu\_beds,

&#x20;   staff\_count,

&#x20;   infection\_rate,

&#x20;   utilization\_rate,

&#x20;   avg\_wait\_time,

&#x20;   equipment\_score,

&#x20;   patient\_load,

&#x20;   surgery\_count,

&#x20;   emergency\_cases,

&#x20;   NULLIF(data\_quality\_flag, '') AS data\_quality\_flag,

&#x20;   \_ingested\_at,

&#x20;   \_source\_file

FROM deduped

WHERE rn = 1

**silver\_lab\_results.sql**
{{ config(materialized='table', schema='silver') }}



WITH source\_data AS (

&#x20;   SELECT

&#x20;       NULLIF(TRIM(patient\_id), '') AS patient\_id,

&#x20;       INITCAP(TRIM(lab\_test\_name)) AS lab\_test\_name,

&#x20;       INITCAP(TRIM(hospital\_name)) AS hospital\_name,

&#x20;       INITCAP(TRIM(technician\_name)) AS technician\_name,

&#x20;       TRY\_CAST(record\_date AS DATE) AS record\_date,



&#x20;       TRY\_CAST(hemoglobin AS DOUBLE) AS hemoglobin,

&#x20;       TRY\_CAST(platelets AS DOUBLE) AS platelets,

&#x20;       TRY\_CAST(wbc\_count AS DOUBLE) AS wbc\_count,

&#x20;       TRY\_CAST(rbc\_count AS DOUBLE) AS rbc\_count,

&#x20;       TRY\_CAST(creatinine AS DOUBLE) AS creatinine,

&#x20;       TRY\_CAST(sodium AS DOUBLE) AS sodium,

&#x20;       TRY\_CAST(potassium AS DOUBLE) AS potassium,

&#x20;       TRY\_CAST(calcium AS DOUBLE) AS calcium,

&#x20;       TRY\_CAST(bilirubin AS DOUBLE) AS bilirubin,

&#x20;       TRY\_CAST(test\_cost AS DOUBLE) AS test\_cost,



&#x20;       CURRENT\_TIMESTAMP() AS \_ingested\_at,

&#x20;       'lab\_results.parquet' AS \_source\_file



&#x20;   FROM {{ source('bronze', 'lab\_results') }}

),



validated AS (

&#x20;   SELECT

&#x20;       patient\_id,

&#x20;       lab\_test\_name,

&#x20;       hospital\_name,

&#x20;       technician\_name,

&#x20;       record\_date,



&#x20;       CASE WHEN hemoglobin BETWEEN 3 AND 25 THEN hemoglobin ELSE NULL END AS hemoglobin,

&#x20;       CASE WHEN platelets BETWEEN 10000 AND 1000000 THEN platelets ELSE NULL END AS platelets,

&#x20;       CASE WHEN wbc\_count BETWEEN 0.5 AND 100 THEN wbc\_count ELSE NULL END AS wbc\_count,

&#x20;       CASE WHEN rbc\_count BETWEEN 1 AND 8 THEN rbc\_count ELSE NULL END AS rbc\_count,

&#x20;       CASE WHEN creatinine BETWEEN 0.1 AND 20 THEN creatinine ELSE NULL END AS creatinine,

&#x20;       CASE WHEN sodium BETWEEN 100 AND 180 THEN sodium ELSE NULL END AS sodium,

&#x20;       CASE WHEN potassium BETWEEN 1.5 AND 8 THEN potassium ELSE NULL END AS potassium,

&#x20;       CASE WHEN calcium BETWEEN 5 AND 15 THEN calcium ELSE NULL END AS calcium,

&#x20;       CASE WHEN bilirubin BETWEEN 0 AND 30 THEN bilirubin ELSE NULL END AS bilirubin,

&#x20;       CASE WHEN test\_cost >= 0 THEN test\_cost ELSE NULL END AS test\_cost,



&#x20;       DAY(record\_date) AS day,

&#x20;       MONTH(record\_date) AS month,

&#x20;       DATE\_FORMAT(record\_date, 'MMMM') AS month\_name,

&#x20;       QUARTER(record\_date) AS quarter,

&#x20;       YEAR(record\_date) AS year,



&#x20;       CONCAT\_WS(', ',

&#x20;           CASE WHEN hemoglobin IS NOT NULL AND NOT hemoglobin BETWEEN 3 AND 25 THEN 'invalid\_hemoglobin\_nulled' END,

&#x20;           CASE WHEN platelets IS NOT NULL AND NOT platelets BETWEEN 10000 AND 1000000 THEN 'invalid\_platelets\_nulled' END,

&#x20;           CASE WHEN wbc\_count IS NOT NULL AND NOT wbc\_count BETWEEN 0.5 AND 100 THEN 'invalid\_wbc\_count\_nulled' END,

&#x20;           CASE WHEN rbc\_count IS NOT NULL AND NOT rbc\_count BETWEEN 1 AND 8 THEN 'invalid\_rbc\_count\_nulled' END,

&#x20;           CASE WHEN creatinine IS NOT NULL AND NOT creatinine BETWEEN 0.1 AND 20 THEN 'invalid\_creatinine\_nulled' END,

&#x20;           CASE WHEN sodium IS NOT NULL AND NOT sodium BETWEEN 100 AND 180 THEN 'invalid\_sodium\_nulled' END,

&#x20;           CASE WHEN potassium IS NOT NULL AND NOT potassium BETWEEN 1.5 AND 8 THEN 'invalid\_potassium\_nulled' END,

&#x20;           CASE WHEN calcium IS NOT NULL AND NOT calcium BETWEEN 5 AND 15 THEN 'invalid\_calcium\_nulled' END,

&#x20;           CASE WHEN bilirubin IS NOT NULL AND NOT bilirubin BETWEEN 0 AND 30 THEN 'invalid\_bilirubin\_nulled' END,

&#x20;           CASE WHEN test\_cost IS NOT NULL AND test\_cost < 0 THEN 'invalid\_test\_cost\_nulled' END

&#x20;       ) AS data\_quality\_flag,



&#x20;       \_ingested\_at,

&#x20;       \_source\_file



&#x20;   FROM source\_data

&#x20;   WHERE patient\_id IS NOT NULL

&#x20;     AND hospital\_name IS NOT NULL

&#x20;     AND lab\_test\_name IS NOT NULL

&#x20;     AND record\_date IS NOT NULL

),



deduped AS (

&#x20;   SELECT

&#x20;       \*,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY patient\_id, hospital\_name, record\_date, lab\_test\_name

&#x20;           ORDER BY \_ingested\_at DESC

&#x20;       ) AS rn

&#x20;   FROM validated

),



patient\_lookup AS (

&#x20;   SELECT patient\_id

&#x20;   FROM {{ ref('silver\_patient\_demographics') }}

&#x20;   GROUP BY patient\_id

),



hospital\_lookup AS (

&#x20;   SELECT

&#x20;       hospital\_name,

&#x20;       MAX(hospital\_id) AS hospital\_id

&#x20;   FROM {{ ref('silver\_hospital\_info') }}

&#x20;   GROUP BY hospital\_name

),



with\_dimensions AS (

&#x20;   SELECT

&#x20;       l.\*,

&#x20;       p.patient\_id AS resolved\_patient\_id,

&#x20;       h.hospital\_id AS resolved\_hospital\_id

&#x20;   FROM deduped l

&#x20;   LEFT JOIN patient\_lookup p

&#x20;       ON l.patient\_id = p.patient\_id

&#x20;   LEFT JOIN hospital\_lookup h

&#x20;       ON l.hospital\_name = h.hospital\_name

)



SELECT

&#x20;   patient\_id,

&#x20;   resolved\_hospital\_id AS hospital\_id,

&#x20;   lab\_test\_name,

&#x20;   hospital\_name,

&#x20;   technician\_name,

&#x20;   record\_date,

&#x20;   day,

&#x20;   month,

&#x20;   month\_name,

&#x20;   quarter,

&#x20;   year,

&#x20;   hemoglobin,

&#x20;   platelets,

&#x20;   wbc\_count,

&#x20;   rbc\_count,

&#x20;   creatinine,

&#x20;   sodium,

&#x20;   potassium,

&#x20;   calcium,

&#x20;   bilirubin,

&#x20;   test\_cost,

&#x20;   NULLIF(CONCAT\_WS(', ',

&#x20;       data\_quality\_flag,

&#x20;       CASE WHEN resolved\_patient\_id IS NULL THEN 'orphan\_patient\_reference' END,

&#x20;       CASE WHEN resolved\_hospital\_id IS NULL THEN 'orphan\_hospital\_reference' END

&#x20;   ), '') AS data\_quality\_flag,

&#x20;   \_ingested\_at,

&#x20;   \_source\_file

FROM with\_dimensions

WHERE rn = 1

&#x20; AND resolved\_patient\_id IS NOT NULL

&#x20; AND resolved\_hospital\_id IS NOT NULL





**silver\_patient\_demographics.sql**

{{ config(materialized='table', schema='silver') }}



WITH source\_data AS (

&#x20;   SELECT

&#x20;       NULLIF(TRIM(patient\_id), '') AS patient\_id,

&#x20;       INITCAP(TRIM(patient\_name)) AS patient\_name,



&#x20;       CASE

&#x20;           WHEN UPPER(TRIM(gender)) IN ('M', 'MALE') THEN 'M'

&#x20;           WHEN UPPER(TRIM(gender)) IN ('F', 'FEMALE') THEN 'F'

&#x20;           ELSE 'Unknown'

&#x20;       END AS gender,



&#x20;       INITCAP(TRIM(city)) AS city,

&#x20;       TRY\_CAST(record\_date AS DATE) AS record\_date,



&#x20;       CAST(ROUND(TRY\_CAST(age AS DOUBLE)) AS INT) AS age,

&#x20;       TRY\_CAST(income\_index AS DOUBLE) AS income\_index,

&#x20;       TRY\_CAST(health\_score AS DOUBLE) AS health\_score,

&#x20;       TRY\_CAST(lifestyle\_risk AS DOUBLE) AS lifestyle\_risk,

&#x20;       TRY\_CAST(exercise\_hours AS DOUBLE) AS exercise\_hours,

&#x20;       TRY\_CAST(sleep\_hours AS DOUBLE) AS sleep\_hours,

&#x20;       TRY\_CAST(alcohol\_index AS DOUBLE) AS alcohol\_index,

&#x20;       TRY\_CAST(smoking\_index AS DOUBLE) AS smoking\_index,

&#x20;       TRY\_CAST(diet\_score AS DOUBLE) AS diet\_score,

&#x20;       TRY\_CAST(insurance\_score AS DOUBLE) AS insurance\_score,



&#x20;       CURRENT\_TIMESTAMP() AS \_ingested\_at,

&#x20;       'patient\_demographics.parquet' AS \_source\_file

&#x20;   FROM {{ source('bronze', 'patient\_demographics') }}

),



validated AS (

&#x20;   SELECT

&#x20;       patient\_id,

&#x20;       patient\_name,

&#x20;       gender,

&#x20;       city,

&#x20;       record\_date,



&#x20;       CASE WHEN age BETWEEN 0 AND 120 THEN age ELSE NULL END AS age,

&#x20;       CASE WHEN income\_index BETWEEN 0 AND 1 THEN income\_index ELSE NULL END AS income\_index,

&#x20;       CASE WHEN health\_score BETWEEN 0 AND 100 THEN health\_score ELSE NULL END AS health\_score,

&#x20;       CASE WHEN lifestyle\_risk BETWEEN 0 AND 100 THEN lifestyle\_risk ELSE NULL END AS lifestyle\_risk,

&#x20;       CASE WHEN exercise\_hours BETWEEN 0 AND 24 THEN exercise\_hours ELSE NULL END AS exercise\_hours,

&#x20;       CASE WHEN sleep\_hours BETWEEN 0 AND 24 THEN sleep\_hours ELSE NULL END AS sleep\_hours,

&#x20;       CASE WHEN alcohol\_index BETWEEN 0 AND 1 THEN alcohol\_index ELSE NULL END AS alcohol\_index,

&#x20;       CASE WHEN smoking\_index BETWEEN 0 AND 1 THEN smoking\_index ELSE NULL END AS smoking\_index,

&#x20;       CASE WHEN diet\_score BETWEEN 0 AND 100 THEN diet\_score ELSE NULL END AS diet\_score,

&#x20;       CASE WHEN insurance\_score BETWEEN 0 AND 100 THEN insurance\_score ELSE NULL END AS insurance\_score,



&#x20;       DAY(record\_date) AS day,

&#x20;       MONTH(record\_date) AS month,

&#x20;       DATE\_FORMAT(record\_date, 'MMMM') AS month\_name,

&#x20;       QUARTER(record\_date) AS quarter,

&#x20;       YEAR(record\_date) AS year,



&#x20;       CONCAT\_WS(', ',

&#x20;           CASE WHEN age IS NOT NULL AND NOT age BETWEEN 0 AND 120 THEN 'invalid\_age\_nulled' END,

&#x20;           CASE WHEN income\_index IS NOT NULL AND NOT income\_index BETWEEN 0 AND 1 THEN 'invalid\_income\_index\_nulled' END,

&#x20;           CASE WHEN health\_score IS NOT NULL AND NOT health\_score BETWEEN 0 AND 100 THEN 'invalid\_health\_score\_nulled' END,

&#x20;           CASE WHEN lifestyle\_risk IS NOT NULL AND NOT lifestyle\_risk BETWEEN 0 AND 100 THEN 'invalid\_lifestyle\_risk\_nulled' END,

&#x20;           CASE WHEN exercise\_hours IS NOT NULL AND NOT exercise\_hours BETWEEN 0 AND 24 THEN 'invalid\_exercise\_hours\_nulled' END,

&#x20;           CASE WHEN sleep\_hours IS NOT NULL AND NOT sleep\_hours BETWEEN 0 AND 24 THEN 'invalid\_sleep\_hours\_nulled' END,

&#x20;           CASE WHEN alcohol\_index IS NOT NULL AND NOT alcohol\_index BETWEEN 0 AND 1 THEN 'invalid\_alcohol\_index\_nulled' END,

&#x20;           CASE WHEN smoking\_index IS NOT NULL AND NOT smoking\_index BETWEEN 0 AND 1 THEN 'invalid\_smoking\_index\_nulled' END,

&#x20;           CASE WHEN diet\_score IS NOT NULL AND NOT diet\_score BETWEEN 0 AND 100 THEN 'invalid\_diet\_score\_nulled' END,

&#x20;           CASE WHEN insurance\_score IS NOT NULL AND NOT insurance\_score BETWEEN 0 AND 100 THEN 'invalid\_insurance\_score\_nulled' END

&#x20;       ) AS data\_quality\_flag,



&#x20;       \_ingested\_at,

&#x20;       \_source\_file



&#x20;   FROM source\_data

&#x20;   WHERE patient\_id IS NOT NULL

&#x20;     AND record\_date IS NOT NULL

),



deduped AS (

&#x20;   SELECT

&#x20;       \*,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY patient\_id, record\_date

&#x20;           ORDER BY \_ingested\_at DESC

&#x20;       ) AS rn

&#x20;   FROM validated

)



SELECT

&#x20;   patient\_id,

&#x20;   patient\_name,

&#x20;   gender,

&#x20;   city,

&#x20;   record\_date,

&#x20;   day,

&#x20;   month,

&#x20;   month\_name,

&#x20;   quarter,

&#x20;   year,

&#x20;   age,

&#x20;   income\_index,

&#x20;   health\_score,

&#x20;   lifestyle\_risk,

&#x20;   exercise\_hours,

&#x20;   sleep\_hours,

&#x20;   alcohol\_index,

&#x20;   smoking\_index,

&#x20;   diet\_score,

&#x20;   insurance\_score,

&#x20;   NULLIF(data\_quality\_flag, '') AS data\_quality\_flag,

&#x20;   \_ingested\_at,

&#x20;   \_source\_file

FROM deduped

WHERE rn = 1





**silver\_patient\_diagnosis.sql**

{{ config(materialized='table', schema='silver') }}



WITH source\_data AS (

&#x20;   SELECT

&#x20;       NULLIF(TRIM(patient\_id), '') AS patient\_id,

&#x20;       UPPER(TRIM(diagnosis\_code)) AS diagnosis\_code,

&#x20;       INITCAP(TRIM(doctor\_name)) AS doctor\_name,

&#x20;       INITCAP(TRIM(hospital\_name)) AS hospital\_name,

&#x20;       TRY\_CAST(record\_date AS DATE) AS record\_date,



&#x20;       TRY\_CAST(severity\_score AS DOUBLE) AS severity\_score,

&#x20;       TRY\_CAST(risk\_probability AS DOUBLE) AS risk\_probability,

&#x20;       TRY\_CAST(treatment\_cost AS DOUBLE) AS treatment\_cost,

&#x20;       TRY\_CAST(insurance\_claim AS DOUBLE) AS insurance\_claim,

&#x20;       TRY\_CAST(medication\_count AS INT) AS medication\_count,

&#x20;       TRY\_CAST(visit\_duration AS DOUBLE) AS visit\_duration,

&#x20;       TRY\_CAST(procedure\_count AS INT) AS procedure\_count,

&#x20;       TRY\_CAST(recovery\_days AS INT) AS recovery\_days,

&#x20;       TRY\_CAST(comorbidity\_score AS DOUBLE) AS comorbidity\_score,



&#x20;       CASE

&#x20;           WHEN UPPER(TRIM(readmission\_risk)) IN ('LOW', 'L') THEN 'Low'

&#x20;           WHEN UPPER(TRIM(readmission\_risk)) IN ('MEDIUM', 'MED', 'MODERATE', 'M') THEN 'Medium'

&#x20;           WHEN UPPER(TRIM(readmission\_risk)) IN ('HIGH', 'CRITICAL', 'H') THEN 'High'

&#x20;           WHEN TRY\_CAST(readmission\_risk AS DOUBLE) < 60 THEN 'Low'

&#x20;           WHEN TRY\_CAST(readmission\_risk AS DOUBLE) BETWEEN 60 AND 120 THEN 'Medium'

&#x20;           WHEN TRY\_CAST(readmission\_risk AS DOUBLE) > 120 THEN 'High'

&#x20;           ELSE 'Unknown'

&#x20;       END AS readmission\_risk,



&#x20;       CURRENT\_TIMESTAMP() AS \_ingested\_at,

&#x20;       'patient\_diagnosis.parquet' AS \_source\_file



&#x20;   FROM {{ source('bronze', 'patient\_diagnosis') }}

),



validated AS (

&#x20;   SELECT

&#x20;       patient\_id,

&#x20;       diagnosis\_code,

&#x20;       doctor\_name,

&#x20;       hospital\_name,

&#x20;       record\_date,



&#x20;       CASE

&#x20;           WHEN severity\_score BETWEEN 0 AND 1 THEN severity\_score

&#x20;           WHEN severity\_score > 1 AND severity\_score <= 100 THEN severity\_score / 100

&#x20;           ELSE NULL

&#x20;       END AS severity\_score,



&#x20;       CASE

&#x20;           WHEN risk\_probability BETWEEN 0 AND 1 THEN risk\_probability

&#x20;           WHEN risk\_probability > 1 AND risk\_probability <= 100 THEN risk\_probability / 100

&#x20;           ELSE NULL

&#x20;       END AS risk\_probability,



&#x20;       CASE WHEN treatment\_cost >= 0 THEN treatment\_cost ELSE NULL END AS treatment\_cost,

&#x20;       CASE WHEN insurance\_claim >= 0 THEN insurance\_claim ELSE NULL END AS insurance\_claim,

&#x20;       CASE WHEN medication\_count >= 0 THEN medication\_count ELSE NULL END AS medication\_count,

&#x20;       CASE WHEN visit\_duration >= 0 THEN visit\_duration ELSE NULL END AS visit\_duration,

&#x20;       CASE WHEN procedure\_count >= 0 THEN procedure\_count ELSE NULL END AS procedure\_count,

&#x20;       CASE WHEN recovery\_days >= 0 THEN recovery\_days ELSE NULL END AS recovery\_days,

&#x20;       CASE WHEN comorbidity\_score BETWEEN 0 AND 100 THEN comorbidity\_score ELSE NULL END AS comorbidity\_score,

&#x20;       readmission\_risk,



&#x20;       DAY(record\_date) AS day,

&#x20;       MONTH(record\_date) AS month,

&#x20;       DATE\_FORMAT(record\_date, 'MMMM') AS month\_name,

&#x20;       QUARTER(record\_date) AS quarter,

&#x20;       YEAR(record\_date) AS year,



&#x20;       CONCAT\_WS(', ',

&#x20;           CASE WHEN severity\_score IS NOT NULL AND NOT severity\_score BETWEEN 0 AND 100 THEN 'invalid\_severity\_score\_nulled' END,

&#x20;           CASE WHEN risk\_probability IS NOT NULL AND NOT risk\_probability BETWEEN 0 AND 100 THEN 'invalid\_risk\_probability\_nulled' END,

&#x20;           CASE WHEN treatment\_cost IS NOT NULL AND treatment\_cost < 0 THEN 'invalid\_treatment\_cost\_nulled' END,

&#x20;           CASE WHEN insurance\_claim IS NOT NULL AND insurance\_claim < 0 THEN 'invalid\_insurance\_claim\_nulled' END,

&#x20;           CASE WHEN medication\_count IS NOT NULL AND medication\_count < 0 THEN 'invalid\_medication\_count\_nulled' END,

&#x20;           CASE WHEN visit\_duration IS NOT NULL AND visit\_duration < 0 THEN 'invalid\_visit\_duration\_nulled' END,

&#x20;           CASE WHEN procedure\_count IS NOT NULL AND procedure\_count < 0 THEN 'invalid\_procedure\_count\_nulled' END,

&#x20;           CASE WHEN recovery\_days IS NOT NULL AND recovery\_days < 0 THEN 'invalid\_recovery\_days\_nulled' END,

&#x20;           CASE WHEN comorbidity\_score IS NOT NULL AND NOT comorbidity\_score BETWEEN 0 AND 100 THEN 'invalid\_comorbidity\_score\_nulled' END

&#x20;       ) AS data\_quality\_flag,



&#x20;       \_ingested\_at,

&#x20;       \_source\_file



&#x20;   FROM source\_data

&#x20;   WHERE patient\_id IS NOT NULL

&#x20;     AND hospital\_name IS NOT NULL

&#x20;     AND diagnosis\_code IS NOT NULL

&#x20;     AND record\_date IS NOT NULL

),



deduped AS (

&#x20;   SELECT

&#x20;       \*,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY patient\_id, hospital\_name, record\_date, diagnosis\_code

&#x20;           ORDER BY \_ingested\_at DESC

&#x20;       ) AS rn

&#x20;   FROM validated

),



patient\_lookup AS (

&#x20;   SELECT patient\_id

&#x20;   FROM {{ ref('silver\_patient\_demographics') }}

&#x20;   GROUP BY patient\_id

),



hospital\_lookup AS (

&#x20;   SELECT

&#x20;       hospital\_name,

&#x20;       MAX(hospital\_id) AS hospital\_id

&#x20;   FROM {{ ref('silver\_hospital\_info') }}

&#x20;   GROUP BY hospital\_name

),



with\_dimensions AS (

&#x20;   SELECT

&#x20;       d.\*,

&#x20;       p.patient\_id AS resolved\_patient\_id,

&#x20;       h.hospital\_id AS resolved\_hospital\_id

&#x20;   FROM deduped d

&#x20;   LEFT JOIN patient\_lookup p

&#x20;       ON d.patient\_id = p.patient\_id

&#x20;   LEFT JOIN hospital\_lookup h

&#x20;       ON d.hospital\_name = h.hospital\_name

)



SELECT

&#x20;   patient\_id,

&#x20;   resolved\_hospital\_id AS hospital\_id,

&#x20;   diagnosis\_code,

&#x20;   doctor\_name,

&#x20;   hospital\_name,

&#x20;   record\_date,

&#x20;   day,

&#x20;   month,

&#x20;   month\_name,

&#x20;   quarter,

&#x20;   year,

&#x20;   severity\_score,

&#x20;   risk\_probability,

&#x20;   readmission\_risk,

&#x20;   treatment\_cost,

&#x20;   insurance\_claim,

&#x20;   medication\_count,

&#x20;   visit\_duration,

&#x20;   procedure\_count,

&#x20;   recovery\_days,

&#x20;   comorbidity\_score,

&#x20;   NULLIF(data\_quality\_flag, '') AS data\_quality\_flag,

&#x20;   \_ingested\_at,

&#x20;   \_source\_file

FROM with\_dimensions

WHERE rn = 1

&#x20; AND resolved\_patient\_id IS NOT NULL

&#x20; AND resolved\_hospital\_id IS NOT NULL





**silver\_patient\_vitals.sql**



{{ config(materialized='table', schema='silver') }}



WITH source\_data AS (

&#x20;   SELECT

&#x20;       NULLIF(TRIM(patient\_id), '') AS patient\_id,

&#x20;       INITCAP(TRIM(patient\_name)) AS patient\_name,

&#x20;       INITCAP(TRIM(hospital\_name)) AS hospital\_name,

&#x20;       TRY\_CAST(record\_date AS DATE) AS record\_date,



&#x20;       INITCAP(TRIM(device\_type)) AS device\_type,



&#x20;       TRY\_CAST(heart\_rate AS DOUBLE) AS heart\_rate,

&#x20;       TRY\_CAST(blood\_pressure\_sys AS DOUBLE) AS blood\_pressure\_sys,

&#x20;       TRY\_CAST(blood\_pressure\_dia AS DOUBLE) AS blood\_pressure\_dia,

&#x20;       TRY\_CAST(oxygen\_level AS DOUBLE) AS oxygen\_level,

&#x20;       TRY\_CAST(body\_temp AS DOUBLE) AS body\_temp,

&#x20;       TRY\_CAST(respiration\_rate AS DOUBLE) AS respiration\_rate,

&#x20;       TRY\_CAST(glucose\_level AS DOUBLE) AS glucose\_level,

&#x20;       TRY\_CAST(cholesterol AS DOUBLE) AS cholesterol,

&#x20;       TRY\_CAST(bmi AS DOUBLE) AS bmi,

&#x20;       TRY\_CAST(stress\_index AS DOUBLE) AS stress\_index,



&#x20;       CURRENT\_TIMESTAMP() AS \_ingested\_at,

&#x20;       'patient\_vitals.parquet' AS \_source\_file



&#x20;   FROM {{ source('bronze', 'patient\_vitals') }}

),



validated AS (

&#x20;   SELECT

&#x20;       patient\_id,

&#x20;       patient\_name,

&#x20;       hospital\_name,

&#x20;       record\_date,

&#x20;       device\_type,



&#x20;       CASE WHEN heart\_rate BETWEEN 30 AND 220 THEN heart\_rate ELSE NULL END AS heart\_rate,

&#x20;       CASE WHEN blood\_pressure\_sys BETWEEN 70 AND 200 THEN blood\_pressure\_sys ELSE NULL END AS blood\_pressure\_sys,

&#x20;       CASE WHEN blood\_pressure\_dia BETWEEN 40 AND 130 THEN blood\_pressure\_dia ELSE NULL END AS blood\_pressure\_dia,

&#x20;       CASE WHEN oxygen\_level BETWEEN 0 AND 100 THEN oxygen\_level ELSE NULL END AS oxygen\_level,

&#x20;       CASE WHEN body\_temp BETWEEN 90 AND 110 THEN body\_temp ELSE NULL END AS body\_temp,

&#x20;       CASE WHEN respiration\_rate BETWEEN 5 AND 60 THEN respiration\_rate ELSE NULL END AS respiration\_rate,

&#x20;       CASE WHEN glucose\_level BETWEEN 40 AND 500 THEN glucose\_level ELSE NULL END AS glucose\_level,

&#x20;       CASE WHEN cholesterol BETWEEN 50 AND 500 THEN cholesterol ELSE NULL END AS cholesterol,

&#x20;       CASE WHEN bmi BETWEEN 10 AND 80 THEN bmi ELSE NULL END AS bmi,

&#x20;       CASE WHEN stress\_index BETWEEN 0 AND 100 THEN stress\_index ELSE NULL END AS stress\_index,



&#x20;       DAY(record\_date) AS day,

&#x20;       MONTH(record\_date) AS month,

&#x20;       DATE\_FORMAT(record\_date, 'MMMM') AS month\_name,

&#x20;       QUARTER(record\_date) AS quarter,

&#x20;       YEAR(record\_date) AS year,



&#x20;       CONCAT\_WS(', ',

&#x20;           CASE WHEN heart\_rate IS NOT NULL AND NOT heart\_rate BETWEEN 30 AND 220 THEN 'invalid\_heart\_rate\_nulled' END,

&#x20;           CASE WHEN blood\_pressure\_sys IS NOT NULL AND NOT blood\_pressure\_sys BETWEEN 70 AND 200 THEN 'invalid\_blood\_pressure\_sys\_nulled' END,

&#x20;           CASE WHEN blood\_pressure\_dia IS NOT NULL AND NOT blood\_pressure\_dia BETWEEN 40 AND 130 THEN 'invalid\_blood\_pressure\_dia\_nulled' END,

&#x20;           CASE WHEN oxygen\_level IS NOT NULL AND NOT oxygen\_level BETWEEN 0 AND 100 THEN 'invalid\_oxygen\_level\_nulled' END,

&#x20;           CASE WHEN body\_temp IS NOT NULL AND NOT body\_temp BETWEEN 90 AND 110 THEN 'invalid\_body\_temp\_nulled' END,

&#x20;           CASE WHEN respiration\_rate IS NOT NULL AND NOT respiration\_rate BETWEEN 5 AND 60 THEN 'invalid\_respiration\_rate\_nulled' END,

&#x20;           CASE WHEN glucose\_level IS NOT NULL AND NOT glucose\_level BETWEEN 40 AND 500 THEN 'invalid\_glucose\_level\_nulled' END,

&#x20;           CASE WHEN cholesterol IS NOT NULL AND NOT cholesterol BETWEEN 50 AND 500 THEN 'invalid\_cholesterol\_nulled' END,

&#x20;           CASE WHEN bmi IS NOT NULL AND NOT bmi BETWEEN 10 AND 80 THEN 'invalid\_bmi\_nulled' END,

&#x20;           CASE WHEN stress\_index IS NOT NULL AND NOT stress\_index BETWEEN 0 AND 100 THEN 'invalid\_stress\_index\_nulled' END

&#x20;       ) AS data\_quality\_flag,



&#x20;       \_ingested\_at,

&#x20;       \_source\_file



&#x20;   FROM source\_data

&#x20;   WHERE patient\_id IS NOT NULL

&#x20;     AND hospital\_name IS NOT NULL

&#x20;     AND record\_date IS NOT NULL

),



deduped AS (

&#x20;   SELECT

&#x20;       \*,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY patient\_id, hospital\_name, record\_date

&#x20;           ORDER BY \_ingested\_at DESC

&#x20;       ) AS rn

&#x20;   FROM validated

),



patient\_lookup AS (

&#x20;   SELECT patient\_id

&#x20;   FROM {{ ref('silver\_patient\_demographics') }}

&#x20;   GROUP BY patient\_id

),



hospital\_lookup AS (

&#x20;   SELECT

&#x20;       hospital\_name,

&#x20;       MAX(hospital\_id) AS hospital\_id

&#x20;   FROM {{ ref('silver\_hospital\_info') }}

&#x20;   GROUP BY hospital\_name

),



with\_dimensions AS (

&#x20;   SELECT

&#x20;       v.\*,

&#x20;       p.patient\_id AS resolved\_patient\_id,

&#x20;       h.hospital\_id AS resolved\_hospital\_id

&#x20;   FROM deduped v

&#x20;   LEFT JOIN patient\_lookup p

&#x20;       ON v.patient\_id = p.patient\_id

&#x20;   LEFT JOIN hospital\_lookup h

&#x20;       ON v.hospital\_name = h.hospital\_name

)



SELECT

&#x20;   patient\_id,

&#x20;   resolved\_hospital\_id AS hospital\_id,

&#x20;   patient\_name,

&#x20;   hospital\_name,

&#x20;   record\_date,

&#x20;   day,

&#x20;   month,

&#x20;   month\_name,

&#x20;   quarter,

&#x20;   year,

&#x20;   device\_type,

&#x20;   heart\_rate,

&#x20;   blood\_pressure\_sys,

&#x20;   blood\_pressure\_dia,

&#x20;   oxygen\_level,

&#x20;   body\_temp,

&#x20;   respiration\_rate,

&#x20;   glucose\_level,

&#x20;   cholesterol,

&#x20;   bmi,

&#x20;   stress\_index,

&#x20;   NULLIF(CONCAT\_WS(', ',

&#x20;       data\_quality\_flag,

&#x20;       CASE WHEN resolved\_patient\_id IS NULL THEN 'orphan\_patient\_reference' END,

&#x20;       CASE WHEN resolved\_hospital\_id IS NULL THEN 'orphan\_hospital\_reference' END

&#x20;   ), '') AS data\_quality\_flag,

&#x20;   \_ingested\_at,

&#x20;   \_source\_file

FROM with\_dimensions

WHERE rn = 1

&#x20; AND resolved\_patient\_id IS NOT NULL

&#x20; AND resolved\_hospital\_id IS NOT NULL
