

**dim\_date.sql**

{{ config(materialized='table', schema='gold') }}



WITH all\_dates AS (

&#x20;   SELECT record\_date FROM {{ ref('silver\_patient\_demographics') }}

&#x20;   UNION

&#x20;   SELECT record\_date FROM {{ ref('silver\_hospital\_info') }}

&#x20;   UNION

&#x20;   SELECT record\_date FROM {{ ref('silver\_patient\_diagnosis') }}

&#x20;   UNION

&#x20;   SELECT record\_date FROM {{ ref('silver\_lab\_results') }}

&#x20;   UNION

&#x20;   SELECT record\_date FROM {{ ref('silver\_patient\_vitals') }}

),



deduped AS (

&#x20;   SELECT DISTINCT record\_date

&#x20;   FROM all\_dates

&#x20;   WHERE record\_date IS NOT NULL

)



SELECT

&#x20;   CAST(DATE\_FORMAT(record\_date, 'yyyyMMdd') AS INT) AS date\_key,

&#x20;   record\_date,

&#x20;   DAY(record\_date) AS day,

&#x20;   MONTH(record\_date) AS month,

&#x20;   DATE\_FORMAT(record\_date, 'MMMM') AS month\_name,

&#x20;   QUARTER(record\_date) AS quarter,

&#x20;   YEAR(record\_date) AS year,

&#x20;   DATE\_FORMAT(record\_date, 'E') AS day\_name,

&#x20;   CASE

&#x20;       WHEN DATE\_FORMAT(record\_date, 'E') IN ('Sat', 'Sun') THEN true

&#x20;       ELSE false

&#x20;   END AS is\_weekend

FROM deduped





**dim\_hospital.sql**

{{ config(materialized='table', schema='gold') }}



WITH ranked\_hospitals AS (

&#x20;   SELECT

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       city,

&#x20;       state,

&#x20;       bed\_capacity,

&#x20;       icu\_beds,

&#x20;       staff\_count,

&#x20;       infection\_rate,

&#x20;       utilization\_rate,

&#x20;       avg\_wait\_time,

&#x20;       equipment\_score,

&#x20;       patient\_load,

&#x20;       surgery\_count,

&#x20;       emergency\_cases,

&#x20;       record\_date,

&#x20;       \_ingested\_at,

&#x20;       \_source\_file,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY hospital\_id

&#x20;           ORDER BY record\_date DESC, \_ingested\_at DESC

&#x20;       ) AS rn

&#x20;   FROM {{ ref('silver\_hospital\_info') }}

)



SELECT

&#x20;   SHA2(CAST(hospital\_id AS STRING), 256) AS hospital\_key,

&#x20;   hospital\_id,

&#x20;   hospital\_name,

&#x20;   city,

&#x20;   state,

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

&#x20;   record\_date AS latest\_record\_date,

&#x20;   \_ingested\_at,

&#x20;   \_source\_file

FROM ranked\_hospitals

WHERE rn = 1





**dim\_observations.sql**

{{ config(materialized='table', schema='gold') }}



WITH diagnosis\_observations AS (

&#x20;   SELECT DISTINCT

&#x20;       patient\_id,

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       record\_date,

&#x20;       diagnosis\_code,

&#x20;       doctor\_name,

&#x20;       CAST(NULL AS STRING) AS lab\_test\_name,

&#x20;       CAST(NULL AS STRING) AS technician\_name,

&#x20;       CAST(NULL AS STRING) AS device\_type,

&#x20;       'DIAGNOSIS' AS observation\_type

&#x20;   FROM {{ ref('silver\_patient\_diagnosis') }}

),



lab\_observations AS (

&#x20;   SELECT DISTINCT

&#x20;       patient\_id,

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       record\_date,

&#x20;       CAST(NULL AS STRING) AS diagnosis\_code,

&#x20;       CAST(NULL AS STRING) AS doctor\_name,

&#x20;       lab\_test\_name,

&#x20;       technician\_name,

&#x20;       CAST(NULL AS STRING) AS device\_type,

&#x20;       'LAB' AS observation\_type

&#x20;   FROM {{ ref('silver\_lab\_results') }}

),



