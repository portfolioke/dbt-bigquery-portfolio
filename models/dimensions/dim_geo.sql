with geo as (
    select distinct
        geo_country,
        geo_region,
        geo_city
    from {{ ref('stg_ga4_events') }}
    where geo_country is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['geo_country', 'geo_region', 'geo_city']) }} as geo_key,
    geo_country,
    geo_region,
    geo_city
from geo