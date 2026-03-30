with users as (
    select * from {{ ref('dim_user') }}
),

purchases as (
    select * from {{ ref('fact_purchases') }}
)

select
    u.geo_country,
    u.device_category,
    u.traffic_source,
    u.is_authenticated,
    u.is_mobile_user,
    count(distinct u.user_key)   as total_users,
    count(p.purchase_key)        as total_purchases,
    round(sum(p.revenue_usd), 2) as total_revenue_usd,
    round(
        count(p.purchase_key) * 1.0 / nullif(count(distinct u.user_key), 0)
    , 4)                         as purchase_rate
from users u
left join purchases p on u.user_key = p.user_key
group by 1, 2, 3, 4, 5
order by total_revenue_usd desc