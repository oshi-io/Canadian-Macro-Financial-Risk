CREATE OR REPLACE VIEW public.v_bi_regime_shifts AS
SELECT current_period.predictor, current_period.predictor_order,
       current_period.economic_period, current_period.period_order,
       baseline.correlation_r AS pre_pandemic_r,
       current_period.correlation_r AS period_r,
       ROUND((current_period.correlation_r - baseline.correlation_r)::NUMERIC, 3) AS delta_r,
       (baseline.correlation_r * current_period.correlation_r < 0) AS sign_reversal,
       baseline.paired_months AS baseline_months,
       current_period.paired_months AS period_months
FROM public.v_bi_regime_correlations current_period
JOIN public.v_bi_regime_correlations baseline
    ON baseline.predictor = current_period.predictor AND baseline.period_order = 1
WHERE current_period.period_order IN (2, 3);
