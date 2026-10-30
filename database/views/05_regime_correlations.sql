CREATE OR REPLACE VIEW public.v_bi_regime_correlations AS
WITH expanded AS (
    SELECT o.period_order, o.economic_period, o.month, o.insolvencies_yoy,
           x.predictor, x.predictor_value, x.predictor_order
    FROM public.v_bi_economic_overview o
    CROSS JOIN LATERAL (
        VALUES (1, 'Unemployment change', o.unemployment_change_3m_pp),
               (2, 'Real earnings growth', o.real_earnings_yoy),
               (3, 'GDP growth', o.gdp_yoy),
               (4, 'Mortgage rate', o.mortgage_rate_pct)
    ) AS x(predictor_order, predictor, predictor_value)
    WHERE o.insolvencies_yoy IS NOT NULL AND x.predictor_value IS NOT NULL
)
SELECT period_order, economic_period, predictor,
       COUNT(*) AS paired_months,
       ROUND(CORR(insolvencies_yoy, predictor_value)::NUMERIC, 3) AS correlation_r,
       MIN(predictor_order) AS predictor_order
FROM expanded
GROUP BY period_order, economic_period, predictor;
