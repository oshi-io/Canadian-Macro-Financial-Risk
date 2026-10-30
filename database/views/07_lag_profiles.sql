-- Predictor and outcome reference months must fall in the SAME non-pandemic regime.
CREATE OR REPLACE VIEW public.v_bi_lag_profiles AS
WITH aligned AS (
    SELECT t.month AS outcome_month, s.month AS predictor_month, l.months_back,
           t.insolvencies_yoy, s.real_earnings_yoy, s.unemployment_change_3m_pp,
           s.gdp_yoy, m.level AS mortgage_rate_pct
    FROM public.v_household_stress_features t
    CROSS JOIN (VALUES (0), (3), (6), (12)) AS l(months_back)
    JOIN public.v_household_stress_features s
        ON s.month = (t.month - MAKE_INTERVAL(months => l.months_back))::DATE
    LEFT JOIN public.observations m
        ON m.date = s.month AND m.indicator = '247five_year_conventional_mortgage_rate'
    WHERE t.insolvencies_yoy IS NOT NULL
),
expanded AS (
    SELECT CASE WHEN a.outcome_month < DATE '2020-01-01'
                  AND a.predictor_month < DATE '2020-01-01' THEN 1
                WHEN a.outcome_month >= DATE '2022-01-01'
                  AND a.predictor_month >= DATE '2022-01-01' THEN 2
                ELSE NULL END AS period_order,
           a.months_back, a.insolvencies_yoy,
           p.predictor_order, p.predictor, p.predictor_value
    FROM aligned a
    CROSS JOIN LATERAL (
        VALUES (1, 'Unemployment change', a.unemployment_change_3m_pp),
               (2, 'Real earnings growth', a.real_earnings_yoy),
               (3, 'GDP growth', a.gdp_yoy),
               (4, 'Mortgage rate', a.mortgage_rate_pct)
    ) AS p(predictor_order, predictor, predictor_value)
)
SELECT CASE WHEN period_order = 1 THEN '2010-2019'
            WHEN period_order = 2 THEN '2022-2026' END AS economic_period,
       period_order, predictor_order, predictor, months_back,
       COUNT(*) AS paired_months,
       ROUND(CORR(insolvencies_yoy, predictor_value)::NUMERIC, 3) AS correlation_r
FROM expanded
WHERE period_order IS NOT NULL AND predictor_value IS NOT NULL
GROUP BY period_order, predictor_order, predictor, months_back;
