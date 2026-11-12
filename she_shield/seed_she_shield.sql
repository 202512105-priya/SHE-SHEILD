-- SHE SHIELD PostgreSQL Database Schema & Seed Data

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    email VARCHAR(128) NOT NULL,
    phone VARCHAR(32) NOT NULL,
    role VARCHAR(32) NOT NULL,
    aadhaar_verified BOOLEAN DEFAULT TRUE,
    face_match_score NUMERIC(5,2) DEFAULT 94.60,
    safety_index INT DEFAULT 100,
    risk_trend VARCHAR(32) DEFAULT 'STABLE',
    secret_phrase VARCHAR(64) DEFAULT 'capcap',
    secret_word VARCHAR(64) DEFAULT 'Box Box'
);

CREATE TABLE IF NOT EXISTS sos_cases (
    id VARCHAR(64) PRIMARY KEY,
    user_name VARCHAR(128) NOT NULL,
    user_email VARCHAR(128),
    user_phone VARCHAR(32) NOT NULL,
    age INT,
    blood_group VARCHAR(16),
    priority VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    gps VARCHAR(64) NOT NULL,
    timestamp VARCHAR(64) NOT NULL,
    device_type VARCHAR(128) NOT NULL,
    evidence_count INT DEFAULT 1,
    location_name VARCHAR(256)
);

CREATE TABLE IF NOT EXISTS cyber_complaints (
    id VARCHAR(64) PRIMARY KEY,
    category VARCHAR(64) NOT NULL,
    description TEXT NOT NULL,
    threat_score VARCHAR(16) NOT NULL,
    status VARCHAR(32) NOT NULL,
    timestamp VARCHAR(64) NOT NULL,
    user_name VARCHAR(128) NOT NULL,
    user_phone VARCHAR(32) NOT NULL,
    offender_link VARCHAR(256),
    evidence_count INT DEFAULT 1,
    attached_evidence TEXT
);

CREATE TABLE IF NOT EXISTS vault_assets (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(256) NOT NULL,
    file_type VARCHAR(32) NOT NULL,
    hash_sha256 VARCHAR(128) NOT NULL,
    tamper_check VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    timestamp VARCHAR(64) NOT NULL,
    size_mb VARCHAR(32),
    chain_of_custody VARCHAR(256)
);

CREATE TABLE IF NOT EXISTS guardians (
    id VARCHAR(64) PRIMARY KEY,
    ward_name VARCHAR(128) NOT NULL,
    guardian_name VARCHAR(128) NOT NULL,
    email VARCHAR(128) NOT NULL,
    phone VARCHAR(32) NOT NULL,
    relation VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL,
    safety_score VARCHAR(32),
    risk_status VARCHAR(32),
    battery_level VARCHAR(16),
    device_state VARCHAR(256),
    location_text VARCHAR(256),
    gps VARCHAR(64)
);

CREATE TABLE IF NOT EXISTS cab_trips (
    id VARCHAR(64) PRIMARY KEY,
    plate_number VARCHAR(32) NOT NULL,
    driver_name VARCHAR(128) NOT NULL,
    provider VARCHAR(64) NOT NULL,
    destination VARCHAR(256) NOT NULL,
    origin VARCHAR(256) NOT NULL,
    speed_kmh INT DEFAULT 38,
    deviation_meters NUMERIC(6,2) DEFAULT 28.0,
    safety_score VARCHAR(32) DEFAULT '98%',
    status VARCHAR(32) DEFAULT 'ACTIVE',
    timestamp VARCHAR(64) NOT NULL
);

-- Clean previous seed to ensure fresh 5-10 records
TRUNCATE TABLE users, sos_cases, cyber_complaints, vault_assets, guardians, cab_trips;

