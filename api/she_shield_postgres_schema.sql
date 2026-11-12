-- ==============================================================================
-- SHE SHIELD - Cloud PostgreSQL Schema (Neon / Vercel Marketplace)
-- Production Database DDL for Safe Arrival & Full Security Platform
-- ==============================================================================

-- 1. Roles & Permissions (RBAC)
CREATE TABLE IF NOT EXISTS roles (
    id TEXT PRIMARY KEY,
    role_name TEXT UNIQUE NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS permissions (
    id TEXT PRIMARY KEY,
    permission_name TEXT UNIQUE NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id TEXT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- 2. Users Table
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
    face_match_score DOUBLE PRECISION DEFAULT 0.0,
    safety_index INTEGER DEFAULT 100,
    risk_trend TEXT DEFAULT 'STABLE',
    secret_phrase TEXT DEFAULT 'capcap',
    secret_word TEXT DEFAULT 'Box Box',
    badge_id TEXT,
    station TEXT,
    created_at TEXT,
    updated_at TEXT,
    voice_sos_language TEXT DEFAULT 'English',
    voice_sos_enabled INTEGER DEFAULT 0,
    voice_sos_max_duration INTEGER DEFAULT 120,
    silent_sos_mode INTEGER DEFAULT 0
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users(LOWER(email));
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_digits_unique ON users(phone_digits);

-- 3. Sessions & Audit Logs
CREATE TABLE IF NOT EXISTS authentication_sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT UNIQUE NOT NULL,
    expires_at TEXT NOT NULL,
    revoked INTEGER NOT NULL DEFAULT 0,
    user_agent TEXT,
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON authentication_sessions(user_id);

CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    actor_user_id TEXT,
    action TEXT NOT NULL,
    target_id TEXT,
    details TEXT,
    created_at TEXT NOT NULL
);

-- 4. Incident & Case Management
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
    gps TEXT,
    user_id TEXT,
    guardian_user_id TEXT,
    relationship TEXT,
    is_active INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS cab_trips (
    id TEXT PRIMARY KEY,
    plate_number TEXT NOT NULL,
    driver_name TEXT NOT NULL,
    provider TEXT NOT NULL,
    destination TEXT NOT NULL,
    origin TEXT NOT NULL,
    speed_kmh INTEGER DEFAULT 38,
    deviation_meters DOUBLE PRECISION DEFAULT 28.0,
    safety_score TEXT DEFAULT '98%',
    status TEXT DEFAULT 'ACTIVE',
    timestamp TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS audio_evidence (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sos_event_id TEXT REFERENCES sos_cases(id) ON DELETE SET NULL,
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
    integrity_status TEXT NOT NULL DEFAULT 'UNVERIFIED'
);

CREATE INDEX IF NOT EXISTS idx_audio_evidence_user ON audio_evidence(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audio_evidence_sos ON audio_evidence(sos_event_id);

-- 5. Safe Arrival Travel Journeys & Live GPS Tracking
CREATE TABLE IF NOT EXISTS travel_journeys (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_location_name TEXT,
    start_latitude DOUBLE PRECISION,
    start_longitude DOUBLE PRECISION,
    destination_name TEXT NOT NULL,
    destination_latitude DOUBLE PRECISION NOT NULL,
    destination_longitude DOUBLE PRECISION NOT NULL,
    distance_meters DOUBLE PRECISION DEFAULT 0.0,
    estimated_duration INTEGER NOT NULL,
    recording_mode TEXT NOT NULL DEFAULT 'None',
    route_polyline TEXT,
    route_summary TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    deviation_meters DOUBLE PRECISION DEFAULT 0.0,
    deviation_warning INTEGER DEFAULT 0,
    eta_extended_count INTEGER DEFAULT 0,
    arrival_verified INTEGER DEFAULT 0,
    arrival_distance_meters DOUBLE PRECISION,
    last_latitude DOUBLE PRECISION,
    last_longitude DOUBLE PRECISION,
    last_accuracy DOUBLE PRECISION,
    last_gps_at TEXT,
    start_time TEXT NOT NULL,
    estimated_arrival_time TEXT NOT NULL,
    actual_arrival_time TEXT,
    sos_event_id TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_travel_journeys_user ON travel_journeys(user_id, status, created_at DESC);

CREATE TABLE IF NOT EXISTS journey_locations (
    id TEXT PRIMARY KEY,
    journey_id TEXT NOT NULL REFERENCES travel_journeys(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION DEFAULT 0.0,
    speed DOUBLE PRECISION DEFAULT 0.0,
    heading DOUBLE PRECISION DEFAULT 0.0,
    recorded_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_journey_locations_jid ON journey_locations(journey_id, recorded_at ASC);

CREATE TABLE IF NOT EXISTS journey_sharing (
    id TEXT PRIMARY KEY,
    journey_id TEXT NOT NULL REFERENCES travel_journeys(id) ON DELETE CASCADE,
    guardian_id TEXT REFERENCES guardians(id) ON DELETE SET NULL,
    guardian_name TEXT,
    guardian_phone TEXT,
    guardian_email TEXT,
    sharing_token_hash TEXT UNIQUE NOT NULL,
    delivery_status TEXT NOT NULL DEFAULT 'NOT_CONFIGURED',
    delivery_message TEXT,
    created_at TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    revoked_at TEXT,
    guardian_user_id TEXT,
    sharing_status TEXT DEFAULT 'ACTIVE',
    accepted_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_journey_sharing_jid ON journey_sharing(journey_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_journey_sharing_tok ON journey_sharing(sharing_token_hash);
CREATE INDEX IF NOT EXISTS idx_journey_sharing_guser ON journey_sharing(guardian_user_id, sharing_status);

CREATE TABLE IF NOT EXISTS journey_events (
    id TEXT PRIMARY KEY,
    journey_id TEXT NOT NULL REFERENCES travel_journeys(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    details TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_journey_events_jid ON journey_events(journey_id, created_at DESC);

-- 6. Guardian Connections, Invitations & Notifications
CREATE TABLE IF NOT EXISTS guardian_connections (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    guardian_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    relationship TEXT NOT NULL DEFAULT 'Guardian',
    connection_status TEXT NOT NULL DEFAULT 'PENDING',
    permissions TEXT NOT NULL DEFAULT 'live_journey,sos_alerts',
    created_at TEXT NOT NULL,
    accepted_at TEXT,
    revoked_at TEXT,
    UNIQUE(user_id, guardian_id)
);

CREATE INDEX IF NOT EXISTS idx_gconn_guardian ON guardian_connections(guardian_id, connection_status);
CREATE INDEX IF NOT EXISTS idx_gconn_user ON guardian_connections(user_id, connection_status);

CREATE TABLE IF NOT EXISTS guardian_invitations (
    id TEXT PRIMARY KEY,
    sender_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    guardian_name TEXT,
    guardian_email TEXT,
    guardian_phone TEXT,
    relationship TEXT NOT NULL DEFAULT 'Guardian',
    invitation_token_hash TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING',
    expires_at TEXT NOT NULL,
    created_at TEXT NOT NULL,
    responded_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_ginv_sender ON guardian_invitations(sender_user_id, status);
CREATE INDEX IF NOT EXISTS idx_ginv_email ON guardian_invitations(LOWER(guardian_email), status);

CREATE TABLE IF NOT EXISTS guardian_notifications (
    id TEXT PRIMARY KEY,
    guardian_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    journey_id TEXT REFERENCES travel_journeys(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL,
    message TEXT NOT NULL,
    delivery_status TEXT NOT NULL DEFAULT 'IN_APP',
    created_at TEXT NOT NULL,
    read_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_gnotif_guardian ON guardian_notifications(guardian_id, created_at DESC);
