#!/usr/bin/env python3
"""
SHE SHIELD - Unified Database Adapter
Supports Neon PostgreSQL (production on Vercel) and SQLite 3 (local development).
Handles:
- Dynamic connection via DATABASE_URL / POSTGRES_URL
- Pure-Python pg8000 and binary psycopg2 driver support
- Automatic query parameter translation (? to %s for PostgreSQL)
- Dual-access DictRow (row["column"] and row[0])
- Table creation, role/permission seeding, and automatic data migration
"""

import base64
import json
import os
import re
import sqlite3
import ssl
import sys
import urllib.error
import urllib.request
from urllib.parse import urlparse

# Driver discovery
HAVE_PSYCOPG2 = False
HAVE_PG8000 = False

try:
    import psycopg2
    import psycopg2.extras
    HAVE_PSYCOPG2 = True
except ImportError:
    pass

try:
    import pg8000.dbapi
    HAVE_PG8000 = True
except ImportError:
    pass


class DictRow(tuple):
    """Row wrapper allowing column access by name (row['email']) and index (row[0])."""
    def __new__(cls, values, description):
        instance = super().__new__(cls, values)
        instance._index = {}
        if description:
            for i, desc in enumerate(description):
                col_name = desc[0] if isinstance(desc, (list, tuple)) else str(desc)
                instance._index[col_name] = i
                # Also store lowercase variant for case-insensitive lookup
                instance._index[col_name.lower()] = i
        return instance

    def __getitem__(self, key):
        if isinstance(key, str):
            idx = self._index.get(key)
            if idx is None:
                idx = self._index.get(key.lower())
            if idx is None:
                raise KeyError(key)
            return super().__getitem__(idx)
        return super().__getitem__(key)

    def get(self, key, default=None):
        try:
            return self[key]
        except (KeyError, IndexError):
            return default

    def keys(self):
        return [k for k in self._index.keys() if k == k.lower()]


def translate_query_for_postgres(sql: str) -> str:
    """Translates SQLite query constructs to PostgreSQL-compatible SQL."""
    # Convert 'INSERT OR IGNORE INTO' -> 'INSERT INTO ... ON CONFLICT DO NOTHING'
    is_insert_ignore = bool(re.search(r"INSERT\s+OR\s+IGNORE\s+INTO", sql, re.IGNORECASE))
    if is_insert_ignore:
        sql = re.sub(r"INSERT\s+OR\s+IGNORE\s+INTO", "INSERT INTO", sql, flags=re.IGNORECASE)

    # Convert parameter placeholders '?' -> '%s' (outside single-quoted strings)
    result = []
    in_quote = False
    i = 0
    n = len(sql)
    while i < n:
        ch = sql[i]
        if ch == "'":
            if in_quote and i + 1 < n and sql[i + 1] == "'":
                result.append("''")
                i += 2
                continue
            in_quote = not in_quote
            result.append(ch)
        elif ch == "?" and not in_quote:
            result.append("%s")
        else:
            result.append(ch)
        i += 1

    converted = "".join(result).strip()

    if is_insert_ignore and not re.search(r"ON\s+CONFLICT", converted, re.IGNORECASE):
        # Append ON CONFLICT DO NOTHING if query ends with semicolon
        if converted.endswith(";"):
            converted = converted[:-1].strip() + " ON CONFLICT DO NOTHING;"
        else:
            converted = converted + " ON CONFLICT DO NOTHING"

    return converted


class PostgresCursorWrapper:
    """Wraps PostgreSQL cursor to mimic sqlite3.Cursor with DictRow row factory."""
    def __init__(self, raw_cursor, connection):
        self._cur = raw_cursor
        self.connection = connection

    @property
    def description(self):
        return self._cur.description

    @property
    def rowcount(self):
        return self._cur.rowcount

    def execute(self, sql, params=None):
        pg_sql = translate_query_for_postgres(sql)
        if params is not None:
            if isinstance(params, (list, tuple)):
                p = tuple(params)
            else:
                p = (params,)
            self._cur.execute(pg_sql, p)
        else:
            self._cur.execute(pg_sql)
        return self

    def executemany(self, sql, seq_of_params):
        pg_sql = translate_query_for_postgres(sql)
        self._cur.executemany(pg_sql, seq_of_params)
        return self

    def fetchone(self):
        row = self._cur.fetchone()
        if row is None:
            return None
        return DictRow(row, self._cur.description)

    def fetchall(self):
        desc = self._cur.description
        rows = self._cur.fetchall()
        return [DictRow(r, desc) for r in rows]

    def close(self):
        try:
            self._cur.close()
        except Exception:
            pass


