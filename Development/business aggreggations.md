**gold\_cost\_analysis.sql**



{{ config(materialized='table', schema='gold') }}



SELECT

&#x20;   hospital\_id,

&#x20;   hospital\_name,

&#x20;   hospital\_city,

&#x20;   hospital\_state,

&#x20;   diagnosis\_code,

&#x20;   COUNT(\*) AS observation\_count,

&#x20;   COUNT(DISTINCT patient\_id) AS patient\_count,

&#x20;   ROUND(SUM(treatment\_cost), 2) AS total\_treatment\_cost,

&#x20;   ROUND(SUM(total\_test\_cost), 2) AS total\_test\_cost,

&#x20;   ROUND(SUM(insurance\_claim), 2) AS total\_insurance\_claim,

&#x20;   ROUND(AVG(treatment\_cost), 2) AS avg\_treatment\_cost,

&#x20;   ROUND(AVG(total\_test\_cost), 2) AS avg\_test\_cost,

&#x20;   ROUND(AVG(insurance\_claim), 2) AS avg\_insurance\_claim,

&#x20;   ROUND(AVG(patient\_risk\_score), 4) AS avg\_patient\_risk\_score

FROM {{ ref('fact\_health\_metrics') }}

GROUP BY

&#x20;   hospital\_id,

&#x20;   hospital\_name,

&#x20;   hospital\_city,

&#x20;   hospital\_state,

&#x20;   diagnosis\_code





**gold\_hospital\_performance\_scorecard**

{{ config(materialized='table', schema='gold') }}



SELECT

&#x20;   hospital\_id,

&#x20;   hospital\_name,

&#x20;   hospital\_city,

&#x20;   hospital\_state,

&#x20;   COUNT(\*) AS observation\_count,

&#x20;   COUNT(DISTINCT patient\_id) AS patient\_count,

&#x20;   ROUND(AVG(infection\_rate), 4) AS avg\_infection\_rate,

&#x20;   ROUND(AVG(utilization\_rate), 4) AS avg\_utilization\_rate,

&#x20;   ROUND(AVG(avg\_wait\_time), 4) AS avg\_wait\_time,

&#x20;   ROUND(AVG(equipment\_score), 4) AS avg\_equipment\_score,

&#x20;   ROUND(AVG(patient\_load), 4) AS avg\_patient\_load,

&#x20;   SUM(surgery\_count) AS total\_surgery\_count,

&#x20;   SUM(emergency\_cases) AS total\_emergency\_cases,

&#x20;   ROUND(AVG(patient\_risk\_score), 4) AS avg\_patient\_risk\_score

FROM {{ ref('fact\_health\_metrics') }}

GROUP BY

&#x20;   hospital\_id,

&#x20;   hospital\_name,

&#x20;   hospital\_city,

&#x20;   hospital\_state





**gold\_lab\_abnormality\_rate**

{{ config(materialized='table', schema='gold') }}



WITH lab\_flags AS (

&#x20;   SELECT

&#x20;       l.lab\_test\_name,

&#x20;       l.patient\_id,

&#x20;       l.hospital\_id,

&#x20;       l.record\_date,

&#x20;       CASE WHEN l.data\_quality\_flag IS NOT NULL THEN 1 ELSE 0 END AS is\_abnormal\_lab

&#x20;   FROM {{ ref('silver\_lab\_results') }} l

)



SELECT

&#x20;   lab\_test\_name,

&#x20;   COUNT(\*) AS lab\_observation\_count,

&#x20;   COUNT(DISTINCT patient\_id) AS patient\_count,

&#x20;   SUM(is\_abnormal\_lab) AS abnormal\_lab\_count,

&#x20;   ROUND((SUM(is\_abnormal\_lab) / COUNT(\*)) \* 100, 2) AS abnormal\_lab\_percentage

FROM lab\_flags

GROUP BY lab\_test\_name





**gold\_lifestyle\_health\_correlation**

{{ config(materialized='table', schema='gold') }}



SELECT

&#x20;   age\_group,

&#x20;   gender,

&#x20;   COUNT(\*) AS observation\_count,

&#x20;   COUNT(DISTINCT patient\_id) AS patient\_count,

&#x20;   ROUND(AVG(smoking\_index), 4) AS avg\_smoking\_index,

&#x20;   ROUND(AVG(alcohol\_index), 4) AS avg\_alcohol\_index,

&#x20;   ROUND(AVG(exercise\_hours), 4) AS avg\_exercise\_hours,

&#x20;   ROUND(AVG(sleep\_hours), 4) AS avg\_sleep\_hours,

&#x20;   ROUND(AVG(diet\_score), 4) AS avg\_diet\_score,

&#x20;   ROUND(AVG(lifestyle\_risk), 4) AS avg\_lifestyle\_risk,

&#x20;   ROUND(AVG(health\_score), 4) AS avg\_health\_score,

