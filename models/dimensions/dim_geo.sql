with geo as (
    select distinct
        geo_country,
        geo_region,
        geo_city
    from {{ ref('stg_ga4_events') }}
    where geo_country is not null
),

region_mapping as (
    select
        country_name,
        region,
        sub_region
    from {{ ref('country_region_mapping') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['geo_country', 'geo_region', 'geo_city']) }}
        as geo_key,
    g.geo_country,
    g.geo_region,
    g.geo_city,
    coalesce(r.region, 'Other')         as world_region,
    coalesce(r.sub_region, 'Other')     as world_sub_region
from geo g
left join region_mapping r
    on g.geo_country = r.country_name