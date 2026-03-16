-- ============================================================
-- Purchase Trends Analysis
-- Business question: How does revenue trend over time
-- and when do customers buy most?
-- ============================================================

-- 1. Daily revenue trend
select
    d.date_id,
    d.day_name,
    d.is_weekend,
    d.week_of_year,
    count(p.purchase_key)               as daily_purchases,
    round(sum(p.revenue_usd), 2)        as daily_revenue_usd,
    round(avg(p.revenue_usd), 2)        as avg_order_value_usd,
    round(avg(sum(p.revenue_usd)) over (
        order by d.date_id
        rows between 6 preceding and current row
    ), 2)                               as revenue_7day_moving_avg
from {{ ref('fact_purchases') }} p
join {{ ref('dim_date') }} d
    on p.event_date = d.date_id
group by 1, 2, 3, 4
order by d.date_id
;

-- 2. Revenue by day of week (which days perform best?)
select
    d.day_name,
    d.is_weekend,
    count(p.purchase_key)               as total_purchases,
    round(sum(p.revenue_usd), 2)        as total_revenue_usd,
    round(avg(p.revenue_usd), 2)        as avg_order_value_usd
from {{ ref('fact_purchases') }} p
join {{ ref('dim_date') }} d
    on p.event_date = d.date_id
group by 1, 2
order by total_revenue_usd desc
;

-- 3. Monthly revenue summary with month-over-month growth
with monthly as (
    select
        d.year,
        d.month,
        d.month_name,
        count(p.purchase_key)           as total_purchases,
        round(sum(p.revenue_usd), 2)    as monthly_revenue_usd
    from {{ ref('fact_purchases') }} p
    join {{ ref('dim_date') }} d
        on p.event_date = d.date_id
    group by 1, 2, 3
)
select
    year,
    month,
    month_name,
    total_purchases,
    monthly_revenue_usd,
    round(
        (monthly_revenue_usd - lag(monthly_revenue_usd) over (order by year, month))
        * 100.0
        / nullif(lag(monthly_revenue_usd) over (order by year, month), 0)
    , 1)                                as mom_growth_pct
from monthly
order by year, month
;