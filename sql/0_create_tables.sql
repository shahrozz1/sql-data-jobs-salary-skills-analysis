/*
================================================================================
 0. Create the star schema and load the raw CSVs
================================================================================
 Data model
   job_postings_fact  (fact)   one row per job posting
   company_dim        (dim)    one row per hiring company
   skills_dim         (dim)    one row per skill (e.g. sql, python, aws)
   skills_job_dim     (bridge) many-to-many link between postings and skills

 Written in PostgreSQL-compatible SQL. The same script runs in DuckDB, which is
 what run_analysis.py uses so the project can be reproduced without a server.
 (In psql, swap COPY for \copy if the CSVs live on your local machine.)
================================================================================
*/

DROP TABLE IF EXISTS skills_job_dim;
DROP TABLE IF EXISTS job_postings_fact;
DROP TABLE IF EXISTS skills_dim;
DROP TABLE IF EXISTS company_dim;

CREATE TABLE company_dim (
    company_id   INT PRIMARY KEY,
    name         TEXT,
    link         TEXT,
    link_google  TEXT,
    thumbnail    TEXT
);

CREATE TABLE skills_dim (
    skill_id  INT PRIMARY KEY,
    skills    TEXT,
    type      TEXT
);

CREATE TABLE job_postings_fact (
    job_id                 INT PRIMARY KEY,
    company_id             INT REFERENCES company_dim (company_id),
    job_title_short        VARCHAR(255),
    job_title              TEXT,
    job_location           TEXT,
    job_via                TEXT,
    job_schedule_type      TEXT,
    job_work_from_home     BOOLEAN,
    search_location        TEXT,
    job_posted_date        TIMESTAMP,
    job_no_degree_mention  BOOLEAN,
    job_health_insurance   BOOLEAN,
    job_country            TEXT,
    salary_rate            VARCHAR(255),
    salary_year_avg        NUMERIC,
    salary_hour_avg        NUMERIC
);

CREATE TABLE skills_job_dim (
    job_id    INT REFERENCES job_postings_fact (job_id),
    skill_id  INT REFERENCES skills_dim (skill_id),
    PRIMARY KEY (job_id, skill_id)
);

-- Load order matters: dimensions first, then the fact table, then the bridge.
COPY company_dim       FROM 'data/company_dim.csv'       WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"');
COPY skills_dim        FROM 'data/skills_dim.csv'        WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"');
COPY job_postings_fact FROM 'data/job_postings_fact.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"');
COPY skills_job_dim    FROM 'data/skills_job_dim.csv'    WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ESCAPE '"');

-- Helpful indexes for the joins used throughout the analysis
CREATE INDEX idx_postings_title   ON job_postings_fact (job_title_short);
CREATE INDEX idx_skills_job_skill ON skills_job_dim (skill_id);
