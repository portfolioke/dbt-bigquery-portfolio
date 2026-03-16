-- ============================================================
-- Traffic Source ROI Analysis
-- Business question: Which channels bring users that actually
-- buy, not just browse? Where should we invest?
-- ============================================================

-- 1. Channel efficiency: revenue per session by source
with sessions_per_source as (
    select
        t.traffic_source,
        t.traffic_medium,
        t.is_organic,
        t.is_paid,
        count(distinct case when e.event_name = 'session_start'
            then e.user_key end)        as total_sessions,
        count(distinct e.user_key)      as total_users
    from {{ ref('fact_events') }} e
    join {{ ref('dim_traffic_source') }} t
        on e.traffic_key = t.traffic_key
    group by 1, 2, 3, 4
),
revenue_per_source as (
    select
        t.traffic_source,
        t.traffic_medium,
        count(p.purchase_key)           as total_purchases,
        round(sum(p.revenue_usd), 2)    as total_revenue_usd,
        count(distinct p.user_key)      as purchasing_users
    from {{ ref('fact_purchases') }} p
    join {{ ref('dim_traffic_source') }} t
        on p.traffic_key = t.traffic_key
    group by 1, 2
)
select
    s.traffic_source,
    s.traffic_medium,
    s.is_organic,
    s.is_paid,
    s.total_sessions,
    s.total_users,
    coalesce(r.total_purchases, 0)      as total_purchases,
    coalesce(r.total_revenue_usd, 0)    as total_revenue_usd,
    coalesce(r.purchasing_users, 0)     as purchasing_users,
    round(
        coalesce(r.purchasing_users, 0) * 100.0
        / nullif(s.total_users, 0)
    , 2)                                as user_conversion_rate_pct,
    round(
        coalesce(r.total_revenue_usd, 0)
        / nullif(s.total_sessions, 0)
    , 4)                                as revenue_per_session_usd
from sessions_per_source s
left join revenue_per_source r
    on s.traffic_source = r.traffic_source
    and s.traffic_medium = r.traffic_medium
order by total_revenue_usd desc
;

-- 2. Organic vs paid summary
select
    case
        when t.is_paid    then 'Paid'
        when t.is_organic then 'Organic'
        else 'Other'
    end                                 as channel_type,
    count(distinct p.user_key)          as purchasing_users,
    count(p.purchase_key)               as total_purchases,
    round(sum(p.revenue_usd), 2)        as total_revenue_usd,
    round(avg(p.revenue_usd), 2)        as avg_order_value_usd,
    round(
        sum(p.revenue_usd) * 100.0
        / nullif(sum(sum(p.revenue_usd)) over (), 0)
    , 1)                                as revenue_share_pct
from {{ ref('fact_purchases') }} p
join {{ ref('dim_traffic_source') }} t
    on p.traffic_key = t.traffic_key
group by 1
order by total_revenue_usd desc
;