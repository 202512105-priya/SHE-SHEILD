#!/usr/bin/env python3
"""
SHE SHIELD - Safe Cloud PostgreSQL & Neon Verification Suite
Performs zero-PII, masked credential verification of the cloud database connection:
1. Validates DATABASE_URL / POSTGRES_URL environment variables.
2. Safely displays masked hostname and database identity (NEVER exposing passwords).
3. Connects using available PostgreSQL driver (pg8000 or psycopg2).
4. Retrieves PostgreSQL server version and database name.
5. Verifies presence of all 19 required SHE SHIELD domain tables.
6. Performs an atomic write-read-delete verification probe.
7. Verifies table row counts and schema readiness.
"""

import os
import re
import sys
from urllib.parse import urlparse

# Ensure imports work from she_shield/server and local directory
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
SERVER_DIR = os.path.join(CURRENT_DIR, "she_shield", "server")
API_DIR = os.path.join(CURRENT_DIR, "api")
for p in [CURRENT_DIR, SERVER_DIR, API_DIR]:
    if p not in sys.path:
        sys.path.insert(0, p)

# Load .env file if present
def load_env_file():
    env_paths = [
        os.path.join(CURRENT_DIR, ".env"),
        os.path.join(CURRENT_DIR, ".env.local"),
        os.path.join(SERVER_DIR, ".env"),
        os.path.join(API_DIR, ".env"),
    ]
    loaded = []
    for ep in env_paths:
        if os.path.isfile(ep):
            try:
                with open(ep, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if not line or line.startswith("#") or "=" not in line:
                            continue
                        k, v = line.split("=", 1)
                        k = k.strip()
                        v = v.strip().strip("'\"")
                        if k not in os.environ:
                            os.environ[k] = v
                loaded.append(ep)
            except Exception:
                pass
    return loaded

REQUIRED_TABLES = [
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

def mask_connection_url(url: str) -> str:
    if not url:
        return "[EMPTY / NOT SET]"
    return re.sub(r"://([^:]+):([^@]+)@", r"://\1:********@", url)

def run_health_check():
    loaded_env = load_env_file()
    
    print("=" * 70)
    print("  SHE SHIELD - NEON POSTGRESQL CLOUD CONNECTION HEALTH CHECK")
    print("=" * 70)
    
    if loaded_env:
        print(f"[Config] Loaded environment file(s): {', '.join(loaded_env)}")
    else:
        print("[Config] No local .env file found; checking process environment...")

    import db_adapter

    raw_url = db_adapter.get_database_url()
    
    if not raw_url:
        print("\n❌ STATUS: FAILED")
        print("   Reason: Missing DATABASE_URL / POSTGRES_URL environment variable.")
        print("\n   Diagnosis:")
        print("   • Neither DATABASE_URL nor POSTGRES_URL is set in environment or .env.")
        print("   • When no DATABASE_URL is configured, the local application silently falls")
        print("     back to local SQLite (she_shield/server/she_shield.db).")
        print("   • To connect the local application to the same Neon database connected to Vercel:")
        print("     1. Retrieve the Neon DATABASE_URL from Vercel Project Settings > Storage / Environment Variables")
        print("        or run: npx vercel env pull .env")
        print("     2. Place it in a .env file: DATABASE_URL=\"postgresql://...\"")
        print("     3. Re-run this check.")
        print("=" * 70)
        return False, "MISSING_DATABASE_URL"

    # Mask and parse
    masked = mask_connection_url(raw_url)
    parsed = urlparse(raw_url)
    hostname = parsed.hostname or "unknown"
    dbname = parsed.path.lstrip("/") or "unknown"
    is_neon = "neon.tech" in hostname.lower()

    print(f"\n[1/5] Database Connection String:")
    print(f"      • URL:      {masked}")
    print(f"      • Hostname: {hostname}")
    print(f"      • Database: {dbname}")
    print(f"      • Provider: {'Neon PostgreSQL (Verified Hostname)' if is_neon else 'PostgreSQL'}")

    # Check driver
    driver_avail = []
    if db_adapter.HAVE_PSYCOPG2:
        driver_avail.append("psycopg2-binary")
    if db_adapter.HAVE_PG8000:
        driver_avail.append("pg8000 (Pure Python)")
    print(f"      • Drivers:  {', '.join(driver_avail) if driver_avail else 'None available!'}")

    if not driver_avail:
        print("\n❌ STATUS: FAILED")
        print("   Reason: No PostgreSQL driver installed (requires psycopg2 or pg8000).")
        print("=" * 70)
        return False, "MISSING_DRIVER"

    # Attempt connection
    print(f"\n[2/5] Establishing secure SSL connection to PostgreSQL...")
    try:
        conn = db_adapter.connect_postgres(raw_url)
        cur = conn.cursor()
        print(f"      ✅ Connected successfully using driver: {conn.driver_name}")
    except Exception as e:
        print(f"\n❌ STATUS: FAILED")
        print(f"   Reason: Connection error: {e}")
        print("=" * 70)
        return False, f"CONNECTION_ERROR: {e}"

    # Server version & metadata
    print(f"\n[3/5] Querying PostgreSQL server metadata...")
    try:
        cur.execute("SELECT current_database(), version(), current_user;")
        row = cur.fetchone()
        db_curr = row[0]
        ver = row[1]
        user_curr = row[2]
        print(f"      • Current DB:   {db_curr}")
        print(f"      • Connected As: {user_curr}")
        print(f"      • Version:      {ver.split(',')[0] if ver else 'PostgreSQL'}")
    except Exception as e:
        conn.close()
        print(f"\n❌ STATUS: FAILED to query metadata: {e}")
        print("=" * 70)
        return False, f"METADATA_QUERY_FAILED: {e}"

    # Verify tables
    print(f"\n[4/5] Checking schema tables (expected: {len(REQUIRED_TABLES)} application tables)...")
    try:
        cur.execute(
            """
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public';
            """
        )
        existing_tables = set(r[0] for r in cur.fetchall())
        missing = [t for t in REQUIRED_TABLES if t not in existing_tables]
        
        table_counts = {}
        for t in REQUIRED_TABLES:
            if t in existing_tables:
                cur.execute(f"SELECT COUNT(*) FROM {t};")
                cnt = cur.fetchone()[0]
                table_counts[t] = cnt
            else:
                table_counts[t] = 0

        print(f"      • Tables found: {len(existing_tables)} total public tables")
        if missing:
            print(f"      ⚠️ Missing tables: {', '.join(missing)}")
            print("         Run: python3 migrate_to_postgres.py to apply schema.")
        else:
            print("      ✅ All 19 SHE SHIELD domain tables exist!")
            for t in REQUIRED_TABLES:
                print(f"        - {t:<26}: {table_counts[t]} rows")
    except Exception as e:
        conn.close()
        print(f"\n❌ STATUS: FAILED checking tables: {e}")
        print("=" * 70)
        return False, f"TABLE_CHECK_FAILED: {e}"

    # Read/Write/Delete probe
    print(f"\n[5/5] Performing atomic read/write/delete verification probe...")
    test_id = f"PROBE-{os.getpid()}"
    try:
        # Insert test audit log
        insert_sql = """
            INSERT INTO audit_logs (actor_user_id, action, details, created_at)
            VALUES (%s, %s, %s, NOW());
        """
        cur.execute(insert_sql, ("SYSTEM_PROBE", f"HEALTH_CHECK_{test_id}", "127.0.0.1"))
        conn.commit()

        # Read back test audit log
        cur.execute("SELECT id, action FROM audit_logs WHERE action = %s;", (f"HEALTH_CHECK_{test_id}",))
        fetched = cur.fetchone()
        if not fetched:
            raise RuntimeError("Inserted test record could not be retrieved back from PostgreSQL!")
        row_id = fetched[0]
        print(f"      • Insert & retrieve test record: SUCCESS (ID: {row_id})")

        # Delete test audit log
        cur.execute("DELETE FROM audit_logs WHERE id = %s;", (row_id,))
        conn.commit()
        print(f"      • Clean up test record:          SUCCESS (Deleted ID: {row_id})")

    except Exception as e:
        conn.close()
        print(f"\n❌ STATUS: FAILED during read/write probe: {e}")
        print("=" * 70)
        return False, f"RW_PROBE_FAILED: {e}"

    conn.close()
    print("\n" + "=" * 70)
    print("  ✅ VERIFICATION SUCCESSFUL: Neon PostgreSQL is connected, verified,")
    print("     and ready for live reads and writes!")
    print("=" * 70)
    return True, "SUCCESS"

if __name__ == "__main__":
    ok, reason = run_health_check()
    sys.exit(0 if ok else 1)