&#x20;   ROUND(AVG(risk\_probability), 4) AS avg\_risk\_probability,

&#x20;   ROUND(AVG(patient\_risk\_score), 4) AS avg\_patient\_risk\_score

FROM {{ ref('fact\_health\_metrics') }}

GROUP BY age\_group, gender







**gold\_monthly\_quarterly\_trend**

{{ config(materialized='table', schema='gold') }}



SELECT

&#x20;   year,

&#x20;   quarter,

&#x20;   month,

&#x20;   month\_name,

&#x20;   COUNT(\*) AS observation\_count,

&#x20;   COUNT(DISTINCT patient\_id) AS patient\_count,

&#x20;   ROUND(AVG(risk\_probability), 4) AS avg\_risk\_probability,

&#x20;   ROUND(AVG(severity\_score), 4) AS avg\_severity\_score,

&#x20;   ROUND(AVG(patient\_risk\_score), 4) AS avg\_patient\_risk\_score,

&#x20;   ROUND(SUM(treatment\_cost), 2) AS total\_treatment\_cost,

&#x20;   ROUND(SUM(total\_test\_cost), 2) AS total\_test\_cost,

&#x20;   ROUND(SUM(insurance\_claim), 2) AS total\_insurance\_claim

FROM {{ ref('fact\_health\_metrics') }}

GROUP BY

&#x20;   year,

&#x20;   quarter,

&#x20;   month,

&#x20;   month\_name



**gold\_patient\_risk\_summary**

{{ config(materialized='table', schema='gold') }}



SELECT

&#x20;   age\_group,

&#x20;   gender,

&#x20;   COUNT(\*) AS observation\_count,

&#x20;   COUNT(DISTINCT patient\_id) AS patient\_count,

&#x20;   ROUND(AVG(risk\_probability), 4) AS avg\_risk\_probability,

&#x20;   ROUND(AVG(severity\_score), 4) AS avg\_severity\_score,

&#x20;   ROUND(AVG(patient\_risk\_score), 4) AS avg\_patient\_risk\_score,

&#x20;   ROUND(MAX(patient\_risk\_score), 4) AS max\_patient\_risk\_score

FROM {{ ref('fact\_health\_metrics') }}

GROUP BY age\_group, gender





**gold\_readmission\_risk\_distribution**

{{ config(materialized='table', schema='gold') }}



WITH grouped AS (

&#x20;   SELECT

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       readmission\_risk,

&#x20;       COUNT(\*) AS observation\_count,

&#x20;       COUNT(DISTINCT patient\_id) AS patient\_count

&#x20;   FROM {{ ref('fact\_health\_metrics') }}

&#x20;   GROUP BY

&#x20;       hospital\_id,

&#x20;       hospital\_name,

&#x20;       readmission\_risk

),



with\_totals AS (

&#x20;   SELECT

&#x20;       \*,

&#x20;       SUM(patient\_count) OVER (

&#x20;           PARTITION BY hospital\_id, hospital\_name

&#x20;       ) AS total\_patients\_by\_hospital

&#x20;   FROM grouped

)



SELECT

&#x20;   hospital\_id,

&#x20;   hospital\_name,

&#x20;   readmission\_risk,

&#x20;   observation\_count,

&#x20;   patient\_count,

&#x20;   total\_patients\_by\_hospital,

&#x20;   ROUND((patient\_count / total\_patients\_by\_hospital) \* 100, 2) AS patient\_percentage

FROM with\_totals





**gold\_vitals\_trend\_analysis**

{{ config(materialized='table', schema='gold') }}



SELECT

&#x20;   age\_group,

&#x20;   year,

&#x20;   quarter,

&#x20;   month,

&#x20;   month\_name,

&#x20;   COUNT(\*) AS observation\_count,

&#x20;   COUNT(DISTINCT patient\_id) AS patient\_count,

&#x20;   ROUND(AVG(avg\_heart\_rate), 4) AS avg\_heart\_rate,

&#x20;   ROUND(AVG(avg\_cholesterol), 4) AS avg\_cholesterol,

&#x20;   ROUND(AVG(avg\_bmi), 4) AS avg\_bmi,

&#x20;   ROUND(AVG(avg\_glucose\_level), 4) AS avg\_glucose\_level,

&#x20;   ROUND(AVG(avg\_blood\_pressure\_sys), 4) AS avg\_blood\_pressure\_sys,

&#x20;   ROUND(AVG(avg\_blood\_pressure\_dia), 4) AS avg\_blood\_pressure\_dia,

&#x20;   ROUND(AVG(avg\_oxygen\_level), 4) AS avg\_oxygen\_level,

&#x20;   ROUND(AVG(patient\_risk\_score), 4) AS avg\_patient\_risk\_score

FROM {{ ref('fact\_health\_metrics') }}

GROUP BY

&#x20;   age\_group,

&#x20;   year,

&#x20;   quarter,

&#x20;   month,

&#x20;   month\_name
