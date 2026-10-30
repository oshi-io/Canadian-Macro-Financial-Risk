CREATE OR REPLACE VIEW public.v_macro_explorer AS
SELECT o.date, c.series_id, c.indicator, c.indicator_label, c.economic_domain,
       o.level, o.mom_pct_change, o.yoy_pct_change, o.mar_3_pct, o.mar_6_pct
FROM public.observations o
JOIN public.v_indicator_catalog c ON o.indicator = c.indicator;
