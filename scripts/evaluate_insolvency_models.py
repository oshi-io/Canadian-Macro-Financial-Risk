"""Reproduce the initial six-month household-insolvency forecast comparison.

Inputs: analyses/household-financial-stress/data/v_insolvency_forecast_6m.csv
Outputs: analyses/household-financial-stress/outputs/{forecast_metrics,forecast_predictions}.csv

This is a retrospective, reference-month-aligned experiment, NOT a point-in-time
forecast validation. See analyses/household-financial-stress/README.md.
"""
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.linear_model import Ridge
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parents[1]
CASE = ROOT / 'analyses' / 'household-financial-stress'
INPUT = CASE / 'data' / 'v_insolvency_forecast_6m.csv'
OUT = CASE / 'outputs'
OUT.mkdir(parents=True, exist_ok=True)

TARGET = 'target_insolvencies_yoy'
HIST = ['past_insolvencies_yoy']
MACRO = HIST + [
    'real_earnings_yoy',
    'unemployment_change_3m_pp',
    'mortgage_rate_change_3m_pp',
]
ALPHAS = [0.01, 0.1, 1, 10, 100, 1000]

raw = pd.read_csv(INPUT, parse_dates=['target_month', 'predictor_month'])
df = raw.sort_values('target_month').dropna(subset=[TARGET] + MACRO).copy()
if df['target_month'].duplicated().any():
    raise ValueError('Duplicate target months in forecast input')
if not ((df['target_month'].dt.to_period('M') - df['predictor_month'].dt.to_period('M')).apply(lambda p: p.n) == 6).all():
    raise ValueError('Predictor months must precede outcome months by six calendar months')

train = df[df['target_month'] <= '2021-06-01'].copy()
validation = df[df['target_month'].between('2022-01-01', '2024-06-01')].copy()
test = df[df['target_month'] >= '2025-01-01'].copy()
if min(len(train), len(validation), len(test)) == 0:
    raise ValueError('One or more chronological evaluation splits are empty')


def fitted_predictions(features):
    """Select alpha by validation MAE, refit training+validation, evaluate test."""
    candidates = []
    for alpha in ALPHAS:
        model = make_pipeline(StandardScaler(), Ridge(alpha=alpha))
        model.fit(train[features], train[TARGET])
        preds = model.predict(validation[features])
        mae = float(np.mean(np.abs(validation[TARGET].to_numpy() - preds)))
        candidates.append((mae, alpha, preds))
    val_mae, chosen_alpha, val_predictions = min(candidates, key=lambda c: (c[0], c[1]))

    combined = pd.concat([train, validation], ignore_index=True)
    final_model = make_pipeline(StandardScaler(), Ridge(alpha=chosen_alpha))
    final_model.fit(combined[features], combined[TARGET])
    test_predictions = final_model.predict(test[features])
    return val_predictions, test_predictions, chosen_alpha, val_mae


hist_val, hist_test, hist_alpha, _ = fitted_predictions(HIST)
macro_val, macro_test, macro_alpha, _ = fitted_predictions(MACRO)


def rows_for(split_df, split_name, hist_pred, macro_pred):
    out = split_df[['target_month', 'predictor_month', TARGET]].copy()
    out['split'] = split_name
    out['persistence_prediction'] = split_df['past_insolvencies_yoy'].to_numpy()
    out['historical_ridge_prediction'] = hist_pred
    out['macro_ridge_prediction'] = macro_pred
    return out

predictions = pd.concat([
    rows_for(validation, 'validation', hist_val, macro_val),
    rows_for(test, 'test', hist_test, macro_test),
], ignore_index=True).sort_values('target_month')
predictions.to_csv(OUT / 'forecast_predictions.csv', index=False)

metrics = []
for split_name in ['validation', 'test']:
    group = predictions[predictions['split'] == split_name]
    actual = group[TARGET].to_numpy()
    for model, field in [
        ('persistence', 'persistence_prediction'),
        ('historical_ridge', 'historical_ridge_prediction'),
        ('macro_ridge', 'macro_ridge_prediction'),
    ]:
        residual = actual - group[field].to_numpy()
        metrics.append({
            'split': split_name,
            'model': model,
            'months': len(group),
            'mae_pp': round(float(np.mean(np.abs(residual))), 3),
            'rmse_pp': round(float(np.sqrt(np.mean(residual ** 2))), 3),
            'mean_error_pp': round(float(np.mean(residual)), 3),
        })
metric_table = pd.DataFrame(metrics)
metric_table.to_csv(OUT / 'forecast_metrics.csv', index=False)
print('Chosen Ridge alphas:', {'historical': hist_alpha, 'macro': macro_alpha})
print(metric_table.to_string(index=False))
print('Wrote outputs to', OUT)
