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
), advertising_costs as(
select DATE_TRUNC('day', campaign_date) as visit_date,
 utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
        from vk_ya
        group by 1, 2, 3, 4)
    select
        to_char( shpro.visit_date, 'YYYY-MM-DD') as visit_date,
        COUNT(visitor_id) as visitors_count,
        shpro.utm_source,
        shpro.utm_medium,
        shpro.utm_campaign,
        total_cost,
        count(lead_id) as leads_count,
        SUM(case
            when closing_reason = 'Успешная продажа' or status_id = 142
                then 1
            else 0
        end) as purchases_count,
        SUM(amount) as revenue
    from public.shpro_last_paid1 as shpro
    left join advertising_costs as adv
        ON DATE_TRUNC('day', shpro.visit_date) = adv.visit_date
        and shpro.utm_source = adv.utm_source
        and shpro.utm_medium = adv.utm_medium
        and shpro.utm_campaign = adv.utm_campaign
    group by 1, 3, 4, 5, 6
    order by purchases_count desc,
        visit_date asc,
        visitors_count desc,
        shpro.utm_source asc,
        shpro.utm_medium asc,
        shpro.utm_campaign asc
limit 15;
