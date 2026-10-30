"""Load the two canonical CSV exports into an existing PostgreSQL schema.

Run database/schema/00_tables.sql first. Explicit --replace required; this
truncates BOTH base tables, so use only on a new/demo database or one that you
intentionally want to reconstruct. Use PG* environment variables to connect.
"""
import argparse
import os
from pathlib import Path
import psycopg

ROOT = Path(__file__).resolve().parents[1]
PARSER = argparse.ArgumentParser(description=__doc__)
PARSER.add_argument('--replace', action='store_true', help='Required; clears existing imported data')
args = PARSER.parse_args()
if not args.replace:
    PARSER.error('Pass --replace after confirming that the destination is safe to clear.')

options = {k: os.environ[k] for k in ['PGHOST','PGPORT','PGDATABASE','PGUSER','PGPASSWORD'] if k in os.environ}
if not options.get('PGDATABASE'):
    raise SystemExit('Set PGDATABASE and other PG* variables first (see .env.example).')

files = [
    ('public.observations', ROOT / 'data/processed/macroeconomic_consolidated.csv'),
    ('public.data_quality_report', ROOT / 'data/quality/data_quality_report.csv'),
]
with psycopg.connect(**{
    'host':options.get('PGHOST','localhost'),
    'port':int(options.get('PGPORT',5432)),
    'dbname':options['PGDATABASE'],
    'user':options.get('PGUSER','postgres'),
    **({'password':options['PGPASSWORD']} if 'PGPASSWORD' in options else {}),
}) as conn:
    with conn.cursor() as cur:
        cur.execute('TRUNCATE TABLE public.observations, public.data_quality_report')
        for table, filepath in files:
            print('Loading',filepath)
            with filepath.open('r',encoding='utf-8-sig',newline='') as src:
                with cur.copy(f'COPY {table} FROM STDIN WITH (FORMAT CSV, HEADER TRUE)') as cp:
                    while chunk := src.read(65536):
                        cp.write(chunk)
        for table,_ in files:
            cur.execute(f'SELECT COUNT(*) FROM {table}')
            print(table, cur.fetchone()[0], 'rows')
print('Import committed successfully.')
