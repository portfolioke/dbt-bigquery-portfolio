# 📊 GA4 E-Commerce Analytics Engineering Project
### dbt + BigQuery | Star Schema Data Warehouse

<img width="400" alt="dbt + BigQuery" src="https://github.com/user-attachments/assets/d9307afa-3570-4fac-b0b9-06b81610e7f1" />

---

## 🧩 Business Problem

E-commerce companies collect massive amounts of raw behavioral data through Google Analytics 4. However, **raw GA4 data in BigQuery is notoriously difficult to query** — events are stored in nested, repeated records with one table per day, making it nearly impossible for analysts and business stakeholders to answer basic questions like:

- 📈 *Which traffic channels are driving the most revenue?*
- 🛒 *What is our conversion rate from session to purchase?*
- 🌍 *Which countries and devices generate the highest lifetime value?*
- 🔄 *How are our daily active users trending over time?*

This project solves that problem by building a **production-ready analytics data warehouse** on top of raw GA4 data using dbt and BigQuery — transforming messy, nested event data into a clean, queryable star schema that any analyst can use.

---

## 🏗️ Architecture Overview
```
Raw Source (BigQuery)
        │
        ▼
┌─────────────────────────────────┐
│         STAGING LAYER           │
│  stg_ga4_events (view)          │
│  • Unnests nested GA4 records   │
│  • Flattens device/geo/traffic  │
│  • Standardizes data types      │
└────────────────┬────────────────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
┌───────────────┐  ┌──────────────────┐
│  DIMENSIONS   │  │     FACTS        │
│               │  │                  │
│ dim_user      │  │ fact_events      │
│ dim_device    │  │ fact_purchases   │
│ dim_geo       │  │                  │
│ dim_traffic   │  │ (incremental)    │
│ dim_date      │  │                  │
└───────────────┘  └──────────────────┘
        │                 │
        └────────┬────────┘
                 ▼
┌─────────────────────────────────┐
│         SNAPSHOT LAYER          │
│  dim_user_snapshot (SCD Type 2) │
│  • Tracks attribute changes     │
│  • dbt_valid_from / valid_to    │
└─────────────────────────────────┘
                 │
                 ▼
    BI Tools / Looker Studio / SQL
```

---

