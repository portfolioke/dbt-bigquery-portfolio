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
Raw Source (BigQuery Public Data)
        │
        ▼
┌─────────────────────────────────┐
│         STAGING LAYER           │
│  stg_ga4_events                 │
│  • Unnests nested GA4 records   │
│  • Flattens event_params        │
│  • Standardizes data types      │
│  • Deduplicates events          │
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
│ dim_traffic   │  │                  │
│ dim_date      │  │                  │
└───────────────┘  └──────────────────┘
        │                 │
        └────────┬────────┘
                 ▼
    BI Tools / Looker Studio / SQL
```

---

## 📁 Project Structure

```
dbt_bigquery/
├── models/
│   ├── staging/
│   │   ├── sources.yml          # Source definitions
│   │   └── stg_ga4_events.sql   # Flattens raw GA4 nested data
│   ├── dimensions/
│   │   ├── dim_user.sql         # User attributes & lifetime value
│   │   ├── dim_device.sql       # Device, browser, OS
│   │   ├── dim_geo.sql          # Country, region, city
│   │   ├── dim_traffic_source.sql # Source, medium, campaign
│   │   └── dim_date.sql         # Date dimension
│   └── facts/
│       ├── fact_events.sql      # All GA4 events with metrics
│       └── fact_purchases.sql   # E-commerce transactions
├── tests/                       # Data quality tests
├── macros/                      # Reusable SQL macros
├── seeds/                       # Static reference data
├── snapshots/                   # SCD Type 2 tracking
├── analyses/                    # Ad-hoc analytical queries
└── dbt_project.yml              # Project configuration
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **dbt Core** | Data transformation & modeling |
| **Google BigQuery** | Cloud data warehouse |
| **GA4 Public Dataset** | Source data (Google Merchandise Store) |
| **Git + GitHub** | Version control |
| **Ubuntu (Hetzner)** | dbt runtime environment |

---

## 📐 Data Models

### Staging
| Model | Description |
|-------|-------------|
| `stg_ga4_events` | Flattens all raw GA4 nested fields into clean columns. Handles `event_params`, `device`, `geo`, `traffic_source` and `ecommerce` RECORD types |

### Dimensions
| Model | Description | Key Fields |
|-------|-------------|------------|
| `dim_user` | One row per unique user | `user_pseudo_id`, `first_touch_date`, `ltv_revenue` |
| `dim_device` | Device characteristics | `device_category`, `browser`, `os` |
| `dim_geo` | Geographic attributes | `country`, `region`, `city` |
| `dim_traffic_source` | Acquisition channels | `source`, `medium`, `campaign` |
| `dim_date` | Date spine | `date`, `week`, `month`, `quarter`, `year` |

### Facts
| Model | Description | Grain |
|-------|-------------|-------|
| `fact_events` | All GA4 events with metrics | One row per event |
| `fact_purchases` | E-commerce transactions | One row per purchase |

---

## 🔑 Key Engineering Decisions

**1. Incremental models for facts**
Fact tables use dbt's incremental materialization — only new daily partitions are processed on each run, keeping costs low on BigQuery's free tier.

**2. Views for staging**
Staging models are materialized as views — no storage cost, always reflect the latest raw data.

**3. Unnesting GA4 nested fields**
GA4 stores event parameters as `RECORD REPEATED` types. The staging model handles all unnesting logic in one place, keeping downstream models clean and simple.

**4. Source freshness tests**
dbt source freshness checks ensure the pipeline alerts if raw GA4 data stops arriving.

---

## ✅ Data Quality Tests

Every model includes dbt tests for:
- `not_null` on primary keys
- `unique` on grain columns
- `accepted_values` for categorical fields
- Custom tests for business logic validation

---

## 🚀 How to Run

```bash
# Activate virtual environment
source ~/.venv/dbt/bin/activate

# Test connection
dbt debug

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

---

## 📬 Contact

Built by **Kyamil** as part of an analytics engineering portfolio.
- GitHub: [portfolioke](https://github.com/portfolioke)
- LinkedIn:  [in/databiai](https://www.linkedin.com/in/databiai/)
