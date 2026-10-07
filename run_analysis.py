"""Run every SQL file in sql/ against the raw CSVs and export results + charts.

Usage:  python run_analysis.py
The SQL does the analysis; this script only executes it and draws the charts.
"""
from pathlib import Path

import duckdb
import matplotlib.pyplot as plt

ROOT = Path(__file__).parent
SQL_DIR, RESULTS_DIR, CHARTS_DIR = ROOT / "sql", ROOT / "results", ROOT / "charts"

ROLE_ORDER = [
    "Senior Data Scientist", "Senior Data Engineer", "Data Scientist",
    "Data Engineer", "Machine Learning Engineer", "Senior Data Analyst",
    "Software Engineer", "Cloud Engineer", "Data Analyst", "Business Analyst",
]
BAR_COLOR = "#2a6fdb"


def run_queries(con):
    results = {}
    for path in sorted(SQL_DIR.glob("*.sql")):
        sql = path.read_text()
        if path.name.startswith("0_"):
            print(f"Loading data with {path.name} ...")
            con.execute(sql)
            continue
        print(f"Running {path.name} ...")
        df = con.sql(sql).df()
        df.to_csv(RESULTS_DIR / f"{path.stem}.csv", index=False)
        results[path.stem] = df
    return results


def chart_avg_salary(df):
    df = df.sort_values("avg_salary")
    fig, ax = plt.subplots(figsize=(9, 5.5))
    ax.barh(df["role"], df["avg_salary"], color=BAR_COLOR)
    for y, v in enumerate(df["avg_salary"]):
        ax.text(v + 1500, y, f"${v/1000:,.0f}K", va="center", fontsize=9)
    ax.set_title("Average yearly salary by role", loc="left", fontweight="bold")
    ax.set_xlabel("Average salary (USD)")
    ax.xaxis.set_major_formatter(lambda x, _: f"${x/1000:,.0f}K")
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(CHARTS_DIR / "1_avg_salary_by_role.png", dpi=150)
    plt.close(fig)


def chart_small_multiples(df, value_col, title, fmt, filename):
    roles = [r for r in ROLE_ORDER if r in set(df["role"])]
    ncols = 2
    nrows = -(-len(roles) // ncols)
    fig, axes = plt.subplots(nrows, ncols, figsize=(12, 3.0 * nrows))
    for ax, role in zip(axes.flat, roles):
        sub = df[df["role"] == role].head(10).iloc[::-1]
        ax.barh(sub["skill"], sub[value_col], color=BAR_COLOR)
        ax.set_title(role, loc="left", fontsize=11, fontweight="bold")
        ax.xaxis.set_major_formatter(lambda x, _: fmt(x))
        ax.tick_params(labelsize=8)
        ax.spines[["top", "right"]].set_visible(False)
    for ax in list(axes.flat)[len(roles):]:
        ax.axis("off")
    fig.suptitle(title, x=0.01, ha="left", fontsize=14, fontweight="bold")
    fig.tight_layout()
    fig.savefig(CHARTS_DIR / filename, dpi=150)
    plt.close(fig)


def main():
    RESULTS_DIR.mkdir(exist_ok=True)
    CHARTS_DIR.mkdir(exist_ok=True)
    con = duckdb.connect()
    results = run_queries(con)

    chart_avg_salary(results["1_avg_salary_by_role"])
    chart_small_multiples(
        results["2_top_skills_by_role"], "pct_of_postings",
        "Top 10 most in-demand skills by role (% of postings)",
        lambda x: f"{x:.0f}%", "2_top_skills_by_role.png",
    )
    chart_small_multiples(
        results["3_top_paying_skills_by_role"], "avg_salary",
        "Top 10 highest-paying skills by role (avg yearly salary, min. 30 postings)",
        lambda x: f"${x/1000:,.0f}K", "3_top_paying_skills_by_role.png",
    )
    print("Done. See results/ and charts/.")


if __name__ == "__main__":
    main()
