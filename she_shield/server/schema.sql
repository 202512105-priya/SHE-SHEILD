-- SHE SHIELD SQLite 3 Schema Snapshot
-- Initialized and migrated cleanly via server/local_sqlite_server.py:init_db()

CREATE TABLE audio_evidence (
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

CREATE TABLE audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actor_user_id TEXT,
            action TEXT NOT NULL,
            target_id TEXT,
            details TEXT,
            created_at TEXT NOT NULL
        );

CREATE TABLE authentication_sessions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            token_hash TEXT UNIQUE NOT NULL,
            expires_at TEXT NOT NULL,
            revoked INTEGER NOT NULL DEFAULT 0,
            user_agent TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );

CREATE TABLE cab_trips (
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

CREATE TABLE cyber_complaints (
        id TEXT PRIMARY KEY,
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
    , user_id TEXT, user_email TEXT);

CREATE TABLE guardian_connections (
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

CREATE TABLE guardian_invitations (
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

CREATE TABLE guardian_notifications (
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

CREATE TABLE guardians (
        id TEXT PRIMARY KEY,
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
    , owner_user_id TEXT, owner_email TEXT, user_id TEXT, relationship TEXT, is_active INTEGER DEFAULT 1, guardian_user_id TEXT);

CREATE TABLE journey_events (
            id TEXT PRIMARY KEY,
            journey_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            details TEXT,
            latitude REAL,
            longitude REAL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (journey_id) REFERENCES travel_journeys(id) ON DELETE CASCADE
        );

CREATE TABLE journey_locations (
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

CREATE TABLE journey_sharing (
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
            revoked_at TEXT, guardian_user_id TEXT, sharing_status TEXT DEFAULT 'ACTIVE', accepted_at TEXT,
            FOREIGN KEY (journey_id) REFERENCES travel_journeys(id) ON DELETE CASCADE,
            FOREIGN KEY (guardian_id) REFERENCES guardians(id) ON DELETE SET NULL
        );

CREATE TABLE permissions (
            id TEXT PRIMARY KEY,
            permission_name TEXT UNIQUE NOT NULL,
            description TEXT NOT NULL
        );

CREATE TABLE role_permissions (
            role_id TEXT NOT NULL,
            permission_id TEXT NOT NULL,
            PRIMARY KEY (role_id, permission_id),
            FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
            FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
        );

CREATE TABLE roles (
            id TEXT PRIMARY KEY,
            role_name TEXT UNIQUE NOT NULL,
            description TEXT NOT NULL
        );

CREATE TABLE sos_cases (
        id TEXT PRIMARY KEY,
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
    , user_id TEXT);

CREATE TABLE travel_journeys (
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

CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        role TEXT NOT NULL,
        aadhaar_verified INTEGER DEFAULT 1,
        face_match_score REAL DEFAULT 94.60,
        safety_index INTEGER DEFAULT 100,
        risk_trend TEXT DEFAULT 'STABLE',
        secret_phrase TEXT DEFAULT 'capcap',
        secret_word TEXT DEFAULT 'Box Box'
    , full_name TEXT, phone_digits TEXT, password_hash TEXT, role_id TEXT DEFAULT 'ROLE_USER', account_status TEXT NOT NULL DEFAULT 'ACTIVE', face_verified INTEGER DEFAULT 0, otp_verified INTEGER DEFAULT 0, badge_id TEXT, station TEXT, created_at TEXT, updated_at TEXT, voice_sos_language TEXT DEFAULT 'English', voice_sos_enabled INTEGER DEFAULT 0, voice_sos_max_duration INTEGER DEFAULT 120, silent_sos_mode INTEGER DEFAULT 0);

CREATE TABLE vault_assets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        file_type TEXT NOT NULL,
        hash_sha256 TEXT NOT NULL,
        tamper_check TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        size_mb TEXT,
        chain_of_custody TEXT
    , owner_user_id TEXT, owner_email TEXT);

CREATE INDEX idx_audio_evidence_sos ON audio_evidence(sos_event_id);

CREATE INDEX idx_audio_evidence_user ON audio_evidence(user_id, created_at DESC);

CREATE INDEX idx_gconn_guardian ON guardian_connections(guardian_id, connection_status);

CREATE INDEX idx_gconn_user ON guardian_connections(user_id, connection_status);

CREATE INDEX idx_ginv_email ON guardian_invitations(LOWER(guardian_email), status);

CREATE INDEX idx_ginv_sender ON guardian_invitations(sender_user_id, status);

CREATE INDEX idx_gnotif_guardian ON guardian_notifications(guardian_id, created_at DESC);

CREATE INDEX idx_journey_events_jid ON journey_events(journey_id, created_at DESC);

CREATE INDEX idx_journey_locations_jid ON journey_locations(journey_id, recorded_at ASC);

CREATE INDEX idx_journey_sharing_guser ON journey_sharing(guardian_user_id, sharing_status);

CREATE INDEX idx_journey_sharing_jid ON journey_sharing(journey_id, created_at DESC);

CREATE INDEX idx_journey_sharing_tok ON journey_sharing(sharing_token_hash);

CREATE INDEX idx_sessions_user ON authentication_sessions(user_id);

CREATE INDEX idx_travel_journeys_user ON travel_journeys(user_id, status, created_at DESC);

CREATE UNIQUE INDEX idx_users_email_unique ON users(LOWER(email));

CREATE UNIQUE INDEX idx_users_phone_digits_unique ON users(phone_digits);

