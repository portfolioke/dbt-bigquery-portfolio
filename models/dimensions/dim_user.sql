with users as (
    select
        user_pseudo_id,
        user_id,
        user_first_touch_timestamp,
        geo_country,
        geo_city,
        device_category,
        device_os,
        traffic_source,
        traffic_medium,
        traffic_campaign,
        row_number() over (
            partition by user_pseudo_id 
            order by user_first_touch_timestamp asc
        ) as row_num
    from {{ ref('stg_ga4_events') }}
    where user_pseudo_id is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['user_pseudo_id']) }} as user_key,
    user_pseudo_id,
    user_id,
    user_first_touch_timestamp,
    geo_country,
    geo_city,
    device_category,
    device_os,
    traffic_source,
    traffic_medium,
    traffic_campaign
    case when user_id is not null then true else false end as is_authenticated,
    case when device_category = 'mobile' then true else false end as is_mobile_user
from users
where row_num = 1