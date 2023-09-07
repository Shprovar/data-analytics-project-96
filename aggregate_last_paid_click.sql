--версия для загрузки, неокончательная
with vk_daily as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        DATE_TRUNC('day', campaign_date) as vk_campaign_date,
        SUM(daily_spent) as total_vk_spent
    from vk_ads
    group by
        DATE_TRUNC('day', campaign_date), utm_source, utm_medium, utm_campaign
),
ya_daily as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        DATE_TRUNC('day', campaign_date) as ya_campaign_date,
        SUM(daily_spent) as total_ya_spent
    from ya_ads
    group by
        DATE_TRUNC('day', campaign_date), utm_source, utm_medium, utm_campaign
), tab as(
select
    TO_CHAR(visit_date, 'YY-MM-DD') as visit_date,
    shpro.utm_source,
    shpro.utm_medium,
    shpro.utm_campaign,
    COUNT(visitor_id) as visitors_count,
    COALESCE(total_ya_spent, 0) + COALESCE(total_vk_spent, 0) as total_cost,
    COUNT(lead_id) as leads_count,
    SUM(case
        when closing_reason = 'Успешная продажа' or status_id = 142
            then 1
        else 0
    end) as purchases_count,
    SUM(amount) as revenue
from shpro_last_paid1 as shpro
left join vk_daily as vk
    on
        shpro.visit_date = vk.vk_campaign_date
        and shpro.utm_source = vk.utm_source
        and shpro.utm_medium = vk.utm_medium
        and shpro.utm_campaign = vk.utm_campaign
left join ya_daily as ya
    on
        shpro.visit_date = ya.ya_campaign_date
        and shpro.utm_source = ya.utm_source
        and shpro.utm_medium = ya.utm_medium
        and shpro.utm_campaign = ya.utm_campaign
group by visit_date, 2, 3, 4, total_cost
order by
    purchases_count desc,
    visit_date asc,
    --visitors_count desc,
    shpro.utm_source asc,
    shpro.utm_medium asc,
    shpro.utm_campaign asc)
select *
from tab
order by purchases_count desc
limit 15;





