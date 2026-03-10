with devices as (
    select distinct
        device_category,
        device_os,
        device_browser,
        device_language
    from {{ ref('stg_ga4_events') }}
    where device_category is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['device_category', 'device_os', 'device_browser']) }} as device_key,
    device_category,
    device_os,
    device_browser,
    device_language,
    case when device_category = 'mobile' then true else false end as is_mobile,
    case when device_category = 'tablet' then true else false end as is_tablet,
    case when device_category = 'desktop' then true else false end as is_desktop
from devices