-- Run against a NEW/EMPTY database named canadian_macro_risk.
-- These tables contain the canonical normalized observations and their ingest audit.
CREATE SCHEMA IF NOT EXISTS public;

CREATE TABLE IF NOT EXISTS public.observations (
    date DATE NOT NULL,
    indicator TEXT NOT NULL,
    level DOUBLE PRECISION,
    mom_pct_change DOUBLE PRECISION,
    yoy_pct_change DOUBLE PRECISION,
    mar_3_pct DOUBLE PRECISION,
    mar_6_pct DOUBLE PRECISION,
    CONSTRAINT observations_indicator_date_pk PRIMARY KEY (indicator, date)
);

CREATE INDEX IF NOT EXISTS observations_date_idx ON public.observations (date);

CREATE TABLE IF NOT EXISTS public.data_quality_report (
    filename TEXT PRIMARY KEY,
    indicator TEXT NOT NULL,
    status TEXT NOT NULL,
    rows INTEGER,
    first_date DATE,
    last_date DATE,
    missing_level INTEGER,
    missing_mom INTEGER,
    missing_yoy INTEGER,
    error TEXT
);

CREATE INDEX IF NOT EXISTS data_quality_report_indicator_idx
    ON public.data_quality_report (indicator);
