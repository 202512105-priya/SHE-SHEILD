#!/usr/bin/env python3
"""
SHE SHIELD - Local SQLite Live Database & Auth Server
Hosts a secure, RBAC-enforced REST API backed by SQLite 3 (she_shield.db).
Features:
- bcrypt password hashing ($2b$)
- Parameterized queries against SQL injection
- Role-Based Access Control (roles, permissions, role_permissions)
- Token-based session management (authentication_sessions with expiration & logout revocation)
- Admin user management & audit logging
"""

from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
import hashlib
import hmac
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import math
import os
import re
import secrets
import smtplib
import socket
from socketserver import ThreadingMixIn
import sqlite3
import ssl
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlencode, urlparse
import urllib.request
import uuid

import bcrypt

PORT = 8080
SERVER_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(SERVER_DIR, "she_shield.db")
AUDIO_VAULT_DIR = os.path.join(SERVER_DIR, "secure_audio_vault")
SESSION_TTL_HOURS = 24
MAX_AUDIO_BYTES = 25 * 1024 * 1024  # 25 MB limit
PHRASE_HMAC_KEY = os.environ.get("SHESHIELD_PHRASE_HMAC_KEY", "she_shield_voice_hmac_internal_v1").encode("utf-8")

ALLOWED_AUDIO_MIMES = {
    "audio/webm": ".webm",
    "audio/mp4": ".m4a",
    "audio/x-m4a": ".m4a",
    "audio/aac": ".aac",
    "audio/mpeg": ".mp3",
    "audio/wav": ".wav",
    "audio/x-wav": ".wav",
    "audio/ogg": ".ogg",
}

EMAIL_REGEX = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
ALLOWED_ACCOUNT_STATUSES = {"ACTIVE", "SUSPENDED"}

ROLE_DEFINITIONS = [
    ("ROLE_ADMIN", "admin", "System administrator with full user, role, and audit control."),
    ("ROLE_OFFICER", "officer", "Law enforcement / responder authorized for live SOS and cyber triage."),
    ("ROLE_GUARDIAN", "guardian", "Trusted family guardian authorized to monitor linked wards and escalate SOS."),
    ("ROLE_USER", "registered_user", "Standard registered user with personal safety, complaints, and evidence vault access."),
]

PERMISSION_DEFINITIONS = [
    ("dashboard:user", "Access User Safety Dashboard"),
    ("dashboard:guardian", "Access Guardian Monitoring Portal"),
    ("dashboard:officer", "Access Officer / Responder Command Panel"),
    ("dashboard:admin", "Access Admin Command Center"),
    ("sos:create", "Create emergency SOS alerts"),
    ("sos:view_own", "View own SOS alerts"),
    ("sos:view_all", "View all SOS emergency cases"),
    ("sos:update_status", "Update SOS incident lifecycle status"),
    ("complaint:create", "Submit digital crime complaints"),
    ("complaint:view_own", "View own cyber complaints"),
    ("complaint:view_all", "View all cyber complaints"),
    ("complaint:update_status", "Update cyber complaint lifecycle status"),
    ("vault:view_own", "View own evidence vault assets"),
    ("vault:view_all", "View all evidence vault assets"),
    ("vault:upload", "Upload cryptographic evidence assets"),
    ("guardian:manage", "View and manage linked guardians"),
    ("guardian:escalate", "Escalate ward distress alert to police"),
    ("admin:users_read", "View and search all registered users"),
    ("admin:users_write", "Activate or suspend user accounts"),
    ("admin:create_officer", "Provision authorized officer accounts"),
    ("admin:assign_role", "Assign or modify user roles"),
    ("admin:audit_view", "View security audit logs"),
    ("voice_sos:own", "Manage own Voice SOS settings and phrase"),
    ("audio_evidence:own", "Record, play, verify, download, and delete own audio evidence"),
    ("travel:own", "Manage own Safe Arrival Travel journeys and guardian sharing"),
]

PRIVATE_USER_ONLY_PERMISSIONS = {"voice_sos:own", "audio_evidence:own"}

ROLE_PERMISSIONS_MAP = {
    "ROLE_ADMIN": [p[0] for p in PERMISSION_DEFINITIONS if p[0] not in PRIVATE_USER_ONLY_PERMISSIONS],
    "ROLE_OFFICER": [
        "dashboard:officer",
        "sos:create",
        "sos:view_all",
        "sos:update_status",
        "complaint:view_all",
        "complaint:update_status",
        "vault:view_all",
        "vault:upload",
        "travel:own",
    ],
    "ROLE_GUARDIAN": [
        "dashboard:guardian",
        "sos:create",
        "sos:view_own",
        "guardian:manage",
        "guardian:escalate",
    ],
    "ROLE_USER": [
        "dashboard:user",
        "sos:create",
        "sos:view_own",
        "complaint:create",
        "complaint:view_own",
        "vault:view_own",
        "vault:upload",
        "guardian:manage",
        "voice_sos:own",
        "audio_evidence:own",
        "travel:own",
    ],
}

ROUTE_DEVIATION_THRESHOLD_METERS = 350.0
ARRIVAL_VERIFICATION_RADIUS_METERS = 250.0
ETA_GRACE_PERIOD_MINUTES = 5
GOOGLE_MAPS_API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY", "").strip()
SMTP_HOST = os.environ.get("SHESHIELD_SMTP_HOST", "").strip()
SMTP_PORT = int(os.environ.get("SHESHIELD_SMTP_PORT", "587") or 587)
SMTP_USER = os.environ.get("SHESHIELD_SMTP_USER", "").strip()
SMTP_PASS = os.environ.get("SHESHIELD_SMTP_PASS", "").strip()
SMTP_FROM = os.environ.get("SHESHIELD_SMTP_FROM", SMTP_USER).strip()


def utc_now():
    return datetime.now(timezone.utc)


def utc_now_iso():
    return utc_now().isoformat()


def hash_password(plain_password: str) -> str:
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(plain_password.encode("utf-8"), salt).decode("utf-8")


def verify_password(plain_password: str, password_hash: str) -> bool:
    if not plain_password or not password_hash:
        return False
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), password_hash.encode("utf-8"))
    except Exception:
        return False


