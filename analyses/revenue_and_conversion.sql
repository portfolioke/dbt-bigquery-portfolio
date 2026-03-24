-- ============================================================
-- Revenue & Conversion Analysis
-- Business question: How does traffic convert to revenue
-- and which sources drive the most value?
-- ============================================================

-- 1. Overall conversion funnel: sessions → purchases
with funnel as (
    select
        count(distinct case when event_name = 'session_start'
            then e.user_key end)                as total_sessions,
        count(distinct p.user_key)              as purchasing_users,
        count(p.purchase_key)                   as total_purchases,
        round(sum(p.revenue_usd), 2)            as total_revenue_usd
    from {{ ref('fact_events') }} e
    left join {{ ref('fact_purchases') }} p
        on e.user_key = p.user_key
)
select
    total_sessions,
    purchasing_users,
    total_purchases,
    total_revenue_usd,
    round(purchasing_users * 100.0 / nullif(total_sessions, 0), 2)
        as conversion_rate_pct,
    round(total_revenue_usd / nullif(total_purchases, 0), 2)
        as avg_order_value_usd
from funnel
;

-- 2. Revenue by traffic source with share of total
select
    t.traffic_source,
    t.traffic_medium,
    t.is_organic,
    t.is_paid,
    count(p.purchase_key)                                   as total_purchases,
    round(sum(p.revenue_usd), 2)                            as total_revenue_usd,
    round(avg(p.revenue_usd), 2)                            as avg_order_value_usd,
    round(
        sum(p.revenue_usd) * 100.0
        / nullif(sum(sum(p.revenue_usd)) over (), 0)
    , 2)                                                    as revenue_share_pct
from {{ ref('fact_purchases') }} p
join {{ ref('dim_traffic_source') }} t
    on p.traffic_key = t.traffic_key
group by 1, 2, 3, 4
order by total_revenue_usd desc
;# CI/CD test
