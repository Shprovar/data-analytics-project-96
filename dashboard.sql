
–ШАГ4
--Запрос 1. Сколько у нас пользователей заходят на сайт?
SELECT 
  COUNT(DISTINCT visitor_id) AS unique_visitors 
FROM sessions;

–Запрос 2. Какие каналы их приводят на сайт? Хочется видеть по дням/неделям/месяцам.
SELECT
to_char(visit_date, 'YYYY-MM') AS visit_month,
source,
COUNT(DISTINCT visitor_id) AS unique_visitors,
FROM sessions
GROUP BY source, visit_month
ORDER by source;

SELECT
to_char(visit_date, 'YYYY-WW') AS week,
source,
COUNT(DISTINCT visitor_id) AS unique_visitors
FROM sessions
GROUP BY week, source
ORDER BY week, source;

SELECT
  to_char(visit_date, 'YYYY-MM-DD') AS day,
  source,
  COUNT(DISTINCT visitor_id) AS unique_visitors
FROM sessions
GROUP BY day, source
ORDER BY day, source;

–Запрос 3. Сколько лидов к нам приходят?
SELECT
COUNT(DISTINCT lead_id) AS unique_leads
FROM leads;

select
count(distinct s.visitor_id) as uniq_vis,
count(distinct lead_id) as uniq_lead
from sessions s
left join leads on s.visitor_id=leads.visitor_id;

–Запрос 4. Какая конверсия из клика в лид? А из лида в оплату?
SELECT
    COUNT(DISTINCT l.lead_id) AS leads_count,
    COUNT(DISTINCT s.visitor_id) AS visitors_count,
    ROUND(
        100.0 * COUNT(DISTINCT l.lead_id) / COUNT(DISTINCT s.visitor_id), 2
    ) AS lead_conversion_rate,
    COUNT(DISTINCT l.lead_id) FILTER (
        WHERE l.amount > 0
    ) AS paying_customers_count,
    ROUND(
        100.0
        * COUNT(DISTINCT l.lead_id) FILTER (WHERE l.amount > 0)
        / COUNT(DISTINCT l.lead_id),
        2
    ) AS conversion_rate
FROM sessions AS s
LEFT JOIN leads AS l ON s.visitor_id = l.visitor_id;


–Запрос 5. Сколько мы тратим по разным каналам в динамике? 
select
    utm_source,
    to_char(campaign_date, 'YYYY-MM-DD') as day,
    sum(daily_spent)
from vk_ads
group by utm_source, to_char(campaign_date, 'YYYY-MM-DD')
union all
select
    utm_source,
    to_char(campaign_date, 'YYYY-MM-DD') as day,
    sum(daily_spent)
from ya_ads
group by utm_source, to_char(campaign_date, 'YYYY-MM-DD')
order by utm_source, day;


–Окупаются ли каналы?
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
),
final_tab as (
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
    left join advertising_costs as adv
        on
            DATE_TRUNC('day', shpro.visit_date) = adv.visit_date
            and shpro.utm_source = adv.utm_source
            and shpro.utm_medium = adv.utm_medium
            and shpro.utm_campaign = adv.utm_campaign
    group by 1, 3, 4, 5, 6
)
select
    utm_source,
    ROUND(SUM(total_cost) / SUM(visitors_count), 2) as cpu,
    ROUND(SUM(total_cost) / SUM(leads_count), 2) as cpl,
    ROUND(SUM(total_cost) / SUM(purchases_count), 2) as cppu,
    ROUND((SUM(revenue) - SUM(total_cost)) * 100.00 / SUM(total_cost), 2) as roi
from final_tab
group by 1
order by
    roi desc nulls last;




select
    utm_source,
    utm_medium,
    utm_campaign,
    ROUND((SUM(revenue) - SUM(total_cost)) * 100.00 / SUM(total_cost), 2) as roi
from final_tab
group by 1, 2, 3
order by
    roi desc nulls last;




–90% лидов закроется:
select percentile_disc(0.9) within group (order by (created_at - visit_date))
from shpro_last_paid1
where closing_reason = 'Успешная продажа' or status_id = 142;



–Корреляция между рекламой и ростом органики:
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


