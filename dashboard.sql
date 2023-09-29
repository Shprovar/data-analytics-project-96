with vk_ya as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        campaign_date,
        daily_spent
    from vk_ads
    union all
    select
        utm_source,
        utm_medium,
        utm_campaign,
        campaign_date,
        daily_spent
    from ya_ads
),

advertising_costs as (
    select
        DATE_TRUNC('day', campaign_date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) as total_cost
    from vk_ya
    group by 1, 2, 3, 4
)

select
    TO_CHAR(s.visit_date, 'YYYY-MM-DD') as visit_date,
    COUNT(visitor_id) as visitors_count,
    source,
    SUM(total_cost)
from sessions as s
left join advertising_costs as adv
    on
        DATE_TRUNC('day', s.visit_date) = adv.visit_date
        and s.source = adv.utm_source
        and s.medium = adv.utm_medium
        and s.campaign = adv.utm_campaign
group by 1, 3;