vital\_observations AS (

&#x20;   SELECT DISTINCT

&#x20;       patient\_id,

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       record\_date,

&#x20;       CAST(NULL AS STRING) AS diagnosis\_code,

&#x20;       CAST(NULL AS STRING) AS doctor\_name,

&#x20;       CAST(NULL AS STRING) AS lab\_test\_name,

&#x20;       CAST(NULL AS STRING) AS technician\_name,

&#x20;       device\_type,

&#x20;       'VITAL' AS observation\_type

&#x20;   FROM {{ ref('silver\_patient\_vitals') }}

),



combined AS (

&#x20;   SELECT \* FROM diagnosis\_observations

&#x20;   UNION

&#x20;   SELECT \* FROM lab\_observations

&#x20;   UNION

&#x20;   SELECT \* FROM vital\_observations

)



SELECT

&#x20;   SHA2(

&#x20;       CONCAT\_WS('|',

&#x20;           patient\_id,

&#x20;           hospital\_id,

&#x20;           CAST(record\_date AS STRING),

&#x20;           COALESCE(diagnosis\_code, ''),

&#x20;           COALESCE(lab\_test\_name, ''),

&#x20;           COALESCE(device\_type, ''),

&#x20;           observation\_type

&#x20;       ),

&#x20;       256

&#x20;   ) AS observation\_key,

&#x20;   patient\_id,

&#x20;   hospital\_id,

&#x20;   hospital\_name,

&#x20;   record\_date,

&#x20;   diagnosis\_code,

&#x20;   doctor\_name,

&#x20;   lab\_test\_name,

&#x20;   technician\_name,

&#x20;   device\_type,

&#x20;   observation\_type

FROM combined



**dim\_patients.sql**

{{ config(materialized='table', schema='gold') }}



WITH ranked\_patients AS (

&#x20;   SELECT

&#x20;       patient\_id,

&#x20;       patient\_name,

&#x20;       gender,

&#x20;       city,

&#x20;       age,

&#x20;       CASE

&#x20;           WHEN age < 18 THEN '0-17'

&#x20;           WHEN age BETWEEN 18 AND 35 THEN '18-35'

&#x20;           WHEN age BETWEEN 36 AND 50 THEN '36-50'

&#x20;           WHEN age BETWEEN 51 AND 65 THEN '51-65'

&#x20;           WHEN age > 65 THEN '65+'

&#x20;           ELSE 'Unknown'

&#x20;       END AS age\_group,

&#x20;       income\_index,

&#x20;       health\_score,

&#x20;       lifestyle\_risk,

&#x20;       exercise\_hours,

&#x20;       sleep\_hours,

&#x20;       alcohol\_index,

&#x20;       smoking\_index,

&#x20;       diet\_score,

&#x20;       insurance\_score,

&#x20;       record\_date,

&#x20;       \_ingested\_at,

&#x20;       \_source\_file,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY patient\_id

&#x20;           ORDER BY record\_date DESC, \_ingested\_at DESC

&#x20;       ) AS rn

&#x20;   FROM {{ ref('silver\_patient\_demographics') }}

)



SELECT

&#x20;   SHA2(CAST(patient\_id AS STRING), 256) AS patient\_key,

&#x20;   patient\_id,

&#x20;   patient\_name,

&#x20;   gender,

&#x20;   city,

&#x20;   age,

&#x20;   age\_group,

&#x20;   income\_index,

&#x20;   health\_score,

&#x20;   lifestyle\_risk,

&#x20;   exercise\_hours,

&#x20;   sleep\_hours,

&#x20;   alcohol\_index,

&#x20;   smoking\_index,

&#x20;   diet\_score,