## 📁 Project Structure
```
dbt_bigquery/
├── models/
│   ├── staging/
│   │   ├── sources.yml              # Source definitions
│   │   └── stg_ga4_events.sql       # Flattens raw GA4 nested data
│   ├── dimensions/
│   │   ├── dim_user.sql             # User attributes (first touch)
│   │   ├── dim_device.sql           # Device, browser, OS, language
│   │   ├── dim_geo.sql              # Country, region, city
│   │   ├── dim_traffic_source.sql   # Source, medium, campaign
│   │   └── dim_date.sql             # Date spine for 2021
│   └── facts/
│       ├── fact_events.sql          # All GA4 events (incremental)
│       └── fact_purchases.sql       # Purchase transactions (incremental)
├── snapshots/
│   └── dim_user_snapshot.sql        # SCD Type 2 user history tracking
├── analyses/
│   ├── revenue_and_conversion.sql   # Funnel & revenue by traffic source
│   ├── user_behaviour.sql           # Device, geo & auth breakdown
│   ├── purchase_trends.sql          # Daily/monthly trends & MoM growth
│   └── traffic_source_roi.sql       # Channel efficiency & revenue per session
├── tests/                           # Custom SQL data quality tests
├── macros/                          # Reusable SQL macros
├── seeds/                           # Static reference data
└── dbt_project.yml                  # Project configuration
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **dbt Core 1.11** | Data transformation & modeling |
| **Google BigQuery** | Cloud data warehouse (US region) |
| **GA4 Public Dataset** | Source data — Google Merchandise Store 2021 |
| **Dagster** | Pipeline orchestration & monitoring |
| **GitHub Actions** | CI/CD — tests on PR, deploy to prod on merge |
| **Git + GitHub** | Version control |
| **Ubuntu (Hetzner)** | dbt runtime environment |

---

## 📐 Data Models

### Staging
| Model | Materialization | Description |
|-------|-----------------|-------------|
| `stg_ga4_events` | View | Flattens all raw GA4 nested RECORD fields into clean columns. Handles `device`, `geo`, `traffic_source` structs and converts GA4 microsecond timestamps |

### Dimensions
| Model | Rows | Description | Key Fields |
|-------|------|-------------|------------|
| `dim_date` | 364 | Full 2021 calendar with time attributes | `date_id`, `week_of_year`, `quarter`, `is_weekend` |
| `dim_user` | 270,200 | One row per unique user — first touch attributes | `user_key`, `is_authenticated`, `is_mobile_user` |
| `dim_device` | 390 | Unique device/OS/browser/language combinations | `device_key`, `device_category`, `is_mobile` |
| `dim_geo` | 973 | Unique country/region/city combinations | `geo_key`, `geo_country`, `geo_city` |
| `dim_traffic_source` | 15 | Unique source/medium/campaign combinations | `traffic_key`, `is_organic`, `is_paid` |

### Facts
| Model | Rows | Materialization | Description |
|-------|------|-----------------|-------------|
| `fact_events` | 4.3M | Incremental (merge) | All GA4 events with FK to all dimensions |
| `fact_purchases` | 5,200 | Incremental (merge) | Purchase transactions with revenue in USD |

### Snapshots
| Model | Description |
|-------|-------------|
| `dim_user_snapshot` | SCD Type 2 — tracks changes in user `geo_country`, `device_category` and `traffic_source` over time. Adds `dbt_valid_from`, `dbt_valid_to` and `dbt_updated_at` columns automatically |

---

## 🔑 Key Engineering Decisions

**1. Star schema over a flat/wide table**
Dimensions change independently of facts — a user's country or device can update without touching 4.3M event rows. The star schema separates concerns cleanly and enables SCD2 history tracking on dimensions without data duplication.

**2. Incremental models for facts**
`fact_events` has 4.3M rows. Full refresh processes 627MB on every run — expensive at scale. Incremental materialization with BigQuery MERGE only processes new events since the last run, reducing compute cost significantly in production.

**3. Views for staging**
Staging models are materialized as views — no storage cost, always reflect the latest raw data, and keep transformation logic in one place.

**4. Surrogate keys via MD5 hash**
BigQuery has no auto-increment IDs. All dimension primary keys and fact foreign keys are generated using `dbt_utils.generate_surrogate_key()` — an MD5 hash of the grain columns. Same inputs always produce the same hash, guaranteeing consistent joins across incremental runs.

**5. Dev/prod environment separation**
Two BigQuery target environments in `profiles.yml`: `dbt_dev_*` datasets for development and `dbt_prod_*` for production. Prevents development work from touching business-critical data.

**6. SCD Type 2 on dim_user**
User attributes change over time. The snapshot tracks `geo_country`, `device_category` and `traffic_source` changes — enabling point-in-time analysis: "what device was this user on at the time of their first purchase?"

---

## ✅ Data Quality — 47 Automated Tests

Every model includes dbt tests across all layers:

| Test type | What it checks | Applied to |
|-----------|---------------|------------|
| `not_null` | No missing values on key columns | All primary + foreign keys |
| `unique` | No duplicate dimension rows | All surrogate keys |
| `accepted_values` | Only expected values in categoricals | `device_category` |
| `relationships` | Every FK exists in the referenced dimension | All fact → dim joins |

**Real bug caught in development:** `dim_device` had 44 duplicate surrogate keys because `device_language` was in the `SELECT DISTINCT` but missing from the `generate_surrogate_key()` hash. The `unique` test caught it immediately — adding `device_language` to the hash reduced duplicates to zero and the `relationships` tests confirmed full FK integrity across all 4.3M fact rows.

---

## 📊 Business Analyses

Four SQL analyses in `analyses/` answer real business questions directly against the star schema:

| File | Business Question |
|------|-------------------|
| `revenue_and_conversion.sql` | What is our conversion rate and which traffic sources drive the most revenue? |
| `user_behaviour.sql` | How do users engage by device type, geography and authentication status? |
| `purchase_trends.sql` | How does revenue trend daily and monthly — including MoM growth rate? |
| `traffic_source_roi.sql` | Which channels bring buyers vs browsers — revenue per session by source? |

---

## 🚀 How to Run
```bash
# Activate virtual environment (Hetzner server)
source ~/.venv/dbt/bin/activate

# Test BigQuery connection
dbt debug

# Install packages
dbt deps

# Run snapshots first (SCD2 — before dbt run in production)
dbt snapshot

# Run all models (dev environment by default)
dbt run

# Run against production
dbt run --target prod

# Run all 47 tests
dbt test

# Generate and serve documentation
dbt docs generate
dbt docs serve --host 0.0.0.0 --port 8085
```

---

## 🔄 CI/CD Pipeline

- **Pull Request** → GitHub Actions runs `dbt build --target staging` automatically — all models + all 47 tests must pass before merge is allowed
- **Merge to main** → GitHub Actions deploys to production via `dbt run --target prod`
- **BigQuery credentials** stored as GitHub Secrets — never in code

---

## 🌍 Environment

- **Warehouse:** BigQuery (`dwh-kyamil`, US region)
- **Execution:** dbt Core 1.11 on Hetzner Ubuntu server (CPX22)
- **Orchestration:** Dagster — daily scheduled runs with asset lineage graph
- **Dev datasets:** `dbt_dev_staging`, `dbt_dev_dimensions`, `dbt_dev_facts`
- **Prod datasets:** `dbt_prod_staging`, `dbt_prod_dimensions`, `dbt_prod_facts`

---

## 📬 Contact

Built by **Kyamil** as part of an analytics engineering portfolio.

- GitHub: [portfolioke](https://github.com/portfolioke)
- LinkedIn: [in/databiai](https://www.linkedin.com/in/databiai/)
