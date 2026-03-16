-- ============================================================
-- User Behaviour Analysis
-- Business question: Who are our users, how do they engage,
-- and where do they come from?
-- ============================================================

-- 1. Device breakdown: sessions and revenue by device type
select
    d.device_category,
    d.is_mobile,
    d.is_desktop,
    d.is_tablet,
    count(distinct e.user_key)          as unique_users,
    count(distinct case when e.event_name = 'session_start'
        then e.event_key end)           as total_sessions,
    count(p.purchase_key)               as total_purchases,
    round(sum(p.revenue_usd), 2)        as total_revenue_usd,
    round(
        sum(p.revenue_usd) * 100.0
        / nullif(sum(sum(p.revenue_usd)) over (), 0)
    , 2)                                as revenue_share_pct
from {{ ref('fact_events') }} e
join {{ ref('dim_device') }} d
    on e.device_key = d.device_key
left join {{ ref('fact_purchases') }} p
    on e.user_key = p.user_key
    and e.device_key = p.device_key
group by 1, 2, 3, 4
order by total_revenue_usd desc
;

-- 2. Top 10 countries by revenue
select
    g.geo_country,
    count(distinct p.user_key)          as purchasing_users,
    count(p.purchase_key)               as total_purchases,
    round(sum(p.revenue_usd), 2)        as total_revenue_usd,
    round(avg(p.revenue_usd), 2)        as avg_order_value_usd,
    round(
        sum(p.revenue_usd) * 100.0
        / nullif(sum(sum(p.revenue_usd)) over (), 0)
    , 2)                                as revenue_share_pct
from {{ ref('fact_purchases') }} p
join {{ ref('dim_geo') }} g
    on p.geo_key = g.geo_key
group by 1
order by total_revenue_usd desc
limit 10
;

-- 3. Authenticated vs anonymous user behaviour
select
    u.is_authenticated,
    count(distinct u.user_key)          as total_users,
    count(distinct p.purchase_key)      as total_purchases,
    round(sum(p.revenue_usd), 2)        as total_revenue_usd,
    round(avg(p.revenue_usd), 2)        as avg_order_value_usd
from {{ ref('dim_user') }} u
left join {{ ref('fact_purchases') }} p
    on u.user_key = p.user_key
group by 1
order by total_revenue_usd desc
;