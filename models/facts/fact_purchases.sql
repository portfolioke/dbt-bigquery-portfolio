with purchases as (
    select
        -- Keys
        {{ dbt_utils.generate_surrogate_key(['user_pseudo_id', 'event_timestamp']) }} as purchase_key,
        {{ dbt_utils.generate_surrogate_key(['user_pseudo_id']) }} as user_key,
        {{ dbt_utils.generate_surrogate_key(['geo_country', 'geo_region', 'geo_city']) }} as geo_key,
        {{ dbt_utils.generate_surrogate_key(['traffic_source', 'traffic_medium', 'traffic_campaign']) }} as traffic_key,
        {{ dbt_utils.generate_surrogate_key(['device_category', 'device_os', 'device_browser']) }} as device_key,

        -- Date
        parse_date('%Y%m%d', event_date) as event_date,

        -- Purchase metrics
        event_value_in_usd as revenue_usd,
        event_timestamp

    from {{ ref('stg_ga4_events') }}
    where event_name = 'purchase'
        and event_value_in_usd is not null
)

select * from purchases