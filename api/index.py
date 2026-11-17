import os
import shutil
import sys

API_DIR = os.path.dirname(os.path.abspath(__file__))
if API_DIR not in sys.path:
    sys.path.insert(0, API_DIR)

import db_adapter

os.environ["SHESHIELD_VAULT_PATH"] = "/tmp/secure_audio_vault"

if db_adapter.is_cloud_postgres_configured():
    print("[Vercel Serverless] Cloud PostgreSQL (Neon) configured via DATABASE_URL / POSTGRES_URL")
elif db_adapter.is_cloud_turso_configured():
    print("[Vercel Serverless] Cloud Turso libSQL configured via TURSO_DATABASE_URL / TURSO_AUTH_TOKEN")
else:
    print("[Vercel Serverless] Warning: No cloud database connection string found in environment.")

from local_sqlite_server import SQLiteAPIHandler, init_db

try:
    init_db()
except Exception as e:
    print(f"[Vercel Init] init_db warning: {e}")

class handler(SQLiteAPIHandler):
    pass