-- 1. SEED USERS (7 Records)
INSERT INTO users (id, name, email, phone, role, aadhaar_verified, face_match_score, safety_index, risk_trend, secret_phrase, secret_word) VALUES
('USR-001', 'Tisha Patel', 'tisha@gmail.com', '+91 98765 43210', 'user', true, 96.4, 100, 'STABLE', 'capcap', 'Box Box'),
('USR-002', 'Priya Sharma', 'priya.sharma@gmail.com', '+91 98220 11223', 'user', true, 94.6, 95, 'STABLE', 'safeguard', 'Shield Blue'),
('USR-003', 'Anjali Sharma', 'anjali.s@gmail.com', '+91 97234 56789', 'user', true, 91.2, 62, 'ELEVATED', 'emergency', 'Red Alert'),
('USR-004', 'Kavita Roy', 'kavita.r@gmail.com', '+91 98980 11223', 'user', true, 95.0, 88, 'STABLE', 'helpmeplease', 'Hawk Eye'),
('USR-005', 'Inspector Rajesh Rathod', 'rajesh.rathod@police.gov.in', '+91 94260 00100', 'responder', true, 99.1, 100, 'STABLE', 'policedispatch', 'Alpha Bravo'),
('USR-006', 'Sunita Sharma', 'sunita.sharma@gmail.com', '+91 98765 12345', 'guardian', true, 93.8, 100, 'STABLE', 'familysecure', 'Home Safe'),
('USR-007', 'Super Admin Vikram', 'vikram.admin@sheshield.gov.in', '+91 99000 88888', 'admin', true, 98.7, 100, 'STABLE', 'admincommand', 'Omega Zero');

-- 2. SEED SOS EMERGENCY CASES (8 Records for Police Responder Dashboard)
INSERT INTO sos_cases (id, user_name, user_email, user_phone, age, blood_group, priority, status, gps, timestamp, device_type, evidence_count, location_name) VALUES
('case-178051265857', 'Tisha Patel', 'tisha@gmail.com', '+91 98765 43210', 23, 'B+', 'CRITICAL', 'open', '23.0312, 72.5801', '2026-10-27T16:30:15', 'Smartwatch Double Tap & BLE Relay', 3, 'Navrangpura Bus Rapid Transit Corridor'),
('case-1780512510342', 'Priya Sharma', 'priya.sharma@gmail.com', '+91 98220 11223', 22, 'O+', 'HIGH', 'investigating', '23.0225, 72.5714', '2026-10-27T16:15:20', 'Secret Voice Trigger (capcap)', 2, 'Gujarat University Library Circle'),
('case-1780599102', 'Ananya Verma', 'ananya.v@gmail.com', '+91 98234 56789', 24, 'A+', 'CRITICAL', 'assigned', '23.0289, 72.5694', '2026-10-27T15:48:30', 'Wearable BLE Pendant Panic Trigger', 4, 'Mithakhali Six Roads, Ellis Bridge'),
('case-1780599304', 'Sneha Patel', 'sneha.p@gmail.com', '+91 97123 45678', 26, 'AB+', 'HIGH', 'in progress', '23.0335, 72.5620', '2026-10-27T15:20:10', 'Smart Cab 200m Route Deviation Alert', 3, 'CG Road Municipal Market Crossing'),
('case-1780599501', 'Ria Mehta', 'ria.m@gmail.com', '+91 99099 12345', 21, 'B-', 'CRITICAL', 'open', '23.0198, 72.5750', '2026-10-27T14:55:00', 'Secret Voice Phrase (Box Box)', 5, 'VS General Hospital Outer Gate'),
('case-1780599602', 'Meera Joshi', 'meera.j@gmail.com', '+91 98777 44332', 25, 'O-', 'MEDIUM', 'review', '23.0380, 72.5520', '2026-10-27T14:10:45', 'Triple Power Key Hardware Trigger', 1, 'Drive-In Road Himalayan Mall Gate'),
('case-1780599703', 'Pooja Trivedi', 'pooja.t@gmail.com', '+91 96660 55441', 27, 'A-', 'CRITICAL', 'received', '23.0260, 72.5640', '2026-10-27T13:40:12', 'Pedestrian Snatch & Drop Accelerometer', 2, 'Law Garden Night Craft Market'),
('case-1780599804', 'Divya Nair', 'divya.n@gmail.com', '+91 95551 22334', 22, 'B+', 'RESOLVED', 'resolved', '23.0360, 72.5560', '2026-10-27T12:15:00', 'Volume Down 3-Second Hold Trigger', 2, 'St. Xaviers College Corner');

