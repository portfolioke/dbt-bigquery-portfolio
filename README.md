# 📊 GA4 E-Commerce Analytics Engineering Project

### dbt Core + BigQuery + Dagster + Marquez | Production-Grade Analytics Data Warehouse

![dbt](https://img.shields.io/badge/dbt-1.11-orange?logo=dbt)
![BigQuery](https://img.shields.io/badge/BigQuery-Google-blue?logo=googlebigquery)
![Dagster](https://img.shields.io/badge/Dagster-Orchestration-purple?logo=dagster)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-black?logo=githubactions)
![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)
![License](https://img.shields.io/badge/license-MIT-green)

<div style="text-align: center;">
  <img 
    width="500" 
    alt="dbt + BigQuery" 
    src="https://github.com/user-attachments/assets/d9307afa-3570-4fac-b0b9-06b81610e7f1" 
  />
</div>

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
Raw GA4 Source (BigQuery)
         |
         v
    [STAGING]
    stg_ga4_events (view, access: private)
    - Unnests nested GA4 records
    - Flattens device / geo / traffic
    - Standardizes data types
         |
         v
    [CORE LAYER]
    Dimensions                    Facts
    ----------                    -----
    dim_date                      fact_events (4.3M rows, incremental)
    dim_user                      fact_purchases (5.2k rows, incremental + contract)
    dim_device
    dim_geo
    dim_traffic_source
    (all access: public)
         |
         v
    [MARTS LAYER] (access: public)
    mart_revenue_by_channel
    mart_daily_revenue
    mart_user_cohorts
    mart_geo_revenue
         |
         v
    [SNAPSHOT LAYER]
    dim_user_snapshot (SCD Type 2)
         |
         v
    Looker Studio Dashboard
```

---

## 📁 Project Structure

```
dbt_bigquery/
├── models/
│   ├── staging/          # Private layer — flattens raw GA4 data
│   ├── dimensions/       # Public core — dim_user, dim_device, dim_geo, dim_traffic, dim_date
│   ├── facts/            # Public core — fact_events (4.3M), fact_purchases (contracted)
│   └── marts/
│       └── ecommerce/    # Public consumer layer — 4 pre-aggregated mart models
├── snapshots/            # dim_user_snapshot — SCD Type 2
├── analyses/             # Ad-hoc business SQL queries
├── tests/
│   └── generic/          # Custom reusable tests
├── seeds/                # country_region_mapping.csv (48 countries)
├── .github/
│   └── workflows/
│       ├── dbt_ci.yml    # Slim CI: zero-copy clone + state:modified+ + defer
│       └── dbt_cd.yml    # CD: full prod deploy on merge to main
├── .sqlfluff             # SQL linting config
├── profiles_ci.yml       # CI-safe profiles (no secrets)
└── dbt_project.yml       # Tags, meta, hooks, access, persist_docs
```
---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **dbt Core 1.11** | Data transformation, testing, documentation |
| **Google BigQuery** | Cloud data warehouse (US region) |
| **GA4 Public Dataset** | Source — Google Merchandise Store 2021 |
| **Dagster** | Pipeline orchestration, scheduling, asset catalog |
| **Marquez + OpenLineage** | Data lineage tracking via dbt-ol |
| **GitHub Actions** | CI/CD — slim CI on PR, prod deploy on merge |
| **Hetzner Ubuntu CPX32** | dbt + Dagster runtime server |
| **Looker Studio** | Business intelligence dashboard |

---

## 📐 Data Models

### Staging
| Model | Materialization | Description |
|-------|-----------------|-------------|
| `stg_ga4_events` | View | Flattens all raw GA4 nested RECORD fields. Handles `device`, `geo`, `traffic_source` structs. Converts GA4 microsecond timestamps. Access: **private** |

### Dimensions
| Model | Rows | Description |
|-------|------|-------------|
| `dim_date` | 364 | Full 2021 calendar — `week_of_year`, `quarter`, `is_weekend` |
| `dim_user` | 270,200 | One row per unique user, first-touch attributes — `is_authenticated`, `is_mobile_user` |
| `dim_device` | 390 | Unique device/OS/browser/language combos — `is_mobile`, `is_desktop`, `is_tablet` |
| `dim_geo` | 973 | Country/region/city enriched with `world_region` and `world_sub_region` from seed |
| `dim_traffic_source` | 15 | Source/medium/campaign — `is_organic`, `is_paid` |

### Facts
| Model | Rows | Materialization | Notes |
|-------|------|-----------------|-------|
| `fact_events` | 4.3M | Incremental (merge) | All GA4 events with FK to all dims |
| `fact_purchases` | 5,200 | Incremental (merge) | Revenue in USD — **contract enforced** |

### Marts
| Model | Description |
|-------|-------------|
| `mart_revenue_by_channel` | Revenue + purchases by traffic source and medium |
| `mart_daily_revenue` | Daily revenue with calendar attributes for time series |
| `mart_user_cohorts` | User cohorts by country, device, source with purchase rate |
| `mart_geo_revenue` | Revenue by country and world region |

### Snapshots
| Model | Description |
|-------|-------------|
| `dim_user_snapshot` | SCD Type 2 — tracks changes in `geo_country`, `device_category`, `traffic_source`. Adds `dbt_valid_from`, `dbt_valid_to`, `dbt_updated_at` |

---

## 🔑 Key Engineering Decisions

**1. Star schema with marts layer**
Staging → dimensions + facts → marts. Staging is `access: private` — downstream consumers can only ref the public dimensions, facts and marts. Mirrors the dbt Labs recommended layered architecture.

**2. Incremental models for facts**
`fact_events` has 4.3M rows. Full refresh processes 627MB every run. Incremental materialization with BigQuery MERGE only processes new events since the last run — essential at production scale.

**3. Model contracts on fact_purchases**
`contract: enforced: true` on `fact_purchases` guarantees column names and data types match exactly what the schema.yml declares. Breaking changes are caught at compile time, not at query time.

**4. Surrogate keys via MD5 hash**
All keys generated with `dbt_utils.generate_surrogate_key()`. Same inputs always produce the same hash — consistent joins across incremental runs guaranteed.

**5. Dev / CI / prod separation**
Three BigQuery environments: `dbt_dev_*` (local development), `dbt_ci_*` (GitHub Actions PRs), `dbt_prod_*` (merged to main). Prevents development work from ever touching production data.

**6. SCD Type 2 on dim_user**
Tracks historical user attribute changes — enabling point-in-time analysis: *"what device was this user on at the time of their first purchase?"*

**7. Seed for region mapping**
Static country → world region lookup maintained as a CSV seed. Classic use case: small reference data managed by the analytics team, not a source system.

---

## ✅ Data Quality — 68 Automated Tests

| Test type | Severity | Applied to |
|-----------|----------|------------|
| `not_null` | error | All primary + foreign keys |
| `unique` | error | All surrogate keys |
| `relationships` | error | All fact → dim FK joins |
| `accepted_values` | warn | `device_category`, `platform` |
| `dbt_expectations.expect_column_values_to_be_between` | warn | `revenue_usd` (0–10,000) |
| `dbt_expectations.expect_column_value_lengths_to_be_between` | warn | `event_name` (1–100 chars) |
| `assert_column_is_positive` | error | `revenue_usd` |
| `assert_column_not_empty_string` | error | `event_name` |

**Real bug caught:** `dim_device` had 44 duplicate surrogate keys because `device_language` was missing from the `generate_surrogate_key()` hash. The `unique` test caught it immediately — a textbook example of why automated testing matters in analytics engineering.

---

## 📊 Source Freshness

Source freshness monitoring is configured in `_sources.yml`:
```yaml
freshness:
  warn_after: {count: 24, period: hour}
  error_after: {count: 48, period: hour}
```

Running `dbt source freshness` returns **ERROR STALE** — which is expected and intentional. This is a static 2021 demo dataset. In production, this check would catch upstream ingestion failures before they silently produce stale dashboards. The configuration demonstrates the pattern even though the data will always be stale.

---

## 🔄 CI/CD Pipeline

### Pull Request (CI)
git push origin feature/branch
→ GitHub Actions triggers automatically
→ dbt clone (zero-copy BigQuery clones of unchanged prod tables)
→ dbt build --select state:modified+ --defer --state ./previous-state
→ Only changed models + downstream deps are rebuilt and tested
→ PR blocked if any error-severity test fails
→ manifest.json cached for next PR's state comparison

### Merge to main (CD)
PR merged to main
→ GitHub Actions triggers automatically
→ dbt seed --target prod
→ dbt snapshot --target prod
→ dbt build --target prod
→ dbt docs generate
→ No manual prod deployment ever needed

**Key CI/CD features:**
- Slim CI with `state:modified+` — only rebuilds what changed
- `--defer` flag — resolves unchanged upstream refs against prod, no rebuild needed
- Zero-copy clone strategy — unchanged prod tables cloned instantly, zero storage cost
- BigQuery credentials stored as GitHub Secrets — never in the repository

---

## 🎭 Model Governance
```yaml
# dbt_project.yml
staging:   access: private   # Implementation detail — not for downstream ref()
dimensions: access: public   # Core layer — safe to ref() from anywhere
facts:      access: public   # Core layer — safe to ref() from anywhere
marts:      access: public   # Consumer layer — BI tools connect here
```

All models tagged with `daily` and layer-specific tags (`staging`, `core`, `marts`) enabling selective runs:
```bash
dbt run --select tag:daily
dbt run --select tag:core
```

All models carry `meta` properties: `owner`, `team`, `layer`, `contains_pii` — visible in dbt docs and BigQuery metadata via `persist_docs`.

---

## 🚀 How to Run
```bash
# Activate virtual environment
source ~/.venv/dbt/bin/activate

# Test BigQuery connection
dbt debug

# Install packages
dbt deps

# Run all models (dev environment by default)
dbt build

# Run against production
dbt build --target prod

# Run specific layer
dbt run --select tag:core

# Run snapshot (SCD2)
dbt snapshot

# Load seeds
dbt seed

# Generate and serve documentation
dbt docs generate
dbt docs serve --host 0.0.0.0 --port 8085

# Run with OpenLineage emission to Marquez
OPENLINEAGE_URL=http://localhost:5000 dbt-ol run

# Clean compiled artifacts
dbt clean
```

---

## 🔭 Orchestration — Dagster

- All 12 dbt models visible in Dagster Asset Catalog with descriptions from `schema.yml`
- Daily schedule configured at **06:00 UTC** via `dbt_daily_schedule`
- Full lineage graph visible in Dagster UI at `http://server:3000`
- Runs as a permanent `systemd` service — survives server reboots

---

## 🗺️ Data Lineage — Marquez + OpenLineage

Dataset-level lineage tracked via `dbt-ol` (OpenLineage dbt wrapper) emitting events to a self-hosted **Marquez** metadata server:
```bash
OPENLINEAGE_URL=http://localhost:5000 dbt-ol run
```

- Marquez UI accessible at `http://server:3001`
- Full dataset lineage graph from raw GA4 source through staging, dimensions, facts and marts
- Namespace: `bigquery` — all datasets tracked as `dwh-kyamil.*` nodes

> **Note:** Automated lineage emission on every Dagster run is a known improvement area. `dagster-openlineage` v0.1.0 is pre-production. Current workflow requires manual `dbt-ol` invocation. In production this would be automated via a Dagster sensor or dbt Cloud's native OpenLineage support.

---

## 🌍 Environments

| Environment | Datasets | When used |
|-------------|----------|-----------|
| `dev` | `dbt_dev_*` | Local development — manual `dbt run` |
| `ci` | `dbt_ci_*` | GitHub Actions PRs — automated testing |
| `prod` | `dbt_prod_*` | GitHub Actions — merged to main only |

---

## 📊 Looker Studio Dashboard

Live dashboard connected to `dbt_prod_*` BigQuery datasets:

🔗 [GA4 Ecommerce Analytics Dashboard](https://lookerstudio.google.com/reporting/743a1687-f0f4-4ab8-b5f5-efc422f39330)

Includes: revenue scorecards, revenue by traffic source, daily revenue trend, geographic revenue map, country-level table.

---

## 📬 Contact

Built by **Kyamil** as an analytics engineering portfolio project.

- GitHub: [portfolioke](https://github.com/portfolioke)
- LinkedIn: [in/databiai](https://www.linkedin.com/in/databiai/)