class PostgresConnectionWrapper:
    """Wraps PostgreSQL connection to provide unified SQLite-compatible interface."""
    def __init__(self, raw_conn, driver_name="pg8000"):
        self._conn = raw_conn
        self.driver_name = driver_name
        self.is_postgres = True

    def cursor(self):
        return PostgresCursorWrapper(self._conn.cursor(), self)

    def execute(self, sql, params=None):
        cur = self.cursor()
        cur.execute(sql, params)
        return cur

    def commit(self):
        self._conn.commit()

    def rollback(self):
        try:
            self._conn.rollback()
        except Exception:
            pass

    def close(self):
        try:
            self._conn.close()
        except Exception:
            pass

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.rollback()
        else:
            self.commit()
        self.close()


def load_env_file():
    """Safely loads variables from .env or .env.local if present, without overwriting existing env."""
    current = os.path.dirname(os.path.abspath(__file__))
    candidates = [
        os.path.join(current, ".env"),
        os.path.join(current, ".env.local"),
        os.path.join(current, "..", ".env"),
        os.path.join(current, "..", ".env.local"),
        os.path.join(current, "..", "..", ".env"),
        os.path.join(current, "..", "..", ".env.local"),
    ]
    for c in candidates:
        if os.path.isfile(c):
            try:
                with open(c, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if not line or line.startswith("#") or "=" not in line:
                            continue
                        k, v = line.split("=", 1)
                        k = k.strip()
                        v = v.strip().strip("'\"")
                        if k and k not in os.environ:
                            os.environ[k] = v
            except Exception:
                pass


def get_database_url() -> str:
    """Retrieves PostgreSQL connection URL from environment variables."""
    load_env_file()
    url = (
        os.environ.get("DATABASE_URL")
        or os.environ.get("POSTGRES_URL")
        or os.environ.get("POSTGRES_PRISMA_URL")
        or os.environ.get("POSTGRES_URL_NON_POOLING")
        or ""
    ).strip()
    return url


def is_cloud_postgres_configured() -> bool:
    """Returns True if a PostgreSQL connection string is configured in environment."""
    url = get_database_url()
    return bool(url and (url.startswith("postgres://") or url.startswith("postgresql://")))


def connect_postgres(url: str):
    """Establishes SSL connection to Neon PostgreSQL using available driver."""
    # Standardize URL scheme for driver compatibility
    clean_url = url
    if clean_url.startswith("postgres://"):
        clean_url = "postgresql://" + clean_url[len("postgres://"):]

    # Remove conflicting query parameters if any
    parsed = urlparse(clean_url)
    user = parsed.username or "default"
    password = parsed.password or ""
    host = parsed.hostname or "localhost"
    port = parsed.port or 5432
    database = parsed.path.lstrip("/") or "neondb"

    # Strategy 1: psycopg2 (fastest binary C-extension)
    if HAVE_PSYCOPG2:
        try:
            conn = psycopg2.connect(
                clean_url,
                sslmode="require",
                connect_timeout=10,
            )
            return PostgresConnectionWrapper(conn, driver_name="psycopg2")
        except Exception as e:
            print(f"[DB Adapter] psycopg2 connection failed: {e}. Trying pg8000...")

    # Strategy 2: pg8000 (pure Python, 100% serverless compatible)
    if HAVE_PG8000:
        ssl_ctx = ssl.create_default_context()
        ssl_ctx.check_hostname = False
        ssl_ctx.verify_mode = ssl.CERT_NONE
        conn = pg8000.dbapi.connect(
            user=user,
            password=password,
            host=host,
            port=port,
            database=database,
            ssl_context=ssl_ctx,
            timeout=15,
        )
        return PostgresConnectionWrapper(conn, driver_name="pg8000")

    raise RuntimeError("No PostgreSQL driver available (neither psycopg2 nor pg8000 installed).")


class SqliteConnectionWrapper:
    """Wraps sqlite3.Connection to provide is_postgres attribute and transparent delegation."""
    def __init__(self, raw_conn):
        self._conn = raw_conn
        self.is_postgres = False
        self.driver_name = "sqlite3"

    @property
    def row_factory(self):
        return self._conn.row_factory

    @row_factory.setter
    def row_factory(self, val):
        self._conn.row_factory = val

    def cursor(self):
        return self._conn.cursor()

    def execute(self, sql, params=None):
        if params is not None:
            return self._conn.execute(sql, params)
        return self._conn.execute(sql)

    def executemany(self, sql, seq_of_params):
        return self._conn.executemany(sql, seq_of_params)

    def commit(self):
        self._conn.commit()

    def rollback(self):
        self._conn.rollback()

    def close(self):
        self._conn.close()

    def __getattr__(self, name):
        return getattr(self._conn, name)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.rollback()
        else:
            self.commit()
        self.close()


def get_turso_config():
    """Retrieves Turso database URL and auth token from environment variables."""
    load_env_file()
    url = (os.environ.get("TURSO_DATABASE_URL") or os.environ.get("TURSO_DB_URL") or "").strip()
    token = (os.environ.get("TURSO_AUTH_TOKEN") or os.environ.get("TURSO_DB_AUTH_TOKEN") or "").strip()
    return url, token


def is_cloud_turso_configured() -> bool:
    """Returns True if a Turso cloud connection string and auth token are configured."""
    url, token = get_turso_config()
    return bool(url and token and url.startswith("libsql://"))


class TursoCursorWrapper:
    """Wraps Turso / libSQL HTTP pipeline execution with sqlite3.Cursor interface & DictRow."""
    def __init__(self, conn):
        self.conn = conn
        self.connection = conn
        self.description = None
        self.rowcount = -1
        self._rows = []
        self._pos = 0

    def _format_args(self, params):
        if params is None:
            return []
        if not isinstance(params, (list, tuple)):
            params = [params]
        args = []
        for p in params:
            if p is None:
                args.append({"type": "null"})
            elif isinstance(p, bool):
                args.append({"type": "integer", "value": "1" if p else "0"})
            elif isinstance(p, int):
                args.append({"type": "integer", "value": str(p)})
            elif isinstance(p, float):
                args.append({"type": "float", "value": p})
            elif isinstance(p, bytes):
                args.append({"type": "blob", "base64": base64.b64encode(p).decode("ascii")})
            else:
                args.append({"type": "text", "value": str(p)})
        return args

    def execute(self, sql, params=None):
        args = self._format_args(params)
        payload = {
            "requests": [
                {
                    "type": "execute",
                    "stmt": {
                        "sql": sql,
                        "args": args
                    }
                },
                {"type": "close"}
            ]
        }
        res = self.conn._request(payload)
        stmt_res = res["results"][0]
        if stmt_res.get("type") == "error":
            raise RuntimeError(f"Turso Error: {stmt_res['error']['message']}")
        result = stmt_res["response"]["result"]
        cols = result.get("cols", [])
        self.description = [(c["name"], None, None, None, None, None, None) for c in cols]
        self.rowcount = result.get("affected_row_count", 0)
        raw_rows = result.get("rows", [])
        self._rows = []
        for r in raw_rows:
            parsed_vals = []
            for cell in r:
                t = cell.get("type")
                if t == "null":
                    parsed_vals.append(None)
                elif t == "integer":
                    parsed_vals.append(int(cell["value"]))
                elif t == "float":
                    parsed_vals.append(float(cell["value"]))
                elif t == "blob":
                    parsed_vals.append(base64.b64decode(cell["base64"]))
                else:
                    parsed_vals.append(cell.get("value"))
            self._rows.append(DictRow(tuple(parsed_vals), self.description))
        self._pos = 0
        return self

    def executemany(self, sql, seq_of_params):
        for params in seq_of_params:
            self.execute(sql, params)
        return self

    def fetchone(self):
        if self._pos < len(self._rows):
            row = self._rows[self._pos]
            self._pos += 1
            return row
        return None

    def fetchall(self):
        remaining = self._rows[self._pos:]
        self._pos = len(self._rows)
        return remaining

    def close(self):
        pass


class TursoConnectionWrapper:
    """Wraps Turso HTTP pipeline to provide unified SQLite-compatible connection interface."""
    def __init__(self, db_url, auth_token):
        self.db_url = db_url
        self.auth_token = auth_token
        self.http_url = db_url.replace("libsql://", "https://") + "/v2/pipeline"
        self.is_postgres = False
        self.is_turso = True
        self.driver_name = "turso_cloud"
        self._opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def _request(self, payload):
        req = urllib.request.Request(
            self.http_url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {self.auth_token}",
                "Content-Type": "application/json"
            }
        )
        try:
            with self._opener.open(req, timeout=15) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8")
            raise RuntimeError(f"Turso HTTP Error {e.code}: {err_body}")
        except Exception as e:
            raise RuntimeError(f"Turso Connection Error: {e}")

    def cursor(self):
        return TursoCursorWrapper(self)

    def execute(self, sql, params=None):
        cur = self.cursor()
        cur.execute(sql, params)
        return cur

    def commit(self):
        pass

    def rollback(self):
        pass

    def close(self):
        pass

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()


def get_db(sqlite_fallback_path: str = None):
    """
    Main database connection factory.
    1. Returns Turso Cloud connection if TURSO_DATABASE_URL is set.
    2. Returns PostgreSQL connection if DATABASE_URL is set.
    3. Falls back to local SQLite file.
    """
    # 1. Turso Cloud SQLite (Vercel Marketplace)
    if is_cloud_turso_configured():
        url, token = get_turso_config()
        return TursoConnectionWrapper(url, token)

    # 2. PostgreSQL (Neon)
    url = get_database_url()
    if url and (url.startswith("postgres://") or url.startswith("postgresql://")):
        return connect_postgres(url)

    # 3. Offline / Local fallback to SQLite
    if not sqlite_fallback_path:
        server_dir = os.path.dirname(os.path.abspath(__file__))
        sqlite_fallback_path = os.environ.get("SHESHIELD_DB_PATH") or os.path.join(server_dir, "she_shield.db")

    conn = sqlite3.connect(sqlite_fallback_path, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return SqliteConnectionWrapper(conn)
