{% snapshot dim_user_snapshot %}

{{
	config(
	    target_schema='snapshots',
	    unique_key='user_pseudo_id',
	    strategy='check',
	    check_cols=['geo_country','device_category','traffic_source'],
	)
}}

select
    user_pseudo_id,
    user_id,
    geo_country,
    geo_city,
    device_category,
    device_os,
    traffic_source,
    traffic_medium,
    is_authenticated,
    is_mobile_user

from {{ ref('dim_user')}}

{% endsnapshot %}
