/*
================================================================================
 1. What is the average salary for each data role?
================================================================================
 Approach
   - Only postings that publish a yearly salary are used (salary_year_avg IS NOT NULL).
   - Mean AND median are reported: salaries are right-skewed, so the median is a
     more honest "typical" number while the mean shows the pull of top earners.
   - Sample size is shown so readers can judge how reliable each figure is.

 Key insight
   Senior Data Scientists top the list (~$154K avg); Data/Business Analysts
   sit near $90K. Seniority adds roughly $15K-$20K across every track.

 SQL concepts: aggregate functions, PERCENTILE_CONT ... WITHIN GROUP, WHERE vs NULLs,
               ROUND, ORDER BY
================================================================================
*/

SELECT
    job_title_short                                                AS role,
    COUNT(*)                                                       AS salaried_postings,
    ROUND(AVG(salary_year_avg), 0)                                 AS avg_salary,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_year_avg), 0)
                                                                   AS median_salary,
    ROUND(MIN(salary_year_avg), 0)                                 AS min_salary,
    ROUND(MAX(salary_year_avg), 0)                                 AS max_salary
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL
GROUP BY job_title_short
ORDER BY avg_salary DESC;