&#x20;   insurance\_score,

&#x20;   record\_date AS latest\_record\_date,

&#x20;   \_ingested\_at,

&#x20;   \_source\_file

FROM ranked\_patients

WHERE rn = 1



**fact\_health\_metrics.sql**



{{ config(materialized='table', schema='gold') }}



WITH diagnosis AS (

&#x20;   SELECT

&#x20;       patient\_id,

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       record\_date,

&#x20;       diagnosis\_code,

&#x20;       doctor\_name,

&#x20;       severity\_score,

&#x20;       risk\_probability,

&#x20;       readmission\_risk,

&#x20;       treatment\_cost,

&#x20;       insurance\_claim,

&#x20;       medication\_count,

&#x20;       visit\_duration,

&#x20;       procedure\_count,

&#x20;       recovery\_days,

&#x20;       comorbidity\_score,

&#x20;       data\_quality\_flag AS diagnosis\_quality\_flag

&#x20;   FROM {{ ref('silver\_patient\_diagnosis') }}

),



patient AS (

&#x20;   SELECT

&#x20;       patient\_key,

&#x20;       patient\_id,

&#x20;       age,

&#x20;       age\_group,

&#x20;       gender,

&#x20;       city,

&#x20;       lifestyle\_risk,

&#x20;       smoking\_index,

&#x20;       alcohol\_index,

&#x20;       health\_score,

&#x20;       exercise\_hours,

&#x20;       sleep\_hours,

&#x20;       diet\_score,

&#x20;       insurance\_score

&#x20;   FROM {{ ref('dim\_patient') }}

),



hospital AS (

&#x20;   SELECT

&#x20;       hospital\_key,

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       city AS hospital\_city,

&#x20;       state AS hospital\_state,

&#x20;       infection\_rate,

&#x20;       utilization\_rate,

&#x20;       avg\_wait\_time,

&#x20;       equipment\_score,

&#x20;       patient\_load,

&#x20;       surgery\_count,

&#x20;       emergency\_cases

&#x20;   FROM {{ ref('dim\_hospital') }}

),



date\_dim AS (

&#x20;   SELECT

&#x20;       date\_key,

&#x20;       record\_date,

&#x20;       day,

&#x20;       month,

&#x20;       month\_name,

&#x20;       quarter,

&#x20;       year

&#x20;   FROM {{ ref('dim\_date') }}

),



vitals AS (

&#x20;   SELECT

&#x20;       patient\_id,

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       record\_date,

&#x20;       AVG(heart\_rate) AS avg\_heart\_rate,

&#x20;       AVG(blood\_pressure\_sys) AS avg\_blood\_pressure\_sys,

&#x20;       AVG(blood\_pressure\_dia) AS avg\_blood\_pressure\_dia,

&#x20;       AVG(oxygen\_level) AS avg\_oxygen\_level,

&#x20;       AVG(body\_temp) AS avg\_body\_temp,

&#x20;       AVG(respiration\_rate) AS avg\_respiration\_rate,

&#x20;       AVG(glucose\_level) AS avg\_glucose\_level,

&#x20;       AVG(cholesterol) AS avg\_cholesterol,

&#x20;       AVG(bmi) AS avg\_bmi,

&#x20;       AVG(stress\_index) AS avg\_stress\_index,

&#x20;       MAX(CASE WHEN data\_quality\_flag IS NOT NULL THEN 1 ELSE 0 END) AS has\_vital\_quality\_flag

&#x20;   FROM {{ ref('silver\_patient\_vitals') }}

&#x20;   GROUP BY patient\_id, hospital\_id, hospital\_name, record\_date

),



