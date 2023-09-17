Шаг2 запрос для атрибуции лидов по модели Last Paid Click
WITH tab AS (
    select
        *,
        s.visitor_id as sessions_visitor_id,
        ROW_NUMBER()
            over (partition by lead_id order by s.visit_date desc)
        as click_rank
        --,CASE WHEN s.visit_date < leads.created_at THEN leads.lead_id ELSE '0' END AS leads_tmp
    from sessions as s
    left join leads on s.visitor_id = leads.visitor_id AND s.visit_date <= leads.created_at
    where medium != 'organic'
)
select
    sessions_visitor_id as visitor_id,
    visit_date,
    source as utm_source,
    medium as utm_medium,
    campaign as utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
from tab
where
    click_rank = 1 and amount is not null
order by
    amount desc,
    visit_date asc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc;