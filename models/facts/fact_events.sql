with events as (
    select
        -- Keys for joining to dimensions
        {{ dbt_utils.generate_surrogate_key(['user_pseudo_id', 'event_name', 'event_timestamp']) }} as event_key,
        {{ dbt_utils.generate_surrogate_key(['user_pseudo_id']) }} as user_key,
        {{ dbt_utils.generate_surrogate_key(['device_category', 'device_os', 'device_browser']) }} as device_key,
        {{ dbt_utils.generate_surrogate_key(['geo_country', 'geo_region', 'geo_city']) }} as geo_key,
        {{ dbt_utils.generate_surrogate_key(['traffic_source', 'traffic_medium', 'traffic_campaign']) }} as traffic_key,

        -- Date for joining to dim_date
        parse_date('%Y%m%d', event_date) as event_date,

        -- Event attributes
        event_name,
        event_timestamp,
        event_value_in_usd,
        platform,
        stream_id

    from {{ ref('stg_ga4_events') }}
    where event_name is not null
)

select * from events