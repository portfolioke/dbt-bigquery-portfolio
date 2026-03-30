with purchases as (
    select * from {{ ref('fact_purchases') }}
),

geo as (
    select * from {{ ref('dim_geo') }}
)

select
    g.geo_country,
    g.world_region,
    g.world_sub_region,
    count(p.purchase_key)        as total_purchases,
    round(sum(p.revenue_usd), 2) as total_revenue_usd,
    round(avg(p.revenue_usd), 2) as avg_order_value_usd
from purchases p
left join geo g on p.geo_key = g.geo_key
group by 1, 2, 3
order by total_revenue_usd desc