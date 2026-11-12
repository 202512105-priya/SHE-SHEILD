#!/usr/bin/env python3
"""
SHE SHIELD - SQLite to Neon PostgreSQL Database Migration Script
Safely migrates all 19 domain tables, records, foreign keys, and indexes from
she_shield.db to the connected Neon PostgreSQL database.
"""

import argparse
import os
import sqlite3
import sys
from urllib.parse import urlparse

# Ensure local imports work
SERVER_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "she_shield", "server")
if SERVER_DIR not in sys.path:
    sys.path.insert(0, SERVER_DIR)

import db_adapter

TABLES_IN_ORDER = [
    "roles",
    "permissions",
    "role_permissions",
    "users",
    "authentication_sessions",
    "audit_logs",
    "sos_cases",
    "cyber_complaints",
    "vault_assets",
    "guardians",
    "cab_trips",
    "audio_evidence",
    "travel_journeys",
    "journey_locations",
    "journey_sharing",
    "journey_events",
    "guardian_connections",
    "guardian_invitations",
    "guardian_notifications",
]


def load_schema_ddl():
    schema_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "she_shield_postgres_schema.sql")
    if not os.path.isfile(schema_path):
        raise FileNotFoundError(f"PostgreSQL schema file not found at: {schema_path}")
    with open(schema_path, "r", encoding="utf-8") as f:
        return f.read()


def migrate(database_url: str, sqlite_db_path: str):
    print("=" * 70)
    print("  SHE SHIELD - NEON POSTGRESQL DATABASE MIGRATION")
    print("=" * 70)

    if not sqlite_db_path or not os.path.isfile(sqlite_db_path):
        raise FileNotFoundError(f"SQLite source database not found at: {sqlite_db_path}")

    # 1. Connect to SQLite
    print(f"\n[1/5] Connecting to SQLite source: {sqlite_db_path}")
    s_conn = sqlite3.connect(sqlite_db_path)
    s_conn.row_factory = sqlite3.Row
    s_cur = s_conn.cursor()

    sqlite_counts = {}
    for table in TABLES_IN_ORDER:
        try:
            cnt = s_cur.execute(f"SELECT COUNT(*) FROM {table};").fetchone()[0]
            sqlite_counts[table] = cnt
        except sqlite3.OperationalError:
            sqlite_counts[table] = 0
    print(f"      Source contains records across {len(sqlite_counts)} tables.")

    # 2. Connect to PostgreSQL
    print(f"\n[2/5] Connecting to Cloud PostgreSQL (Neon)...")
    parsed = urlparse(database_url)
    masked_url = f"{parsed.scheme}://{parsed.username}:****@{parsed.hostname}:{parsed.port or 5432}{parsed.path}"
    print(f"      Target: {masked_url}")

    pg_conn = db_adapter.connect_postgres(database_url)
    pg_cur = pg_conn.cursor()
    print(f"      Connection established using driver: {pg_conn.driver_name}")

    # 3. Create Schema & Tables
    print(f"\n[3/5] Applying PostgreSQL DDL Schema (19 tables, constraints, indexes)...")
    ddl = load_schema_ddl()
    # Split statements safely by semicolon
    statements = [stmt.strip() for stmt in ddl.split(";") if stmt.strip()]
    applied_count = 0
    for stmt in statements:
        # Ignore comments
        clean = "\n".join(l for l in stmt.splitlines() if not l.strip().startswith("--")).strip()
        if clean:
            pg_cur.execute(clean)
            applied_count += 1
    pg_conn.commit()
    print(f"      Executed {applied_count} DDL statements successfully.")

    # 4. Migrate Data
    print(f"\n[4/5] Migrating records in foreign-key dependency order...")
    pg_counts_after = {}

    for table in TABLES_IN_ORDER:
        src_count = sqlite_counts.get(table, 0)
        if src_count == 0:
            print(f"      - {table}: 0 records (skipped)")
            pg_cur.execute(f"SELECT COUNT(*) FROM {table};")
            pg_counts_after[table] = pg_cur.fetchone()[0]
            continue

        # Fetch SQLite columns
        s_cur.execute(f"SELECT * FROM {table};")
        rows = s_cur.fetchall()
        if not rows:
            continue

        col_names = [d[0] for d in s_cur.description]
        col_list_str = ", ".join(col_names)
        placeholders = ", ".join("%s" for _ in col_names)

        # Build conflict resolution
        conflict_clause = "ON CONFLICT DO NOTHING"

        insert_sql = f"INSERT INTO {table} ({col_list_str}) VALUES ({placeholders}) {conflict_clause};"

        inserted_batch = []
        for r in rows:
            inserted_batch.append(tuple(r[col] for col in col_names))

        pg_cur.executemany(insert_sql, inserted_batch)
        pg_conn.commit()

        # Count in PG
        pg_cur.execute(f"SELECT COUNT(*) FROM {table};")
        after_count = pg_cur.fetchone()[0]
        pg_counts_after[table] = after_count

        print(f"      - {table}: migrated {len(inserted_batch)} rows (PostgreSQL total: {after_count})")

    # 5. Fix sequence for audit_logs
    try:
        pg_cur.execute("SELECT setval('audit_logs_id_seq', COALESCE((SELECT MAX(id) FROM audit_logs), 1));")
        pg_conn.commit()
    except Exception as e:
        print(f"      [Notice] Sequence reset for audit_logs: {e}")

    # Summary report
    print("\n[5/5] Migration Verification Report:")
    print("-" * 60)
    print(f"{'Table Name':<28} | {'SQLite Count':<12} | {'PostgreSQL Count':<12}")
    print("-" * 60)
    all_match = True
    for table in TABLES_IN_ORDER:
        s_c = sqlite_counts.get(table, 0)
        p_c = pg_counts_after.get(table, 0)
        status = "OK" if p_c >= s_c else "MISMATCH"
        if status != "OK":
            all_match = False
        print(f"{table:<28} | {s_c:<12} | {p_c:<12} [{status}]")
    print("-" * 60)

    if all_match:
        print("\nSUCCESS: All tables and records successfully migrated to Neon PostgreSQL!")
    else:
        print("\nWARNING: Some tables have count differences. Inspect output above.")

    s_conn.close()
    pg_conn.close()
    return all_match


def main():
    parser = argparse.ArgumentParser(description="Migrate SHE SHIELD from SQLite to Neon PostgreSQL.")
    parser.add_argument("--database-url", help="Target PostgreSQL connection string (defaults to DATABASE_URL env var)")
    parser.add_argument("--sqlite-db", help="Source SQLite DB path (defaults to she_shield/server/she_shield.db)")

    args = parser.parse_args()

    db_url = args.database_url or os.environ.get("DATABASE_URL") or os.environ.get("POSTGRES_URL")
    if not db_url:
        print("ERROR: DATABASE_URL not provided.")
        print("Provide via environment variable: export DATABASE_URL='postgresql://...'")
        print("Or pass as argument: python3 migrate_to_postgres.py --database-url 'postgresql://...'")
        sys.exit(1)

    sqlite_path = args.sqlite_db or os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "she_shield", "server", "she_shield.db"
    )

    success = migrate(db_url, sqlite_path)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
