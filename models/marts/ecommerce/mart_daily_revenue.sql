with purchases as (
    select * from {{ ref('fact_purchases') }}
),

dates as (
    select * from {{ ref('dim_date') }}
)

select
    d.date_id,
    d.day_name,
    d.is_weekend,
    d.month_name,
    d.quarter,
    count(p.purchase_key)        as total_purchases,
    round(sum(p.revenue_usd), 2) as total_revenue_usd,
    round(avg(p.revenue_usd), 2) as avg_order_value_usd
from dates d
left join purchases p on d.date_id = p.event_date
group by 1, 2, 3, 4, 5
order by date_id