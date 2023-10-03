with vk_ya as(
select
    utm_source,
    utm_medium,
    utm_campaign,
    DATE_TRUNC('day', campaign_date) as visit_date,
    sum(daily_spent) as total_cost
from vk_ads
group by 1, 2, 3, 4
union all
select
    utm_source,
    utm_medium,
    utm_campaign,
    DATE_TRUNC('day', campaign_date) as visit_date,
    sum(daily_spent) as total_cost
from ya_ads
group by 1, 2, 3, 4)
select
    TO_CHAR(shpro.visit_date, 'YYYY-MM-DD') as visit_date,
    COUNT(visitor_id) as visitors_count,
    shpro.utm_source,
    shpro.utm_medium,
    shpro.utm_campaign,
    total_cost,
    COUNT(lead_id) as leads_count,
    SUM(case
        when closing_reason = 'Успешная продажа' or status_id = 142
            then 1
        else 0
    end) as purchases_count,
    SUM(amount) as revenue
from public.shpro_last_paid1 as shpro
left join vk_ya
    on
        DATE_TRUNC('day', shpro.visit_date) = vk_ya.visit_date
        and shpro.utm_source = vk_ya.utm_source
        and shpro.utm_medium = vk_ya.utm_medium
        and shpro.utm_campaign = vk_ya.utm_campaign
group by 1, 3, 4, 5,6
order by
    revenue desc nulls last,
    visit_date asc,
    visitors_count desc,
    shpro.utm_source asc,
    shpro.utm_medium asc,
    shpro.utm_campaign asc
limit 15;
