with source as (
    select *
    from {{ source('ga4', 'events') }}
),

renamed as (
    select
        -- Event fields
        event_date,
        timestamp_micros(event_timestamp) as event_timestamp,
        event_name,
        event_value_in_usd,

        -- User fields
        user_pseudo_id,
        user_id,
        timestamp_micros(user_first_touch_timestamp) as user_first_touch_timestamp,

        -- Device fields
        device.category as device_category,
        device.operating_system as device_os,
        device.web_info.browser as device_browser,
        device.language as device_language,

        -- Geo fields
        geo.country as geo_country,
        geo.region as geo_region,
        geo.city as geo_city,

        -- Traffic source fields
        traffic_source.source as traffic_source,
        traffic_source.medium as traffic_medium,
        traffic_source.name as traffic_campaign,

        -- Platform
        platform,
        stream_id

    from source
)

select * from renamed