labs AS (

&#x20;   SELECT

&#x20;       patient\_id,

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       record\_date,

&#x20;       AVG(hemoglobin) AS avg\_hemoglobin,

&#x20;       AVG(platelets) AS avg\_platelets,

&#x20;       AVG(wbc\_count) AS avg\_wbc\_count,

&#x20;       AVG(rbc\_count) AS avg\_rbc\_count,

&#x20;       AVG(creatinine) AS avg\_creatinine,

&#x20;       AVG(sodium) AS avg\_sodium,

&#x20;       AVG(potassium) AS avg\_potassium,

&#x20;       AVG(calcium) AS avg\_calcium,

&#x20;       AVG(bilirubin) AS avg\_bilirubin,

&#x20;       SUM(test\_cost) AS total\_test\_cost,

&#x20;       MAX(CASE WHEN data\_quality\_flag IS NOT NULL THEN 1 ELSE 0 END) AS has\_lab\_quality\_flag

&#x20;   FROM {{ ref('silver\_lab\_results') }}

&#x20;   GROUP BY patient\_id, hospital\_id, hospital\_name, record\_date

),



observation AS (

&#x20;   SELECT

&#x20;       observation\_key,

&#x20;       patient\_id,

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       record\_date,

&#x20;       diagnosis\_code,

&#x20;       doctor\_name

&#x20;   FROM {{ ref('dim\_observation') }}

&#x20;   WHERE observation\_type = 'DIAGNOSIS'

),



fact\_base AS (

&#x20;   SELECT

&#x20;       p.patient\_key,

&#x20;       h.hospital\_key,

&#x20;       dt.date\_key,

&#x20;       o.observation\_key,



&#x20;       d.patient\_id,

&#x20;       d.hospital\_id,

&#x20;       d.hospital\_name,

&#x20;       d.record\_date,

&#x20;       d.diagnosis\_code,

&#x20;       d.doctor\_name,



&#x20;       p.age,

&#x20;       p.age\_group,

&#x20;       p.gender,

&#x20;       p.city AS patient\_city,

&#x20;       p.lifestyle\_risk,

&#x20;       p.smoking\_index,

&#x20;       p.alcohol\_index,

&#x20;       p.health\_score,

&#x20;       p.exercise\_hours,

&#x20;       p.sleep\_hours,

&#x20;       p.diet\_score,

&#x20;       p.insurance\_score,



&#x20;       h.hospital\_city,

&#x20;       h.hospital\_state,

&#x20;       h.infection\_rate,

&#x20;       h.utilization\_rate,

&#x20;       h.avg\_wait\_time,

&#x20;       h.equipment\_score,

&#x20;       h.patient\_load,

&#x20;       h.surgery\_count,

&#x20;       h.emergency\_cases,



&#x20;       dt.day,

&#x20;       dt.month,

&#x20;       dt.month\_name,

&#x20;       dt.quarter,

&#x20;       dt.year,



&#x20;       d.severity\_score,

&#x20;       d.risk\_probability,

&#x20;       d.readmission\_risk,

&#x20;       d.treatment\_cost,

&#x20;       d.insurance\_claim,

&#x20;       d.medication\_count,

&#x20;       d.visit\_duration,

&#x20;       d.procedure\_count,

&#x20;       d.recovery\_days,

&#x20;       d.comorbidity\_score,



&#x20;       v.avg\_heart\_rate,

&#x20;       v.avg\_blood\_pressure\_sys,

&#x20;       v.avg\_blood\_pressure\_dia,

&#x20;       v.avg\_oxygen\_level,

&#x20;       v.avg\_body\_temp,

&#x20;       v.avg\_respiration\_rate,

&#x20;       v.avg\_glucose\_level,

&#x20;       v.avg\_cholesterol,

&#x20;       v.avg\_bmi,

&#x20;       v.avg\_stress\_index,

&#x20;       COALESCE(v.has\_vital\_quality\_flag, 0) AS has\_vital\_quality\_flag,



&#x20;       l.avg\_hemoglobin,

&#x20;       l.avg\_platelets,

&#x20;       l.avg\_wbc\_count,

&#x20;       l.avg\_rbc\_count,

&#x20;       l.avg\_creatinine,

&#x20;       l.avg\_sodium,

&#x20;       l.avg\_potassium,

&#x20;       l.avg\_calcium,

&#x20;       l.avg\_bilirubin,

&#x20;       COALESCE(l.total\_test\_cost, 0) AS total\_test\_cost,

&#x20;       COALESCE(l.has\_lab\_quality\_flag, 0) AS has\_lab\_quality\_flag,



&#x20;       d.diagnosis\_quality\_flag



&#x20;   FROM diagnosis d

&#x20;   INNER JOIN patient p

&#x20;       ON d.patient\_id = p.patient\_id

&#x20;   INNER JOIN hospital h

&#x20;       ON d.hospital\_id = h.hospital\_id

&#x20;   INNER JOIN date\_dim dt

&#x20;       ON d.record\_date = dt.record\_date

&#x20;   LEFT JOIN observation o

&#x20;       ON d.patient\_id = o.patient\_id

&#x20;      AND d.hospital\_id = o.hospital\_id

&#x20;      AND d.record\_date = o.record\_date

&#x20;      AND d.diagnosis\_code = o.diagnosis\_code

&#x20;   LEFT JOIN vitals v

&#x20;       ON d.patient\_id = v.patient\_id

&#x20;      AND d.hospital\_id = v.hospital\_id

&#x20;      AND d.record\_date = v.record\_date

&#x20;   LEFT JOIN labs l

&#x20;       ON d.patient\_id = l.patient\_id

&#x20;      AND d.hospital\_id = l.hospital\_id

&#x20;      AND d.record\_date = l.record\_date

),



