import os
import shutil
import sys

API_DIR = os.path.dirname(os.path.abspath(__file__))
if API_DIR not in sys.path:
    sys.path.insert(0, API_DIR)

import db_adapter

os.environ["SHESHIELD_VAULT_PATH"] = "/tmp/secure_audio_vault"

if db_adapter.is_cloud_turso_configured():
    print("[Vercel Serverless] Cloud Turso libSQL configured via TURSO_DATABASE_URL / TURSO_AUTH_TOKEN")
elif db_adapter.is_cloud_postgres_configured():
    print("[Vercel Serverless] Cloud PostgreSQL configured via DATABASE_URL / POSTGRES_URL")
else:
    # Fallback to ephemeral SQLite in /tmp only when no cloud database URL is configured
    TMP_DB = "/tmp/she_shield.db"
    BUNDLED_DB = os.path.join(API_DIR, "she_shield.db")
    if not os.path.exists(TMP_DB) and os.path.exists(BUNDLED_DB):
        try:
            shutil.copyfile(BUNDLED_DB, TMP_DB)
        except Exception as e:
            print(f"[Vercel Init] Could not copy bundled DB to /tmp: {e}")
    os.environ["SHESHIELD_DB_PATH"] = TMP_DB

from local_sqlite_server import SQLiteAPIHandler, init_db

try:
    init_db()
except Exception as e:
    print(f"[Vercel Init] init_db warning: {e}")

class handler(SQLiteAPIHandler):
    pass
