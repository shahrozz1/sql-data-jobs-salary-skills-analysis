/*
================================================================================
 2. Which skills are most in demand for each role?
================================================================================
 Approach
   - Join every posting to the skills it lists (fact -> bridge -> dimension).
   - Count postings per (role, skill) and express it as a share of all postings
     for that role, so roles of different sizes can be compared fairly.
   - Keep the top 10 skills per role with a window function.

 Key insight
   SQL is the #1 skill for every analyst and data-engineering role (47-61%
   of postings); Python leads for scientist, ML and software roles.

 SQL concepts: CTEs, multi-table INNER JOINs, COUNT(DISTINCT), window functions
               (ROW_NUMBER with PARTITION BY), filtering on a window result
================================================================================
*/

WITH role_totals AS (
    -- Denominator: how many postings exist for each role
    SELECT
        job_title_short,
        COUNT(*) AS total_postings
    FROM job_postings_fact
    GROUP BY job_title_short
),

skill_counts AS (
    -- Numerator: how many of those postings mention each skill
    SELECT
        jp.job_title_short,
        s.skills                    AS skill,
        COUNT(DISTINCT jp.job_id)   AS postings_with_skill
    FROM job_postings_fact AS jp
    INNER JOIN skills_job_dim AS sj ON jp.job_id   = sj.job_id
    INNER JOIN skills_dim     AS s  ON sj.skill_id = s.skill_id
    GROUP BY jp.job_title_short, s.skills
),

ranked AS (
    SELECT
        sc.job_title_short                                            AS role,
        sc.skill,
        sc.postings_with_skill,
        ROUND(100.0 * sc.postings_with_skill / rt.total_postings, 1)  AS pct_of_postings,
        ROW_NUMBER() OVER (
            PARTITION BY sc.job_title_short
            ORDER BY sc.postings_with_skill DESC
        )                                                             AS demand_rank
    FROM skill_counts AS sc
    INNER JOIN role_totals AS rt ON sc.job_title_short = rt.job_title_short
)

SELECT role, demand_rank, skill, postings_with_skill, pct_of_postings
FROM ranked
WHERE demand_rank <= 10
ORDER BY role, demand_rank;