final AS (

&#x20;   SELECT

&#x20;       SHA2(

&#x20;           CONCAT\_WS('|',

&#x20;               patient\_id,

&#x20;               hospital\_id,

&#x20;               CAST(record\_date AS STRING),

&#x20;               diagnosis\_code,

&#x20;               COALESCE(observation\_key, '')

&#x20;           ),

&#x20;           256

&#x20;       ) AS health\_metric\_key,



&#x20;       patient\_key,

&#x20;       hospital\_key,

&#x20;       date\_key,

&#x20;       observation\_key,



&#x20;       patient\_id,

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       record\_date,

&#x20;       diagnosis\_code,

&#x20;       doctor\_name,



&#x20;       age,

&#x20;       age\_group,

&#x20;       gender,

&#x20;       patient\_city,



&#x20;       hospital\_city,

&#x20;       hospital\_state,



&#x20;       day,

&#x20;       month,

&#x20;       month\_name,

&#x20;       quarter,

&#x20;       year,



&#x20;       severity\_score,

&#x20;       risk\_probability,

&#x20;       readmission\_risk,

&#x20;       treatment\_cost,

&#x20;       insurance\_claim,

&#x20;       medication\_count,

&#x20;       visit\_duration,

&#x20;       procedure\_count,

&#x20;       recovery\_days,

&#x20;       comorbidity\_score,



&#x20;       avg\_heart\_rate,

&#x20;       avg\_blood\_pressure\_sys,

&#x20;       avg\_blood\_pressure\_dia,

&#x20;       avg\_oxygen\_level,

&#x20;       avg\_body\_temp,

&#x20;       avg\_respiration\_rate,

&#x20;       avg\_glucose\_level,

&#x20;       avg\_cholesterol,

&#x20;       avg\_bmi,

&#x20;       avg\_stress\_index,



&#x20;       avg\_hemoglobin,

&#x20;       avg\_platelets,

&#x20;       avg\_wbc\_count,

&#x20;       avg\_rbc\_count,

&#x20;       avg\_creatinine,

&#x20;       avg\_sodium,

&#x20;       avg\_potassium,

&#x20;       avg\_calcium,

&#x20;       avg\_bilirubin,

&#x20;       total\_test\_cost,



&#x20;       infection\_rate,

&#x20;       utilization\_rate,

&#x20;       avg\_wait\_time,

&#x20;       equipment\_score,

&#x20;       patient\_load,

&#x20;       surgery\_count,

&#x20;       emergency\_cases,



&#x20;       lifestyle\_risk,

&#x20;       smoking\_index,

&#x20;       alcohol\_index,

&#x20;       health\_score,

&#x20;       exercise\_hours,

&#x20;       sleep\_hours,

&#x20;       diet\_score,

&#x20;       insurance\_score,



&#x20;       has\_vital\_quality\_flag,

&#x20;       has\_lab\_quality\_flag,



&#x20;       ROUND(

&#x20;           (

&#x20;               0.40 \* COALESCE(risk\_probability, 0)

&#x20;             + 0.25 \* COALESCE(severity\_score, 0)

&#x20;             + 0.15 \* COALESCE(comorbidity\_score / 100, 0)

&#x20;             + 0.10 \* COALESCE(lifestyle\_risk / 100, 0)

&#x20;             + 0.10 \* COALESCE((smoking\_index + alcohol\_index) / 2, 0)

&#x20;             + 0.05 \* CASE

&#x20;                   WHEN has\_vital\_quality\_flag = 1 OR has\_lab\_quality\_flag = 1 THEN 1

&#x20;                   ELSE 0

&#x20;               END

&#x20;           ),

&#x20;           4

&#x20;       ) AS patient\_risk\_score,



&#x20;       diagnosis\_quality\_flag



&#x20;   FROM fact\_base

),



