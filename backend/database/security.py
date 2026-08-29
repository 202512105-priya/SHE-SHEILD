"""
SHE SHIELD Database Security Module
Defines query safety verification, SQL injection mitigation heuristics,
safe identifier validation, and parameterized query execution standards.

SECURITY NOTICE:
Keyword blacklists (such as check_query_safe) serve ONLY as an initial heuristic
filter (e.g., in WAF or intrusion detection layers). They are NOT a complete defense
against SQL injection attacks. Attackers can bypass keyword filters using character
encoding, obfuscation, whitespace manipulation, or SQL dialect-specific semantics.
ALL actual database interactions in production MUST use parameterized queries
(prepared statements) provided by DB-API 2.0 or an ORM such as SQLAlchemy.
"""

import re
import logging
import sqlite3
import unittest
from typing import Any, Dict, Iterable, List, Optional, Tuple, Union

logger = logging.getLogger(__name__)

# Pattern for safe SQL identifiers (table names, column names)
_SAFE_IDENTIFIER_PATTERN = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_]*$")

# Common SQL injection signatures and dangerous SQL keywords
_DANGEROUS_KEYWORDS: Tuple[str, ...] = (
    "DROP",
    "DELETE",
    "TRUNCATE",
    "OR 1=1",
    "UNION SELECT",
    "EXEC",
    "EXECUTE",
    "SHUTDOWN",
    "ALTER TABLE",
    "--",
    "/*",
    "XP_CMDSHELL",
)


def check_query_safe(query: Any) -> bool:
    """
    Evaluates whether an incoming raw SQL query string contains known dangerous
    keywords or SQL injection patterns.

    Limitations:
        - A keyword blacklist is NOT a comprehensive defense against SQL injection.
        - Obfuscated queries, alternative encodings, and valid user data containing
          substrings like 'delete' can evade or false-positive this filter.
        - Always combine with parameterized queries (execute_parameterized_query).

    Args:
        query: Query string to inspect.

    Returns:
        bool: True if query contains no blacklisted keywords; False otherwise.
    """
    if not isinstance(query, str):
        return False

    cleaned_query = query.strip()
    if not cleaned_query:
        return False

    normalized_upper = cleaned_query.upper()

    # Normalize multiple whitespace characters for detection
    normalized_spacing = " ".join(normalized_upper.split())

    for keyword in _DANGEROUS_KEYWORDS:
        if keyword in normalized_upper or keyword in normalized_spacing:
            logger.warning("Unsafe SQL query detected containing keyword: %s", keyword)
            return False

    # Check for common tautology patterns like ' OR 'a'='a'
    if re.search(r"OR\s+['\"].+?['\"]\s*=\s*['\"].+?['\"]", normalized_spacing):
        logger.warning("Unsafe SQL query detected matching tautology pattern.")
        return False

    return True


def validate_identifier(identifier: str, allowed: Optional[Iterable[str]] = None) -> str:
    """
    Validates a SQL identifier (such as table or column name) against a strict
    alphanumeric whitelist pattern and an optional allowed set.

    SQL identifiers cannot be parameterized using standard query placeholders.
    This validator prevents identifier-based SQL injection.

    Args:
        identifier: The identifier name to validate.
        allowed: Optional collection of permitted identifier names.

    Returns:
        The validated identifier.

    Raises:
        ValueError: If identifier is invalid, empty, or not in the allowed list.
    """
    if not isinstance(identifier, str):
        raise TypeError("SQL identifier must be a string")

    clean_id = identifier.strip()
    if not clean_id or not _SAFE_IDENTIFIER_PATTERN.match(clean_id):
        raise ValueError(f"Invalid SQL identifier: '{identifier}'. Must match ^[a-zA-Z_][a-zA-Z0-9_]*$")

    if allowed is not None and clean_id not in allowed:
        raise ValueError(f"Unauthorized SQL identifier: '{clean_id}'. Not in allowed set.")

    return clean_id


def sanitize_input(value: Any) -> Any:
    """
    Sanitizes string input values by removing null bytes.
    Non-string values are returned as-is.

    Args:
        value: Input data to sanitize.

    Returns:
        Sanitized value.
    """
    if isinstance(value, str):
        return value.replace("\x00", "").strip()
    return value


def build_parameterized_where(
    filters: Dict[str, Any],
    placeholder_style: str = "%s"
) -> Tuple[str, List[Any]]:
    """
    Constructs a safe, parameterized WHERE clause and parameter list from a dictionary.
    Each column name is strictly validated to prevent identifier injection.

    Args:
        filters: Mapping of column names to values.
        placeholder_style: Parameter placeholder style ('%s', '?', ':param').

    Returns:
        Tuple of (where_clause_sql, parameter_values_list).
    """
    if not filters:
        return "", []

    clauses: List[str] = []
    values: List[Any] = []

    for col, val in filters.items():
        validated_col = validate_identifier(col)
        clauses.append(f"{validated_col} = {placeholder_style}")
        values.append(sanitize_input(val))

    where_sql = " WHERE " + " AND ".join(clauses)
    return where_sql, values


