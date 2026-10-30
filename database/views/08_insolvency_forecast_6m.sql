CREATE OR REPLACE VIEW public.v_insolvency_forecast_6m AS
SELECT target.month AS target_month,
       historical.month AS predictor_month,
       target.insolvencies_yoy AS target_insolvencies_yoy,
       historical.insolvencies_yoy AS past_insolvencies_yoy,
       historical.real_earnings_yoy,
       historical.unemployment_change_3m_pp,
       mortgage.level AS mortgage_rate_pct,
       mortgage.level - mortgage_3m_prior.level AS mortgage_rate_change_3m_pp
FROM public.v_household_stress_features target
JOIN public.v_household_stress_features historical
    ON historical.month = (target.month - INTERVAL '6 months')::DATE
LEFT JOIN public.observations mortgage
    ON mortgage.date = historical.month
   AND mortgage.indicator = '247five_year_conventional_mortgage_rate'
LEFT JOIN public.observations mortgage_3m_prior
    ON mortgage_3m_prior.date = (historical.month - INTERVAL '3 months')::DATE
   AND mortgage_3m_prior.indicator = '247five_year_conventional_mortgage_rate'
WHERE target.insolvencies_yoy IS NOT NULL;
