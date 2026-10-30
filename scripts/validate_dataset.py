"""Check canonical data, indicator coverage, and household analysis exports."""
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data'
CASE = ROOT / 'analyses' / 'household-financial-stress' / 'data'
obs = pd.read_csv(DATA / 'processed' / 'macroeconomic_consolidated.csv', parse_dates=['date'])
q = pd.read_csv(DATA / 'quality' / 'data_quality_report.csv')
features = pd.read_csv(CASE / 'v_household_stress_features.csv', parse_dates=['month'])
forecast = pd.read_csv(CASE / 'v_insolvency_forecast_6m.csv', parse_dates=['target_month','predictor_month'])

checks = {
 'no observation-key duplicates': not obs.duplicated(['indicator','date']).any(),
 'no null observation-levels': bool(obs['level'].notna().all()),
 'distinct indicators match quality report': set(obs['indicator']) == set(q['indicator']),
 'quality report has distinct indicators': not q['indicator'].duplicated().any(),
 'monthly features have unique dates': not features['month'].duplicated().any(),
 'forecast targets are unique': not forecast['target_month'].duplicated().any(),
 'forecast horizons all six months': all(
     (t.to_period('M')-p.to_period('M')).n == 6
     for t,p in zip(forecast['target_month'],forecast['predictor_month'])
 ),
}
print('Observations:',len(obs),'| Indicators:',obs.indicator.nunique(),
      '| Coverage:',obs.date.min().date(),'to',obs.date.max().date())
print('Household features:',len(features),'| Forecast rows:',len(forecast))
for label, passes in checks.items():
 print(('PASS' if passes else 'FAIL'), '-', label)
if not all(checks.values()):
 raise SystemExit('Dataset validation failed')
