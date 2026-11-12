import os
import shutil
import sys

API_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.abspath(os.path.join(API_DIR, ".."))
SERVER_DIR = os.path.join(ROOT_DIR, "she_shield", "server")

# Add server directory to Python path
if SERVER_DIR not in sys.path:
    sys.path.insert(0, SERVER_DIR)
if API_DIR not in sys.path:
    sys.path.insert(0, API_DIR)

# Prepare writable database in /tmp for Vercel Serverless environment
TMP_DB = "/tmp/she_shield.db"
BUNDLED_DB = os.path.join(API_DIR, "she_shield.db")
if not os.path.exists(BUNDLED_DB):
    BUNDLED_DB = os.path.join(SERVER_DIR, "she_shield.db")

if not os.path.exists(TMP_DB) and os.path.exists(BUNDLED_DB):
    try:
        shutil.copyfile(BUNDLED_DB, TMP_DB)
    except Exception as e:
        print(f"[Vercel Init] Could not copy bundled DB to /tmp: {e}")

# Set database and vault paths
os.environ["SHESHIELD_DB_PATH"] = TMP_DB
os.environ["SHESHIELD_VAULT_PATH"] = "/tmp/secure_audio_vault"

from local_sqlite_server import SQLiteAPIHandler, init_db

# Ensure all tables and seed records are initialized
try:
    init_db()
except Exception as e:
    print(f"[Vercel Init] init_db warning: {e}")

class handler(SQLiteAPIHandler):
    pass
