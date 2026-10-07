/*
================================================================================
 3. Which skills are the most financially rewarding for each role?
================================================================================
 Approach
   - Restrict to postings with a published yearly salary.
   - Average the salary of every posting that lists a given skill, per role.
   - HAVING COUNT(*) >= 30 removes niche skills whose average is based on a
     handful of postings (otherwise one outlier job dominates the ranking).
   - RANK() per role keeps the 10 best-paying skills for each role.

 Key insight
   Top-paying skills are big-data / engineering tools (Kafka, Scala, Spark,
   Airflow, NoSQL stores) - even for analysts, they carry a $19K-$36K premium.

 SQL concepts: CTEs, JOINs, GROUP BY + HAVING, RANK() OVER (PARTITION BY ...)
================================================================================
*/

WITH skill_salaries AS (
    SELECT
        jp.job_title_short            AS role,
        s.skills                      AS skill,
        COUNT(*)                      AS salaried_postings,
        ROUND(AVG(jp.salary_year_avg), 0) AS avg_salary
    FROM job_postings_fact AS jp
    INNER JOIN skills_job_dim AS sj ON jp.job_id   = sj.job_id
    INNER JOIN skills_dim     AS s  ON sj.skill_id = s.skill_id
    WHERE jp.salary_year_avg IS NOT NULL
    GROUP BY jp.job_title_short, s.skills
    HAVING COUNT(*) >= 30
),

ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY role ORDER BY avg_salary DESC) AS pay_rank
    FROM skill_salaries
)

SELECT role, pay_rank, skill, avg_salary, salaried_postings
FROM ranked
WHERE pay_rank <= 10
ORDER BY role, pay_rank;
