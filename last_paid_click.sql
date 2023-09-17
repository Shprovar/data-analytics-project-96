Шаг2 запрос для атрибуции лидов по модели Last Paid Click
WITH tab AS (
    SELECT
        *,
        s.visitor_id AS sessions_visitor_id,
        ROW_NUMBER()
            OVER (PARTITION BY s.visitor_id ORDER BY s.visit_date DESC)
        AS click_rank
    FROM sessions AS s
    LEFT JOIN
        leads
        ON s.visitor_id = leads.visitor_id AND s.visit_date <= leads.created_at
    WHERE medium != 'organic'
)

SELECT
    sessions_visitor_id AS visitor_id,
    visit_date,
    source AS utm_source,
    medium AS utm_medium,
    campaign AS utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
FROM tab
WHERE
    click_rank = 1
ORDER BY
    amount DESC,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;