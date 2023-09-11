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
    DATE_TRUNC('day', visit_date) as visit_date,
    shpro.utm_source,
    shpro.utm_medium,
    shpro.utm_campaign,
    COUNT(visitor_id) as visitors_count,
    COUNT(lead_id) as leads_count,
    SUM(case
        when closing_reason = 'Успешная продажа' or status_id = 142
            then 1
        else 0
    end) as purchases_count,
    SUM(amount) as revenue
from shpro_last_paid1 as shpro
group by 1, 2, 3, 4),
crab as(
select
    to_char(visit_date, 'YYYY-MM-DD') as visit_date,
    visitors_count,
    tab.utm_source,
    tab.utm_medium,
    tab.utm_campaign,
    COALESCE(total_ya_spent, 0) + COALESCE(total_vk_spent, 0) as total_cost,
    leads_count,
    purchases_count,
    revenue
    from tab
left join vk_daily as vk
    on
        tab.visit_date = vk.vk_campaign_date
        and tab.utm_source = vk.utm_source
        and tab.utm_medium = vk.utm_medium
        and tab.utm_campaign = vk.utm_campaign
left join ya_daily as ya
    on
        tab.visit_date = ya.ya_campaign_date
        and tab.utm_source = ya.utm_source
        and tab.utm_medium = ya.utm_medium
        and tab.utm_campaign = ya.utm_campaign
order by
    purchases_count desc,
    visit_date asc,
    visitors_count desc,
    tab.utm_source asc,
    tab.utm_medium asc,
    tab.utm_campaign asc)
select * from crab
order by purchases_count desc limit 15;