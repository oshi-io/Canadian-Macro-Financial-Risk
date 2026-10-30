-- Exploratory feature construction. Months represent reference dates, not publication timestamps.
CREATE OR REPLACE VIEW public.v_household_stress_features AS
WITH monthly AS (
    SELECT date AS month,
           MAX(level) FILTER (WHERE indicator = '132unemployment_rate') AS unemployment_rate,
           MAX(level) FILTER (WHERE indicator = '247five_year_conventional_mortgage_rate') AS mortgage_rate,
           MAX(yoy_pct_change) FILTER (WHERE indicator = '161average_weekly_earnings') AS earnings_yoy,
           MAX(yoy_pct_change) FILTER (WHERE indicator = '184consumer_price_index_all_items') AS inflation_yoy,
           MAX(yoy_pct_change) FILTER (WHERE indicator = '117consumer_insolvencies') AS insolvencies_yoy,
           MAX(yoy_pct_change) FILTER (WHERE indicator = '30retail_sales_volume') AS retail_volume_yoy,
           MAX(yoy_pct_change) FILTER (WHERE indicator = '1gross_domestic_product_at_basic_prices') AS gdp_yoy,
           MAX(yoy_pct_change) FILTER (WHERE indicator = '42new_motor_vehicle_sales_total_units') AS vehicle_sales_yoy
    FROM public.observations
    GROUP BY date
),
features AS (
    SELECT month, insolvencies_yoy, unemployment_rate,
           unemployment_rate - LAG(unemployment_rate, 3) OVER (ORDER BY month)
               AS unemployment_change_3m_pp,
           LAG(mortgage_rate, 6) OVER (ORDER BY month) AS mortgage_rate_lag_6m,
           ((1 + earnings_yoy / 100.0) / NULLIF(1 + inflation_yoy / 100.0, 0) - 1) * 100
               AS real_earnings_yoy,
           retail_volume_yoy, gdp_yoy, vehicle_sales_yoy
    FROM monthly
)
SELECT * FROM features WHERE month >= DATE '2010-01-01';