-- 3. SEED CYBER CRIME COMPLAINTS (6 Records)
INSERT INTO cyber_complaints (id, category, description, threat_score, status, timestamp, user_name, user_phone, offender_link, evidence_count) VALUES
('case-1780512594344', 'BLACKMAIL & EXTORTION', 'Blackmail demanding financial ransom using manipulated deepfake images sent via Telegram.', '94%', 'SUBMITTED', '2026-10-27T16:10:00', 'Tisha Patel', '+91 98765 43210', 'https://instagram.com/fake_threat_user_99', 4),
('case-1780588220', 'CYBER STALKING', 'Persistent unauthorized tracking and vulgar threat messages across social media platforms.', '88%', 'UNDER REVIEW', '2026-10-27T15:00:00', 'Kavita Roy', '+91 98980 11223', 'https://facebook.com/offender_stalker_id', 5),
('case-1780588331', 'IDENTITY THEFT & IMPERSONATION', 'Cloned WhatsApp business account asking contacts for emergency money pretending to be victim.', '91%', 'INVESTIGATING', '2026-10-27T14:20:00', 'Priya Sharma', '+91 98220 11223', '+91 91234 56780 (Spoofed Sim)', 3),
('case-1780588442', 'FINANCIAL UPI PHISHING', 'Fake electricity payment APK sent via SMS that attempted to capture device OTP and credentials.', '96%', 'VERIFIED PROOF', '2026-10-27T13:45:00', 'Anjali Sharma', '+91 97234 56789', 'http://power-bill-payment-fake.apk', 6),
('case-1780588553', 'UNAUTHORIZED MORPHING', 'Non-consensual altered photo circulated in public WhatsApp community group.', '92%', 'OFFICIAL CASE FILED', '2026-10-27T12:30:00', 'Sneha Patel', '+91 97123 45678', 'Telegram Channel: @leaked_group_ahmedabad', 7),
('case-1780588664', 'CYBER HARASSMENT & TROLLING', 'Coordinated defamatory messages and threatening phone calls from untraceable VOIP numbers.', '85%', 'RESOLVED', '2026-10-27T10:15:00', 'Ria Mehta', '+91 99099 12345', 'VOIP Call Relay +1 (202) 555-0193', 2);

