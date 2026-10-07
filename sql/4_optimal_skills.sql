/*
================================================================================
 4. What are the optimal skills to learn for each role (high demand AND high pay)?
================================================================================
 Approach
   - A skill that pays well but appears in 0.5% of postings is not a great bet,
     and a skill everyone asks for may not move salary. This query combines both.
   - demand  CTE: share of the role's postings that list the skill.
   - pay     CTE: average salary of the role's salaried postings listing the skill.
   - Keep skills requested in at least 10% of the role's postings, then rank them
     by salary premium vs. the role's overall average salary.

 Key insight
   For Data Analysts, Python is the best demand x pay bet (+$7.6K vs. role
   average); SQL is the baseline everyone expects; Excel and Power BI pay below average.

 SQL concepts: multiple CTEs, LEFT/INNER JOINs between CTEs, scalar comparisons
               against a per-group baseline, CASE, ROW_NUMBER()
================================================================================
*/

WITH role_baseline AS (
    SELECT
        job_title_short,
        COUNT(*)                                                AS total_postings,
        AVG(salary_year_avg)                                    AS role_avg_salary
    FROM job_postings_fact
    GROUP BY job_title_short
),

demand AS (
    SELECT
        jp.job_title_short,
        sj.skill_id,
        COUNT(*) AS postings_with_skill
    FROM job_postings_fact AS jp
    INNER JOIN skills_job_dim AS sj ON jp.job_id = sj.job_id
    GROUP BY jp.job_title_short, sj.skill_id
),

pay AS (
    SELECT
        jp.job_title_short,
        sj.skill_id,
        COUNT(*)                 AS salaried_postings,
        AVG(jp.salary_year_avg)  AS skill_avg_salary
    FROM job_postings_fact AS jp
    INNER JOIN skills_job_dim AS sj ON jp.job_id = sj.job_id
    WHERE jp.salary_year_avg IS NOT NULL
    GROUP BY jp.job_title_short, sj.skill_id
    HAVING COUNT(*) >= 30
),

scored AS (
    SELECT
        d.job_title_short                                                AS role,
        s.skills                                                         AS skill,
        ROUND(100.0 * d.postings_with_skill / b.total_postings, 1)       AS pct_of_postings,
        ROUND(p.skill_avg_salary, 0)                                     AS avg_salary,
        ROUND(p.skill_avg_salary - b.role_avg_salary, 0)                 AS salary_premium,
        CASE
            WHEN p.skill_avg_salary >= b.role_avg_salary THEN 'pays above role average'
            ELSE 'pays below role average'
        END                                                              AS verdict
    FROM demand AS d
    INNER JOIN pay           AS p ON d.job_title_short = p.job_title_short
                                 AND d.skill_id        = p.skill_id
    INNER JOIN role_baseline AS b ON d.job_title_short = b.job_title_short
    INNER JOIN skills_dim    AS s ON d.skill_id        = s.skill_id
    WHERE 100.0 * d.postings_with_skill / b.total_postings >= 10
)

SELECT *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY role ORDER BY avg_salary DESC) AS optimal_rank
    FROM scored
) AS t
WHERE optimal_rank <= 5
ORDER BY role, optimal_rank;
