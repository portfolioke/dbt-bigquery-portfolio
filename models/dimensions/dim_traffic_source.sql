with traffic as (
    select distinct
        traffic_source,
        traffic_medium,
        traffic_campaign
    from {{ ref('stg_ga4_events') }}
    where traffic_source is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['traffic_source', 'traffic_medium', 'traffic_campaign']) }} as traffic_key,
    traffic_source,
    traffic_medium,
    traffic_campaign,
    case when traffic_medium = 'organic' then true else false end as is_organic,
    case when traffic_medium = 'cpc' then true else false end as is_paid
from traffic