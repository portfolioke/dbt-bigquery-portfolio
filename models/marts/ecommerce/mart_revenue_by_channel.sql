with purchases as (
    select * from {{ ref('fact_purchases') }}
),

traffic as (
    select * from {{ ref('dim_traffic_source') }}
)

select
    t.traffic_source,
    t.traffic_medium,
    t.is_organic,
    t.is_paid,
    count(p.purchase_key)        as total_purchases,
    round(sum(p.revenue_usd), 2) as total_revenue_usd,
    round(avg(p.revenue_usd), 2) as avg_order_value_usd
from purchases p
left join traffic t on p.traffic_key = t.traffic_key
group by 1, 2, 3, 4
order by total_revenue_usd desc