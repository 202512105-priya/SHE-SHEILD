#!/usr/bin/env python3
"""
SHE SHIELD - Admin CLI Provisioner
Creates or sets the password for an Admin user directly in she_shield.db using bcrypt.
Never embeds passwords in frontend or API application source code.
"""

import argparse
import getpass
import sys
import uuid

from local_sqlite_server import (
    EMAIL_REGEX,
    get_db,
    hash_password,
    init_db,
    log_audit,
    normalize_phone,
    phone_digits,
    utc_now_iso,
    validate_password_strength,
)


def main():
    parser = argparse.ArgumentParser(description="Create or update a SHE SHIELD Admin account in SQLite.")
    parser.add_argument("--email", required=True, help="Admin email address")
    parser.add_argument("--name", default="System Administrator", help="Full name (used if creating new admin)")
    parser.add_argument("--phone", default="+91 90000 00001", help="Phone number (used if creating new admin)")
    parser.add_argument("--password", help="Admin password (if omitted, prompts securely)")
    args = parser.parse_args()

    email = args.email.strip().lower()
    if not EMAIL_REGEX.match(email):
        print("Error: Invalid email format.", file=sys.stderr)
        sys.exit(1)

    password = args.password
    if not password:
        password = getpass.getpass("Enter Admin password: ")
        confirm = getpass.getpass("Confirm Admin password: ")
        if password != confirm:
            print("Error: Passwords do not match.", file=sys.stderr)
            sys.exit(1)

    pw_err = validate_password_strength(password)
    if pw_err:
        print(f"Error: {pw_err}", file=sys.stderr)
        sys.exit(1)

    init_db()
    conn = get_db()
    c = conn.cursor()
    now_iso = utc_now_iso()
    pw_hash = hash_password(password)

    existing = c.execute("SELECT id, full_name, role_id FROM users WHERE LOWER(email) = ?;", (email,)).fetchone()
    if existing:
        c.execute(
            """
            UPDATE users
            SET password_hash = ?, role_id = 'ROLE_ADMIN', role = 'admin',
                account_status = 'ACTIVE', updated_at = ?
            WHERE id = ?;
            """,
            (pw_hash, now_iso, existing["id"]),
        )
        log_audit(c, existing["id"], "CLI_ADMIN_PROVISIONED", existing["id"], f"Updated admin credentials for {email}")
        conn.commit()
        print(f"Updated existing Admin account {existing['id']} ({email}) with bcrypt password hash.")
    else:
        p_digits = phone_digits(args.phone)
        if len(p_digits) < 10 or len(p_digits) > 15:
            print("Error: Phone number must contain 10 to 15 digits.", file=sys.stderr)
            sys.exit(1)
        uid = "USR-ADMIN-" + uuid.uuid4().hex[:8].upper()
        c.execute(
            """
            INSERT INTO users (
                id, name, full_name, email, phone, phone_digits, password_hash,
                role, role_id, account_status, aadhaar_verified, face_verified, otp_verified,
                created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 'admin', 'ROLE_ADMIN', 'ACTIVE', 0, 0, 0, ?, ?);
            """,
            (uid, args.name.strip(), args.name.strip(), email, normalize_phone(args.phone), p_digits, pw_hash, now_iso, now_iso),
        )
        log_audit(c, uid, "CLI_ADMIN_CREATED", uid, f"Created admin account {email}")
        conn.commit()
        print(f"Created Admin account {uid} ({email}) with bcrypt password hash.")

    conn.close()


if __name__ == "__main__":
    main()