-- 4. SEED EVIDENCE VAULT ASSETS (6 Records)
INSERT INTO vault_assets (id, name, file_type, hash_sha256, tamper_check, status, timestamp, size_mb, chain_of_custody) VALUES
('EV-101', 'Cab_Audio_Blackbox_Recording.mp3', 'AUDIO', 'SHA256: 7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069', 'PASS', 'Verified', '2026-10-27T16:25:00', '12.4 MB', 'Device Mic -> Local Encrypted Storage -> State Forensic Node'),
('EV-102', 'Blackmail_Instagram_DM_Screenshots.pdf', 'DOCUMENT', 'SHA256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'PASS', 'Under Review', '2026-10-27T16:05:00', '4.2 MB', 'Secure Screenshot Ingestion -> Exif Metadata Locked'),
('EV-103', 'Pedestrian_Walk_GPS_Telemetry_Log.json', 'TELEMETRY', 'SHA256: 2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae', 'PASS', 'Verified', '2026-10-27T15:40:00', '1.1 MB', 'GPS NMEA Sensor Log -> SHA-256 Timestamper'),
('EV-104', 'CCTV_Corridor_Feed_Mithakhali.mp4', 'VIDEO', 'SHA256: fcde2b2edba56bf408601fb721fe9b5c338d10ee429ea04fae5511b68fbf8fb9', 'PASS', 'Investigation Updated', '2026-10-27T14:50:00', '48.7 MB', 'Smart City Municipal Surveillance -> Police Hash Vault'),
('EV-105', 'Phishing_APK_Decompiled_Manifest.txt', 'DOCUMENT', 'SHA256: a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e', 'PASS', 'Verified', '2026-10-27T13:50:00', '0.8 MB', 'CERT-In Threat Signature Repository'),
('EV-106', 'Live_Face_Scan_Biometric_Token.dat', 'BIOMETRIC', 'SHA256: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865', 'PASS', 'Uploaded', '2026-10-27T12:00:00', '0.3 MB', 'Mobile Camera Neural Core -> Aadhaar Biometric Vault');

-- 5. SEED GUARDIAN NETWORK (5 Records)
INSERT INTO guardians (id, ward_name, guardian_name, email, phone, relation, status, safety_score, risk_status, battery_level, device_state, location_text, gps) VALUES
('GDN-01', 'Priya Sharma', 'Sunita Sharma', 'sunita.sharma@gmail.com', '+91 98765 12345', 'Mother', 'ACTIVE', '95% Safety', 'SAFE', '88%', 'Charging • Smartwatch Paired • GPS Active', 'University Campus • Safe Zone', '23.0225, 72.5714'),
('GDN-02', 'Anjali Sharma', 'Sunita Sharma', 'sunita.sharma@gmail.com', '+91 98765 12345', 'Mother', 'ACTIVE', '62% Medium Risk', 'MEDIUM RISK', '45%', 'Walk Mode Active • Route Deviation 200m Flagged', 'CG Road • Commercial Crossing', '23.0335, 72.5620'),
('GDN-03', 'Tisha Patel', 'Mahesh Patel', 'mahesh.patel@gmail.com', '+91 98220 99887', 'Father', 'ACTIVE', '100% Stable', 'SAFE', '92%', 'Cab Monitoring Active • Corridor Green', 'CG Road • Near Law Garden', '23.0310, 72.5590'),
('GDN-04', 'Ananya Verma', 'Karan Verma', 'karan.verma@gmail.com', '+91 97111 22334', 'Brother', 'ACTIVE', '78% Safe', 'SAFE', '67%', 'Pedestrian Mode Active • Bluetooth Connected', 'Mithakhali Six Roads', '23.0289, 72.5694'),
('GDN-05', 'Ria Mehta', 'Meena Mehta', 'meena.mehta@gmail.com', '+91 99000 11223', 'Mother', 'PENDING', '85% Safe', 'SAFE', '54%', 'Offline Cache Synced • Awaiting Verification', 'VS General Hospital Area', '23.0198, 72.5750');

-- 6. SEED SMART CAB JOURNEYS (5 Records)
INSERT INTO cab_trips (id, plate_number, driver_name, provider, destination, origin, speed_kmh, deviation_meters, safety_score, status, timestamp) VALUES
('CAB-501', 'GJ-01-XX-9999', 'Ramesh Patel (4.9★)', 'Uber Premier', 'CG Road, Ahmedabad', 'University Gate', 38, 28.0, '98%', 'ACTIVE', '2026-10-27T16:20:00'),
('CAB-502', 'GJ-01-AB-1234', 'Suresh Yadav (4.8★)', 'Ola Prime', 'Prahlad Nagar Garden', 'IIM Ahmedabad Gate 2', 42, 15.0, '99%', 'COMPLETED', '2026-10-27T15:00:00'),
('CAB-503', 'GJ-27-K-8821', 'Mohan Vaghela (4.7★)', 'Rapido Auto', 'Law Garden Night Bazaar', 'Navrangpura Bus Stop', 32, 45.0, '96%', 'COMPLETED', '2026-10-27T14:15:00'),
('CAB-504', 'GJ-01-ER-4402', 'Dinesh Rawat (4.9★)', 'Private Taxi', 'Ahmedabad International Airport', 'Sindhu Bhavan Road', 58, 12.0, '100%', 'COMPLETED', '2026-10-27T12:30:00'),
('CAB-505', 'GJ-06-ZZ-7711', 'Kamlesh Chauhan (4.6★)', 'Uber Premier', 'SG Highway Corporate Park', 'Vastrapur Lake Corner', 40, 85.0, '93%', 'COMPLETED', '2026-10-27T10:45:00');
