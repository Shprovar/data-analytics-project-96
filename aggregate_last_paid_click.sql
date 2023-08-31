--версия для загрузки, неокончательная
select
    to_char(visit_date, 'YY-MM-DD') as visit_date,
    shpro.utm_source,
    shpro.utm_medium,
    shpro.utm_campaign,
    count(visitor_id) as visitors_count,
    case
        when vk.daily_spent is not null then vk.daily_spent
        when ya.daily_spent is not null then ya.daily_spent
        else 0
    end as total_cost,
    count(lead_id) as leads_count,
    count(closing_reason) as purchases_count,
    sum(amount) as revenue
from shpro_last_paid1 as shpro
left join vk_ads as vk
    on
        date_trunc('day', shpro.visit_date)
        = date_trunc('day', vk.campaign_date)
        and shpro.utm_source = vk.utm_source
        and shpro.utm_medium = vk.utm_medium
        and shpro.utm_campaign = vk.utm_campaign
left join ya_ads as ya
    on
        date_trunc('day', shpro.visit_date)
        = date_trunc('day', ya.campaign_date)
        and shpro.utm_source = ya.utm_source
        and shpro.utm_medium = ya.utm_medium
        and shpro.utm_campaign = ya.utm_campaign
where status_id = 142
group by visit_date, 1, 2, 3, 4, vk.daily_spent, ya.daily_spent
order by
    purchases_count desc, visit_date asc, visitors_count desc, shpro.utm_source asc, shpro.utm_medium asc, shpro.utm_campaign asc;




