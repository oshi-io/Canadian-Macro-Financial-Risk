CREATE OR REPLACE VIEW public.v_indicator_catalog AS
WITH parsed AS (
    SELECT indicator,
           SUBSTRING(indicator FROM '^[0-9]+')::INTEGER AS series_id,
           INITCAP(REPLACE(REGEXP_REPLACE(indicator, '^[0-9]+', ''), '_', ' ')) AS indicator_label,
           first_date, last_date, rows AS observation_count
    FROM public.data_quality_report
)
SELECT indicator, series_id, indicator_label,
       CASE
           WHEN series_id BETWEEN 1 AND 28 THEN 'GDP and industry output'
           WHEN series_id BETWEEN 29 AND 48 THEN 'Retail and motor vehicles'
           WHEN series_id BETWEEN 49 AND 73 THEN 'Wholesale, services and transport'
           WHEN series_id BETWEEN 74 AND 95 THEN 'Manufacturing and construction'
           WHEN series_id BETWEEN 96 AND 110 THEN 'Trade and tourism'
           WHEN series_id BETWEEN 111 AND 125 THEN 'Business activity and insolvency'
           WHEN series_id BETWEEN 126 AND 170 THEN 'Labour market'
           WHEN series_id BETWEEN 171 AND 198 THEN 'Consumer prices'
           WHEN series_id BETWEEN 199 AND 226 THEN 'Other prices, commodities and housing'
           WHEN series_id BETWEEN 227 AND 256 THEN 'Financial markets and credit'
           ELSE 'Unclassified'
       END AS economic_domain,
       first_date, last_date, observation_count
FROM parsed;
