"""Fail-fast isolated core setup (00/02/03/04 only), never full-demo certification.

Use an existing extra-small, auto-suspending warehouse. This runner refuses
canonical/live database names, existing databases, wrong accounts, and large
warehouses. It does not train models, activate schedules, or create AWS objects.
"""
import argparse
import io
import json
import re
import time
from pathlib import Path

FILES = ('00_setup.sql', '02_raw_tables.sql', '03_staging.sql', '04_dynamic_tables.sql')
DYNAMIC_TABLES = ('PERFORMANCE_SUMMARY', 'TREND_ANALYSIS', 'EVENT_TYPE_SUMMARY', 'KPI_SUMMARY')


def checked_identifier(value):
    if not re.fullmatch(r'[A-Z][A-Z0-9_]{0,127}', value):
        raise ValueError('Use simple uppercase SQL identifiers')
    return value


def validate_target(database, warehouse):
    checked_identifier(database)
    checked_identifier(warehouse)
    if not database.startswith('PHILIPPINES_BPO_WORKFORCE_'):
        raise ValueError('Only isolated PHILIPPINES_BPO_WORKFORCE_ databases are accepted')


def connect(name):
    import os
    import tomllib
    import snowflake.connector
    home = Path(os.environ.get('SNOWFLAKE_HOME', Path.home() / '.snowflake'))
    for filename in ('connections.toml', 'config.toml'):
        path = home / filename
        if path.exists():
            config = tomllib.loads(path.read_text())
            connections = config.get('connections', config)
            if name in connections:
                return snowflake.connector.connect(**connections[name])
    raise RuntimeError('Named local Snowflake connection not found')


def run(connection, database, warehouse, expect_account=None):
    from snowflake.connector.util_text import split_statements
    validate_target(database, warehouse)
    evidence = []
    cursor = connection.cursor()
    created_database = False
    try:
        cursor.execute('SELECT CURRENT_ACCOUNT_NAME(), CURRENT_ACCOUNT(), CURRENT_REGION()')
        identity = cursor.fetchone()
        if expect_account and identity[1] != expect_account.upper():
            raise RuntimeError('Snowflake identity mismatch; no writes attempted')
        cursor.execute('SHOW WAREHOUSES')
        names = [column[0].lower() for column in cursor.description]
        warehouses = [dict(zip(names, row)) for row in cursor.fetchall()]
        selected = next((row for row in warehouses if row['name'] == warehouse), None)
        if not selected or selected['size'] != 'X-Small' or not 1 <= int(selected['auto_suspend']) <= 120:
            raise RuntimeError('Warehouse must exist, be X-Small and auto-suspend within 120 seconds')
        cursor.execute('SHOW DATABASES')
        names = [column[0].lower() for column in cursor.description]
        if any(dict(zip(names, row))['name'] == database for row in cursor.fetchall()):
            raise RuntimeError('Target already exists; choose a new isolated namespace')
        cursor.execute('SET DEMO_DB = %s', (database,))
        cursor.execute('SET DEMO_WH = %s', (warehouse,))
        cursor.execute("ALTER SESSION SET STATEMENT_TIMEOUT_IN_SECONDS = 60, QUERY_TAG = 'ph-bpo-workforce-core'")
        for filename in FILES:
            sql = (Path(__file__).resolve().parent / filename).read_text()
            # DT WAREHOUSE is a DDL property and rejects IDENTIFIER($variable).
            # Only a validated simple identifier is substituted, never free text.
            sql = sql.replace('__DEMO_WH__', warehouse)
            for statement, _ in split_statements(io.StringIO(sql)):
                if not statement.strip():
                    continue
                started = time.monotonic()
                cursor.execute(statement)
                if filename == '00_setup.sql' and 'CREATE DATABASE IDENTIFIER' in statement:
                    created_database = True
                evidence.append({'file': filename, 'query_id': cursor.sfqid,
                                 'seconds': round(time.monotonic() - started, 3)})
        cursor.execute('SELECT COUNT(*) FROM RAW.TEAMS')
        team_count = cursor.fetchone()[0]
        cursor.execute('SELECT COUNT(*) FROM RAW.TEAM_DAILY')
        observations = cursor.fetchone()[0]
        if (team_count, observations) != (40, 3600):
            raise RuntimeError('Unexpected synthetic source cardinalities')
        cursor.execute("SELECT TITLE, VALUE_NUM FROM CURATED.KPI_SUMMARY ORDER BY SORT_ORDER")
        metrics = dict(cursor.fetchall())
        # Data is randomised, so check KPIs against independent recomputation from RAW.
        cursor.execute("""SELECT (SELECT COUNT(*) FROM RAW.TEAMS),
            (SELECT ROUND(100.0 * SUM(LEAST(ON_FILE_QTY, REQUIRED_QTY)) / SUM(REQUIRED_QTY), 6) FROM RAW.TRAINING_RECORDS),
            (SELECT ROUND(100.0 * SUM(GAP_COUNT) / SUM(WORKFORCE_EVENT_COUNT), 6) FROM RAW.TEAM_DAILY),
            (SELECT ROUND(100.0 * SUM(QA_COMPLETED) / SUM(QA_DUE), 6) FROM RAW.TEAM_DAILY),
            (SELECT SUM(WORKFORCE_EVENT_COUNT) FROM RAW.TEAM_DAILY),
            (SELECT ROUND(100.0 * (SUM(CONTACTS_HANDLED) - SUM(WORKFORCE_EVENT_COUNT)) / SUM(CONTACTS_HANDLED), 6) FROM RAW.TEAM_DAILY)""")
        expected = dict(zip(['Teams Monitored', 'Training Coverage', 'Event Gap Rate',
                             'QA Calibration Compliance', 'Workforce Events Logged', 'Event-Free Contact Rate'],
                            cursor.fetchone()))
        for title, value in expected.items():
            if abs(float(metrics[title]) - float(value)) > 1e-4:
                raise RuntimeError(f'KPI {title} failed recomputation')
        cursor.execute("SELECT MAX(EVENT_GAP_PCT) - MIN(EVENT_GAP_PCT) FROM CURATED.PERFORMANCE_SUMMARY")
        if float(cursor.fetchone()[0]) < 1.0:
            raise RuntimeError('Synthetic data lacks variation between teams')
        if not 0 <= metrics['Event Gap Rate'] <= 100:
            raise RuntimeError('Event gap rate outside valid range')
        return {'database': database, 'warehouse': warehouse, 'queries': evidence,
                'team_count': team_count, 'observation_count': observations,
                'kpis': metrics, 'scope': 'core only; ML/AI/AWS/app checks not included'}
    finally:
        if created_database:
            # Only the namespace created by this run can be suspended here.
            for table in DYNAMIC_TABLES:
                try:
                    cursor.execute(f'ALTER DYNAMIC TABLE IF EXISTS {database}.CURATED.{table} SUSPEND')
                except Exception:
                    print(f'WARNING: verify suspension for {database}.CURATED.{table}')
        cursor.close()
        connection.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--connection', required=True, help='Snowflake connection name')
    parser.add_argument('--expect-account', help='Optional account locator guard; stops before writes on mismatch')
    parser.add_argument('--database', required=True)
    parser.add_argument('--warehouse', required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    validate_target(args.database, args.warehouse)
    if not args.apply:
        print(json.dumps({'mode': 'dry-run', 'database': args.database, 'warehouse': args.warehouse, 'scripts': FILES}))
        return
    print(json.dumps(run(connect(args.connection), args.database, args.warehouse, args.expect_account), indent=2, default=str))


if __name__ == '__main__':
    main()
