CREATE OR REPLACE VIEW public.v_bi_economic_overview AS
SELECT h.month, TO_CHAR(h.month, 'YYYY-MM') AS month_id,
       CASE WHEN h.month < DATE '2020-01-01' THEN '2010-2019'
            WHEN h.month < DATE '2022-01-01' THEN '2020-2021'
            ELSE '2022-2026' END AS economic_period,
       CASE WHEN h.month < DATE '2020-01-01' THEN 1
            WHEN h.month < DATE '2022-01-01' THEN 2 ELSE 3 END AS period_order,
       h.insolvencies_yoy, h.unemployment_rate, h.unemployment_change_3m_pp,
       h.real_earnings_yoy, h.gdp_yoy, m.level AS mortgage_rate_pct
FROM public.v_household_stress_features h
LEFT JOIN public.observations m
    ON m.date = h.month AND m.indicator = '247five_year_conventional_mortgage_rate'
WHERE h.insolvencies_yoy IS NOT NULL;