def execute_parameterized_query(
    cursor: Any,
    query: str,
    params: Optional[Union[Tuple[Any, ...], List[Any], Dict[str, Any]]] = None
) -> Any:
    """
    Executes a database query using DB-API parameterized execution.
    Parameters are bound safely by the driver, never concatenated into the query.

    Args:
        cursor: Active database cursor (e.g., sqlite3.Cursor or psycopg2 cursor).
        query: SQL statement with parameter placeholders ('?' or '%s').
        params: Parameters to bind to the query.

    Returns:
        The cursor after execution.

    Raises:
        ValueError: If query string is empty or invalid.
        Exception: Re-raises database exceptions after logging.
    """
    if not isinstance(query, str) or not query.strip():
        raise ValueError("Query must be a non-empty string.")

    try:
        if params is None:
            return cursor.execute(query)
        return cursor.execute(query, params)
    except Exception as exc:
        logger.error("Error executing parameterized query: %s", exc)
        raise


# =====================================================================
# Authentication Security Validators (KAN-39)
# =====================================================================
# Security checks module

def validate_auth_payload(payload: Any) -> bool:
    """
    Validates baseline authentication request payload structure.
    """
    if not isinstance(payload, dict):
        return False
    return bool(payload.get("email") and payload.get("password"))


# =====================================================================
# Unit Tests for Database Security Module
# =====================================================================

class TestDatabaseSecurity(unittest.TestCase):
    """Test suite for security verification and parameterized execution."""

    def test_safe_query_passes(self):
        safe_query = "SELECT id, username FROM users WHERE role_id = 1;"
        self.assertTrue(check_query_safe(safe_query))

    def test_dangerous_keywords_detected(self):
        dangerous_queries = [
            "DROP TABLE users;",
            "SELECT * FROM users WHERE id = 1; DELETE FROM users;",
            "TRUNCATE complaints;",
            "SELECT * FROM users WHERE username = 'admin' OR 1=1;",
            "SELECT * FROM users UNION SELECT null, null, null FROM secrets;",
            "EXEC sp_executesql N'SELECT 1';",
            "SELECT * FROM users; -- comment out check",
            "SELECT * FROM users /* comment block */ WHERE 1=1",
        ]
        for query in dangerous_queries:
            with self.subTest(query=query):
                self.assertFalse(check_query_safe(query))

    def test_invalid_input_types(self):
        self.assertFalse(check_query_safe(None))
        self.assertFalse(check_query_safe(""))
        self.assertFalse(check_query_safe(12345))
        self.assertFalse(check_query_safe(["SELECT * FROM users"]))

    def test_validate_identifier_valid(self):
        self.assertEqual(validate_identifier("users"), "users")
        self.assertEqual(validate_identifier("user_id"), "user_id")
        self.assertEqual(validate_identifier("table_123"), "table_123")
        self.assertEqual(validate_identifier("status", allowed={"status", "id"}), "status")

    def test_validate_identifier_invalid(self):
        invalid_ids = [
            "users; DROP TABLE users;",
            "user id",
            "users--",
            "users' OR '1'='1",
            "123_invalid_start",
            "",
            "users/*comment*/",
        ]
        for bad_id in invalid_ids:
            with self.subTest(bad_id=bad_id):
                with self.assertRaises(ValueError):
                    validate_identifier(bad_id)

    def test_validate_identifier_not_in_allowed(self):
        with self.assertRaises(ValueError):
            validate_identifier("password_hash", allowed={"id", "username"})

    def test_sanitize_input(self):
        self.assertEqual(sanitize_input(" hello\x00world "), "helloworld")
        self.assertEqual(sanitize_input(100), 100)

    def test_build_parameterized_where(self):
        filters = {"username": "alice", "status": "active"}
        sql, params = build_parameterized_where(filters, placeholder_style="?")
        self.assertEqual(sql, " WHERE username = ? AND status = ?")
        self.assertEqual(params, ["alice", "active"])

    def test_execute_parameterized_query_sqlite(self):
        conn = sqlite3.connect(":memory:")
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, role TEXT);")
        cursor.execute("INSERT INTO users (username, role) VALUES ('admin', 'superuser');")
        cursor.execute("INSERT INTO users (username, role) VALUES ('alice', 'user');")

        # Parameterized query with user input containing malicious injection string
        malicious_input = "' OR '1'='1"
        execute_parameterized_query(
            cursor,
            "SELECT id, username FROM users WHERE username = ?",
            (malicious_input,)
        )
        results = cursor.fetchall()
        # Parameterized execution treats malicious_input as literal string; returns no rows
        self.assertEqual(results, [])

        # Legitimate query
        execute_parameterized_query(
            cursor,
            "SELECT username FROM users WHERE username = ?",
            ("alice",)
        )
        row = cursor.fetchone()
        self.assertIsNotNone(row)
        self.assertEqual(row[0], "alice")
        conn.close()


if __name__ == "__main__":
    unittest.main()