def hash_token(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()


def hmac_phrase(phrase: str) -> str:
    if not phrase:
        return ""
    return hmac.new(PHRASE_HMAC_KEY, phrase.strip().lower().encode("utf-8"), hashlib.sha256).hexdigest()


def is_valid_audio_magic(base_mime: str, raw_bytes: bytes) -> bool:
    if not raw_bytes or len(raw_bytes) < 64 or len(raw_bytes) > MAX_AUDIO_BYTES:
        return False
    if base_mime == "audio/webm":
        return raw_bytes.startswith(b"\x1a\x45\xdf\xa3")
    if base_mime in ("audio/mp4", "audio/x-m4a"):
        return len(raw_bytes) >= 12 and b"ftyp" in raw_bytes[4:12]
    if base_mime == "audio/ogg":
        return raw_bytes.startswith(b"OggS")
    if base_mime in ("audio/wav", "audio/x-wav"):
        return raw_bytes[:4] == b"RIFF" and raw_bytes[8:12] == b"WAVE"
    if base_mime == "audio/mpeg":
        return raw_bytes.startswith(b"ID3") or (raw_bytes[0] == 0xFF and (raw_bytes[1] & 0xE0) == 0xE0)
    if base_mime == "audio/aac":
        return raw_bytes[0] == 0xFF and (raw_bytes[1] & 0xF0) == 0xF0
    return False


def normalize_phone(raw_phone: str) -> str:
    cleaned = re.sub(r"[^\d+]", "", (raw_phone or "").strip())
    return cleaned


def phone_digits(raw_phone: str) -> str:
    return re.sub(r"\D", "", raw_phone or "")


def validate_password_strength(password: str):
    if not password or len(password) < 8:
        return "Password must be at least 8 characters long."
    if len(password) > 128:
        return "Password must not exceed 128 characters."
    if not re.search(r"[A-Z]", password):
        return "Password must include at least one uppercase letter."
    if not re.search(r"[a-z]", password):
        return "Password must include at least one lowercase letter."
    if not re.search(r"\d", password):
        return "Password must include at least one digit."
    if not re.search(r"[!@#$%^&*(),.?\":{}|<>_\-+=/\\;~\[\]]", password):
        return "Password must include at least one special character."
    return None


def verhoeff_valid(number_str: str) -> bool:
    """Validates a 12-digit Aadhaar number using the official Verhoeff checksum."""
    if not re.fullmatch(r"\d{12}", number_str or ""):
        return False
    d = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
        [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
        [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
        [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
        [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
        [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
        [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
        [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
        [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
    ]
    p = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
        [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
        [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
        [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
        [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
        [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
        [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
    ]
    c = 0
    for i, item in enumerate(reversed(number_str)):
        c = d[c][p[i % 8][int(item)]]
    return c == 0


def parse_iso_dt(raw: str):
    if not raw or not isinstance(raw, str):
        return None
    try:
        norm = raw.strip()
        if norm.endswith("Z"):
            norm = norm[:-1] + "+00:00"
        dt = datetime.fromisoformat(norm)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return None


def parse_coord(val, min_v: float, max_v: float):
    if val is None or isinstance(val, bool):
        return None
    try:
        f = float(val)
    except (TypeError, ValueError):
        return None
    if math.isnan(f) or math.isinf(f) or f < min_v or f > max_v:
        return None
    return f


def haversine_meters(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371000.0
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2.0) ** 2 + math.cos(p1) * math.cos(p2) * (math.sin(dl / 2.0) ** 2)
    return 2.0 * r * math.atan2(math.sqrt(a), math.sqrt(max(0.0, 1.0 - a)))


def _point_to_segment_meters(lat: float, lng: float, a_lat: float, a_lng: float, b_lat: float, b_lng: float) -> float:
    meters_per_deg_lat = 111320.0
    meters_per_deg_lng = max(1e-6, 111320.0 * math.cos(math.radians(lat)))
    px, py = 0.0, 0.0
    ax = (a_lng - lng) * meters_per_deg_lng
    ay = (a_lat - lat) * meters_per_deg_lat
    bx = (b_lng - lng) * meters_per_deg_lng
    by = (b_lat - lat) * meters_per_deg_lat
    dx = bx - ax
    dy = by - ay
    seg_len_sq = dx * dx + dy * dy
    if seg_len_sq <= 1e-9:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / seg_len_sq))
    proj_x = ax + t * dx
    proj_y = ay + t * dy
    return math.hypot(px - proj_x, py - proj_y)


def point_to_polyline_meters(lat: float, lng: float, polyline) -> float:
    if not polyline or not isinstance(polyline, list):
        return 0.0
    valid = []
    for pt in polyline:
        if isinstance(pt, (list, tuple)) and len(pt) >= 2:
            plat = parse_coord(pt[0], -90.0, 90.0)
            plng = parse_coord(pt[1], -180.0, 180.0)
            if plat is not None and plng is not None:
                valid.append((plat, plng))
    if not valid:
        return 0.0
    if len(valid) == 1:
        return haversine_meters(lat, lng, valid[0][0], valid[0][1])
    best = float("inf")
    for i in range(len(valid) - 1):
        d = _point_to_segment_meters(lat, lng, valid[i][0], valid[i][1], valid[i + 1][0], valid[i + 1][1])
        if d < best:
            best = d
    return 0.0 if math.isinf(best) else best


def decode_google_polyline(encoded: str):
    points = []
    index = 0
    lat = 0
    lng = 0
    while index < len(encoded):
        for coord_idx in (0, 1):
            shift = 0
            result = 0
            while index < len(encoded):
                b = ord(encoded[index]) - 63
                index += 1
                result |= (b & 0x1F) << shift
                shift += 5
                if b < 0x20:
                    break
            delta = ~(result >> 1) if (result & 1) else (result >> 1)
            if coord_idx == 0:
                lat += delta
            else:
                lng += delta
        points.append([lat / 1e5, lng / 1e5])
    return points


def _http_get_json(url: str, timeout: float = 8.0):
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "SheShieldSafetyApp/1.0 (SafeArrivalTravelMode)",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def search_places_live(query_text: str, bias_lat=None, bias_lng=None):
    q = (query_text or "").strip()
    if len(q) < 2:
        return {"provider": "none", "results": []}

    results = []
    seen = set()
    last_err = None

    def _add(place_id, name, display_name, category, lat_v, lng_v):
        plat = parse_coord(lat_v, -90.0, 90.0)
        plng = parse_coord(lng_v, -180.0, 180.0)
        if plat is None or plng is None:
            return
        key = (round(plat, 5), round(plng, 5), (name or "").lower())
        if key in seen:
            return
        seen.add(key)
        results.append(
            {
                "placeId": str(place_id or f"place-{len(results)+1}"),
                "name": name or display_name or "Selected Location",
                "displayName": display_name or name or f"{plat:.5f}, {plng:.5f}",
                "category": (category or "location").replace("_", " ").title(),
                "latitude": plat,
                "longitude": plng,
            }
        )

    if GOOGLE_MAPS_API_KEY:
        try:
            params = {"query": q, "key": GOOGLE_MAPS_API_KEY}
            if bias_lat is not None and bias_lng is not None:
                params["location"] = f"{bias_lat},{bias_lng}"
                params["radius"] = "30000"
            data = _http_get_json("https://maps.googleapis.com/maps/api/place/textsearch/json?" + urlencode(params))
            for item in data.get("results", [])[:8]:
                loc = (item.get("geometry") or {}).get("location") or {}
                types = item.get("types") or ["place"]
                _add(
                    item.get("place_id"),
                    item.get("name"),
                    item.get("formatted_address") or item.get("name"),
                    types[0],
                    loc.get("lat"),
                    loc.get("lng"),
                )
            if results:
                return {"provider": "google_places", "results": results}
        except Exception as e:
            last_err = str(e)

    # Photon (OpenStreetMap fast autocomplete with optional bias)
    try:
        params = {"q": q, "limit": 8}
        if bias_lat is not None and bias_lng is not None:
            params["lat"] = f"{bias_lat:.6f}"
            params["lon"] = f"{bias_lng:.6f}"
        data = _http_get_json("https://photon.komoot.io/api/?" + urlencode(params))
        for idx, feat in enumerate(data.get("features", [])):
            props = feat.get("properties") or {}
            coords = (feat.get("geometry") or {}).get("coordinates") or []
            if len(coords) < 2:
                continue
            parts = [
                p
                for p in [
                    props.get("name"),
                    props.get("street"),
                    props.get("district") or props.get("suburb"),
                    props.get("city") or props.get("town") or props.get("village"),
                    props.get("state"),
                    props.get("country"),
                ]
                if p
            ]
            name = props.get("name") or (parts[0] if parts else q)
            display = ", ".join(dict.fromkeys(parts)) if parts else name
            cat = props.get("osm_value") or props.get("osm_key") or "place"
            _add(props.get("osm_id") or f"photon-{idx}", name, display, cat, coords[1], coords[0])
        if results:
            return {"provider": "openstreetmap_photon", "results": results}
    except Exception as e:
        last_err = str(e)

    # Nominatim OpenStreetMap fallback
    try:
        params = {"q": q, "format": "jsonv2", "addressdetails": 1, "limit": 8}
        data = _http_get_json("https://nominatim.openstreetmap.org/search?" + urlencode(params))
        if isinstance(data, list):
            for idx, item in enumerate(data):
                display = item.get("display_name") or q
                name = item.get("name") or display.split(",")[0].strip()
                cat = item.get("type") or item.get("category") or "place"
                _add(item.get("place_id") or f"nom-{idx}", name, display, cat, item.get("lat"), item.get("lon"))
            return {"provider": "openstreetmap_nominatim", "results": results}
    except Exception as e:
        last_err = str(e)

    if last_err:
        raise RuntimeError(f"Geocoding providers unavailable: {last_err}")
    return {"provider": "openstreetmap", "results": []}


def compute_routes_live(start_lat: float, start_lng: float, dest_lat: float, dest_lng: float, mode: str = "driving"):
    last_err = None
    routes_out = []

    if GOOGLE_MAPS_API_KEY:
        try:
            g_mode = "walking" if mode == "walking" else "driving"
            params = {
                "origin": f"{start_lat:.6f},{start_lng:.6f}",
                "destination": f"{dest_lat:.6f},{dest_lng:.6f}",
                "mode": g_mode,
                "alternatives": "true",
                "key": GOOGLE_MAPS_API_KEY,
            }
            data = _http_get_json("https://maps.googleapis.com/maps/api/directions/json?" + urlencode(params))
            for idx, r in enumerate(data.get("routes", [])[:3]):
                leg = (r.get("legs") or [{}])[0]
                dist_m = float(((leg.get("distance") or {}).get("value")) or 0)
                dur_s = int(((leg.get("duration") or {}).get("value")) or 0)
                poly_enc = ((r.get("overview_polyline") or {}).get("points")) or ""
                pts = decode_google_polyline(poly_enc)
                if len(pts) >= 2:
                    routes_out.append(
                        {
                            "routeId": f"google-{idx}",
                            "label": "Fastest Route" if idx == 0 else f"Alternative {idx}",
                            "summary": r.get("summary") or f"Route {idx + 1}",
                            "distanceMeters": round(dist_m, 1),
                            "durationSeconds": dur_s,
                            "durationMinutes": max(1, round(dur_s / 60.0)),
                            "polyline": pts,
                        }
                    )
            if routes_out:
                return {"provider": "google_directions", "routes": routes_out}
        except Exception as e:
            last_err = str(e)

    profile = "foot" if mode == "walking" else "driving"
    osrm_url = (
        f"http://router.project-osrm.org/route/v1/{profile}/"
        f"{start_lng:.6f},{start_lat:.6f};{dest_lng:.6f},{dest_lat:.6f}"
        "?overview=full&geometries=geojson&alternatives=true&steps=false"
    )
    try:
        data = _http_get_json(osrm_url, timeout=10.0)
        if data.get("code") == "Ok":
            for idx, r in enumerate(data.get("routes", [])[:3]):
                coords = ((r.get("geometry") or {}).get("coordinates")) or []
                pts = [[float(c_pt[1]), float(c_pt[0])] for c_pt in coords if isinstance(c_pt, list) and len(c_pt) >= 2]
                if len(pts) < 2:
                    continue
                dist_m = float(r.get("distance") or haversine_meters(start_lat, start_lng, dest_lat, dest_lng))
                dur_s = int(round(float(r.get("duration") or max(60, dist_m / 8.0))))
                # Walking fallback realism if public OSRM car profile returns driving duration when mode=='walking'
                if mode == "walking":
                    dur_s = int(round(max(dur_s, dist_m / 1.35)))
                legs = r.get("legs") or [{}]
                summary = (legs[0].get("summary") or "").strip() or (
                    "Primary Safe Corridor" if idx == 0 else f"Alternate Route {idx}"
                )
                routes_out.append(
                    {
                        "routeId": f"osrm-{idx}",
                        "label": "Fastest Route" if idx == 0 else f"Alternative {idx}",
                        "summary": summary,
                        "distanceMeters": round(dist_m, 1),
                        "durationSeconds": dur_s,
                        "durationMinutes": max(1, round(dur_s / 60.0)),
                        "polyline": pts,
                    }
                )
            if routes_out:
                return {"provider": "osrm_openstreetmap", "routes": routes_out}
    except Exception as e:
        last_err = str(e)

    raise RuntimeError(f"Routing service unavailable: {last_err or 'No road route returned'}")


def deliver_guardian_notifications(recipients, subject: str, body_text: str):
    """Attempts real SMTP email dispatch if env vars are configured; never fakes SMS/WhatsApp delivery."""
    smtp_ready = bool(SMTP_HOST and SMTP_USER and SMTP_PASS and SMTP_FROM)
    if not smtp_ready:
        return {
            "deliveryConfigured": False,
            "deliveryStatus": "NOT_CONFIGURED",
            "deliveryMessage": (
                "External SMS/WhatsApp/Email gateway is not configured on this server. "
                "Share the generated secure tracking link directly with your guardian."
            ),
            "results": [
                {
                    "guardianName": r.get("guardianName") or "Guardian",
                    "phone": r.get("phone") or "",
                    "email": r.get("email") or "",
                    "status": "NOT_CONFIGURED",
                }
                for r in recipients
            ],
        }

    results = []
    sent_any = False
    try:
        ctx = ssl.create_default_context()
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=8) as server:
            server.starttls(context=ctx)
            server.login(SMTP_USER, SMTP_PASS)
            for r in recipients:
                email_addr = (r.get("email") or "").strip()
                if not email_addr or not EMAIL_REGEX.match(email_addr):
                    results.append(
                        {
                            "guardianName": r.get("guardianName") or "Guardian",
                            "phone": r.get("phone") or "",
                            "email": email_addr,
                            "status": "SKIPPED_NO_EMAIL",
                        }
                    )
                    continue
                msg = EmailMessage()
                msg["From"] = SMTP_FROM
                msg["To"] = email_addr
                msg["Subject"] = subject
                msg.set_content(body_text)
                server.send_message(msg)
                sent_any = True
                results.append(
                    {
                        "guardianName": r.get("guardianName") or "Guardian",
                        "phone": r.get("phone") or "",
                        "email": email_addr,
                        "status": "SENT_EMAIL",
                    }
                )
    except Exception as e:
        return {
            "deliveryConfigured": True,
            "deliveryStatus": "FAILED",
            "deliveryMessage": f"Email gateway delivery error: {e}",
            "results": results,
        }

    return {
        "deliveryConfigured": True,
        "deliveryStatus": "SENT" if sent_any else "NO_EMAIL_RECIPIENT",
        "deliveryMessage": (
            "Email alert dispatched to guardian(s) with email addresses."
            if sent_any
            else "SMTP configured, but selected guardian(s) had no email address; share link via SMS/WhatsApp."
        ),
        "results": results,
    }


def get_db():
    conn = sqlite3.connect(DB_FILE, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


def log_audit(c, actor_user_id, action, target_id=None, details=None):
    c.execute(
        """
        INSERT INTO audit_logs (actor_user_id, action, target_id, details, created_at)
        VALUES (?, ?, ?, ?, ?);
        """,
        (actor_user_id, action, target_id, details, utc_now_iso()),
    )


def map_legacy_role_to_role_id(legacy_role: str) -> str:
    r = (legacy_role or "").strip().lower()
    if r == "admin":
        return "ROLE_ADMIN"
    if r in ("officer", "responder", "police"):
        return "ROLE_OFFICER"
    if r == "guardian":
        return "ROLE_GUARDIAN"
    return "ROLE_USER"


def _ensure_column(c, table: str, column: str, definition: str):
    existing = {row[1] for row in c.execute(f"PRAGMA table_info({table});").fetchall()}
    if column not in existing:
        c.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition};")


def init_db():
    conn = get_db()
    c = conn.cursor()

    # 1. Roles, Permissions, Role_Permissions
    c.execute(
        """
        CREATE TABLE IF NOT EXISTS roles (
            id TEXT PRIMARY KEY,
            role_name TEXT UNIQUE NOT NULL,
            description TEXT NOT NULL
        );
        """
    )

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS permissions (
            id TEXT PRIMARY KEY,
            permission_name TEXT UNIQUE NOT NULL,
            description TEXT NOT NULL
        );
        """
    )

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS role_permissions (
            role_id TEXT NOT NULL,
            permission_id TEXT NOT NULL,
            PRIMARY KEY (role_id, permission_id),
            FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
            FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
        );
        """
    )

    for rid, rname, rdesc in ROLE_DEFINITIONS:
        c.execute(
            "INSERT OR IGNORE INTO roles (id, role_name, description) VALUES (?, ?, ?);",
            (rid, rname, rdesc),
        )

    for pname, pdesc in PERMISSION_DEFINITIONS:
        pid = "PERM_" + pname.upper().replace(":", "_")
        c.execute(
            "INSERT OR IGNORE INTO permissions (id, permission_name, description) VALUES (?, ?, ?);",
            (pid, pname, pdesc),
        )

    for rid, perms in ROLE_PERMISSIONS_MAP.items():
        desired_pids = ["PERM_" + pname.upper().replace(":", "_") for pname in perms]
        for pid in desired_pids:
            c.execute(
                "INSERT OR IGNORE INTO role_permissions (role_id, permission_id) VALUES (?, ?);",
                (rid, pid),
            )
        placeholders = ",".join("?" for _ in desired_pids)
        if desired_pids:
            c.execute(
                f"DELETE FROM role_permissions WHERE role_id = ? AND permission_id NOT IN ({placeholders});",
                (rid, *desired_pids),
            )
        # Ensure private user-only permissions are not accidentally assigned to non-user roles
        if rid != "ROLE_USER":
            for priv in PRIVATE_USER_ONLY_PERMISSIONS:
                priv_pid = "PERM_" + priv.upper().replace(":", "_")
                c.execute(
                    "DELETE FROM role_permissions WHERE role_id = ? AND permission_id = ?;",
                    (rid, priv_pid),
                )

    # 2. Users table (preserve existing rows and upgrade columns cleanly)
    c.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            full_name TEXT,
            email TEXT NOT NULL,
            phone TEXT NOT NULL,
            phone_digits TEXT,
            password_hash TEXT,
            role TEXT NOT NULL DEFAULT 'registered_user',
            role_id TEXT DEFAULT 'ROLE_USER' REFERENCES roles(id),
            account_status TEXT NOT NULL DEFAULT 'ACTIVE',
            aadhaar_verified INTEGER DEFAULT 0,
            face_verified INTEGER DEFAULT 0,
            otp_verified INTEGER DEFAULT 0,
            face_match_score REAL DEFAULT 0.0,
            safety_index INTEGER DEFAULT 100,
            risk_trend TEXT DEFAULT 'STABLE',
            secret_phrase TEXT DEFAULT 'capcap',
            secret_word TEXT DEFAULT 'Box Box',
            badge_id TEXT,
            station TEXT,
            created_at TEXT,
            updated_at TEXT
        );
        """
    )

    # Migrate legacy columns cleanly if users table already existed
    _ensure_column(c, "users", "full_name", "TEXT")
    _ensure_column(c, "users", "phone_digits", "TEXT")
    _ensure_column(c, "users", "password_hash", "TEXT")
    _ensure_column(c, "users", "role_id", "TEXT")
    _ensure_column(c, "users", "account_status", "TEXT DEFAULT 'ACTIVE'")
    _ensure_column(c, "users", "face_verified", "INTEGER DEFAULT 0")
    _ensure_column(c, "users", "otp_verified", "INTEGER DEFAULT 0")
    _ensure_column(c, "users", "badge_id", "TEXT")
    _ensure_column(c, "users", "station", "TEXT")
    _ensure_column(c, "users", "created_at", "TEXT")
    _ensure_column(c, "users", "updated_at", "TEXT")
    _ensure_column(c, "users", "voice_sos_language", "TEXT DEFAULT 'English'")
    _ensure_column(c, "users", "voice_sos_enabled", "INTEGER DEFAULT 0")
    _ensure_column(c, "users", "voice_sos_max_duration", "INTEGER DEFAULT 120")
    _ensure_column(c, "users", "silent_sos_mode", "INTEGER DEFAULT 0")

    now_iso = utc_now_iso()
    legacy_rows = c.execute("SELECT id, name, full_name, email, phone, role, role_id, password_hash, created_at FROM users;").fetchall()
    for row in legacy_rows:
        uid = row["id"]
        full_name = row["full_name"] or row["name"]
        email_norm = (row["email"] or "").strip().lower()
        p_digits = phone_digits(row["phone"] or "")
        role_id = row["role_id"]
        if not role_id or role_id not in ROLE_PERMISSIONS_MAP:
            role_id = map_legacy_role_to_role_id(row["role"])
        role_name = c.execute("SELECT role_name FROM roles WHERE id = ?;", (role_id,)).fetchone()["role_name"]
        created_at = row["created_at"] or now_iso

        c.execute(
            """
            UPDATE users
            SET full_name = ?,
                email = ?,
                phone_digits = ?,
                role = ?,
                role_id = ?,
                account_status = COALESCE(NULLIF(account_status, ''), 'ACTIVE'),
                created_at = ?,
                updated_at = COALESCE(updated_at, ?)
            WHERE id = ?;
            """,
            (full_name, email_norm, p_digits, role_name, role_id, created_at, now_iso, uid),
        )

    c.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users(LOWER(email));")
    c.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_digits_unique ON users(phone_digits);")

    # 3. Authentication Sessions & Audit Logs
    c.execute(
        """
        CREATE TABLE IF NOT EXISTS authentication_sessions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            token_hash TEXT UNIQUE NOT NULL,
            expires_at TEXT NOT NULL,
            revoked INTEGER NOT NULL DEFAULT 0,
            user_agent TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        """
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_sessions_user ON authentication_sessions(user_id);")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actor_user_id TEXT,
            action TEXT NOT NULL,
            target_id TEXT,
            details TEXT,
            created_at TEXT NOT NULL
        );
        """
    )

    # 4. Domain tables (preserving existing schema & adding owner scoping columns cleanly)
    c.execute(
        """
        CREATE TABLE IF NOT EXISTS sos_cases (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            user_name TEXT NOT NULL,
            user_email TEXT,
            user_phone TEXT NOT NULL,
            age INTEGER DEFAULT 22,
            blood_group TEXT DEFAULT 'O+',
            priority TEXT NOT NULL,
            status TEXT NOT NULL,
            gps TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            device_type TEXT NOT NULL,
            evidence_count INTEGER DEFAULT 1,
            location_name TEXT
        );
        """
    )
    _ensure_column(c, "sos_cases", "user_id", "TEXT")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS cyber_complaints (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            user_email TEXT,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            threat_score TEXT NOT NULL,
            status TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            user_name TEXT NOT NULL,
            user_phone TEXT NOT NULL,
            offender_link TEXT,
            evidence_count INTEGER DEFAULT 1,
            attached_evidence TEXT
        );
        """
    )
    _ensure_column(c, "cyber_complaints", "user_id", "TEXT")
    _ensure_column(c, "cyber_complaints", "user_email", "TEXT")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS vault_assets (
            id TEXT PRIMARY KEY,
            owner_user_id TEXT,
            owner_email TEXT,
            name TEXT NOT NULL,
            file_type TEXT NOT NULL,
            hash_sha256 TEXT NOT NULL,
            tamper_check TEXT NOT NULL,
            status TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            size_mb TEXT,
            chain_of_custody TEXT
        );
        """
    )
    _ensure_column(c, "vault_assets", "owner_user_id", "TEXT")
    _ensure_column(c, "vault_assets", "owner_email", "TEXT")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS guardians (
            id TEXT PRIMARY KEY,
            owner_user_id TEXT,
            owner_email TEXT,
            ward_name TEXT NOT NULL,
            guardian_name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT NOT NULL,
            relation TEXT NOT NULL,
            status TEXT NOT NULL,
            safety_score TEXT,
            risk_status TEXT,
            battery_level TEXT,
            device_state TEXT,
            location_text TEXT,
            gps TEXT
        );
        """
    )
    _ensure_column(c, "guardians", "owner_user_id", "TEXT")
    _ensure_column(c, "guardians", "owner_email", "TEXT")
    _ensure_column(c, "guardians", "user_id", "TEXT")
    _ensure_column(c, "guardians", "guardian_user_id", "TEXT")
    _ensure_column(c, "guardians", "relationship", "TEXT")
    _ensure_column(c, "guardians", "is_active", "INTEGER DEFAULT 1")
    c.execute("UPDATE guardians SET user_id = owner_user_id WHERE user_id IS NULL AND owner_user_id IS NOT NULL;")
    c.execute("UPDATE guardians SET relationship = relation WHERE relationship IS NULL AND relation IS NOT NULL;")
    c.execute("UPDATE guardians SET is_active = 1 WHERE is_active IS NULL;")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS travel_journeys (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            start_location_name TEXT,
            start_latitude REAL,
            start_longitude REAL,
            destination_name TEXT NOT NULL,
            destination_latitude REAL NOT NULL,
            destination_longitude REAL NOT NULL,
            distance_meters REAL DEFAULT 0.0,
            estimated_duration INTEGER NOT NULL,
            recording_mode TEXT NOT NULL DEFAULT 'None',
            route_polyline TEXT,
            route_summary TEXT,
            status TEXT NOT NULL DEFAULT 'ACTIVE',
            deviation_meters REAL DEFAULT 0.0,
            deviation_warning INTEGER DEFAULT 0,
            eta_extended_count INTEGER DEFAULT 0,
            arrival_verified INTEGER DEFAULT 0,
            arrival_distance_meters REAL,
            last_latitude REAL,
            last_longitude REAL,
            last_accuracy REAL,
            last_gps_at TEXT,
            start_time TEXT NOT NULL,
            estimated_arrival_time TEXT NOT NULL,
            actual_arrival_time TEXT,
            sos_event_id TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        """
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_travel_journeys_user ON travel_journeys(user_id, status, created_at DESC);")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS journey_locations (
            id TEXT PRIMARY KEY,
            journey_id TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL DEFAULT 0.0,
            speed REAL DEFAULT 0.0,
            heading REAL DEFAULT 0.0,
            recorded_at TEXT NOT NULL,
            FOREIGN KEY (journey_id) REFERENCES travel_journeys(id) ON DELETE CASCADE
        );
        """
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_journey_locations_jid ON journey_locations(journey_id, recorded_at ASC);")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS journey_sharing (
            id TEXT PRIMARY KEY,
            journey_id TEXT NOT NULL,
            guardian_id TEXT,
            guardian_name TEXT,
            guardian_phone TEXT,
            guardian_email TEXT,
            sharing_token_hash TEXT UNIQUE NOT NULL,
            delivery_status TEXT NOT NULL DEFAULT 'NOT_CONFIGURED',
            delivery_message TEXT,
            created_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            revoked_at TEXT,
            FOREIGN KEY (journey_id) REFERENCES travel_journeys(id) ON DELETE CASCADE,
            FOREIGN KEY (guardian_id) REFERENCES guardians(id) ON DELETE SET NULL
        );
        """
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_journey_sharing_jid ON journey_sharing(journey_id, created_at DESC);")
    c.execute("CREATE INDEX IF NOT EXISTS idx_journey_sharing_tok ON journey_sharing(sharing_token_hash);")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS journey_events (
            id TEXT PRIMARY KEY,
            journey_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            details TEXT,
            latitude REAL,
            longitude REAL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (journey_id) REFERENCES travel_journeys(id) ON DELETE CASCADE
        );
        """
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_journey_events_jid ON journey_events(journey_id, created_at DESC);")

    _ensure_column(c, "journey_sharing", "guardian_user_id", "TEXT")
    _ensure_column(c, "journey_sharing", "sharing_status", "TEXT DEFAULT 'ACTIVE'")
    _ensure_column(c, "journey_sharing", "accepted_at", "TEXT")
    c.execute(
        "UPDATE journey_sharing SET sharing_status = CASE WHEN revoked_at IS NOT NULL THEN 'REVOKED' ELSE 'ACTIVE' END WHERE sharing_status IS NULL;"
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_journey_sharing_guser ON journey_sharing(guardian_user_id, sharing_status);")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS guardian_connections (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            guardian_id TEXT NOT NULL,
            relationship TEXT NOT NULL DEFAULT 'Guardian',
            connection_status TEXT NOT NULL DEFAULT 'PENDING',
            permissions TEXT NOT NULL DEFAULT 'live_journey,sos_alerts',
            created_at TEXT NOT NULL,
            accepted_at TEXT,
            revoked_at TEXT,
            UNIQUE(user_id, guardian_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (guardian_id) REFERENCES users(id) ON DELETE CASCADE
        );
        """
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_gconn_guardian ON guardian_connections(guardian_id, connection_status);")
    c.execute("CREATE INDEX IF NOT EXISTS idx_gconn_user ON guardian_connections(user_id, connection_status);")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS guardian_invitations (
            id TEXT PRIMARY KEY,
            sender_user_id TEXT NOT NULL,
            guardian_name TEXT,
            guardian_email TEXT,
            guardian_phone TEXT,
            relationship TEXT NOT NULL DEFAULT 'Guardian',
            invitation_token_hash TEXT UNIQUE NOT NULL,
            status TEXT NOT NULL DEFAULT 'PENDING',
            expires_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            responded_at TEXT,
            FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        """
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_ginv_sender ON guardian_invitations(sender_user_id, status);")
    c.execute("CREATE INDEX IF NOT EXISTS idx_ginv_email ON guardian_invitations(LOWER(guardian_email), status);")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS guardian_notifications (
            id TEXT PRIMARY KEY,
            guardian_id TEXT NOT NULL,
            journey_id TEXT,
            notification_type TEXT NOT NULL,
            message TEXT NOT NULL,
            delivery_status TEXT NOT NULL DEFAULT 'IN_APP',
            created_at TEXT NOT NULL,
            read_at TEXT,
            FOREIGN KEY (guardian_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (journey_id) REFERENCES travel_journeys(id) ON DELETE CASCADE
        );
        """
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_gnotif_guardian ON guardian_notifications(guardian_id, created_at DESC);")

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS cab_trips (
            id TEXT PRIMARY KEY,
            plate_number TEXT NOT NULL,
            driver_name TEXT NOT NULL,
            provider TEXT NOT NULL,
            destination TEXT NOT NULL,
            origin TEXT NOT NULL,
            speed_kmh INTEGER DEFAULT 38,
            deviation_meters REAL DEFAULT 28.0,
            safety_score TEXT DEFAULT '98%',
            status TEXT DEFAULT 'ACTIVE',
            timestamp TEXT NOT NULL
        );
        """
    )

    c.execute(
        """
        CREATE TABLE IF NOT EXISTS audio_evidence (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            sos_event_id TEXT,
            filename TEXT NOT NULL,
            storage_path TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            duration_seconds INTEGER NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT NOT NULL,
            trigger_phrase_hmac TEXT,
            sha256_hash TEXT NOT NULL,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'SAVED',
            last_verified_at TEXT,
            integrity_status TEXT NOT NULL DEFAULT 'UNVERIFIED',
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (sos_event_id) REFERENCES sos_cases(id) ON DELETE SET NULL
        );
        """
    )
    c.execute("CREATE INDEX IF NOT EXISTS idx_audio_evidence_user ON audio_evidence(user_id, created_at DESC);")
    c.execute("CREATE INDEX IF NOT EXISTS idx_audio_evidence_sos ON audio_evidence(sos_event_id);")
    os.makedirs(AUDIO_VAULT_DIR, mode=0o700, exist_ok=True)

    # Seed domain tables ONLY when completely empty (never overwrites existing DB)
    c.execute("SELECT COUNT(*) FROM sos_cases;")
    if c.fetchone()[0] == 0:
        c.executemany(
            """
            INSERT INTO sos_cases (id, user_name, user_email, user_phone, age, blood_group, priority, status, gps, timestamp, device_type, evidence_count, location_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            [
                ("case-178051265857", "Tisha Patel", "tisha@gmail.com", "+91 98765 43210", 23, "B+", "CRITICAL", "open", "23.0312, 72.5801", "2026-10-27T16:30:15", "Smartwatch Double Tap & BLE Relay", 3, "Navrangpura Bus Rapid Transit Corridor"),
                ("case-1780512510342", "Priya Sharma", "priya.sharma@gmail.com", "+91 98220 11223", 22, "O+", "HIGH", "investigating", "23.0225, 72.5714", "2026-10-27T16:15:20", "Secret Voice Trigger (capcap)", 2, "Gujarat University Library Circle"),
                ("case-1780599102", "Ananya Verma", "ananya.v@gmail.com", "+91 98234 56789", 24, "A+", "CRITICAL", "assigned", "23.0289, 72.5694", "2026-10-27T15:48:30", "Wearable BLE Pendant Panic Trigger", 4, "Mithakhali Six Roads, Ellis Bridge"),
            ],
        )

    c.execute("SELECT COUNT(*) FROM cyber_complaints;")
    if c.fetchone()[0] == 0:
        c.executemany(
            """
            INSERT INTO cyber_complaints (id, category, description, threat_score, status, timestamp, user_name, user_phone, offender_link, evidence_count, attached_evidence)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            [
                ("case-1780512594344", "BLACKMAIL & EXTORTION", "Blackmail demanding financial ransom using manipulated deepfake images sent via Telegram.", "94%", "SUBMITTED", "2026-10-27T16:10:00", "Tisha Patel", "+91 98765 43210", "https://instagram.com/fake_threat_user_99", 4, "Extortion_Blackmail_DM_Proof.png; CERT_In_Forensic_Report.pdf"),
                ("case-1780588220", "CYBER STALKING", "Persistent unauthorized tracking and vulgar threat messages across social media platforms.", "88%", "UNDER REVIEW", "2026-10-27T15:00:00", "Kavita Roy", "+91 98980 11223", "https://facebook.com/offender_stalker_id", 5, "Stalking_Chat_Log.pdf"),
            ],
        )

    # Ensure there is at least one Admin user ONLY if zero admins exist at bootstrap
    admin_count = c.execute("SELECT COUNT(*) FROM users WHERE role_id = 'ROLE_ADMIN';").fetchone()[0]
    if admin_count == 0:
        bootstrap_pass = os.environ.get("SHESHIELD_ADMIN_PASSWORD") or secrets.token_urlsafe(12)
        uid = "USR-ADMIN-" + uuid.uuid4().hex[:6].upper()
        c.execute(
            """
            INSERT INTO users (
                id, name, full_name, email, phone, phone_digits, password_hash,
                role, role_id, account_status, aadhaar_verified, face_verified, otp_verified,
                created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 'admin', 'ROLE_ADMIN', 'ACTIVE', 0, 0, 0, ?, ?);
            """,
            (
                uid,
                "System Administrator",
                "System Administrator",
                "admin@sheshield.local",
                "+91 90000 00001",
                "919000000001",
                hash_password(bootstrap_pass),
                now_iso,
                now_iso,
            ),
        )
        print(f"[Bootstrap] Created initial Admin user admin@sheshield.local (set password via server/create_admin.py)")

    conn.commit()
    conn.close()
    print(f"[SQLite] Database initialized & RBAC ready at {DB_FILE}")


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


class SQLiteAPIHandler(BaseHTTPRequestHandler):
    def _send_cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Evidence-Meta, Range")
        self.send_header("Access-Control-Expose-Headers", "Content-Disposition, X-Sha256-Hash, Accept-Ranges, Content-Range")
        self.send_header("Access-Control-Allow-Private-Network", "true")

    def do_OPTIONS(self):
        self.send_response(204)
        self._send_cors()
        self.end_headers()

    def _send_json(self, data, status=200):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self._send_cors()
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
        except ValueError:
            return None
        if length <= 0:
            return {}
        if length > 1024 * 1024:
            return None
        try:
            raw = self.rfile.read(length).decode("utf-8")
            parsed = json.loads(raw)
            return parsed if isinstance(parsed, dict) else None
        except Exception:
            return None

    def _get_bearer_token(self):
        auth_header = self.headers.get("Authorization", "").strip()
        if auth_header.lower().startswith("bearer "):
            return auth_header[7:].strip()
        return None

    def _get_role_permissions(self, c, role_id: str):
        rows = c.execute(
            """
            SELECT p.permission_name
            FROM permissions p
            JOIN role_permissions rp ON rp.permission_id = p.id
            WHERE rp.role_id = ?
            ORDER BY p.permission_name;
            """,
            (role_id,),
        ).fetchall()
        return [r[0] for r in rows]

    def _user_dto(self, row, permissions):
        return {
            "id": row["id"],
            "fullName": row["full_name"] or row["name"],
            "email": row["email"],
            "phone": row["phone"],
            "role": row["role_name"],
            "roleId": row["role_id"],
            "accountStatus": row["account_status"],
            "aadhaarVerified": bool(row["aadhaar_verified"]),
            "faceVerified": bool(row["face_verified"]),
            "otpVerified": bool(row["otp_verified"]),
            "badgeId": row["badge_id"] or "",
            "station": row["station"] or "",
            "permissions": permissions,
            "createdAt": row["created_at"] or "",
            "updatedAt": row["updated_at"] or "",
        }

    def _authenticate(self, c):
        raw_token = self._get_bearer_token()
        if not raw_token:
            return None, (401, {"error": "Authentication required. Missing Bearer token."})

        t_hash = hash_token(raw_token)
        row = c.execute(
            """
            SELECT s.id AS session_id, s.expires_at, s.revoked,
                   u.*, r.role_name
            FROM authentication_sessions s
            JOIN users u ON u.id = s.user_id
            JOIN roles r ON r.id = u.role_id
            WHERE s.token_hash = ?;
            """,
            (t_hash,),
        ).fetchone()

        if not row:
            return None, (401, {"error": "Invalid session token."})
        if row["revoked"]:
            return None, (401, {"error": "Session has been logged out or revoked."})

        try:
            exp = datetime.fromisoformat(row["expires_at"])
            if exp.tzinfo is None:
                exp = exp.replace(tzinfo=timezone.utc)
            if utc_now() >= exp:
                c.execute("UPDATE authentication_sessions SET revoked = 1 WHERE id = ?;", (row["session_id"],))
                return None, (401, {"error": "Session expired. Please sign in again."})
        except Exception:
            return None, (401, {"error": "Corrupt session expiration."})

        if row["account_status"] != "ACTIVE":
            return None, (403, {"error": f"Account is {row['account_status']}. Contact an administrator."})

        permissions = self._get_role_permissions(c, row["role_id"])
        return {
            "session_id": row["session_id"],
            "token_hash": t_hash,
            "user_row": row,
            "user": self._user_dto(row, permissions),
            "permissions": set(permissions),
        }, None

    def _require_auth(self, c):
        auth, err = self._authenticate(c)
        if err:
            self._send_json(err[1], status=err[0])
            return None
        return auth

    def _require_permission(self, c, permission_name: str):
        auth = self._require_auth(c)
        if not auth:
            return None
        if permission_name not in auth["permissions"]:
            log_audit(
                c,
                auth["user"]["id"],
                "ACCESS_DENIED",
                permission_name,
                f"Role {auth['user']['role']} denied {self.command} {self.path}",
            )
            self._send_json(
                {
                    "error": "Forbidden: insufficient role permissions.",
                    "requiredPermission": permission_name,
                    "role": auth["user"]["role"],
                },
                status=403,
            )
            return None
        return auth

    def _create_session(self, c, user_id: str):
        raw_token = secrets.token_urlsafe(48)
        t_hash = hash_token(raw_token)
        session_id = "SES-" + uuid.uuid4().hex[:16]
        now = utc_now()
        exp = now + timedelta(hours=SESSION_TTL_HOURS)
        ua = (self.headers.get("User-Agent") or "")[:200]
        c.execute(
            """
            INSERT INTO authentication_sessions (id, user_id, token_hash, expires_at, revoked, user_agent, created_at)
            VALUES (?, ?, ?, ?, 0, ?, ?);
            """,
            (session_id, user_id, t_hash, exp.isoformat(), ua, now.isoformat()),
        )
        return raw_token, exp.isoformat()

    def _audio_dto(self, row):
        return {
            "id": row["id"],
            "userId": row["user_id"],
            "sosEventId": row["sos_event_id"] or "",
            "filename": row["filename"],
            "mimeType": row["mime_type"],
            "fileSize": row["file_size"],
            "durationSeconds": row["duration_seconds"],
            "startedAt": row["started_at"],
            "endedAt": row["ended_at"],
            "phraseTriggered": bool(row["trigger_phrase_hmac"]),
            "sha256Hash": row["sha256_hash"],
            "createdAt": row["created_at"],
            "status": row["status"],
            "integrityStatus": row["integrity_status"] or "UNVERIFIED",
            "lastVerifiedAt": row["last_verified_at"] or "",
        }

    def _serve_audio_binary(self, c, rec_id: str, as_attachment: bool):
        auth = self._require_permission(c, "audio_evidence:own")
        if not auth:
            conn = c.connection
            conn.commit()
            return
        row = c.execute("SELECT * FROM audio_evidence WHERE id = ?;", (rec_id,)).fetchone()
        if not row:
            self._send_json({"error": "Audio evidence not found."}, status=404)
            return
        if row["user_id"] != auth["user"]["id"]:
            log_audit(c, auth["user"]["id"], "AUDIO_ACCESS_DENIED", rec_id, "Ownership mismatch")
            c.connection.commit()
            self._send_json({"error": "Forbidden: you do not own this audio recording."}, status=403)
            return

        file_path = row["storage_path"]
        if not file_path or not os.path.isfile(file_path):
            self._send_json({"error": "Audio file missing from secure storage."}, status=404)
            return

        file_size = os.path.getsize(file_path)
        range_header = self.headers.get("Range")
        start = 0
        end = file_size - 1
        status_code = 200

        if range_header and range_header.startswith("bytes=") and file_size > 0:
            try:
                spec = range_header.replace("bytes=", "").split(",")[0].strip()
                start_str, end_str = spec.split("-", 1)
                if start_str:
                    start = int(start_str)
                if end_str:
                    end = min(int(end_str), file_size - 1)
                if start < 0 or start > end or end >= file_size:
                    self._send_json({"error": "Requested range not satisfiable."}, status=416)
                    return
                status_code = 206
            except Exception:
                start = 0
                end = file_size - 1
                status_code = 200

        chunk_len = (end - start) + 1 if file_size > 0 else 0
        with open(file_path, "rb") as f:
            if start > 0:
                f.seek(start)
            data = f.read(chunk_len)

        safe_name = re.sub(r"[^A-Za-z0-9._-]", "_", row["filename"])
        self.send_response(status_code)
        self.send_header("Content-Type", row["mime_type"] or "application/octet-stream")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, private")
        self.send_header("X-Sha256-Hash", row["sha256_hash"])
        if status_code == 206:
            self.send_header("Content-Range", f"bytes {start}-{end}/{file_size}")
        if as_attachment:
            self.send_header("Content-Disposition", f'attachment; filename="{safe_name}"')
        else:
            self.send_header("Content-Disposition", f'inline; filename="{safe_name}"')
        self._send_cors()
        self.end_headers()
        self.wfile.write(data)

    def _delete_audio_evidence(self, c, rec_id: str):
        auth = self._require_permission(c, "audio_evidence:own")
        if not auth:
            c.connection.commit()
            return
        row = c.execute("SELECT * FROM audio_evidence WHERE id = ?;", (rec_id,)).fetchone()
        if not row:
            self._send_json({"error": "Audio evidence not found."}, status=404)
            return
        if row["user_id"] != auth["user"]["id"]:
            log_audit(c, auth["user"]["id"], "AUDIO_DELETE_DENIED", rec_id, "Ownership mismatch")
            c.connection.commit()
            self._send_json({"error": "Forbidden: you do not own this audio recording."}, status=403)
            return

        file_path = row["storage_path"]
        if file_path and os.path.isfile(file_path):
            try:
                sz = os.path.getsize(file_path)
                with open(file_path, "r+b") as f:
                    f.write(b"\x00" * min(sz, 1024 * 1024))
                    f.flush()
                os.remove(file_path)
            except Exception:
                try:
                    os.remove(file_path)
                except Exception:
                    pass

        c.execute("DELETE FROM audio_evidence WHERE id = ? AND user_id = ?;", (rec_id, auth["user"]["id"]))
        log_audit(c, auth["user"]["id"], "AUDIO_EVIDENCE_DELETED", rec_id, f"Securely deleted {row['filename']}")
        c.connection.commit()
        self._send_json({"success": True, "deletedId": rec_id})

    def _record_journey_event(self, c, journey_id: str, event_type: str, details: str = None, lat=None, lng=None):
        c.execute(
            """
            INSERT INTO journey_events (id, journey_id, event_type, details, latitude, longitude, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """,
            (f"JEV-{uuid.uuid4().hex[:10]}", journey_id, event_type, details, lat, lng, utc_now_iso()),
        )

    def _fetch_journey_owned(self, c, journey_id: str, auth_user: dict):
        if not journey_id:
            self._send_json({"error": "journeyId is required."}, status=400)
            return None
        row = c.execute("SELECT * FROM travel_journeys WHERE id = ?;", (journey_id,)).fetchone()
        if not row:
            self._send_json({"error": "Journey not found."}, status=404)
            return None
        if row["user_id"] != auth_user["id"]:
            log_audit(c, auth_user["id"], "JOURNEY_ACCESS_DENIED", journey_id, "Ownership mismatch")
            c.connection.commit()
            self._send_json({"error": "Forbidden: you do not own this travel journey."}, status=403)
            return None
        return row

    def _insert_guardian_notification(
        self,
        c,
        guardian_user_id: str,
        journey_id,
        notification_type: str,
        message: str,
        delivery_status: str = "IN_APP",
    ):
        if not guardian_user_id:
            return
        c.execute(
            """
            INSERT INTO guardian_notifications (id, guardian_id, journey_id, notification_type, message, delivery_status, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """,
            (
                f"GNT-{uuid.uuid4().hex[:10]}",
                guardian_user_id,
                journey_id,
                notification_type,
                message,
                delivery_status,
                utc_now_iso(),
            ),
        )

    def _find_guardian_account(self, c, email: str = "", raw_phone: str = ""):
        em = (email or "").strip().lower()
        p_dig = phone_digits(raw_phone)
        if em:
            row = c.execute(
                "SELECT id, full_name, email, phone, account_status FROM users WHERE LOWER(email) = ? AND role = 'guardian' AND account_status = 'ACTIVE' LIMIT 1;",
                (em,),
            ).fetchone()
            if row:
                return row
        if len(p_dig) >= 10:
            row = c.execute(
                "SELECT id, full_name, email, phone, account_status FROM users WHERE phone_digits = ? AND role = 'guardian' AND account_status = 'ACTIVE' LIMIT 1;",
                (p_dig,),
            ).fetchone()
            if row:
                return row
        return None

    def _connected_guardian_user_ids(self, c, ward_user_id: str):
        rows = c.execute(
            "SELECT guardian_id FROM guardian_connections WHERE user_id = ? AND connection_status = 'ACCEPTED';",
            (ward_user_id,),
        ).fetchall()
        return [r["guardian_id"] for r in rows]

    def _guardian_has_journey_access(self, c, guardian_user_id: str, j_row):
        conn_row = c.execute(
            """
            SELECT relationship, permissions FROM guardian_connections
            WHERE user_id = ? AND guardian_id = ? AND connection_status = 'ACCEPTED';
            """,
            (j_row["user_id"], guardian_user_id),
        ).fetchone()
        if conn_row and "live_journey" in (conn_row["permissions"] or ""):
            return True, "CONNECTION", conn_row["relationship"] or "Guardian"

        now_iso = utc_now_iso()
        share_row = c.execute(
            """
            SELECT s.id, s.expires_at, s.revoked_at, s.sharing_status, g.guardian_user_id as g_uid
            FROM journey_sharing s
            LEFT JOIN guardians g ON g.id = s.guardian_id
            WHERE s.journey_id = ?
              AND (s.guardian_user_id = ? OR g.guardian_user_id = ?)
              AND s.revoked_at IS NULL
              AND COALESCE(s.sharing_status, 'ACTIVE') = 'ACTIVE'
            ORDER BY s.created_at DESC LIMIT 1;
            """,
            (j_row["id"], guardian_user_id, guardian_user_id),
        ).fetchone()
        if share_row:
            exp_dt = parse_iso_dt(share_row["expires_at"])
            if exp_dt and exp_dt > utc_now():
                return True, "SHARED_LINK", "Shared Journey"
        return False, None, None

    def _user_guardians_list(self, c, user: dict):
        rows = c.execute(
            """
            SELECT id, user_id, owner_user_id, owner_email, ward_name, guardian_name, email, phone,
                   COALESCE(relationship, relation) as relationship, relation, status,
                   COALESCE(is_active, 1) as is_active, guardian_user_id
            FROM guardians
            WHERE (owner_user_id = ? OR user_id = ? OR LOWER(COALESCE(owner_email, '')) = ?)
              AND COALESCE(is_active, 1) = 1
            ORDER BY guardian_name ASC;
            """,
            (user["id"], user["id"], user["email"]),
        ).fetchall()
        out = []
        seen_uids = set()
        for r in rows:
            g_uid = r["guardian_user_id"]
            if g_uid:
                seen_uids.add(g_uid)
            out.append(
                {
                    "id": r["id"],
                    "userId": r["user_id"] or r["owner_user_id"],
                    "guardianUserId": g_uid,
                    "guardianName": r["guardian_name"],
                    "phone": r["phone"],
                    "email": r["email"],
                    "relationship": r["relationship"] or r["relation"],
                    "status": r["status"],
                    "isActive": bool(r["is_active"]),
                }
            )
        conn_rows = c.execute(
            """
            SELECT gc.id, gc.guardian_id, gc.relationship, u.full_name, u.email, u.phone
            FROM guardian_connections gc
            JOIN users u ON u.id = gc.guardian_id
            WHERE gc.user_id = ? AND gc.connection_status = 'ACCEPTED';
            """,
            (user["id"],),
        ).fetchall()
        for cr in conn_rows:
            if cr["guardian_id"] not in seen_uids:
                out.append(
                    {
                        "id": cr["id"],
                        "userId": user["id"],
                        "guardianUserId": cr["guardian_id"],
                        "guardianName": cr["full_name"],
                        "phone": cr["phone"],
                        "email": cr["email"],
                        "relationship": cr["relationship"] or "Guardian",
                        "status": "ACCEPTED",
                        "isActive": True,
                    }
                )
        return out

    def _guardian_dashboard_payload(self, c, guardian_user: dict):
        gid = guardian_user["id"]
        g_email = (guardian_user["email"] or "").strip().lower()
        g_phone_dig = phone_digits(guardian_user.get("phone") or "")
        now_dt = utc_now()
        now_iso = now_dt.isoformat()

        # 1. Accepted permanent connections
        conn_rows = c.execute(
            """
            SELECT gc.id as connection_id, gc.user_id, gc.relationship, gc.permissions, gc.accepted_at,
                   u.full_name, u.phone, u.account_status
            FROM guardian_connections gc
            JOIN users u ON u.id = gc.user_id
            WHERE gc.guardian_id = ? AND gc.connection_status = 'ACCEPTED'
            ORDER BY gc.accepted_at DESC;
            """,
            (gid,),
        ).fetchall()

        # 2. Active non-expired, non-revoked journey_sharing entries targeting this guardian user
        share_rows = c.execute(
            """
            SELECT s.id as share_id, s.journey_id, s.expires_at, s.created_at,
                   j.*, u.full_name as user_full_name, u.phone as user_phone
            FROM journey_sharing s
            LEFT JOIN guardians g ON g.id = s.guardian_id
            JOIN travel_journeys j ON j.id = s.journey_id
            JOIN users u ON u.id = j.user_id
            WHERE (s.guardian_user_id = ? OR g.guardian_user_id = ?)
              AND s.revoked_at IS NULL
              AND COALESCE(s.sharing_status, 'ACTIVE') = 'ACTIVE'
            ORDER BY s.created_at DESC;
            """,
            (gid, gid),
        ).fetchall()

        valid_share_rows = []
        for sr in share_rows:
            exp_dt = parse_iso_dt(sr["expires_at"])
            if exp_dt and exp_dt > now_dt:
                valid_share_rows.append(sr)

        # Build unified accessible journeys map keyed by journey_id
        accessible_journeys = {}
        for cr in conn_rows:
            if "live_journey" not in (cr["permissions"] or ""):
                continue
            j_rows = c.execute(
                """
                SELECT * FROM travel_journeys
                WHERE user_id = ?
                ORDER BY created_at DESC LIMIT 5;
                """,
                (cr["user_id"],),
            ).fetchall()
            for jr in j_rows:
                if jr["id"] not in accessible_journeys:
                    accessible_journeys[jr["id"]] = {
                        "row": jr,
                        "userName": cr["full_name"],
                        "userPhone": cr["phone"],
                        "relationship": cr["relationship"] or "Guardian",
                        "source": "CONNECTION",
                    }

        for sr in valid_share_rows:
            if sr["journey_id"] not in accessible_journeys:
                jr = c.execute("SELECT * FROM travel_journeys WHERE id = ?;", (sr["journey_id"],)).fetchone()
                if jr:
                    accessible_journeys[jr["id"]] = {
                        "row": jr,
                        "userName": sr["user_full_name"],
                        "userPhone": sr["user_phone"],
                        "relationship": "Shared Link",
                        "source": "SHARED_LINK",
                    }

        # Convert accessible journeys into DTOs cleanly, check OVERDUE, partition active vs completed
        active_journeys = []
        completed_journeys = []
        latest_journey_by_user = {}

        for jid, meta in accessible_journeys.items():
            dto = self._journey_dto(c, meta["row"])
            dto["userName"] = meta["userName"]
            dto["userPhone"] = meta["userPhone"]
            dto["relationship"] = meta["relationship"]
            dto["accessSource"] = meta["source"]

            last_lat = dto["lastLatitude"] if dto["lastLatitude"] is not None else dto["startLatitude"]
            last_lng = dto["lastLongitude"] if dto["lastLongitude"] is not None else dto["startLongitude"]
            rem_m = (
                round(haversine_meters(last_lat, last_lng, dto["destinationLatitude"], dto["destinationLongitude"]), 1)
                if (last_lat is not None and last_lng is not None)
                else dto["distanceMeters"]
            )
            dto["remainingMeters"] = rem_m
            # Calculate distance traveled cleanly along trail
            trail = dto["locations"] or []
            traveled_m = 0.0
            for idx in range(1, len(trail)):
                traveled_m += haversine_meters(
                    trail[idx - 1]["latitude"],
                    trail[idx - 1]["longitude"],
                    trail[idx]["latitude"],
                    trail[idx]["longitude"],
                )
            dto["traveledMeters"] = round(traveled_m, 1)

            st = dto["status"]
            if st == "EMERGENCY":
                dto["statusBadge"] = "RED – Emergency"
            elif st == "OVERDUE" or dto["deviationWarning"]:
                dto["statusBadge"] = "ORANGE – Delayed"
            elif st == "COMPLETED":
                dto["statusBadge"] = "BLUE – Safely Arrived"
            else:
                dto["statusBadge"] = "GREEN – Journey Active"

            # Emit overdue alert notification once per overdue journey
            if st == "OVERDUE":
                exists_notif = c.execute(
                    "SELECT 1 FROM guardian_notifications WHERE guardian_id = ? AND journey_id = ? AND notification_type = 'OVERDUE_ALERT';",
                    (gid, jid),
                ).fetchone()
                if not exists_notif:
                    self._insert_guardian_notification(
                        c,
                        gid,
                        jid,
                        "OVERDUE_ALERT",
                        f"{meta['userName']}'s trip to {dto['destinationName']} is overdue past ETA.",
                    )

            uid = dto["userId"]
            prev = latest_journey_by_user.get(uid)
            if not prev or (dto["createdAt"] or "") > (prev["createdAt"] or ""):
                latest_journey_by_user[uid] = dto

            if st in ("ACTIVE", "OVERDUE", "DEVIATION_WARNING", "EMERGENCY"):
                active_journeys.append(dto)
            elif st == "COMPLETED":
                completed_journeys.append(dto)

        active_journeys.sort(key=lambda x: x["createdAt"] or "", reverse=True)
        completed_journeys.sort(key=lambda x: x.get("actualArrivalTime") or x["updatedAt"] or "", reverse=True)
        completed_journeys = completed_journeys[:15]

        # Connected Users summary list (from both accepted connections and shared journeys)
        connected_users_map = {}
        for cr in conn_rows:
            uid = cr["user_id"]
            connected_users_map[uid] = {
                "userId": uid,
                "fullName": cr["full_name"],
                "relationship": cr["relationship"] or "Guardian",
                "connectionStatus": "CONNECTED",
                "connectionSource": "APP_CONNECTION",
                "permissions": cr["permissions"],
                "acceptedAt": cr["accepted_at"],
            }
        for sr in valid_share_rows:
            uid = sr["user_id"]
            if uid not in connected_users_map:
                connected_users_map[uid] = {
                    "userId": uid,
                    "fullName": sr["user_full_name"],
                    "relationship": "Shared Link",
                    "connectionStatus": "SHARED_JOURNEY_ONLY",
                    "connectionSource": "SHARED_LINK",
                    "permissions": "live_journey",
                    "acceptedAt": sr["created_at"],
                }

        connected_user_ids = [uid for uid, cu in connected_users_map.items() if cu["connectionSource"] == "APP_CONNECTION"]

        # Emergency alerts (open + historical) for connected users & shared emergency journeys
        emergency_alerts = []
        if connected_user_ids:
            placeholders = ",".join("?" for _ in connected_user_ids)
            sos_rows = c.execute(
                f"""
                SELECT s.*, j.id as linked_journey_id, j.destination_name, j.start_location_name, j.status as journey_status
                FROM sos_cases s
                LEFT JOIN travel_journeys j ON j.sos_event_id = s.id
                WHERE s.user_id IN ({placeholders})
                ORDER BY s.timestamp DESC LIMIT 30;
                """,
                tuple(connected_user_ids),
            ).fetchall()
            for r in sos_rows:
                st_up = (r["status"] or "OPEN").upper()
                gps_parts = [p.strip() for p in (r["gps"] or "").split(",")]
                lat_val = parse_coord(gps_parts[0], -90.0, 90.0) if len(gps_parts) >= 2 else None
                lng_val = parse_coord(gps_parts[1], -180.0, 180.0) if len(gps_parts) >= 2 else None
                emergency_alerts.append(
                    {
                        "sosId": r["id"],
                        "userId": r["user_id"],
                        "userName": r["user_name"],
                        "userPhone": r["user_phone"],
                        "priority": r["priority"],
                        "status": st_up,
                        "resolved": st_up == "RESOLVED",
                        "gps": r["gps"],
                        "latitude": lat_val,
                        "longitude": lng_val,
                        "locationName": r["location_name"],
                        "timestamp": r["timestamp"],
                        "deviceType": r["device_type"],
                        "journeyId": r["linked_journey_id"],
                        "destinationName": r["destination_name"],
                        "startLocationName": r["start_location_name"],
                    }
                )

        open_sos_by_user = {a["userId"]: a for a in emergency_alerts if not a["resolved"] and a.get("userId")}

        connected_users = []
        for uid, cu in connected_users_map.items():
            lj = latest_journey_by_user.get(uid)
            open_sos = open_sos_by_user.get(uid)
            last_gps_dt = parse_iso_dt(lj["lastGpsAt"]) if (lj and lj.get("lastGpsAt")) else None
            online = bool(last_gps_dt and (now_dt - last_gps_dt).total_seconds() <= 120)

            if open_sos or (lj and lj["status"] == "EMERGENCY"):
                status_label = "RED – Emergency"
            elif lj and lj["status"] in ("ACTIVE", "DEVIATION_WARNING", "OVERDUE"):
                if lj["status"] == "OVERDUE" or lj.get("deviationWarning"):
                    status_label = "ORANGE – Delayed"
                else:
                    status_label = "GREEN – Journey Active"
            elif lj and lj["status"] == "COMPLETED":
                status_label = "BLUE – Safely Arrived"
            else:
                status_label = "GREY – No Active Journey"

            cu_out = {
                **cu,
                "statusLabel": status_label,
                "trackingStatus": "Online" if online else ("Offline" if lj and lj["status"] != "COMPLETED" else "Idle"),
                "currentJourney": lj if (lj and lj["status"] != "COMPLETED") else None,
                "latestJourney": lj,
                "hasOpenEmergency": open_sos is not None,
            }
            connected_users.append(cu_out)

        # Pending Invitations (both app connection requests AND email/phone invitations)
        pending_invites = []
        pend_conns = c.execute(
            """
            SELECT gc.id, gc.user_id, gc.relationship, gc.created_at, u.full_name as sender_name
            FROM guardian_connections gc
            JOIN users u ON u.id = gc.user_id
            WHERE gc.guardian_id = ? AND gc.connection_status = 'PENDING'
            ORDER BY gc.created_at DESC;
            """,
            (gid,),
        ).fetchall()
        for pc in pend_conns:
            pending_invites.append(
                {
                    "id": pc["id"],
                    "inviteKind": "CONNECTION_REQUEST",
                    "senderUserId": pc["user_id"],
                    "senderName": pc["sender_name"],
                    "relationship": pc["relationship"] or "Guardian",
                    "invitationType": "App Connection Request",
                    "createdAt": pc["created_at"],
                    "expiresAt": None,
                }
            )

        inv_rows = c.execute(
            """
            SELECT gi.*, u.full_name as sender_name
            FROM guardian_invitations gi
            JOIN users u ON u.id = gi.sender_user_id
            WHERE gi.status = 'PENDING'
              AND (LOWER(COALESCE(gi.guardian_email, '')) = ? OR (? != '' AND gi.guardian_phone != ''))
            ORDER BY gi.created_at DESC;
            """,
            (g_email, g_phone_dig),
        ).fetchall()
        for ir in inv_rows:
            matches_email = bool(g_email and (ir["guardian_email"] or "").strip().lower() == g_email)
            matches_phone = bool(g_phone_dig and phone_digits(ir["guardian_phone"] or "") == g_phone_dig)
            if not (matches_email or matches_phone):
                continue
            exp_dt = parse_iso_dt(ir["expires_at"])
            if exp_dt and exp_dt <= now_dt:
                continue
            pending_invites.append(
                {
                    "id": ir["id"],
                    "inviteKind": "INVITATION",
                    "senderUserId": ir["sender_user_id"],
                    "senderName": ir["sender_name"],
                    "relationship": ir["relationship"] or "Guardian",
                    "invitationType": "Email / Link Invitation",
                    "createdAt": ir["created_at"],
                    "expiresAt": ir["expires_at"],
                }
            )

        notif_rows = c.execute(
            """
            SELECT id, journey_id, notification_type, message, delivery_status, created_at, read_at
            FROM guardian_notifications
            WHERE guardian_id = ?
            ORDER BY created_at DESC LIMIT 30;
            """,
            (gid,),
        ).fetchall()
        notifications = [
            {
                "id": n["id"],
                "journeyId": n["journey_id"],
                "notificationType": n["notification_type"],
                "message": n["message"],
                "deliveryStatus": n["delivery_status"],
                "createdAt": n["created_at"],
                "readAt": n["read_at"],
            }
            for n in notif_rows
        ]
        unread_count = sum(1 for n in notifications if not n["readAt"])
        c.connection.commit()

        return {
            "guardian": {
                "id": guardian_user["id"],
                "fullName": guardian_user["fullName"],
                "email": guardian_user["email"],
                "phone": guardian_user["phone"],
                "accountStatus": guardian_user["accountStatus"],
            },
            "stats": {
                "connectedUsersCount": len(connected_users),
                "activeJourneysCount": len(active_journeys),
                "pendingInvitationsCount": len(pending_invites),
                "emergencyAlertsCount": sum(1 for e in emergency_alerts if not e["resolved"]),
                "unreadNotificationsCount": unread_count,
            },
            "connectedUsers": connected_users,
            "pendingInvitations": pending_invites,
            "activeJourneys": active_journeys,
            "completedJourneys": completed_journeys,
            "emergencyAlerts": emergency_alerts,
            "notifications": notifications,
        }

    def _journey_dto(self, c, row):
        poly = []
        try:
            poly = json.loads(row["route_polyline"] or "[]")
        except Exception:
            poly = []

        locs = c.execute(
            """
            SELECT id, latitude, longitude, accuracy, speed, heading, recorded_at
            FROM journey_locations
            WHERE journey_id = ?
            ORDER BY recorded_at ASC;
            """,
            (row["id"],),
        ).fetchall()
        shares = c.execute(
            """
            SELECT id, guardian_id, guardian_name, guardian_phone, guardian_email,
                   delivery_status, delivery_message, created_at, expires_at, revoked_at
            FROM journey_sharing
            WHERE journey_id = ?
            ORDER BY created_at DESC;
            """,
            (row["id"],),
        ).fetchall()
        events = c.execute(
            """
            SELECT id, event_type, details, latitude, longitude, created_at
            FROM journey_events
            WHERE journey_id = ?
            ORDER BY created_at DESC LIMIT 25;
            """,
            (row["id"],),
        ).fetchall()

        now_dt = utc_now()
        eta_dt = parse_iso_dt(row["estimated_arrival_time"])
        effective_status = row["status"]
        if effective_status == "ACTIVE" and eta_dt and now_dt > eta_dt:
            effective_status = "OVERDUE"
            c.execute(
                "UPDATE travel_journeys SET status = 'OVERDUE', updated_at = ? WHERE id = ? AND status = 'ACTIVE';",
                (utc_now_iso(), row["id"]),
            )
            self._record_journey_event(
                c,
                row["id"],
                "ETA_OVERDUE",
                f"Estimated arrival time ({row['estimated_arrival_time']}) exceeded without Safe Arrival confirmation.",
                row["last_latitude"],
                row["last_longitude"],
            )
            c.connection.commit()

        return {
            "id": row["id"],
            "userId": row["user_id"],
            "startLocationName": row["start_location_name"] or "Current GPS Location",
            "startLatitude": row["start_latitude"],
            "startLongitude": row["start_longitude"],
            "destinationName": row["destination_name"],
            "destinationLatitude": row["destination_latitude"],
            "destinationLongitude": row["destination_longitude"],
            "distanceMeters": float(row["distance_meters"] or 0.0),
            "estimatedDuration": int(row["estimated_duration"] or 0),
            "recordingMode": row["recording_mode"] or "None",
            "routePolyline": poly,
            "routeSummary": row["route_summary"] or "",
            "status": effective_status,
            "deviationMeters": float(row["deviation_meters"] or 0.0),
            "deviationWarning": bool(row["deviation_warning"]),
            "etaExtendedCount": int(row["eta_extended_count"] or 0),
            "arrivalVerified": bool(row["arrival_verified"]),
            "arrivalDistanceMeters": row["arrival_distance_meters"],
            "lastLatitude": row["last_latitude"],
            "lastLongitude": row["last_longitude"],
            "lastAccuracy": row["last_accuracy"],
            "lastGpsAt": row["last_gps_at"],
            "startTime": row["start_time"],
            "estimatedArrivalTime": row["estimated_arrival_time"],
            "actualArrivalTime": row["actual_arrival_time"],
            "sosEventId": row["sos_event_id"],
            "createdAt": row["created_at"],
            "updatedAt": row["updated_at"],
            "locations": [
                {
                    "id": l["id"],
                    "latitude": l["latitude"],
                    "longitude": l["longitude"],
                    "accuracy": l["accuracy"],
                    "speed": l["speed"],
                    "heading": l["heading"],
                    "recordedAt": l["recorded_at"],
                }
                for l in locs
            ],
            "shares": [
                {
                    "id": s["id"],
                    "guardianId": s["guardian_id"],
                    "guardianName": s["guardian_name"],
                    "guardianPhone": s["guardian_phone"],
                    "guardianEmail": s["guardian_email"],
                    "deliveryStatus": s["delivery_status"],
                    "deliveryMessage": s["delivery_message"],
                    "createdAt": s["created_at"],
                    "expiresAt": s["expires_at"],
                    "revokedAt": s["revoked_at"],
                    "isActive": s["revoked_at"] is None,
                }
                for s in shares
            ],
            "events": [
                {
                    "id": ev["id"],
                    "eventType": ev["event_type"],
                    "details": ev["details"],
                    "latitude": ev["latitude"],
                    "longitude": ev["longitude"],
                    "createdAt": ev["created_at"],
                }
                for ev in events
            ],
        }

    def do_DELETE(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        conn = get_db()
        c = conn.cursor()
        try:
            m = re.fullmatch(r"/api/audio_evidence/([A-Za-z0-9_-]+)", path)
            if m:
                self._delete_audio_evidence(c, m.group(1))
                return
            self._send_json({"error": "Endpoint not found"}, status=404)
        except Exception as e:
            self._send_json({"error": str(e)}, status=500)
        finally:
            conn.close()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        query = parse_qs(parsed.query)

        conn = get_db()
        c = conn.cursor()

        try:
            # Public health endpoints (database counts only, no PII)
            if path in ("", "/health", "/api/status"):
                cases_count = c.execute("SELECT COUNT(*) FROM sos_cases;").fetchone()[0]
                complaints_count = c.execute("SELECT COUNT(*) FROM cyber_complaints;").fetchone()[0]
                vault_count = c.execute("SELECT COUNT(*) FROM vault_assets;").fetchone()[0]
                users_count = c.execute("SELECT COUNT(*) FROM users;").fetchone()[0]
                self._send_json(
                    {
                        "status": "ok",
                        "server": "SHE SHIELD Local SQLite Server",
                        "database": "SQLite 3",
                        "port": PORT,
                        "records": {
                            "sos_cases": cases_count,
                            "cyber_complaints": complaints_count,
                            "vault_assets": vault_count,
                            "users": users_count,
                        },
                    }
                )
                return

            # Auth identity endpoint
            if path == "/api/auth/me":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                self._send_json(
                    {
                        "user": auth["user"],
                        "expiresAt": auth["user_row"]["expires_at"],
                    }
                )
                return

            # Women Role: Private Voice SOS Settings
            if path == "/api/user/voice_settings":
                auth = self._require_permission(c, "voice_sos:own")
                if not auth:
                    conn.commit()
                    return
                r = auth["user_row"]
                self._send_json(
                    {
                        "userId": r["id"],
                        "voicePhrase": r["secret_phrase"] or "",
                        "language": r["voice_sos_language"] or "English",
                        "voiceSosEnabled": bool(r["voice_sos_enabled"]),
                        "maxDurationSeconds": int(r["voice_sos_max_duration"] or 120),
                        "silentSosMode": bool(r["silent_sos_mode"]),
                    }
                )
                return

            # Women Role: List Own Audio Evidence
            if path == "/api/audio_evidence":
                auth = self._require_permission(c, "audio_evidence:own")
                if not auth:
                    conn.commit()
                    return
                rows = c.execute(
                    """
                    SELECT * FROM audio_evidence
                    WHERE user_id = ?
                    ORDER BY created_at DESC;
                    """,
                    (auth["user"]["id"],),
                ).fetchall()
                self._send_json([self._audio_dto(r) for r in rows])
                return

            # Women Role: Authenticated Audio Stream / Download
            m_stream = re.fullmatch(r"/api/audio_evidence/([A-Za-z0-9_-]+)/stream", path)
            if m_stream:
                self._serve_audio_binary(c, m_stream.group(1), as_attachment=False)
                return

            m_download = re.fullmatch(r"/api/audio_evidence/([A-Za-z0-9_-]+)/download", path)
            if m_download:
                self._serve_audio_binary(c, m_download.group(1), as_attachment=True)
                return

            # Admin endpoints
            if path == "/api/admin/users":
                auth = self._require_permission(c, "admin:users_read")
                if not auth:
                    conn.commit()
                    return
                q = (query.get("q", [""])[0] or "").strip().lower()
                if q:
                    like = f"%{q}%"
                    rows = c.execute(
                        """
                        SELECT u.*, r.role_name
                        FROM users u
                        JOIN roles r ON r.id = u.role_id
                        WHERE LOWER(COALESCE(u.full_name, u.name)) LIKE ?
                           OR LOWER(u.email) LIKE ?
                           OR LOWER(u.phone) LIKE ?
                           OR COALESCE(u.phone_digits, '') LIKE ?
                        ORDER BY COALESCE(u.created_at, '') DESC;
                        """,
                        (like, like, like, like),
                    ).fetchall()
                else:
                    rows = c.execute(
                        """
                        SELECT u.*, r.role_name
                        FROM users u
                        JOIN roles r ON r.id = u.role_id
                        ORDER BY COALESCE(u.created_at, '') DESC;
                        """
                    ).fetchall()

                users_list = [
                    self._user_dto(row, self._get_role_permissions(c, row["role_id"]))
                    for row in rows
                ]
                self._send_json(users_list)
                return

            if path == "/api/admin/roles":
                auth = self._require_permission(c, "admin:users_read")
                if not auth:
                    conn.commit()
                    return
                roles = c.execute("SELECT id, role_name, description FROM roles ORDER BY id;").fetchall()
                result = [
                    {
                        "id": r["id"],
                        "roleName": r["role_name"],
                        "description": r["description"],
                        "permissions": self._get_role_permissions(c, r["id"]),
                    }
                    for r in roles
                ]
                self._send_json(result)
                return

            if path == "/api/admin/audit_logs":
                auth = self._require_permission(c, "admin:audit_view")
                if not auth:
                    conn.commit()
                    return
                rows = c.execute(
                    """
                    SELECT a.id, a.actor_user_id, COALESCE(u.email, 'system') AS actor_email,
                           a.action, a.target_id, a.details, a.created_at
                    FROM audit_logs a
                    LEFT JOIN users u ON u.id = a.actor_user_id
                    ORDER BY a.id DESC LIMIT 100;
                    """
                ).fetchall()
                self._send_json([dict(r) for r in rows])
                return

            # Domain protected endpoints
            if path == "/api/sos_cases":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                if "sos:view_all" in auth["permissions"]:
                    rows = c.execute(
                        """
                        SELECT id, user_id as userId, user_name as userName, user_email as userEmail,
                               user_phone as userPhone, age, blood_group as bloodGroup, priority,
                               status, gps, timestamp, device_type as deviceType,
                               evidence_count as evidenceCount, location_name as locationName
                        FROM sos_cases ORDER BY timestamp DESC;
                        """
                    ).fetchall()
                elif "dashboard:guardian" in auth["permissions"]:
                    rows = c.execute(
                        """
                        SELECT s.id, s.user_id as userId, s.user_name as userName, '' as userEmail,
                               s.user_phone as userPhone, s.age, s.blood_group as bloodGroup, s.priority,
                               s.status, s.gps, s.timestamp, s.device_type as deviceType,
                               s.evidence_count as evidenceCount, s.location_name as locationName
                        FROM sos_cases s
                        WHERE s.user_id = ?
                           OR s.user_id IN (
                               SELECT user_id FROM guardian_connections
                               WHERE guardian_id = ? AND connection_status = 'ACCEPTED'
                           )
                        ORDER BY s.timestamp DESC;
                        """,
                        (auth["user"]["id"], auth["user"]["id"]),
                    ).fetchall()
                elif "sos:view_own" in auth["permissions"]:
                    rows = c.execute(
                        """
                        SELECT id, user_id as userId, user_name as userName, user_email as userEmail,
                               user_phone as userPhone, age, blood_group as bloodGroup, priority,
                               status, gps, timestamp, device_type as deviceType,
                               evidence_count as evidenceCount, location_name as locationName
                        FROM sos_cases
                        WHERE user_id = ? OR LOWER(COALESCE(user_email, '')) = ?
                        ORDER BY timestamp DESC;
                        """,
                        (auth["user"]["id"], auth["user"]["email"]),
                    ).fetchall()
                else:
                    self._send_json({"error": "Forbidden"}, status=403)
                    return
                self._send_json([dict(r) for r in rows])
                return

            if path == "/api/cyber_complaints":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                if "complaint:view_all" in auth["permissions"]:
                    rows = c.execute(
                        """
                        SELECT id, user_id as userId, user_email as userEmail, category, description,
                               threat_score as threatScore, status, timestamp, user_name as userName,
                               user_phone as userPhone, offender_link as offenderLink,
                               evidence_count as evidenceCount, attached_evidence as attachedEvidence
                        FROM cyber_complaints ORDER BY timestamp DESC;
                        """
                    ).fetchall()
                elif "complaint:view_own" in auth["permissions"]:
                    rows = c.execute(
                        """
                        SELECT id, user_id as userId, user_email as userEmail, category, description,
                               threat_score as threatScore, status, timestamp, user_name as userName,
                               user_phone as userPhone, offender_link as offenderLink,
                               evidence_count as evidenceCount, attached_evidence as attachedEvidence
                        FROM cyber_complaints
                        WHERE user_id = ? OR LOWER(COALESCE(user_email, '')) = ? OR LOWER(user_name) = ?
                        ORDER BY timestamp DESC;
                        """,
                        (auth["user"]["id"], auth["user"]["email"], auth["user"]["fullName"].lower()),
                    ).fetchall()
                else:
                    self._send_json({"error": "Forbidden"}, status=403)
                    return
                self._send_json([dict(r) for r in rows])
                return

            if path == "/api/vault_assets":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                if "vault:view_all" in auth["permissions"]:
                    rows = c.execute(
                        """
                        SELECT id, name, file_type as fileType, hash_sha256 as hash,
                               tamper_check as tamperCheck, status, timestamp, size_mb as sizeMb,
                               chain_of_custody as chainOfCustody
                        FROM vault_assets ORDER BY timestamp DESC;
                        """
                    ).fetchall()
                elif "vault:view_own" in auth["permissions"]:
                    rows = c.execute(
                        """
                        SELECT id, name, file_type as fileType, hash_sha256 as hash,
                               tamper_check as tamperCheck, status, timestamp, size_mb as sizeMb,
                               chain_of_custody as chainOfCustody
                        FROM vault_assets
                        WHERE owner_user_id = ? OR LOWER(COALESCE(owner_email, '')) = ?
                        ORDER BY timestamp DESC;
                        """,
                        (auth["user"]["id"], auth["user"]["email"]),
                    ).fetchall()
                else:
                    self._send_json({"error": "Forbidden"}, status=403)
                    return
                self._send_json([dict(r) for r in rows])
                return

            if path == "/api/guardians":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                if "sos:view_all" in auth["permissions"]:
                    rows = c.execute(
                        """
                        SELECT id, ward_name as wardName, guardian_name as guardianName,
                               email, phone, relation, status, safety_score as safetyScore,
                               risk_status as riskStatus, battery_level as batteryLevel,
                               device_state as deviceState, location_text as locationText, gps
                        FROM guardians;
                        """
                    ).fetchall()
                else:
                    rows = c.execute(
                        """
                        SELECT id, ward_name as wardName, guardian_name as guardianName,
                               email, phone, relation, status, safety_score as safetyScore,
                               risk_status as riskStatus, battery_level as batteryLevel,
                               device_state as deviceState, location_text as locationText, gps
                        FROM guardians
                        WHERE owner_user_id = ? OR LOWER(COALESCE(owner_email, '')) = ? OR LOWER(email) = ?;
                        """,
                        (auth["user"]["id"], auth["user"]["email"], auth["user"]["email"]),
                    ).fetchall()
                self._send_json([dict(r) for r in rows])
                return

            if path == "/api/cab_trips":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                rows = c.execute(
                    """
                    SELECT id, plate_number as plateNumber, driver_name as driverName,
                           provider, destination, origin, speed_kmh as speedKmh,
                           deviation_meters as deviationMeters, safety_score as safetyScore,
                           status, timestamp
                    FROM cab_trips ORDER BY timestamp DESC;
                    """
                ).fetchall()
                self._send_json([dict(r) for r in rows])
                return

            if path == "/api/geo/search":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                q_str = (query.get("q") or [""])[0].strip()
                bias_lat = parse_coord((query.get("lat") or [None])[0], -90.0, 90.0)
                bias_lng = parse_coord((query.get("lng") or [None])[0], -180.0, 180.0)
                if len(q_str) < 2:
                    self._send_json({"provider": "none", "results": []})
                    return
                try:
                    out = search_places_live(q_str, bias_lat=bias_lat, bias_lng=bias_lng)
                    self._send_json(out)
                except Exception as ge:
                    self._send_json({"error": str(ge), "results": []}, status=503)
                return

            if path == "/api/geo/route":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                s_lat = parse_coord((query.get("startLat") or [None])[0], -90.0, 90.0)
                s_lng = parse_coord((query.get("startLng") or [None])[0], -180.0, 180.0)
                d_lat = parse_coord((query.get("destLat") or [None])[0], -90.0, 90.0)
                d_lng = parse_coord((query.get("destLng") or [None])[0], -180.0, 180.0)
                mode = (query.get("mode") or ["driving"])[0].strip().lower()
                if None in (s_lat, s_lng, d_lat, d_lng):
                    self._send_json({"error": "Valid startLat, startLng, destLat, and destLng are required."}, status=400)
                    return
                try:
                    out = compute_routes_live(s_lat, s_lng, d_lat, d_lng, mode=mode)
                    self._send_json(out)
                except Exception as re_err:
                    self._send_json(
                        {
                            "error": str(re_err),
                            "straightLineDistanceMeters": round(haversine_meters(s_lat, s_lng, d_lat, d_lng), 1),
                        },
                        status=503,
                    )
                return

            if path == "/api/journeys/active":
                auth = self._require_permission(c, "travel:own")
                if not auth:
                    conn.commit()
                    return
                row = c.execute(
                    """
                    SELECT * FROM travel_journeys
                    WHERE user_id = ? AND status IN ('ACTIVE', 'OVERDUE', 'DEVIATION_WARNING', 'EMERGENCY')
                    ORDER BY created_at DESC LIMIT 1;
                    """,
                    (auth["user"]["id"],),
                ).fetchone()
                guardians = self._user_guardians_list(c, auth["user"])
                if not row:
                    self._send_json({"active": False, "journey": None, "guardians": guardians})
                    return
                self._send_json({"active": True, "journey": self._journey_dto(c, row), "guardians": guardians})
                return

            if path == "/api/journeys/history":
                auth = self._require_permission(c, "travel:own")
                if not auth:
                    conn.commit()
                    return
                rows = c.execute(
                    """
                    SELECT id, start_location_name, start_latitude, start_longitude,
                           destination_name, destination_latitude, destination_longitude,
                           distance_meters, estimated_duration, recording_mode, status,
                           arrival_verified, arrival_distance_meters, deviation_warning,
                           start_time, estimated_arrival_time, actual_arrival_time, sos_event_id, created_at
                    FROM travel_journeys
                    WHERE user_id = ?
                    ORDER BY created_at DESC LIMIT 30;
                    """,
                    (auth["user"]["id"],),
                ).fetchall()
                self._send_json(
                    [
                        {
                            "id": r["id"],
                            "startLocationName": r["start_location_name"] or "Current GPS Location",
                            "startLatitude": r["start_latitude"],
                            "startLongitude": r["start_longitude"],
                            "destinationName": r["destination_name"],
                            "destinationLatitude": r["destination_latitude"],
                            "destinationLongitude": r["destination_longitude"],
                            "distanceMeters": float(r["distance_meters"] or 0.0),
                            "estimatedDuration": int(r["estimated_duration"] or 0),
                            "recordingMode": r["recording_mode"],
                            "status": r["status"],
                            "arrivalVerified": bool(r["arrival_verified"]),
                            "arrivalDistanceMeters": r["arrival_distance_meters"],
                            "deviationWarning": bool(r["deviation_warning"]),
                            "startTime": r["start_time"],
                            "estimatedArrivalTime": r["estimated_arrival_time"],
                            "actualArrivalTime": r["actual_arrival_time"],
                            "sosEventId": r["sos_event_id"],
                            "createdAt": r["created_at"],
                        }
                        for r in rows
                    ]
                )
                return

            m_share = re.fullmatch(r"/api/journeys/share/([A-Za-z0-9_-]{16,128})", path)
            if m_share:
                raw_share_token = m_share.group(1)
                t_hash = hash_token(raw_share_token)
                share_row = c.execute(
                    """
                    SELECT s.*, u.full_name as traveler_name
                    FROM journey_sharing s
                    JOIN travel_journeys j ON j.id = s.journey_id
                    JOIN users u ON u.id = j.user_id
                    WHERE s.sharing_token_hash = ?;
                    """,
                    (t_hash,),
                ).fetchone()
                if not share_row:
                    self._send_json({"error": "Invalid or unknown tracking link.", "code": "SHARE_NOT_FOUND"}, status=404)
                    return
                if share_row["revoked_at"] is not None:
                    self._send_json({"error": "Tracking link was revoked by the traveler.", "code": "SHARE_REVOKED"}, status=403)
                    return
                exp_dt = parse_iso_dt(share_row["expires_at"])
                if not exp_dt or exp_dt <= utc_now():
                    self._send_json({"error": "This live tracking link has expired.", "code": "SHARE_EXPIRED"}, status=410)
                    return

                j_row = c.execute("SELECT * FROM travel_journeys WHERE id = ?;", (share_row["journey_id"],)).fetchone()
                if not j_row:
                    self._send_json({"error": "Journey no longer exists.", "code": "JOURNEY_NOT_FOUND"}, status=404)
                    return

                dto = self._journey_dto(c, j_row)
                last_lat = dto["lastLatitude"] if dto["lastLatitude"] is not None else dto["startLatitude"]
                last_lng = dto["lastLongitude"] if dto["lastLongitude"] is not None else dto["startLongitude"]
                remaining_m = (
                    haversine_meters(last_lat, last_lng, dto["destinationLatitude"], dto["destinationLongitude"])
                    if (last_lat is not None and last_lng is not None)
                    else dto["distanceMeters"]
                )
                self._send_json(
                    {
                        "valid": True,
                        "travelerName": (share_row["traveler_name"] or "Traveler").split(" ")[0],
                        "guardianName": share_row["guardian_name"],
                        "shareExpiresAt": share_row["expires_at"],
                        "remainingMeters": round(remaining_m, 1),
                        "journey": {
                            "id": dto["id"],
                            "status": dto["status"],
                            "startLocationName": dto["startLocationName"],
                            "startLatitude": dto["startLatitude"],
                            "startLongitude": dto["startLongitude"],
                            "destinationName": dto["destinationName"],
                            "destinationLatitude": dto["destinationLatitude"],
                            "destinationLongitude": dto["destinationLongitude"],
                            "distanceMeters": dto["distanceMeters"],
                            "estimatedDuration": dto["estimatedDuration"],
                            "routePolyline": dto["routePolyline"],
                            "routeSummary": dto["routeSummary"],
                            "deviationMeters": dto["deviationMeters"],
                            "deviationWarning": dto["deviationWarning"],
                            "arrivalVerified": dto["arrivalVerified"],
                            "lastLatitude": dto["lastLatitude"],
                            "lastLongitude": dto["lastLongitude"],
                            "lastAccuracy": dto["lastAccuracy"],
                            "lastGpsAt": dto["lastGpsAt"],
                            "startTime": dto["startTime"],
                            "estimatedArrivalTime": dto["estimatedArrivalTime"],
                            "actualArrivalTime": dto["actualArrivalTime"],
                            "locations": dto["locations"],
                            "events": [ev for ev in dto["events"] if ev["eventType"] != "SENSITIVE"],
                        },
                    }
                )
                return

            if path == "/api/guardians/network":
                auth = self._require_permission(c, "guardian:manage")
                if not auth:
                    conn.commit()
                    return
                uid = auth["user"]["id"]
                conns = c.execute(
                    """
                    SELECT gc.id, gc.guardian_id, gc.relationship, gc.connection_status, gc.permissions,
                           gc.created_at, gc.accepted_at, gc.revoked_at,
                           u.full_name as guardian_name, u.email as guardian_email, u.phone as guardian_phone
                    FROM guardian_connections gc
                    JOIN users u ON u.id = gc.guardian_id
                    WHERE gc.user_id = ?
                    ORDER BY gc.created_at DESC;
                    """,
                    (uid,),
                ).fetchall()
                invs = c.execute(
                    """
                    SELECT id, guardian_name, guardian_email, guardian_phone, relationship, status, expires_at, created_at
                    FROM guardian_invitations
                    WHERE sender_user_id = ?
                    ORDER BY created_at DESC;
                    """,
                    (uid,),
                ).fetchall()
                self._send_json(
                    {
                        "connections": [
                            {
                                "id": r["id"],
                                "guardianUserId": r["guardian_id"],
                                "guardianName": r["guardian_name"],
                                "email": r["guardian_email"],
                                "phone": r["guardian_phone"],
                                "relationship": r["relationship"],
                                "status": r["connection_status"],
                                "permissions": r["permissions"],
                                "createdAt": r["created_at"],
                                "acceptedAt": r["accepted_at"],
                                "revokedAt": r["revoked_at"],
                            }
                            for r in conns
                        ],
                        "invitations": [
                            {
                                "id": r["id"],
                                "guardianName": r["guardian_name"] or r["guardian_email"] or r["guardian_phone"],
                                "email": r["guardian_email"],
                                "phone": r["guardian_phone"],
                                "relationship": r["relationship"],
                                "status": r["status"],
                                "expiresAt": r["expires_at"],
                                "createdAt": r["created_at"],
                            }
                            for r in invs
                        ],
                    }
                )
                return

            if path == "/api/guardian/dashboard":
                auth = self._require_permission(c, "dashboard:guardian")
                if not auth:
                    conn.commit()
                    return
                self._send_json(self._guardian_dashboard_payload(c, auth["user"]))
                return

            m_gj = re.fullmatch(r"/api/guardian/journeys/([A-Za-z0-9_-]+)", path)
            if m_gj:
                auth = self._require_permission(c, "dashboard:guardian")
                if not auth:
                    conn.commit()
                    return
                jid = m_gj.group(1)
                j_row = c.execute("SELECT * FROM travel_journeys WHERE id = ?;", (jid,)).fetchone()
                if not j_row:
                    self._send_json({"error": "Journey not found."}, status=404)
                    return
                allowed, src, rel = self._guardian_has_journey_access(c, auth["user"]["id"], j_row)
                if not allowed:
                    log_audit(c, auth["user"]["id"], "GUARDIAN_JOURNEY_DENIED", jid, "Not connected or share revoked/expired")
                    conn.commit()
                    self._send_json({"error": "Forbidden: no active connection or valid share link for this journey."}, status=403)
                    return
                u_row = c.execute("SELECT full_name, phone FROM users WHERE id = ?;", (j_row["user_id"],)).fetchone()
                dto = self._journey_dto(c, j_row)
                dto["userName"] = u_row["full_name"] if u_row else "Traveler"
                dto["userPhone"] = u_row["phone"] if u_row else ""
                dto["relationship"] = rel
                dto["accessSource"] = src
                last_lat = dto["lastLatitude"] if dto["lastLatitude"] is not None else dto["startLatitude"]
                last_lng = dto["lastLongitude"] if dto["lastLongitude"] is not None else dto["startLongitude"]
                dto["remainingMeters"] = (
                    round(haversine_meters(last_lat, last_lng, dto["destinationLatitude"], dto["destinationLongitude"]), 1)
                    if (last_lat is not None and last_lng is not None)
                    else dto["distanceMeters"]
                )
                trail = dto["locations"] or []
                t_m = 0.0
                for idx in range(1, len(trail)):
                    t_m += haversine_meters(
                        trail[idx - 1]["latitude"], trail[idx - 1]["longitude"], trail[idx]["latitude"], trail[idx]["longitude"]
                    )
                dto["traveledMeters"] = round(t_m, 1)
                self._send_json({"journey": dto})
                return

            self._send_json({"error": "Endpoint not found"}, status=404)

        except Exception as e:
            self._send_json({"error": str(e)}, status=500)
        finally:
            conn.close()

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")

        conn = get_db()
        c = conn.cursor()

        try:
            # Handle binary audio evidence upload BEFORE JSON body reader
            if path == "/api/audio_evidence":
                auth = self._require_permission(c, "audio_evidence:own")
                if not auth:
                    conn.commit()
                    return

                try:
                    content_length = int(self.headers.get("Content-Length", 0))
                except ValueError:
                    self._send_json({"error": "Invalid Content-Length header."}, status=400)
                    return

                if content_length <= 0:
                    self._send_json({"error": "Audio file body cannot be empty."}, status=400)
                    return
                if content_length > MAX_AUDIO_BYTES:
                    self._send_json({"error": "Audio file exceeds 25 MB maximum size."}, status=413)
                    return

                meta_raw = self.headers.get("X-Evidence-Meta", "").strip()
                if not meta_raw:
                    self._send_json({"error": "Missing X-Evidence-Meta header."}, status=400)
                    return
                try:
                    meta = json.loads(meta_raw)
                except Exception:
                    self._send_json({"error": "Invalid X-Evidence-Meta JSON."}, status=400)
                    return

                content_type = (self.headers.get("Content-Type") or meta.get("mimeType") or "").split(";")[0].strip().lower()
                if content_type not in ALLOWED_AUDIO_MIMES:
                    self._send_json({"error": f"Unsupported audio format: {content_type}"}, status=400)
                    return

                raw_bytes = self.rfile.read(content_length)
                if len(raw_bytes) != content_length or not is_valid_audio_magic(content_type, raw_bytes):
                    self._send_json({"error": "Uploaded bytes failed audio format & container validation."}, status=400)
                    return

                computed_sha256 = hashlib.sha256(raw_bytes).hexdigest()
                client_sha = (meta.get("clientSha256") or "").strip().lower()
                if client_sha and client_sha != computed_sha256:
                    self._send_json({"error": "SHA-256 upload integrity mismatch."}, status=400)
                    return

                rec_id = (meta.get("recordingId") or f"AUD-{uuid.uuid4().hex[:12].upper()}").strip()
                if not re.fullmatch(r"[A-Za-z0-9_-]{4,64}", rec_id):
                    rec_id = f"AUD-{uuid.uuid4().hex[:12].upper()}"

                sos_event_id = (meta.get("sosEventId") or "").strip() or None
                if sos_event_id:
                    sos_row = c.execute("SELECT id, user_id FROM sos_cases WHERE id = ?;", (sos_event_id,)).fetchone()
                    if sos_row:
                        if sos_row["user_id"] and sos_row["user_id"] != auth["user"]["id"]:
                            self._send_json({"error": "Forbidden: SOS Event belongs to another account."}, status=403)
                            return
                    else:
                        # If SOS was triggered while offline, create the paired SOS event upon sync
                        c.execute(
                            """
                            INSERT INTO sos_cases (id, user_id, user_name, user_email, user_phone, priority, status, gps, timestamp, device_type, evidence_count, location_name)
                            VALUES (?, ?, ?, ?, ?, 'CRITICAL', 'open', ?, ?, 'Voice SOS Auto-Trigger (Synced)', 1, ?);
                            """,
                            (
                                sos_event_id,
                                auth["user"]["id"],
                                auth["user"]["fullName"],
                                auth["user"]["email"],
                                auth["user"]["phone"],
                                (meta.get("gps") or "23.0225, 72.5714"),
                                (meta.get("startedAt") or utc_now_iso()),
                                (meta.get("locationName") or "Synced Offline Location"),
                            ),
                        )

                ext = ALLOWED_AUDIO_MIMES[content_type]
                orig_name = re.sub(r"[^A-Za-z0-9._-]", "_", (meta.get("filename") or f"{rec_id}{ext}").strip())
                if not orig_name.lower().endswith(ext):
                    orig_name = f"{orig_name}{ext}"

                user_dir = os.path.join(AUDIO_VAULT_DIR, auth["user"]["id"])
                os.makedirs(user_dir, mode=0o700, exist_ok=True)
                storage_path = os.path.join(user_dir, f"{rec_id}{ext}")
                with open(storage_path, "wb") as f:
                    f.write(raw_bytes)
                try:
                    os.chmod(storage_path, 0o600)
                except Exception:
                    pass

                now_iso = utc_now_iso()
                started_at = (meta.get("startedAt") or now_iso).strip()
                ended_at = (meta.get("endedAt") or now_iso).strip()
                duration_seconds = max(1, int(meta.get("durationSeconds") or 1))
                phrase_used = (meta.get("triggerPhrase") or "").strip()
                phrase_hmac = hmac_phrase(phrase_used) if phrase_used else ""

                c.execute(
                    """
                    INSERT INTO audio_evidence (
                        id, user_id, sos_event_id, filename, storage_path, mime_type,
                        file_size, duration_seconds, started_at, ended_at,
                        trigger_phrase_hmac, sha256_hash, created_at, status,
                        last_verified_at, integrity_status
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'SAVED', ?, 'VERIFIED');
                    """,
                    (
                        rec_id,
                        auth["user"]["id"],
                        sos_event_id,
                        orig_name,
                        storage_path,
                        content_type,
                        len(raw_bytes),
                        duration_seconds,
                        started_at,
                        ended_at,
                        phrase_hmac,
                        computed_sha256,
                        now_iso,
                        now_iso,
                    ),
                )
                log_audit(c, auth["user"]["id"], "AUDIO_EVIDENCE_SAVED", rec_id, f"Saved {orig_name} ({len(raw_bytes)} B) for SOS {sos_event_id}")
                conn.commit()
                saved_row = c.execute("SELECT * FROM audio_evidence WHERE id = ?;", (rec_id,)).fetchone()
                self._send_json({"success": True, "recording": self._audio_dto(saved_row)}, status=201)
                return

            data = self._read_body()
            if data is None:
                self._send_json({"error": "Invalid JSON payload."}, status=400)
                return

            # Women Role: Save Voice SOS Settings
            if path == "/api/user/voice_settings":
                auth = self._require_permission(c, "voice_sos:own")
                if not auth:
                    conn.commit()
                    return
                phrase = (data.get("voicePhrase") or "").strip()
                if len(phrase) < 2 or len(phrase) > 64:
                    self._send_json({"error": "Voice activation phrase must be 2 to 64 characters."}, status=400)
                    return
                language = (data.get("language") or "English").strip()
                if language not in ("English", "Hindi", "Gujarati", "Marathi"):
                    self._send_json({"error": "Unsupported language preference."}, status=400)
                    return
                enabled = 1 if bool(data.get("voiceSosEnabled")) else 0
                max_dur = int(data.get("maxDurationSeconds") or 120)
                if max_dur < 15 or max_dur > 600:
                    self._send_json({"error": "Max recording duration must be between 15 and 600 seconds."}, status=400)
                    return
                silent_mode = 1 if bool(data.get("silentSosMode")) else 0

                c.execute(
                    """
                    UPDATE users
                    SET secret_phrase = ?, voice_sos_language = ?, voice_sos_enabled = ?,
                        voice_sos_max_duration = ?, silent_sos_mode = ?, updated_at = ?
                    WHERE id = ?;
                    """,
                    (phrase, language, enabled, max_dur, silent_mode, utc_now_iso(), auth["user"]["id"]),
                )
                log_audit(c, auth["user"]["id"], "VOICE_SOS_SETTINGS_UPDATED", auth["user"]["id"], f"enabled={enabled}, lang={language}")
                conn.commit()
                self._send_json(
                    {
                        "success": True,
                        "settings": {
                            "userId": auth["user"]["id"],
                            "voicePhrase": phrase,
                            "language": language,
                            "voiceSosEnabled": bool(enabled),
                            "maxDurationSeconds": max_dur,
                            "silentSosMode": bool(silent_mode),
                        },
                    }
                )
                return

            # Women Role: Verify Audio Evidence SHA-256 Integrity
            m_verify = re.fullmatch(r"/api/audio_evidence/([A-Za-z0-9_-]+)/verify", path)
            if m_verify:
                rec_id = m_verify.group(1)
                auth = self._require_permission(c, "audio_evidence:own")
                if not auth:
                    conn.commit()
                    return
                row = c.execute("SELECT * FROM audio_evidence WHERE id = ?;", (rec_id,)).fetchone()
                if not row:
                    self._send_json({"error": "Audio evidence not found."}, status=404)
                    return
                if row["user_id"] != auth["user"]["id"]:
                    self._send_json({"error": "Forbidden: you do not own this audio recording."}, status=403)
                    return

                storage_path = row["storage_path"]
                now_iso = utc_now_iso()
                if not storage_path or not os.path.isfile(storage_path):
                    c.execute(
                        "UPDATE audio_evidence SET integrity_status = 'FILE_MISSING', last_verified_at = ? WHERE id = ?;",
                        (now_iso, rec_id),
                    )
                    conn.commit()
                    self._send_json(
                        {
                            "verified": False,
                            "fileExists": False,
                            "storedSha256": row["sha256_hash"],
                            "computedSha256": None,
                            "integrityStatus": "FILE_MISSING",
                        }
                    )
                    return

                with open(storage_path, "rb") as f:
                    raw_disk = f.read()
                disk_sha = hashlib.sha256(raw_disk).hexdigest()
                matched = (disk_sha == row["sha256_hash"]) and (len(raw_disk) == row["file_size"])
                status_label = "VERIFIED" if matched else "TAMPERED"
                c.execute(
                    "UPDATE audio_evidence SET integrity_status = ?, last_verified_at = ? WHERE id = ?;",
                    (status_label, now_iso, rec_id),
                )
                log_audit(c, auth["user"]["id"], "AUDIO_INTEGRITY_VERIFY", rec_id, f"Result={status_label}")
                conn.commit()
                self._send_json(
                    {
                        "verified": matched,
                        "fileExists": True,
                        "fileSizeMatch": len(raw_disk) == row["file_size"],
                        "storedSha256": row["sha256_hash"],
                        "computedSha256": disk_sha,
                        "integrityStatus": status_label,
                        "verifiedAt": now_iso,
                    }
                )
                return

            m_del_post = re.fullmatch(r"/api/audio_evidence/([A-Za-z0-9_-]+)/delete", path)
            if m_del_post:
                self._delete_audio_evidence(c, m_del_post.group(1))
                return
            # ------------------------------------------------------------------
            # PUBLIC AUTHENTICATION ENDPOINTS
            # ------------------------------------------------------------------
            if path == "/api/auth/register":
                full_name = (data.get("fullName") or data.get("name") or "").strip()
                email = (data.get("email") or "").strip().lower()
                raw_phone = (data.get("phone") or "").strip()
                password = data.get("password") or ""
                aadhaar_number = (data.get("aadhaarNumber") or "").strip()

                if len(full_name) < 2 or len(full_name) > 80:
                    self._send_json({"error": "Full Name must be between 2 and 80 characters."}, status=400)
                    return
                if not EMAIL_REGEX.match(email):
                    self._send_json({"error": "Please enter a valid email address."}, status=400)
                    return

                p_digits = phone_digits(raw_phone)
                if len(p_digits) < 10 or len(p_digits) > 15:
                    self._send_json({"error": "Phone Number must contain 10 to 15 digits."}, status=400)
                    return

                pw_err = validate_password_strength(password)
                if pw_err:
                    self._send_json({"error": pw_err}, status=400)
                    return

                if aadhaar_number and not verhoeff_valid(aadhaar_number):
                    self._send_json(
                        {"error": "Invalid 12-digit Aadhaar number checksum."},
                        status=400,
                    )
                    return

                existing_email = c.execute(
                    "SELECT id FROM users WHERE LOWER(email) = ?;", (email,)
                ).fetchone()
                if existing_email:
                    self._send_json({"error": "An account with this email already exists."}, status=409)
                    return

                existing_phone = c.execute(
                    "SELECT id FROM users WHERE phone_digits = ?;", (p_digits,)
                ).fetchone()
                if existing_phone:
                    self._send_json({"error": "An account with this phone number already exists."}, status=409)
                    return

                # Public registration allows ONLY 'registered_user' or 'guardian'.
                # Attempting 'admin', 'officer', or other privileged roles is strictly rejected (403).
                req_account_type = (data.get("accountType") or data.get("role") or "registered_user").strip().lower()
                if req_account_type in ("registered_user", "user", "women", "woman"):
                    assign_role, assign_role_id = "registered_user", "ROLE_USER"
                elif req_account_type == "guardian":
                    assign_role, assign_role_id = "guardian", "ROLE_GUARDIAN"
                else:
                    self._send_json(
                        {"error": "Public registration allows only 'registered_user' or 'guardian' roles."},
                        status=403,
                    )
                    return

                user_id = "USR-" + uuid.uuid4().hex[:12].upper()
                now_iso = utc_now_iso()
                pw_hash = hash_password(password)
                norm_phone = normalize_phone(raw_phone)

                c.execute(
                    """
                    INSERT INTO users (
                        id, name, full_name, email, phone, phone_digits, password_hash,
                        role, role_id, account_status,
                        aadhaar_verified, face_verified, otp_verified, face_match_score,
                        created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', 0, 0, 0, 0.0, ?, ?);
                    """,
                    (user_id, full_name, full_name, email, norm_phone, p_digits, pw_hash, assign_role, assign_role_id, now_iso, now_iso),
                )

                if assign_role == "guardian":
                    c.execute(
                        "UPDATE guardians SET guardian_user_id = ? WHERE guardian_user_id IS NULL AND LOWER(COALESCE(email, '')) = ?;",
                        (user_id, email),
                    )
                    invite_tok = (data.get("inviteToken") or "").strip()
                    if invite_tok:
                        inv_row = c.execute(
                            "SELECT * FROM guardian_invitations WHERE invitation_token_hash = ? AND status = 'PENDING';",
                            (hash_token(invite_tok),),
                        ).fetchone()
                        if inv_row:
                            exp_dt = parse_iso_dt(inv_row["expires_at"])
                            if exp_dt and exp_dt > utc_now():
                                c.execute(
                                    """
                                    INSERT INTO guardian_connections (id, user_id, guardian_id, relationship, connection_status, permissions, created_at, accepted_at)
                                    VALUES (?, ?, ?, ?, 'ACCEPTED', 'live_journey,sos_alerts', ?, ?)
                                    ON CONFLICT(user_id, guardian_id) DO UPDATE SET connection_status='ACCEPTED', accepted_at=excluded.accepted_at, revoked_at=NULL;
                                    """,
                                    (f"GCN-{uuid.uuid4().hex[:10]}", inv_row["sender_user_id"], user_id, inv_row["relationship"] or "Guardian", now_iso, now_iso),
                                )
                                c.execute(
                                    "UPDATE guardian_invitations SET status = 'ACCEPTED', responded_at = ? WHERE id = ?;",
                                    (now_iso, inv_row["id"]),
                                )
                    share_tok = (data.get("shareToken") or "").strip()
                    if share_tok:
                        sh_row = c.execute(
                            "SELECT * FROM journey_sharing WHERE sharing_token_hash = ? AND revoked_at IS NULL;",
                            (hash_token(share_tok),),
                        ).fetchone()
                        if sh_row:
                            exp_dt = parse_iso_dt(sh_row["expires_at"])
                            if exp_dt and exp_dt > utc_now():
                                c.execute(
                                    "UPDATE journey_sharing SET guardian_user_id = ?, guardian_name = ?, accepted_at = ? WHERE id = ?;",
                                    (user_id, full_name, now_iso, sh_row["id"]),
                                )

                raw_token, expires_at = self._create_session(c, user_id)
                log_audit(c, user_id, "AUTH_REGISTER", user_id, f"Public registration for {email} ({assign_role_id})")
                conn.commit()

                row = c.execute(
                    "SELECT u.*, r.role_name FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = ?;",
                    (user_id,),
                ).fetchone()
                perms = self._get_role_permissions(c, assign_role_id)
                self._send_json(
                    {
                        "success": True,
                        "message": "Registration successful.",
                        "token": raw_token,
                        "expiresAt": expires_at,
                        "user": self._user_dto(row, perms),
                    },
                    status=201,
                )
                return

            if path == "/api/auth/login":
                email = (data.get("email") or "").strip().lower()
                password = data.get("password") or ""

                if not EMAIL_REGEX.match(email) or not password:
                    self._send_json({"error": "Valid email and password are required."}, status=400)
                    return

                row = c.execute(
                    """
                    SELECT u.*, r.role_name
                    FROM users u
                    JOIN roles r ON r.id = u.role_id
                    WHERE LOWER(u.email) = ?;
                    """,
                    (email,),
                ).fetchone()

                if not row or not verify_password(password, row["password_hash"] or ""):
                    log_audit(c, row["id"] if row else None, "AUTH_LOGIN_FAILED", email, "Invalid credentials")
                    conn.commit()
                    self._send_json({"error": "Invalid email or password."}, status=401)
                    return

                if row["account_status"] != "ACTIVE":
                    log_audit(c, row["id"], "AUTH_LOGIN_BLOCKED", row["id"], f"Account status: {row['account_status']}")
                    conn.commit()
                    self._send_json(
                        {"error": f"Your account is currently {row['account_status']}. Contact an administrator."},
                        status=403,
                    )
                    return

                raw_token, expires_at = self._create_session(c, row["id"])
                log_audit(c, row["id"], "AUTH_LOGIN_SUCCESS", row["id"], f"Role {row['role_name']} logged in")
                conn.commit()

                perms = self._get_role_permissions(c, row["role_id"])
                self._send_json(
                    {
                        "success": True,
                        "token": raw_token,
                        "expiresAt": expires_at,
                        "user": self._user_dto(row, perms),
                    }
                )
                return

            if path == "/api/auth/logout":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                c.execute(
                    "UPDATE authentication_sessions SET revoked = 1 WHERE id = ?;",
                    (auth["session_id"],),
                )
                log_audit(c, auth["user"]["id"], "AUTH_LOGOUT", auth["session_id"], "Session revoked on logout")
                conn.commit()
                self._send_json({"success": True, "message": "Logged out successfully."})
                return

            if path == "/api/auth/profile":
                auth = self._require_auth(c)
                if not auth:
                    conn.commit()
                    return
                uid = auth["user"]["id"]
                full_name = (data.get("fullName") or auth["user"]["fullName"] or "").strip()
                raw_phone = (data.get("phone") or auth["user"]["phone"] or "").strip()
                if len(full_name) < 2 or len(full_name) > 80:
                    self._send_json({"error": "Full Name must be between 2 and 80 characters."}, status=400)
                    return
                p_digits = phone_digits(raw_phone)
                if len(p_digits) < 10 or len(p_digits) > 15:
                    self._send_json({"error": "Phone Number must contain 10 to 15 digits."}, status=400)
                    return
                dup_phone = c.execute(
                    "SELECT id FROM users WHERE phone_digits = ? AND id != ?;",
                    (p_digits, uid),
                ).fetchone()
                if dup_phone:
                    self._send_json({"error": "That phone number is already associated with another account."}, status=409)
                    return

                now_iso = utc_now_iso()
                c.execute(
                    """
                    UPDATE users
                    SET name = ?, full_name = ?, phone = ?, phone_digits = ?, updated_at = ?
                    WHERE id = ?;
                    """,
                    (full_name, full_name, normalize_phone(raw_phone), p_digits, now_iso, uid),
                )
                c.execute("UPDATE guardians SET ward_name = ? WHERE owner_user_id = ?;", (full_name, uid))
                log_audit(c, uid, "AUTH_PROFILE_UPDATED", uid, f"Updated profile for {full_name}")
                conn.commit()

                row = c.execute(
                    "SELECT u.*, r.role_name FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = ?;",
                    (uid,),
                ).fetchone()
                perms = self._get_role_permissions(c, row["role_id"])
                self._send_json({"success": True, "user": self._user_dto(row, perms)})
                return

            # ------------------------------------------------------------------
            # ADMIN USER & RBAC MANAGEMENT ENDPOINTS
            # ------------------------------------------------------------------
            if path == "/api/admin/users/create_officer":
                auth = self._require_permission(c, "admin:create_officer")
                if not auth:
                    conn.commit()
                    return

                full_name = (data.get("fullName") or "").strip()
                email = (data.get("email") or "").strip().lower()
                raw_phone = (data.get("phone") or "").strip()
                password = data.get("password") or ""
                badge_id = (data.get("badgeId") or "").strip()
                station = (data.get("station") or "").strip()

                if len(full_name) < 2 or len(full_name) > 80:
                    self._send_json({"error": "Officer Name must be 2 to 80 characters."}, status=400)
                    return
                if not EMAIL_REGEX.match(email):
                    self._send_json({"error": "Invalid official email address."}, status=400)
                    return
                p_digits = phone_digits(raw_phone)
                if len(p_digits) < 10 or len(p_digits) > 15:
                    self._send_json({"error": "Phone Number must contain 10 to 15 digits."}, status=400)
                    return
                pw_err = validate_password_strength(password)
                if pw_err:
                    self._send_json({"error": pw_err}, status=400)
                    return

                if c.execute("SELECT id FROM users WHERE LOWER(email) = ?;", (email,)).fetchone():
                    self._send_json({"error": "Email already exists."}, status=409)
                    return
                if c.execute("SELECT id FROM users WHERE phone_digits = ?;", (p_digits,)).fetchone():
                    self._send_json({"error": "Phone number already exists."}, status=409)
                    return

                user_id = "USR-OFF-" + uuid.uuid4().hex[:10].upper()
                now_iso = utc_now_iso()
                c.execute(
                    """
                    INSERT INTO users (
                        id, name, full_name, email, phone, phone_digits, password_hash,
                        role, role_id, account_status, badge_id, station,
                        aadhaar_verified, face_verified, otp_verified, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, 'officer', 'ROLE_OFFICER', 'ACTIVE', ?, ?, 0, 0, 0, ?, ?);
                    """,
                    (
                        user_id,
                        full_name,
                        full_name,
                        email,
                        normalize_phone(raw_phone),
                        p_digits,
                        hash_password(password),
                        badge_id,
                        station,
                        now_iso,
                        now_iso,
                    ),
                )
                log_audit(c, auth["user"]["id"], "ADMIN_CREATE_OFFICER", user_id, f"Created officer {email}")
                conn.commit()

                row = c.execute(
                    "SELECT u.*, r.role_name FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = ?;",
                    (user_id,),
                ).fetchone()
                self._send_json(
                    {"success": True, "user": self._user_dto(row, self._get_role_permissions(c, "ROLE_OFFICER"))},
                    status=201,
                )
                return

            if path == "/api/admin/users/assign_role":
                auth = self._require_permission(c, "admin:assign_role")
                if not auth:
                    conn.commit()
                    return

                target_user_id = (data.get("userId") or "").strip()
                requested_role = (data.get("roleId") or data.get("role") or "").strip()
                role_row = c.execute(
                    "SELECT id, role_name FROM roles WHERE id = ? OR LOWER(role_name) = ?;",
                    (requested_role, requested_role.lower()),
                ).fetchone()
                if not role_row:
                    self._send_json({"error": "Invalid target role."}, status=400)
                    return

                target = c.execute("SELECT id, role_id FROM users WHERE id = ?;", (target_user_id,)).fetchone()
                if not target:
                    self._send_json({"error": "User not found."}, status=404)
                    return
                if target_user_id == auth["user"]["id"] and role_row["id"] != "ROLE_ADMIN":
                    self._send_json({"error": "Cannot remove your own admin privileges."}, status=400)
                    return

                c.execute(
                    "UPDATE users SET role_id = ?, role = ?, updated_at = ? WHERE id = ?;",
                    (role_row["id"], role_row["role_name"], utc_now_iso(), target_user_id),
                )
                log_audit(
                    c,
                    auth["user"]["id"],
                    "ADMIN_ASSIGN_ROLE",
                    target_user_id,
                    f"Assigned role {role_row['role_name']} ({role_row['id']})",
                )
                conn.commit()
                self._send_json({"success": True, "userId": target_user_id, "roleId": role_row["id"], "role": role_row["role_name"]})
                return

            if path == "/api/admin/users/update_status":
                auth = self._require_permission(c, "admin:users_write")
                if not auth:
                    conn.commit()
                    return

                target_user_id = (data.get("userId") or "").strip()
                new_status = (data.get("accountStatus") or "").strip().upper()
                if new_status not in ALLOWED_ACCOUNT_STATUSES:
                    self._send_json({"error": "accountStatus must be ACTIVE or SUSPENDED."}, status=400)
                    return

                target = c.execute("SELECT id FROM users WHERE id = ?;", (target_user_id,)).fetchone()
                if not target:
                    self._send_json({"error": "User not found."}, status=404)
                    return
                if target_user_id == auth["user"]["id"] and new_status != "ACTIVE":
                    self._send_json({"error": "Cannot suspend your own active admin account."}, status=400)
                    return

                c.execute(
                    "UPDATE users SET account_status = ?, updated_at = ? WHERE id = ?;",
                    (new_status, utc_now_iso(), target_user_id),
                )
                if new_status != "ACTIVE":
                    c.execute(
                        "UPDATE authentication_sessions SET revoked = 1 WHERE user_id = ?;",
                        (target_user_id,),
                    )
                log_audit(c, auth["user"]["id"], "ADMIN_UPDATE_STATUS", target_user_id, f"Status -> {new_status}")
                conn.commit()
                self._send_json({"success": True, "userId": target_user_id, "accountStatus": new_status})
                return

            # ------------------------------------------------------------------
            # PROTECTED DOMAIN WRITE ENDPOINTS
            # ------------------------------------------------------------------
            if path == "/api/sos_cases":
                auth = self._require_permission(c, "sos:create")
                if not auth:
                    conn.commit()
                    return
                case_id = data.get("id") or f"case-{uuid.uuid4().hex[:10]}"
                is_privileged = "sos:view_all" in auth["permissions"]
                u_name = (data.get("userName") if is_privileged else None) or auth["user"]["fullName"]
                u_email = (data.get("userEmail") if is_privileged else None) or auth["user"]["email"]
                u_phone = (data.get("userPhone") if is_privileged else None) or auth["user"]["phone"]
                c.execute(
                    """
                    INSERT INTO sos_cases (id, user_id, user_name, user_email, user_phone, age, blood_group, priority, status, gps, timestamp, device_type, evidence_count, location_name)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET
                        priority=excluded.priority, gps=excluded.gps,
                        device_type=excluded.device_type, location_name=excluded.location_name;
                    """,
                    (
                        case_id,
                        auth["user"]["id"],
                        u_name,
                        u_email,
                        u_phone,
                        data.get("age", 22),
                        data.get("bloodGroup", "O+"),
                        data.get("priority", "CRITICAL"),
                        "open",
                        data.get("gps", "23.0225, 72.5714"),
                        data.get("timestamp") or utc_now_iso(),
                        data.get("deviceType", "Mobile"),
                        data.get("evidenceCount", 1),
                        data.get("locationName", "Safe Zone"),
                    ),
                )
                for g_uid in self._connected_guardian_user_ids(c, auth["user"]["id"]):
                    self._insert_guardian_notification(
                        c,
                        g_uid,
                        None,
                        "EMERGENCY_SOS",
                        f"SOS ALERT triggered by {u_name} ({data.get('locationName', 'Live Zone')}) at {data.get('gps', 'GPS')}",
                    )
                conn.commit()
                self._send_json({"success": True, "id": case_id})
                return

            if path in ("/api/sos_cases/update_status", "/api/cases/update_status"):
                auth = self._require_permission(c, "sos:update_status")
                if not auth:
                    conn.commit()
                    return
                case_id = data.get("id") or data.get("caseId")
                status = (data.get("status") or "open").lower()
                c.execute("UPDATE sos_cases SET status = ? WHERE id = ?;", (status, case_id))
                log_audit(c, auth["user"]["id"], "SOS_STATUS_UPDATE", case_id, f"Status -> {status}")
                conn.commit()
                self._send_json({"success": True, "id": case_id, "status": status})
                return

            if path == "/api/cyber_complaints":
                auth = self._require_permission(c, "complaint:create")
                if not auth:
                    conn.commit()
                    return
                comp_id = data.get("id") or f"case-{uuid.uuid4().hex[:10]}"
                c.execute(
                    """
                    INSERT INTO cyber_complaints (id, user_id, user_email, category, description, threat_score, status, timestamp, user_name, user_phone, offender_link, evidence_count, attached_evidence)
                    VALUES (?, ?, ?, ?, ?, ?, 'SUBMITTED', ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET attached_evidence=excluded.attached_evidence;
                    """,
                    (
                        comp_id,
                        auth["user"]["id"],
                        auth["user"]["email"],
                        data.get("category", "CYBER THREAT"),
                        data.get("description", ""),
                        data.get("threatScore", "90%"),
                        data.get("timestamp") or utc_now_iso(),
                        auth["user"]["fullName"],
                        auth["user"]["phone"],
                        data.get("offenderLink", ""),
                        data.get("evidenceCount", 1),
                        data.get("attachedEvidence", ""),
                    ),
                )
                conn.commit()
                self._send_json({"success": True, "id": comp_id})
                return

            if path in ("/api/cyber_complaints/update_status", "/api/complaints/update_status"):
                auth = self._require_permission(c, "complaint:update_status")
                if not auth:
                    conn.commit()
                    return
                comp_id = data.get("id") or data.get("complaintId")
                status = (data.get("status") or "SUBMITTED").upper()
                c.execute("UPDATE cyber_complaints SET status = ? WHERE id = ?;", (status, comp_id))
                log_audit(c, auth["user"]["id"], "COMPLAINT_STATUS_UPDATE", comp_id, f"Status -> {status}")
                conn.commit()
                self._send_json({"success": True, "id": comp_id, "status": status})
                return

            if path == "/api/vault_assets":
                auth = self._require_permission(c, "vault:upload")
                if not auth:
                    conn.commit()
                    return
                asset_id = data.get("id") or f"EV-{uuid.uuid4().hex[:8]}"
                c.execute(
                    """
                    INSERT INTO vault_assets (id, owner_user_id, owner_email, name, file_type, hash_sha256, tamper_check, status, timestamp, size_mb, chain_of_custody)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET status=excluded.status;
                    """,
                    (
                        asset_id,
                        auth["user"]["id"],
                        auth["user"]["email"],
                        data.get("name", "Evidence.bin"),
                        data.get("fileType", "FILE"),
                        data.get("hash") or data.get("hash_sha256", "SHA256:..."),
                        data.get("tamperCheck", "PASS"),
                        data.get("status", "Uploaded"),
                        data.get("timestamp") or utc_now_iso(),
                        data.get("sizeMb", "1.0 MB"),
                        data.get("chainOfCustody", "Vault"),
                    ),
                )
                conn.commit()
                self._send_json({"success": True, "id": asset_id})
                return

            if path == "/api/guardians":
                auth = self._require_permission(c, "guardian:manage")
                if not auth:
                    conn.commit()
                    return
                g_id = data.get("id") or f"GDN-{uuid.uuid4().hex[:8]}"
                rel = (data.get("relationship") or data.get("relation") or "Guardian").strip()
                c.execute(
                    """
                    INSERT INTO guardians (id, owner_user_id, user_id, owner_email, ward_name, guardian_name, email, phone, relation, relationship, status, is_active, safety_score, risk_status, battery_level, device_state, location_text, gps)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET status=excluded.status, guardian_name=excluded.guardian_name, phone=excluded.phone, email=excluded.email, relation=excluded.relation, relationship=excluded.relationship;
                    """,
                    (
                        g_id,
                        auth["user"]["id"],
                        auth["user"]["id"],
                        auth["user"]["email"],
                        auth["user"]["fullName"],
                        (data.get("guardianName") or "Guardian").strip(),
                        (data.get("email") or "").strip().lower(),
                        (data.get("phone") or "").strip(),
                        rel,
                        rel,
                        data.get("status") or "ACTIVE",
                        data.get("safetyScore", "95%"),
                        data.get("riskStatus", "SAFE"),
                        data.get("batteryLevel", "90%"),
                        data.get("deviceState", "Active"),
                        data.get("locationText", "Safe"),
                        data.get("gps", ""),
                    ),
                )
                conn.commit()
                self._send_json({"success": True, "id": g_id})
                return

            if path == "/api/journeys/start":
                auth = self._require_permission(c, "travel:own")
                if not auth:
                    conn.commit()
                    return

                dest_name = (data.get("destinationName") or "").strip()
                d_lat = parse_coord(data.get("destinationLatitude"), -90.0, 90.0)
                d_lng = parse_coord(data.get("destinationLongitude"), -180.0, 180.0)
                s_lat = parse_coord(data.get("startLatitude"), -90.0, 90.0)
                s_lng = parse_coord(data.get("startLongitude"), -180.0, 180.0)
                start_name = (data.get("startLocationName") or "Current GPS Location").strip()
                rec_mode = (data.get("recordingMode") or "None").strip()
                route_summary = (data.get("routeSummary") or "").strip()

                try:
                    est_mins = int(data.get("estimatedDuration") or 0)
                except (TypeError, ValueError):
                    est_mins = 0

                if len(dest_name) < 2 or d_lat is None or d_lng is None:
                    self._send_json({"error": "Select a real searchable destination with valid coordinates."}, status=400)
                    return
                if s_lat is None or s_lng is None:
                    self._send_json({"error": "Valid starting GPS or selected origin coordinates are required."}, status=400)
                    return
                if est_mins < 1 or est_mins > 1440:
                    self._send_json({"error": "Estimated travel duration must be between 1 and 1440 minutes."}, status=400)
                    return
                if rec_mode not in ("None", "Audio Only", "Video & Audio"):
                    rec_mode = "None"

                raw_poly = data.get("routePolyline") or []
                valid_poly = []
                if isinstance(raw_poly, list):
                    for pt in raw_poly:
                        if isinstance(pt, (list, tuple)) and len(pt) >= 2:
                            plat = parse_coord(pt[0], -90.0, 90.0)
                            plng = parse_coord(pt[1], -180.0, 180.0)
                            if plat is not None and plng is not None:
                                valid_poly.append([plat, plng])
                if len(valid_poly) < 2:
                    self._send_json({"error": "Calculate and select a valid route before starting the journey."}, status=400)
                    return

                try:
                    dist_m = float(data.get("distanceMeters") or haversine_meters(s_lat, s_lng, d_lat, d_lng))
                except (TypeError, ValueError):
                    dist_m = haversine_meters(s_lat, s_lng, d_lat, d_lng)

                existing = c.execute(
                    """
                    SELECT * FROM travel_journeys
                    WHERE user_id = ? AND status IN ('ACTIVE', 'OVERDUE', 'DEVIATION_WARNING', 'EMERGENCY')
                    ORDER BY created_at DESC LIMIT 1;
                    """,
                    (auth["user"]["id"],),
                ).fetchone()
                if existing:
                    if data.get("replaceExisting"):
                        c.execute(
                            "UPDATE travel_journeys SET status = 'INTERRUPTED', updated_at = ? WHERE id = ?;",
                            (utc_now_iso(), existing["id"]),
                        )
                        self._record_journey_event(
                            c, existing["id"], "JOURNEY_INTERRUPTED", "Superseded by a new journey session."
                        )
                    else:
                        self._send_json(
                            {
                                "error": "An active journey is already in progress. Complete or resume it first.",
                                "activeJourney": self._journey_dto(c, existing),
                            },
                            status=409,
                        )
                        return

                j_id = f"TRV-{uuid.uuid4().hex[:10]}"
                now_dt = utc_now()
                now_iso = now_dt.isoformat()
                eta_iso = (now_dt + timedelta(minutes=est_mins)).isoformat()
                acc = parse_coord(data.get("startAccuracy"), 0.0, 50000.0) or 0.0

                c.execute(
                    """
                    INSERT INTO travel_journeys (
                        id, user_id, start_location_name, start_latitude, start_longitude,
                        destination_name, destination_latitude, destination_longitude,
                        distance_meters, estimated_duration, recording_mode, route_polyline, route_summary,
                        status, deviation_meters, deviation_warning, last_latitude, last_longitude,
                        last_accuracy, last_gps_at, start_time, estimated_arrival_time, created_at, updated_at
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', 0.0, 0, ?, ?, ?, ?, ?, ?, ?, ?);
                    """,
                    (
                        j_id,
                        auth["user"]["id"],
                        start_name,
                        s_lat,
                        s_lng,
                        dest_name,
                        d_lat,
                        d_lng,
                        round(dist_m, 1),
                        est_mins,
                        rec_mode,
                        json.dumps(valid_poly),
                        route_summary,
                        s_lat,
                        s_lng,
                        acc,
                        now_iso,
                        now_iso,
                        eta_iso,
                        now_iso,
                        now_iso,
                    ),
                )
                c.execute(
                    """
                    INSERT INTO journey_locations (id, journey_id, latitude, longitude, accuracy, speed, heading, recorded_at)
                    VALUES (?, ?, ?, ?, ?, 0.0, 0.0, ?);
                    """,
                    (f"JLOC-{uuid.uuid4().hex[:10]}", j_id, s_lat, s_lng, acc, now_iso),
                )
                self._record_journey_event(
                    c,
                    j_id,
                    "JOURNEY_STARTED",
                    f"Safe Arrival started from '{start_name}' to '{dest_name}' ({est_mins} min, Mode: {rec_mode}).",
                    s_lat,
                    s_lng,
                )
                log_audit(c, auth["user"]["id"], "JOURNEY_STARTED", j_id, f"Destination: {dest_name}")
                conn.commit()
                created = c.execute("SELECT * FROM travel_journeys WHERE id = ?;", (j_id,)).fetchone()
                self._send_json({"success": True, "journey": self._journey_dto(c, created)}, status=201)
                return

            if path == "/api/journeys/location":
                auth = self._require_permission(c, "travel:own")
                if not auth:
                    conn.commit()
                    return
                j_row = self._fetch_journey_owned(c, (data.get("journeyId") or "").strip(), auth["user"])
                if not j_row:
                    return
                if j_row["status"] in ("COMPLETED", "INTERRUPTED"):
                    self._send_json({"error": "Cannot record location on a finished journey."}, status=409)
                    return

                raw_points = data.get("points")
                if not isinstance(raw_points, list):
                    raw_points = [data]

                valid_pts = []
                for p in raw_points[:100]:
                    if not isinstance(p, dict):
                        continue
                    plat = parse_coord(p.get("latitude"), -90.0, 90.0)
                    plng = parse_coord(p.get("longitude"), -180.0, 180.0)
                    if plat is None or plng is None:
                        continue
                    acc = parse_coord(p.get("accuracy"), 0.0, 50000.0) or 0.0
                    spd = parse_coord(p.get("speed"), 0.0, 200.0) or 0.0
                    hdg = parse_coord(p.get("heading"), 0.0, 360.0) or 0.0
                    rec_at = (p.get("recordedAt") or utc_now_iso()).strip()
                    valid_pts.append((plat, plng, acc, spd, hdg, rec_at))

                if not valid_pts:
                    self._send_json({"error": "No valid GPS coordinates provided."}, status=400)
                    return

                inserted = 0
                for plat, plng, acc, spd, hdg, rec_at in valid_pts:
                    dup = c.execute(
                        "SELECT 1 FROM journey_locations WHERE journey_id = ? AND recorded_at = ? AND ABS(latitude - ?) < 1e-7 AND ABS(longitude - ?) < 1e-7;",
                        (j_row["id"], rec_at, plat, plng),
                    ).fetchone()
                    if dup:
                        continue
                    c.execute(
                        """
                        INSERT INTO journey_locations (id, journey_id, latitude, longitude, accuracy, speed, heading, recorded_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
                        """,
                        (f"JLOC-{uuid.uuid4().hex[:10]}", j_row["id"], plat, plng, acc, spd, hdg, rec_at),
                    )
                    inserted += 1

                last_lat, last_lng, last_acc, _, _, last_rec = valid_pts[-1]
                try:
                    poly = json.loads(j_row["route_polyline"] or "[]")
                except Exception:
                    poly = []

                dev_m = point_to_polyline_meters(last_lat, last_lng, poly) if len(poly) >= 2 else 0.0
                dev_warning = 1 if dev_m > ROUTE_DEVIATION_THRESHOLD_METERS else 0
                now_iso = utc_now_iso()

                c.execute(
                    """
                    UPDATE travel_journeys
                    SET last_latitude = ?, last_longitude = ?, last_accuracy = ?, last_gps_at = ?,
                        deviation_meters = ?, deviation_warning = ?, updated_at = ?
                    WHERE id = ?;
                    """,
                    (last_lat, last_lng, last_acc, last_rec, round(dev_m, 1), dev_warning, now_iso, j_row["id"]),
                )

                if dev_warning and not j_row["deviation_warning"]:
                    self._record_journey_event(
                        c,
                        j_row["id"],
                        "ROUTE_DEVIATION_WARNING",
                        f"User moved {round(dev_m)}m off the planned safe route corridor.",
                        last_lat,
                        last_lng,
                    )

                conn.commit()
                updated = c.execute("SELECT * FROM travel_journeys WHERE id = ?;", (j_row["id"],)).fetchone()
                self._send_json({"success": True, "syncedCount": inserted, "journey": self._journey_dto(c, updated)})
                return

            if path == "/api/journeys/share":
                auth = self._require_permission(c, "travel:own")
                if not auth:
                    conn.commit()
                    return
                j_row = self._fetch_journey_owned(c, (data.get("journeyId") or "").strip(), auth["user"])
                if not j_row:
                    return
                if j_row["status"] == "COMPLETED":
                    self._send_json({"error": "Cannot create a live tracking share for a completed journey."}, status=409)
                    return

                guardian_ids = data.get("guardianIds") if isinstance(data.get("guardianIds"), list) else []
                recipients = []
                if guardian_ids:
                    user_guardians = {g["id"]: g for g in self._user_guardians_list(c, auth["user"])}
                    for gid in guardian_ids:
                        if str(gid) in user_guardians:
                            recipients.append(user_guardians[str(gid)])

                inline_name = (data.get("guardianName") or "").strip()
                inline_phone = (data.get("guardianPhone") or "").strip()
                inline_email = (data.get("guardianEmail") or "").strip().lower()
                inline_rel = (data.get("relationship") or "Guardian").strip()
                if inline_name and (inline_phone or inline_email):
                    new_gid = f"GDN-{uuid.uuid4().hex[:8]}"
                    if data.get("saveGuardian", True):
                        c.execute(
                            """
                            INSERT INTO guardians (id, owner_user_id, user_id, owner_email, ward_name, guardian_name, email, phone, relation, relationship, status, is_active, safety_score, risk_status)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', 1, '100%', 'SAFE');
                            """,
                            (
                                new_gid,
                                auth["user"]["id"],
                                auth["user"]["id"],
                                auth["user"]["email"],
                                auth["user"]["fullName"],
                                inline_name,
                                inline_email,
                                inline_phone,
                                inline_rel,
                                inline_rel,
                            ),
                        )
                    recipients.append(
                        {
                            "id": new_gid if data.get("saveGuardian", True) else None,
                            "guardianName": inline_name,
                            "phone": inline_phone,
                            "email": inline_email,
                            "relationship": inline_rel,
                        }
                    )

                if not recipients:
                    self._send_json({"error": "Select at least one guardian or provide guardian contact details."}, status=400)
                    return

                try:
                    exp_mins = int(data.get("expiresInMinutes") or max(120, int(j_row["estimated_duration"] or 60) + 120))
                except (TypeError, ValueError):
                    exp_mins = 240
                exp_mins = max(15, min(1440, exp_mins))

                raw_share_token = secrets.token_urlsafe(32)
                t_hash = hash_token(raw_share_token)
                share_id = f"SHR-{uuid.uuid4().hex[:10]}"
                now_dt = utc_now()
                exp_iso = (now_dt + timedelta(minutes=exp_mins)).isoformat()
                share_path = f"#/track/{raw_share_token}"

                names_joined = ", ".join(r.get("guardianName") or "Guardian" for r in recipients)
                phones_joined = ", ".join(r.get("phone") for r in recipients if r.get("phone"))
                emails_joined = ", ".join(r.get("email") for r in recipients if r.get("email"))
                first_rec = recipients[0]
                first_gid_raw = first_rec.get("id")
                first_gid_fk = (
                    first_gid_raw
                    if (first_gid_raw and c.execute("SELECT 1 FROM guardians WHERE id = ?;", (first_gid_raw,)).fetchone())
                    else None
                )
                first_g_uid = first_rec.get("guardianUserId")
                if not first_g_uid:
                    found_acc = self._find_guardian_account(c, first_rec.get("email") or "", first_rec.get("phone") or "")
                    if found_acc:
                        first_g_uid = found_acc["id"]

                delivery = deliver_guardian_notifications(
                    recipients,
                    subject=f"SHE SHIELD Live Safe Arrival Tracking from {auth['user']['fullName']}",
                    body_text=(
                        f"{auth['user']['fullName']} shared a live Safe Arrival journey to "
                        f"{j_row['destination_name']}.\nTrack live route and ETA: {share_path}\n"
                        f"Link expires at {exp_iso}."
                    ),
                )

                c.execute(
                    """
                    INSERT INTO journey_sharing (
                        id, journey_id, guardian_id, guardian_user_id, guardian_name, guardian_phone, guardian_email,
                        sharing_token_hash, sharing_status, delivery_status, delivery_message, created_at, expires_at
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', ?, ?, ?, ?);
                    """,
                    (
                        share_id,
                        j_row["id"],
                        first_gid_fk,
                        first_g_uid,
                        names_joined,
                        phones_joined,
                        emails_joined,
                        t_hash,
                        delivery["deliveryStatus"],
                        delivery["deliveryMessage"],
                        now_dt.isoformat(),
                        exp_iso,
                    ),
                )

                # Notify primary & any additional connected Guardian accounts + ensure individual dashboard visibility
                notified_uids = set()
                for idx, rec in enumerate(recipients):
                    r_uid = rec.get("guardianUserId")
                    if not r_uid:
                        found_acc = self._find_guardian_account(c, rec.get("email") or "", rec.get("phone") or "")
                        if found_acc:
                            r_uid = found_acc["id"]
                    if idx > 0 and r_uid:
                        extra_tok = secrets.token_urlsafe(32)
                        c.execute(
                            """
                            INSERT INTO journey_sharing (
                                id, journey_id, guardian_id, guardian_user_id, guardian_name, guardian_phone, guardian_email,
                                sharing_token_hash, sharing_status, delivery_status, delivery_message, created_at, expires_at
                            )
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', ?, ?, ?, ?);
                            """,
                            (
                                f"SHR-{uuid.uuid4().hex[:10]}",
                                j_row["id"],
                                None,
                                r_uid,
                                rec.get("guardianName") or "Guardian",
                                rec.get("phone") or "",
                                rec.get("email") or "",
                                hash_token(extra_tok),
                                delivery["deliveryStatus"],
                                delivery["deliveryMessage"],
                                now_dt.isoformat(),
                                exp_iso,
                            ),
                        )
                    if r_uid and r_uid not in notified_uids:
                        notified_uids.add(r_uid)
                        self._insert_guardian_notification(
                            c,
                            r_uid,
                            j_row["id"],
                            "JOURNEY_SHARED",
                            f"{auth['user']['fullName']} shared a live Safe Arrival journey to {j_row['destination_name']}.",
                            delivery_status=delivery["deliveryStatus"],
                        )

                self._record_journey_event(
                    c,
                    j_row["id"],
                    "GUARDIAN_SHARED",
                    f"Shared live tracking token with {names_joined} (delivery: {delivery['deliveryStatus']}).",
                    j_row["last_latitude"],
                    j_row["last_longitude"],
                )
                log_audit(c, auth["user"]["id"], "JOURNEY_SHARED", j_row["id"], f"Share {share_id} -> {names_joined}")
                conn.commit()
                self._send_json(
                    {
                        "success": True,
                        "shareId": share_id,
                        "sharingToken": raw_share_token,
                        "sharePath": share_path,
                        "expiresAt": exp_iso,
                        "recipients": recipients,
                        **delivery,
                    },
                    status=201,
                )
                return

            m_rev = re.fullmatch(r"/api/journeys/shares?/([A-Za-z0-9_-]+)/revoke", path)
            if m_rev:
                auth = self._require_permission(c, "travel:own")
                if not auth:
                    conn.commit()
                    return
                share_id = m_rev.group(1)
                row = c.execute(
                    """
                    SELECT s.id, s.journey_id, j.user_id
                    FROM journey_sharing s
                    JOIN travel_journeys j ON j.id = s.journey_id
                    WHERE s.id = ?;
                    """,
                    (share_id,),
                ).fetchone()
                if not row:
                    self._send_json({"error": "Share link not found."}, status=404)
                    return
                if row["user_id"] != auth["user"]["id"]:
                    self._send_json({"error": "Forbidden: you cannot revoke this share link."}, status=403)
                    return
                now_iso = utc_now_iso()
                c.execute("UPDATE journey_sharing SET revoked_at = ?, sharing_status = 'REVOKED' WHERE id = ?;", (now_iso, share_id))
                self._record_journey_event(c, row["journey_id"], "SHARE_REVOKED", f"Revoked live share {share_id}.")
                log_audit(c, auth["user"]["id"], "JOURNEY_SHARE_REVOKED", share_id, f"Journey {row['journey_id']}")
                conn.commit()
                self._send_json({"success": True, "revokedId": share_id, "revokedAt": now_iso})
                return

            if path == "/api/journeys/extend-eta":
                auth = self._require_permission(c, "travel:own")
                if not auth:
                    conn.commit()
                    return
                j_row = self._fetch_journey_owned(c, (data.get("journeyId") or "").strip(), auth["user"])
                if not j_row:
                    return
                if j_row["status"] in ("COMPLETED", "INTERRUPTED"):
                    self._send_json({"error": "Cannot extend ETA on a completed journey."}, status=409)
                    return
                try:
                    add_mins = int(data.get("additionalMinutes") or 15)
                except (TypeError, ValueError):
                    add_mins = 15
                if add_mins < 5 or add_mins > 240:
                    self._send_json({"error": "additionalMinutes must be between 5 and 240."}, status=400)
                    return
                now_dt = utc_now()
                cur_eta = parse_iso_dt(j_row["estimated_arrival_time"]) or now_dt
                base_dt = max(now_dt, cur_eta)
                new_eta_iso = (base_dt + timedelta(minutes=add_mins)).isoformat()
                new_dur = int(j_row["estimated_duration"] or 0) + add_mins
                next_status = "ACTIVE" if j_row["status"] == "OVERDUE" else j_row["status"]
                c.execute(
                    """
                    UPDATE travel_journeys
                    SET estimated_arrival_time = ?, estimated_duration = ?,
                        eta_extended_count = COALESCE(eta_extended_count, 0) + 1,
                        status = ?, updated_at = ?
                    WHERE id = ?;
                    """,
                    (new_eta_iso, new_dur, next_status, now_dt.isoformat(), j_row["id"]),
                )
                self._record_journey_event(
                    c,
                    j_row["id"],
                    "ETA_EXTENDED",
                    f"Traveler extended ETA by +{add_mins} min (new ETA: {new_eta_iso}).",
                    j_row["last_latitude"],
                    j_row["last_longitude"],
                )
                conn.commit()
                updated = c.execute("SELECT * FROM travel_journeys WHERE id = ?;", (j_row["id"],)).fetchone()
                self._send_json({"success": True, "journey": self._journey_dto(c, updated)})
                return

            if path == "/api/journeys/complete":
                auth = self._require_permission(c, "travel:own")
                if not auth:
                    conn.commit()
                    return
                j_row = self._fetch_journey_owned(c, (data.get("journeyId") or "").strip(), auth["user"])
                if not j_row:
                    return
                if j_row["status"] == "COMPLETED":
                    self._send_json({"success": True, "journey": self._journey_dto(c, j_row)})
                    return

                fin_lat = parse_coord(data.get("latitude"), -90.0, 90.0)
                fin_lng = parse_coord(data.get("longitude"), -180.0, 180.0)
                fin_acc = parse_coord(data.get("accuracy"), 0.0, 50000.0) or 0.0
                now_iso = utc_now_iso()

                if fin_lat is not None and fin_lng is not None:
                    c.execute(
                        """
                        INSERT INTO journey_locations (id, journey_id, latitude, longitude, accuracy, speed, heading, recorded_at)
                        VALUES (?, ?, ?, ?, ?, 0.0, 0.0, ?);
                        """,
                        (f"JLOC-{uuid.uuid4().hex[:10]}", j_row["id"], fin_lat, fin_lng, fin_acc, now_iso),
                    )
                else:
                    fin_lat = j_row["last_latitude"]
                    fin_lng = j_row["last_longitude"]

                arr_dist = (
                    round(haversine_meters(fin_lat, fin_lng, j_row["destination_latitude"], j_row["destination_longitude"]), 1)
                    if (fin_lat is not None and fin_lng is not None)
                    else None
                )
                verified = 1 if (arr_dist is not None and arr_dist <= ARRIVAL_VERIFICATION_RADIUS_METERS) else 0

                c.execute(
                    """
                    UPDATE travel_journeys
                    SET status = 'COMPLETED', actual_arrival_time = ?,
                        arrival_verified = ?, arrival_distance_meters = ?,
                        last_latitude = COALESCE(?, last_latitude),
                        last_longitude = COALESCE(?, last_longitude),
                        last_gps_at = CASE WHEN ? IS NOT NULL THEN ? ELSE last_gps_at END,
                        updated_at = ?
                    WHERE id = ?;
                    """,
                    (now_iso, verified, arr_dist, fin_lat, fin_lng, fin_lat, now_iso, now_iso, j_row["id"]),
                )
                ver_label = (
                    f"GPS-verified ({arr_dist}m from destination)"
                    if verified
                    else (f"Manual confirmation ({arr_dist}m from destination)" if arr_dist is not None else "Manual confirmation (GPS unavailable)")
                )
                self._record_journey_event(
                    c, j_row["id"], "JOURNEY_COMPLETED", f"Safe Arrival confirmed: {ver_label}.", fin_lat, fin_lng
                )
                log_audit(c, auth["user"]["id"], "JOURNEY_COMPLETED", j_row["id"], ver_label)

                active_shares = c.execute(
                    "SELECT guardian_user_id, guardian_name, guardian_phone, guardian_email FROM journey_sharing WHERE journey_id = ? AND revoked_at IS NULL;",
                    (j_row["id"],),
                ).fetchall()
                share_recipients = [
                    {
                        "guardianName": r["guardian_name"] or "Guardian",
                        "phone": r["guardian_phone"] or "",
                        "email": r["guardian_email"] or "",
                    }
                    for r in active_shares
                ]
                guardian_notif = (
                    deliver_guardian_notifications(
                        share_recipients,
                        subject=f"SHE SHIELD Safe Arrival Confirmed: {auth['user']['fullName']}",
                        body_text=f"{auth['user']['fullName']} reached {j_row['destination_name']} safely ({ver_label}).",
                    )
                    if share_recipients
                    else {"deliveryConfigured": False, "deliveryStatus": "NO_ACTIVE_SHARES", "deliveryMessage": "No shared guardians attached to this journey.", "results": []}
                )
                target_g_uids = set(self._connected_guardian_user_ids(c, auth["user"]["id"]))
                for r in active_shares:
                    if r["guardian_user_id"]:
                        target_g_uids.add(r["guardian_user_id"])
                for g_uid in target_g_uids:
                    self._insert_guardian_notification(
                        c,
                        g_uid,
                        j_row["id"],
                        "SAFE_ARRIVAL",
                        f"{auth['user']['fullName']} reached {j_row['destination_name']} safely ({ver_label}).",
                        delivery_status=guardian_notif.get("deliveryStatus", "IN_APP"),
                    )
                conn.commit()
                completed = c.execute("SELECT * FROM travel_journeys WHERE id = ?;", (j_row["id"],)).fetchone()
                self._send_json(
                    {
                        "success": True,
                        "arrivalVerified": bool(verified),
                        "arrivalDistanceMeters": arr_dist,
                        "guardianNotification": guardian_notif,
                        "journey": self._journey_dto(c, completed),
                    }
                )
                return

            if path == "/api/journeys/sos":
                auth = self._require_permission(c, "travel:own")
                if not auth:
                    conn.commit()
                    return
                j_row = self._fetch_journey_owned(c, (data.get("journeyId") or "").strip(), auth["user"])
                if not j_row:
                    return

                sos_lat = parse_coord(data.get("latitude"), -90.0, 90.0)
                sos_lng = parse_coord(data.get("longitude"), -180.0, 180.0)
                if sos_lat is None or sos_lng is None:
                    sos_lat = j_row["last_latitude"]
                    sos_lng = j_row["last_longitude"]

                now_iso = utc_now_iso()
                sos_id = f"SOS-TRV-{uuid.uuid4().hex[:8]}"
                gps_str = f"{sos_lat:.6f}, {sos_lng:.6f}" if (sos_lat is not None and sos_lng is not None) else "GPS Unavailable"
                loc_label = f"Travel SOS -> {j_row['destination_name']}"

                c.execute(
                    """
                    INSERT INTO sos_cases (id, user_id, user_name, user_email, user_phone, priority, status, gps, timestamp, device_type, evidence_count, location_name)
                    VALUES (?, ?, ?, ?, ?, 'CRITICAL', 'OPEN', ?, ?, ?, 1, ?);
                    """,
                    (
                        sos_id,
                        auth["user"]["id"],
                        auth["user"]["fullName"],
                        auth["user"]["email"],
                        auth["user"]["phone"],
                        gps_str,
                        now_iso,
                        "Safe Arrival Travel SOS",
                        loc_label,
                    ),
                )
                c.execute(
                    """
                    UPDATE travel_journeys
                    SET status = 'EMERGENCY', sos_event_id = ?, updated_at = ?
                    WHERE id = ?;
                    """,
                    (sos_id, now_iso, j_row["id"]),
                )
                self._record_journey_event(
                    c,
                    j_row["id"],
                    "SOS_TRIGGERED",
                    f"Emergency SOS triggered ({sos_id}) at {gps_str}.",
                    sos_lat,
                    sos_lng,
                )
                log_audit(c, auth["user"]["id"], "JOURNEY_SOS_TRIGGERED", sos_id, loc_label)

                guardians = self._user_guardians_list(c, auth["user"])
                notif = deliver_guardian_notifications(
                    guardians,
                    subject=f"EMERGENCY SOS from {auth['user']['fullName']} - Safe Arrival Mode",
                    body_text=(
                        f"URGENT EMERGENCY SOS!\nTraveler: {auth['user']['fullName']}\n"
                        f"Destination: {j_row['destination_name']}\n"
                        f"Last Coordinates: {gps_str}\nTime: {now_iso}"
                    ),
                )
                sos_target_g_uids = set(self._connected_guardian_user_ids(c, auth["user"]["id"]))
                sh_rows = c.execute(
                    "SELECT guardian_user_id FROM journey_sharing WHERE journey_id = ? AND revoked_at IS NULL;",
                    (j_row["id"],),
                ).fetchall()
                for sr in sh_rows:
                    if sr["guardian_user_id"]:
                        sos_target_g_uids.add(sr["guardian_user_id"])
                for g_uid in sos_target_g_uids:
                    self._insert_guardian_notification(
                        c,
                        g_uid,
                        j_row["id"],
                        "EMERGENCY_SOS",
                        f"EMERGENCY SOS from {auth['user']['fullName']} during trip to {j_row['destination_name']} at {gps_str}!",
                        delivery_status=notif.get("deliveryStatus", "IN_APP"),
                    )
                conn.commit()
                updated = c.execute("SELECT * FROM travel_journeys WHERE id = ?;", (j_row["id"],)).fetchone()
                self._send_json(
                    {
                        "success": True,
                        "sosCaseId": sos_id,
                        "gps": gps_str,
                        "guardianContacts": guardians,
                        "guardianNotification": notif,
                        "journey": self._journey_dto(c, updated),
                    },
                    status=201,
                )
                return

            if path == "/api/guardians/request":
                auth = self._require_permission(c, "guardian:manage")
                if not auth:
                    conn.commit()
                    return
                if auth["user"]["role"] == "guardian":
                    self._send_json({"error": "Only users protecting their profile can invite guardians."}, status=403)
                    return
                g_email = (data.get("email") or "").strip().lower()
                g_phone = (data.get("phone") or "").strip()
                g_name = (data.get("guardianName") or "").strip()
                rel = (data.get("relationship") or data.get("relation") or "Guardian").strip()

                if not g_email and len(phone_digits(g_phone)) < 10:
                    self._send_json({"error": "Enter a valid Guardian email address or 10+ digit phone number."}, status=400)
                    return
                if g_email and not EMAIL_REGEX.match(g_email):
                    self._send_json({"error": "Invalid Guardian email format."}, status=400)
                    return
                if g_email and g_email == auth["user"]["email"]:
                    self._send_json({"error": "You cannot add yourself as your own guardian."}, status=400)
                    return

                found_g = self._find_guardian_account(c, g_email, g_phone)
                now_dt = utc_now()
                now_iso = now_dt.isoformat()

                if found_g:
                    if found_g["id"] == auth["user"]["id"]:
                        self._send_json({"error": "Cannot connect your own account as guardian."}, status=400)
                        return
                    existing_conn = c.execute(
                        "SELECT id, connection_status FROM guardian_connections WHERE user_id = ? AND guardian_id = ?;",
                        (auth["user"]["id"], found_g["id"]),
                    ).fetchone()
                    if existing_conn and existing_conn["connection_status"] == "ACCEPTED":
                        self._send_json(
                            {
                                "success": True,
                                "matchedGuardian": True,
                                "alreadyConnected": True,
                                "connectionId": existing_conn["id"],
                                "status": "ACCEPTED",
                                "guardianName": found_g["full_name"],
                                "message": f"{found_g['full_name']} is already an accepted Guardian on your safety network.",
                            }
                        )
                        return
                    if existing_conn:
                        conn_id = existing_conn["id"]
                        c.execute(
                            """
                            UPDATE guardian_connections
                            SET connection_status = 'PENDING', relationship = ?, created_at = ?, accepted_at = NULL, revoked_at = NULL
                            WHERE id = ?;
                            """,
                            (rel, now_iso, conn_id),
                        )
                    else:
                        conn_id = f"GCN-{uuid.uuid4().hex[:10]}"
                        c.execute(
                            """
                            INSERT INTO guardian_connections (id, user_id, guardian_id, relationship, connection_status, permissions, created_at)
                            VALUES (?, ?, ?, ?, 'PENDING', 'live_journey,sos_alerts', ?);
                            """,
                            (conn_id, auth["user"]["id"], found_g["id"], rel, now_iso),
                        )

                    # Keep legacy guardians contact row synced cleanly without creating duplicates
                    existing_legacy = c.execute(
                        "SELECT id FROM guardians WHERE owner_user_id = ? AND guardian_user_id = ?;",
                        (auth["user"]["id"], found_g["id"]),
                    ).fetchone()
                    if existing_legacy:
                        c.execute(
                            "UPDATE guardians SET status = 'PENDING', is_active = 1, relationship = ?, relation = ? WHERE id = ?;",
                            (rel, rel, existing_legacy["id"]),
                        )
                    else:
                        c.execute(
                            """
                            INSERT INTO guardians (id, owner_user_id, user_id, guardian_user_id, owner_email, ward_name, guardian_name, email, phone, relation, relationship, status, is_active, safety_score, risk_status)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING', 1, '100%', 'SAFE');
                            """,
                            (
                                f"GDN-{uuid.uuid4().hex[:8]}",
                                auth["user"]["id"],
                                auth["user"]["id"],
                                found_g["id"],
                                auth["user"]["email"],
                                auth["user"]["fullName"],
                                found_g["full_name"],
                                found_g["email"],
                                found_g["phone"],
                                rel,
                                rel,
                            ),
                        )

                    self._insert_guardian_notification(
                        c,
                        found_g["id"],
                        None,
                        "CONNECTION_REQUEST",
                        f"{auth['user']['fullName']} wants to add you as a trusted Guardian ({rel}).",
                    )
                    log_audit(c, auth["user"]["id"], "GUARDIAN_CONNECTION_REQUESTED", conn_id, f"Target Guardian {found_g['id']}")
                    conn.commit()
                    self._send_json(
                        {
                            "success": True,
                            "matchedGuardian": True,
                            "connectionId": conn_id,
                            "status": "PENDING",
                            "guardianName": found_g["full_name"],
                            "message": f"Connection request sent to Guardian {found_g['full_name']}. Awaiting their approval.",
                        },
                        status=201,
                    )
                    return

                # No registered guardian found -> create/refresh deduplicated guardian_invitations row
                p_dig = phone_digits(g_phone)
                existing_inv = c.execute(
                    """
                    SELECT * FROM guardian_invitations
                    WHERE sender_user_id = ? AND status = 'PENDING'
                      AND (
                          (? != '' AND LOWER(COALESCE(guardian_email, '')) = ?)
                          OR (? != '' AND guardian_phone = ?)
                      )
                    LIMIT 1;
                    """,
                    (auth["user"]["id"], g_email, g_email, g_phone, g_phone),
                ).fetchone()

                raw_inv_tok = secrets.token_urlsafe(24)
                inv_hash = hash_token(raw_inv_tok)
                exp_iso = (now_dt + timedelta(days=7)).isoformat()
                inv_path = f"#/register_user?invite={raw_inv_tok}"

                if existing_inv:
                    inv_id = existing_inv["id"]
                    c.execute(
                        """
                        UPDATE guardian_invitations
                        SET guardian_name = ?, relationship = ?, invitation_token_hash = ?, expires_at = ?
                        WHERE id = ?;
                        """,
                        (g_name or g_email or g_phone, rel, inv_hash, exp_iso, inv_id),
                    )
                else:
                    inv_id = f"GINV-{uuid.uuid4().hex[:10]}"
                    c.execute(
                        """
                        INSERT INTO guardian_invitations (id, sender_user_id, guardian_name, guardian_email, guardian_phone, relationship, invitation_token_hash, status, expires_at, created_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING', ?, ?);
                        """,
                        (inv_id, auth["user"]["id"], g_name or g_email or g_phone, g_email, g_phone, rel, inv_hash, exp_iso, now_iso),
                    )

                delivery = deliver_guardian_notifications(
                    [{"guardianName": g_name or "Guardian", "email": g_email, "phone": g_phone}],
                    subject=f"{auth['user']['fullName']} invited you to join SHE SHIELD as a Guardian",
                    body_text=(
                        f"{auth['user']['fullName']} wants to add you as their trusted Guardian ({rel}).\n"
                        f"Register your Guardian account here: {inv_path}"
                    ),
                )
                conn.commit()
                self._send_json(
                    {
                        "success": True,
                        "matchedGuardian": False,
                        "invitationId": inv_id,
                        "status": "PENDING",
                        "invitePath": inv_path,
                        "inviteToken": raw_inv_tok,
                        **delivery,
                        "message": "No existing Guardian account found for those details. Invitation created—share the registration link below.",
                    },
                    status=201,
                )
                return

            m_g_rev = re.fullmatch(r"/api/guardians/connections/([A-Za-z0-9_-]+)/revoke", path)
            if m_g_rev:
                auth = self._require_permission(c, "guardian:manage")
                if not auth:
                    conn.commit()
                    return
                conn_id = m_g_rev.group(1)
                row = c.execute("SELECT * FROM guardian_connections WHERE id = ?;", (conn_id,)).fetchone()
                if not row:
                    self._send_json({"error": "Guardian connection not found."}, status=404)
                    return
                if row["user_id"] != auth["user"]["id"]:
                    self._send_json({"error": "Forbidden: you cannot revoke another user's guardian connection."}, status=403)
                    return
                now_iso = utc_now_iso()
                c.execute(
                    "UPDATE guardian_connections SET connection_status = 'REVOKED', revoked_at = ? WHERE id = ?;",
                    (now_iso, conn_id),
                )
                c.execute(
                    "UPDATE guardians SET is_active = 0, status = 'REVOKED' WHERE owner_user_id = ? AND guardian_user_id = ?;",
                    (row["user_id"], row["guardian_id"]),
                )
                c.execute(
                    """
                    UPDATE journey_sharing
                    SET revoked_at = COALESCE(revoked_at, ?), sharing_status = 'REVOKED'
                    WHERE guardian_user_id = ?
                      AND journey_id IN (SELECT id FROM travel_journeys WHERE user_id = ?);
                    """,
                    (now_iso, row["guardian_id"], row["user_id"]),
                )
                self._insert_guardian_notification(
                    c,
                    row["guardian_id"],
                    None,
                    "ACCESS_REVOKED",
                    f"{auth['user']['fullName']} revoked your Guardian monitoring access.",
                )
                log_audit(c, auth["user"]["id"], "GUARDIAN_ACCESS_REVOKED", conn_id, f"Guardian {row['guardian_id']}")
                conn.commit()
                self._send_json({"success": True, "revokedConnectionId": conn_id})
                return

            m_resp = re.fullmatch(r"/api/guardian/invitations/([A-Za-z0-9_-]+)/respond", path)
            if m_resp:
                auth = self._require_permission(c, "dashboard:guardian")
                if not auth:
                    conn.commit()
                    return
                item_id = m_resp.group(1)
                action = (data.get("action") or "").strip().lower()
                invite_kind = (data.get("inviteKind") or "").strip().upper()
                if action not in ("accept", "decline"):
                    self._send_json({"error": "action must be 'accept' or 'decline'."}, status=400)
                    return

                now_iso = utc_now_iso()
                gid = auth["user"]["id"]
                g_email = auth["user"]["email"]
                g_phone_dig = phone_digits(auth["user"].get("phone") or "")

                if invite_kind == "CONNECTION_REQUEST" or item_id.startswith("GCN-"):
                    row = c.execute("SELECT * FROM guardian_connections WHERE id = ?;", (item_id,)).fetchone()
                    if not row:
                        self._send_json({"error": "Connection request not found."}, status=404)
                        return
                    if row["guardian_id"] != gid:
                        self._send_json({"error": "Forbidden: this connection request is not addressed to you."}, status=403)
                        return
                    new_st = "ACCEPTED" if action == "accept" else "DECLINED"
                    c.execute(
                        "UPDATE guardian_connections SET connection_status = ?, accepted_at = ?, revoked_at = NULL WHERE id = ?;",
                        (new_st, now_iso if action == "accept" else None, item_id),
                    )
                    c.execute(
                        "UPDATE guardians SET status = ?, is_active = ? WHERE owner_user_id = ? AND guardian_user_id = ?;",
                        ("ACTIVE" if action == "accept" else "DECLINED", 1 if action == "accept" else 0, row["user_id"], gid),
                    )
                    log_audit(c, gid, f"GUARDIAN_CONNECTION_{new_st}", item_id, f"User {row['user_id']}")
                    conn.commit()
                    self._send_json({"success": True, "id": item_id, "status": new_st})
                    return

                inv_row = c.execute("SELECT * FROM guardian_invitations WHERE id = ?;", (item_id,)).fetchone()
                if not inv_row:
                    self._send_json({"error": "Invitation not found."}, status=404)
                    return
                email_match = bool(g_email and (inv_row["guardian_email"] or "").strip().lower() == g_email)
                phone_match = bool(g_phone_dig and phone_digits(inv_row["guardian_phone"] or "") == g_phone_dig)
                if not (email_match or phone_match):
                    self._send_json({"error": "Forbidden: this invitation does not match your account."}, status=403)
                    return

                new_st = "ACCEPTED" if action == "accept" else "DECLINED"
                c.execute(
                    "UPDATE guardian_invitations SET status = ?, responded_at = ? WHERE id = ?;",
                    (new_st, now_iso, item_id),
                )
                if action == "accept":
                    c.execute(
                        """
                        INSERT INTO guardian_connections (id, user_id, guardian_id, relationship, connection_status, permissions, created_at, accepted_at)
                        VALUES (?, ?, ?, ?, 'ACCEPTED', 'live_journey,sos_alerts', ?, ?)
                        ON CONFLICT(user_id, guardian_id) DO UPDATE SET connection_status='ACCEPTED', accepted_at=excluded.accepted_at, revoked_at=NULL;
                        """,
                        (f"GCN-{uuid.uuid4().hex[:10]}", inv_row["sender_user_id"], gid, inv_row["relationship"] or "Guardian", now_iso, now_iso),
                    )
                log_audit(c, gid, f"GUARDIAN_INVITATION_{new_st}", item_id, f"Sender {inv_row['sender_user_id']}")
                conn.commit()
                self._send_json({"success": True, "id": item_id, "status": new_st})
                return

            if path == "/api/guardian/shares/claim":
                auth = self._require_permission(c, "dashboard:guardian")
                if not auth:
                    conn.commit()
                    return
                raw_tok = (data.get("token") or "").strip()
                if not raw_tok:
                    self._send_json({"error": "Share token is required."}, status=400)
                    return
                sh_row = c.execute(
                    "SELECT * FROM journey_sharing WHERE sharing_token_hash = ?;",
                    (hash_token(raw_tok),),
                ).fetchone()
                if not sh_row:
                    self._send_json({"error": "Share link not found."}, status=404)
                    return
                if sh_row["revoked_at"] is not None:
                    self._send_json({"error": "Share link has been revoked."}, status=403)
                    return
                exp_dt = parse_iso_dt(sh_row["expires_at"])
                if not exp_dt or exp_dt <= utc_now():
                    self._send_json({"error": "Share link has expired."}, status=410)
                    return
                now_iso = utc_now_iso()
                c.execute(
                    "UPDATE journey_sharing SET guardian_user_id = ?, guardian_name = ?, accepted_at = ? WHERE id = ?;",
                    (auth["user"]["id"], auth["user"]["fullName"], now_iso, sh_row["id"]),
                )
                conn.commit()
                self._send_json({"success": True, "journeyId": sh_row["journey_id"], "shareId": sh_row["id"]})
                return

            if path == "/api/guardian/notifications/mark-read":
                auth = self._require_permission(c, "dashboard:guardian")
                if not auth:
                    conn.commit()
                    return
                c.execute(
                    "UPDATE guardian_notifications SET read_at = COALESCE(read_at, ?) WHERE guardian_id = ?;",
                    (utc_now_iso(), auth["user"]["id"]),
                )
                conn.commit()
                self._send_json({"success": True})
                return

            self._send_json({"error": "Endpoint not found"}, status=404)

        except sqlite3.IntegrityError as ie:
            self._send_json({"error": f"Database constraint error: {ie}"}, status=409)
        except Exception as e:
            self._send_json({"error": str(e)}, status=500)
        finally:
            conn.close()


def get_lan_ips():
    ips = []
    try:
        import subprocess

        out = subprocess.check_output(["ifconfig"]).decode("utf-8", errors="ignore")
        for line in out.splitlines():
            line = line.strip()
            if line.startswith("inet ") and "127.0.0.1" not in line:
                parts = line.split()
                if len(parts) >= 2:
                    ip = parts[1]
                    if ip not in ips and not ip.startswith("169.254."):
                        ips.append(ip)
    except Exception:
        pass
    if not ips:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ips.append(s.getsockname()[0])
            s.close()
        except Exception:
            pass
    return ips


if __name__ == "__main__":
    init_db()
    server_address = ("0.0.0.0", PORT)
    httpd = ThreadedHTTPServer(server_address, SQLiteAPIHandler)

    lan_ips = get_lan_ips()
    print("=" * 65)
    print("  SHE SHIELD - Secure Local SQLite Auth & API Server Running!")
    print(f"  Database File: {DB_FILE}")
    print(f"  Listening on:  http://0.0.0.0:{PORT}")
    print(f"   • Local Web API:     http://localhost:{PORT}")
    print(f"   • Android Emulator:  http://10.0.2.2:{PORT}")
    for ip in lan_ips:
        print(f"   • Physical Devices:  http://{ip}:{PORT}")
    print("=" * 65)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[SQLite Server] Shutting down...")
        httpd.server_close()
