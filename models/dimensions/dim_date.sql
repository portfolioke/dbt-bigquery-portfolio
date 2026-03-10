with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2021-01-01' as date)",
        end_date="cast('2021-12-31' as date)"
    ) }}
)

select
    cast(date_day as date) as date_id,
    extract(year from date_day) as year,
    extract(month from date_day) as month,
    extract(day from date_day) as day,
    extract(week from date_day) as week_of_year,
    extract(quarter from date_day) as quarter,
    format_date('%B', date_day) as month_name,
    format_date('%A', date_day) as day_name,
    case when extract(dayofweek from date_day) in (1, 7) then true else false end as is_weekend
from date_spine