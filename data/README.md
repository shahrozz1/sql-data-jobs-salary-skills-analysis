# Data

The raw CSVs are not committed (the fact table is ~130 MB, above GitHub's file limit).
Place these four files in this folder before running `python run_analysis.py`:

| File | Rows | Description |
|---|---:|---|
| `job_postings_fact.csv` | 787,686 | One row per job posting (title, location, salary, ...) |
| `company_dim.csv` | 140,033 | Hiring companies |
| `skills_dim.csv` | 259 | Skill names and categories |
| `skills_job_dim.csv` | 3,669,604 | Which skills each posting asks for |

Source: 2023 data-job postings dataset from Luke Barousse's SQL course
([lukebarousse.com/sql](https://lukebarousse.com/sql)).