deduped AS (

&#x20;   SELECT

&#x20;       \*,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY health\_metric\_key

&#x20;           ORDER BY record\_date DESC

&#x20;       ) AS rn

&#x20;   FROM final

)



SELECT

&#x20;   health\_metric\_key,

&#x20;   patient\_key,

&#x20;   hospital\_key,

&#x20;   date\_key,

&#x20;   observation\_key,

&#x20;   patient\_id,

&#x20;   hospital\_id,

&#x20;   hospital\_name,

&#x20;   record\_date,

&#x20;   diagnosis\_code,

&#x20;   doctor\_name,

&#x20;   age,

&#x20;   age\_group,

&#x20;   gender,

&#x20;   patient\_city,

&#x20;   hospital\_city,

&#x20;   hospital\_state,

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

&#x20;   avg\_heart\_rate,

&#x20;   avg\_blood\_pressure\_sys,

&#x20;   avg\_blood\_pressure\_dia,

&#x20;   avg\_oxygen\_level,

&#x20;   avg\_body\_temp,

&#x20;   avg\_respiration\_rate,

&#x20;   avg\_glucose\_level,

&#x20;   avg\_cholesterol,

&#x20;   avg\_bmi,

&#x20;   avg\_stress\_index,

&#x20;   avg\_hemoglobin,

&#x20;   avg\_platelets,

&#x20;   avg\_wbc\_count,

&#x20;   avg\_rbc\_count,

&#x20;   avg\_creatinine,

&#x20;   avg\_sodium,

&#x20;   avg\_potassium,

&#x20;   avg\_calcium,

&#x20;   avg\_bilirubin,

&#x20;   total\_test\_cost,

&#x20;   infection\_rate,

&#x20;   utilization\_rate,

&#x20;   avg\_wait\_time,

&#x20;   equipment\_score,

&#x20;   patient\_load,

&#x20;   surgery\_count,

&#x20;   emergency\_cases,

&#x20;   lifestyle\_risk,

&#x20;   smoking\_index,

&#x20;   alcohol\_index,

&#x20;   health\_score,

&#x20;   exercise\_hours,

&#x20;   sleep\_hours,

&#x20;   diet\_score,

&#x20;   insurance\_score,

&#x20;   has\_vital\_quality\_flag,

&#x20;   has\_lab\_quality\_flag,

&#x20;   patient\_risk\_score,

&#x20;   diagnosis\_quality\_flag

FROM deduped

WHERE rn = 1


