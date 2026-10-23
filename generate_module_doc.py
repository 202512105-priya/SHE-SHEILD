import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=140, right=140):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def format_table(table, col_widths, header_bg="4C1D95", alt_bg="F5F3FF"):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    # Header
    for cell in table.rows[0].cells:
        set_cell_background(cell, header_bg)
        set_cell_margins(cell, top=100, bottom=100, left=130, right=130)
        for p in cell.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for run in p.runs:
                run.font.name = "Arial"
                run.font.size = Pt(9.5)
                run.font.bold = True
                run.font.color.rgb = RGBColor(255, 255, 255)
    # Rows
    for r_idx in range(1, len(table.rows)):
        bg = alt_bg if r_idx % 2 == 1 else "FFFFFF"
        for cell in table.rows[r_idx].cells:
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=80, bottom=80, left=130, right=130)
            for p in cell.paragraphs:
                for run in p.runs:
                    run.font.name = "Arial"
                    run.font.size = Pt(9)
                    run.font.color.rgb = RGBColor(30, 41, 59)
    for row in table.rows:
        for idx, width in enumerate(col_widths):
            row.cells[idx].width = width

def add_callout(doc, title, text, bg="F3E8FF", border_color="7C3AED"):
    t = doc.add_table(rows=1, cols=1)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_cell_background(t.cell(0, 0), bg)
    set_cell_margins(t.cell(0, 0), top=100, bottom=100, left=150, right=150)
    p = t.cell(0, 0).paragraphs[0]
    r1 = p.add_run(f"📌 {title}\n")
    r1.font.name = "Arial"
    r1.font.size = Pt(9.5)
    r1.font.bold = True
    r1.font.color.rgb = RGBColor(76, 29, 149)
    r2 = p.add_run(text)
    r2.font.name = "Arial"
    r2.font.size = Pt(9)
    r2.font.color.rgb = RGBColor(51, 65, 85)
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

def build_module_documentation():
    doc = Document()
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        header = section.header
        p_hdr = header.paragraphs[0]
        p_hdr.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        r_hdr = p_hdr.add_run("SHE SHIELD — Deep Module-by-Module Technical Documentation")
        r_hdr.font.name = "Arial"
        r_hdr.font.size = Pt(8.5)
        r_hdr.font.italic = True
        r_hdr.font.color.rgb = RGBColor(148, 163, 184)

    style = doc.styles['Normal']
    font = style.font
    font.name = 'Arial'
    font.size = Pt(10.5)
    font.color.rgb = RGBColor(30, 41, 59)

    # ==========================================
    # COVER / HEADER
    # ==========================================
    doc.add_paragraph().paragraph_format.space_after = Pt(24)
    p_t = doc.add_paragraph()
    p_t.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t = p_t.add_run("SHE SHIELD\n")
    r_t.font.name = "Arial"
    r_t.font.size = Pt(28)
    r_t.font.bold = True
    r_t.font.color.rgb = RGBColor(76, 29, 149)

    r_sub = p_t.add_run("Deep Module-by-Module Technical Specification & Execution Logic\n")
    r_sub.font.name = "Arial"
    r_sub.font.size = Pt(15)
    r_sub.font.bold = True
    r_sub.font.color.rgb = RGBColor(190, 24, 93)

    r_tag = p_t.add_run("Comprehensive Architectural Breakdown of Mobile, Backend, AI & Storage Components")
    r_tag.font.name = "Arial"
    r_tag.font.size = Pt(11)
    r_tag.font.italic = True
    r_tag.font.color.rgb = RGBColor(100, 116, 139)

    doc.add_paragraph().paragraph_format.space_after = Pt(18)

    # University & Project Metadata Table
    t_meta = doc.add_table(rows=5, cols=2)
    meta_info = [
        ("Project Platform", "SHE SHIELD — Cyber-Integrated Safety Platform for Women"),
        ("Source Code Root", "/Users/priyashah/Downloads/Women (she_shield/ + backend/ + admin_dashboard/)"),
        ("Academic Program", "WSSOA (IT644) · Autumn Semester 2026 · Dhirubhai Ambani University"),
        ("Core Technologies", "Flutter 3.x, Dart, Python Flask, PyTorch NLP, EasyOCR, PostgreSQL, Redis, AES-256, SHA-256"),
        ("Documentation Scope", "Comprehensive technical audit explaining exact UI actions, logic flows, state mutations, and backend hooks")
    ]
    for r_idx, (k, v) in enumerate(meta_info):
        t_meta.cell(r_idx, 0).text = k
        t_meta.cell(r_idx, 1).text = v
    format_table(t_meta, [Inches(2.2), Inches(5.0)], header_bg="4C1D95")

    doc.add_paragraph().paragraph_format.space_after = Pt(18)

    # ==========================================
    # MODULES BREAKDOWN
    # ==========================================
    modules = [
        # MODULE 1
        {
            "num": "1",
            "name": "Authentication, Onboarding & Identity Verification Module",
            "files": "she_shield/lib/screens/onboarding_screen.dart\nshe_shield/lib/screens/auth_screens.dart\nbackend/auth.py\nbackend/database/schema.sql",
            "summary": "Handles initial user introduction, role selection (Women User, Guardian, Emergency Responder, Administrator), secure account credential setup, and multi-factor identity proofing.",
            "components": [
                ("OnboardingScreen", "3-slide swipeable intro carousel detailing: 1. Stealth SOS Triggering, 2. AI Travel Geofencing, 3. Tamper-Proof Cryptographic Evidence. Sets _onboardingCompleted flag in DatabaseService."),
                ("Role Selection Flow", "WelcomeScreen offers 4 distinct portal entry paths. Routing divides into /register_user, /register_guardian, /register_responder, and /admin_login."),
                ("Identity Verification Pipeline", "RegisterUserScreen implements a 3-step proofing simulation: 1. Aadhaar ID document upload, 2. Live camera face capture with biometric match scoring (computes 94.6% confidence score), 3. Mobile OTP verification."),
                ("JWT Token Engine (auth.py)", "generate_token(user_id) produces an RSA/HMAC-SHA256 signed JWT with 15-minute expiration and subject claims; verify_token() validates cryptographic signatures on incoming requests.")
            ],
            "under_the_hood": (
                "When a user completes registration in RegisterUserScreen, the state store (DatabaseService) executes "
                "loginUser(email, name) and updates _aadhaarVerified, _faceVerified, and _otpVerified to true. "
                "In the backend, auth.py issues a cryptographically signed JWT token that includes the user's role and unique UID. "
                "Subsequent requests attach this token via the 'Authorization: Bearer <token>' header, allowing gateway.py to enforce Role-Based Access Control."
            ),
            "state_changes": "_onboardingCompleted = true; _currentRole = 'user'; _currentUserId = 'user_<timestamp>'; _faceMatchScore = 94.6;"
        },

        # MODULE 2
        {
            "num": "2",
            "name": "Main Safety Dashboard & Real-Time Security Index",
            "files": "she_shield/lib/screens/dashboard_screen.dart\nshe_shield/lib/services/database_service.dart\nshe_shield/lib/theme/app_theme.dart",
            "summary": "Serves as the primary operational hub for the woman user, featuring a dynamic safety gauge, a 5-second cancellable SOS activator, and quick launchers to all sub-modules.",
            "components": [
                ("Safety Index Gauge", "Real-time circular indicator displaying the user's computed safety score (100% Stable). Score degrades dynamically when entering unsafe nocturnal corridors or experiencing route offsets."),
                ("5-Second Hold-to-Activate SOS", "Emergency button requires a sustained press. Initiates a 5-second countdown with visual pulsing ripple animations and progressive haptic feedback to prevent accidental triggers."),
                ("Quick Action Grid", "6 modular launch tiles: SOS Protection Center, Safe Arrival Travel Mode, AI Cyber Assistant, Secure Evidence Locker, Guardian Network, and Help & Self-Defense Hub."),
                ("Emergency Offline Banner", "Displays network synchronization state. If cellular data drops, indicates 'Operating on local cache — SMS fallback armed'.")
            ],
            "under_the_hood": (
                "The DashboardScreen listens reactively to DatabaseService using the Provider architecture. "
                "When the user presses the SOS button, _startSosCountdown() initializes a periodic 1-second Dart Timer. "
                "If the countdown reaches zero without cancellation, _triggerSmartShieldSosPortal() fires, mounting a full-screen "
                "emergency alert modal, capturing device GPS coordinates, and invoking the parallel dispatch sequence."
            ),
            "state_changes": "_safetyIndex = 100; _riskTrend = 'STABLE'; _isHoldingSos = true/false; _countdown = 5 -> 0;"
        },

        # MODULE 3
        {
            "num": "3",
            "name": "Multi-Modal Emergency SOS & Stealth Trigger Engine",
            "files": "she_shield/lib/screens/sos_screens.dart\nshe_shield/lib/services/sos_service.dart\nbackend/app.py (/api/sos/trigger, /api/sos/broadcast)",
            "summary": "Provides multi-modal distress triggering mechanisms that operate without looking at the screen, followed by sub-2-second parallel emergency alert broadcasting.",
            "components": [
                ("Multi-Modal Triggers", "Configurable triggering avenues: 1. Hold Volume Down (3s), 2. Double-press Power Key, 3. Triple-press Power Key, 4. Paired Bluetooth LE button, 5. Secret Voice Phrase ('capcap' or 'Box Box')."),
                ("Offline Voice SOS Engine", "Local speech recognition model continuously parses ambient mic input for the custom trigger phrase with zero cloud latency. Works across English, Hindi, and Gujarati."),
                ("Silent SOS Mode", "When enabled, SOS triggers dispatch alerts, captures GPS, and starts audio recording with ZERO screen illumination and NO siren sounds, ensuring attacker is unaware."),
                ("Parallel Broadcast Pipeline", "Concurrently executes 3 actions in <= 2 seconds: 1. Push notification to Linked Guardians, 2. Emergency incident dispatch to Police Dashboard, 3. Carrier SMS fallback containing Google Maps coordinate link.")
            ],
            "under_the_hood": (
                "Upon trigger confirmation, SosService.triggerSos() updates active alert state. The app queries Geolocator for high-precision "
                "lat/lng, packages device battery status, and POSTs to /api/sos/trigger. In backend/app.py, broadcast_sos() generates an alertId "
                "(e.g. SOS_1780512), commits the emergency session to the database, and fans out WebSockets to active police dashboards. "
                "If network times out, the local SQLite queue fires an automated cellular SMS to guardians."
            ),
            "state_changes": "_volButtonTrigger = true; _secretVoiceTriggerEnabled = true; _silentSosMode = false; _smsFallback = true;"
        },

        # MODULE 4
        {
            "num": "4",
            "name": "Travel Guardian & Route Deviation Monitoring Engine",
            "files": "she_shield/lib/screens/travel_monitor_screen.dart\nshe_shield/lib/services/database_service.dart\nbackend/telemetry_worker.py",
            "summary": "Continuous journey companion monitoring cab and pedestrian transit in real time, detecting driver detours and nocturnal route anomalies.",
            "components": [
                ("Cab Guardian Suite", "Allows entry of cab plate number (e.g. GJ-01-XX-9999), destination, and estimated duration. Fetches driver safety rating (4.6 ★)."),
                ("Haversine Deviation Engine", "Continuously calculates the perpendicular distance offset between the user's live GPS breadcrumbs and the planned route vector polyline. Flags warnings if offset > 30 meters."),
                ("Walk Guardian Mode", "Pedestrian protection mode with ETA countdown timer. If the user fails to confirm safe arrival within the allotted duration, an alert is automatically dispatched."),
                ("Blackbox Evidence Ingest", "Prompts user to select continuous background recording mode: 'Video & Audio' or 'Audio Only', streaming recorded chunks to the Evidence Vault."),
                ("Safe Arrival Check-in", "Requires entry of a confidential safety PIN (e.g. '1234') to terminate travel monitoring, preventing assailants from forcibly stopping the monitor.")
            ],
            "under_the_hood": (
                "TravelMonitorScreen uses an active Timer.periodic to decrement remaining travel seconds. "
                "Every 5 seconds, current GPS coordinates are evaluated against the destination vector. "
                "If the calculated route offset exceeds 30m, DatabaseService increments _cabDeviations and recalculates _cabRiskIndex. "
                "In backend/telemetry_worker.py, TelemetryWorker.process_location_ping() buffers waypoints for spatial analysis and logs anomaly metrics."
            ),
            "state_changes": "_isCabTripActive = true; _cabPlate = 'GJ-01-XX-9999'; _routeOffset = 30.0; _cabDeviations = 1; _cabRiskIndex = 37;"
        },

        # MODULE 5
        {
            "num": "5",
            "name": "AI-Powered Cybercrime Reporting & OCR Vision Desk",
            "files": "she_shield/lib/screens/cyber_screens.dart\nbackend/ai_service.py\nbackend/app.py (/api/cybercrime/scan, /api/cybercrime/report)",
            "summary": "Intelligent digital defense desk allowing victims to report online blackmail, doxxing, sextortion, and stalking with automated OCR screenshot parsing and NLP threat scoring.",
            "components": [
                ("Evidence Screenshot Attachment", "Upload interface accepting image evidence of abusive social media messages, WhatsApp chats, or blackmail extortion demands."),
                ("OCR Vision Parsing Engine", "Scans the attached screenshot to extract textual dialog, timestamps, phone numbers, and sender account handles (@unknown_user_99)."),
                ("PyTorch NLP Threat Classifier", "Processes the extracted threat narrative. Evaluates harassment severity and outputs: Threat Category (BLACKMAIL), Risk Level (CRITICAL), Threat Score (92%), and Confidence (90%)."),
                ("Recommended Response Protocols", "Generates immediate contextual guidance: 'Do not pay or interact with the offender', 'Keep screenshots of conversation log chains', 'File official complaint'."),
                ("Automated Police Complaint Filing", "Generates an official complaint case record (e.g. case-1780512594344) with pre-filled forensic evidence attachments.")
            ],
            "under_the_hood": (
                "In CyberReportScreen, tapping 'Perform AI Threat Scan' triggers _uploadScreenshot() and sets _scanning = true. "
                "The image and description are transmitted to /api/cybercrime/scan. In backend/app.py, the threat assessment microservice "
                "analyzes the payload, returning threatCategory='Harassment / Blackmail', riskLevel='CRITICAL', and threatScore='92%'. "
                "Tapping 'File Official Complaint' calls DatabaseService.addCyberComplaint(), adding the case to _cyberComplaints."
            ),
            "state_changes": "_cyberComplaints.add({'id': 'case-1780512...', 'category': 'BLACKMAIL', 'threatScore': '92%', 'status': 'SUBMITTED'});"
        },

        # MODULE 6
        {
            "num": "6",
            "name": "Cryptographic Evidence Locker & Tamper-Proof Vault",
            "files": "she_shield/lib/screens/evidence_vault_screens.dart\nbackend/cloud_storage.py\nbackend/app.py (/api/cybercrime/evidence)",
            "summary": "Secure forensic storage repository that notarizes all recorded audio, video, and screenshot assets with SHA-256 cryptographic fingerprints for court admissibility.",
            "components": [
                ("Multi-Category Asset Vault", "4 categorical views: Uploaded, Under Review, Verified, and Investigated. Manages audio clips, blackbox videos, photos, and formal documents."),
                ("Client-Side SHA-256 Hashing", "Generates an immutable cryptographic hash (e.g. SHA256: 643199974ac7064...) immediately upon capture on the client device before network transit."),
                ("Tamper Check Verification", "Performs hash-match verification against cloud storage. Displays a green 'Tamper Check PASS' badge confirming zero post-capture file alteration."),
                ("Chain of Custody Ledger", "Logs chronological metadata including asset filename, byte size, exact UTC timestamp, and uploading device fingerprint."),
                ("Section 65B Compliance", "Generates an exportable forensic certificate complying with Section 65B of the Indian Evidence Act, ensuring evidence is legally admissible in courtroom trials.")
            ],
            "under_the_hood": (
                "When a file is ingested via _ingestEvidence(), EvidenceVaultScreen calls DatabaseService.addVaultAsset(). "
                "In backend/cloud_storage.py, CloudStorageService.upload_evidence_file() receives the raw bytes, calculates hashlib.sha256(file_bytes).hexdigest(), "
                "stores the blob in S3/MinIO at evidence/<hash>/<filename>, and records the hash in the persistent database. "
                "Any subsequent bit alteration produces a mismatched hash, failing the verification audit."
            ),
            "state_changes": "_vaultAssets.add({'name': 'Travel_Trip_Audio_Evidence.mp4', 'hash': 'SHA256: 643199...', 'tamperCheck': 'PASS'});"
        },

        # MODULE 7
        {
            "num": "7",
            "name": "Guardian Network & Live Radar Tracking Module",
            "files": "she_shield/lib/screens/guardian_linking_screen.dart\nshe_shield/lib/screens/guardian_dashboard_screen.dart\nshe_shield/lib/services/safety_map_service.dart",
            "summary": "Coordinates trusted family contacts, enabling real-time telemetry streaming, geofence arrival monitoring, and quick emergency intervention.",
            "components": [
                ("Guardian Linking Screen", "Allows adding emergency contacts by email, phone, and relationship (Mother, Sister, Friend, Father). Manages authorization status (PENDING / LINKED)."),
                ("Guardian Dashboard Portal", "Dedicated interface for family guardians to monitor linked users. Displays user name, safety score (95%), battery level (88%), and network state."),
                ("Live Location Tracking Card", "Displays real-time GPS coordinates (e.g. 23.0225° N, 72.5714° E) with an active location indicator updated every few seconds via SafetyMapService."),
                ("Guardian Quick Action Bar", "3 one-touch intervention buttons: 1. Call User directly, 2. Navigate (opens driving route to user's live coordinates), 3. Police Emergency (dials 112 with victim's location).")
            ],
            "under_the_hood": (
                "When an emergency SOS or travel session begins, DatabaseService updates the shared session state. "
                "GuardianDashboardScreen subscribes to these updates via Provider. SafetyMapService.getLiveLocation() returns "
                "the latest cached coordinates. If a route deviation occurs, a high-priority push notification and SMS alert are dispatched "
                "to all linked guardians with an immediate Google Maps navigation hyperlink."
            ),
            "state_changes": "_guardians.add({'email': 'abc@gmail.com', 'relation': 'mother', 'status': 'LINKED', 'uid': 'user-178...'});"
        },

        # MODULE 8
        {
            "num": "8",
            "name": "Police Dispatch & Emergency Responder Command System",
            "files": "she_shield/lib/screens/responder_dashboard_screen.dart\nshe_shield/lib/screens/police_admin_screens.dart\nbackend/app.py (/api/admin/incidents)",
            "summary": "Specialized tactical interface for verified law enforcement personnel, featuring live incident queues, victim profiles, breadcrumb GPS maps, and court dossier exports.",
            "components": [
                ("Verified Responder Onboarding", "RegisterResponderScreen enforces strict verification: Govt ID upload, Police Dept ID upload, assigned police station, and jurisdictional sector."),
                ("Live Incident Queue", "Chronological feed of active emergencies with priority tags (CRITICAL for SOS, HIGH for route deviations). Displays victim name, phone, age, and blood group (O+)."),
                ("Interactive Breadcrumb Radar Map", "Uses RouteTrailPainter to render the victim's exact transit trajectory, showing waypoints, speed drops, and deviation points."),
                ("Case Lifecycle Management", "Allows responding officers to claim cases, update status ('dispatched', 'on-scene', 'resolved'), and attach resolution notes."),
                ("Court Dossier Export", "Integrates with PdfReportService to generate a standardized incident report containing victim telemetry, timestamps, and evidence hashes.")
            ],
            "under_the_hood": (
                "ResponderDashboardScreen pulls active emergency cases from DatabaseService._sosCases and backend /api/admin/incidents. "
                "Each case includes medical details (blood group, age) to assist paramedics. When an officer selects an incident, "
                "the map centers on the victim's GPS coordinates and streams real-time updates until the incident is marked as resolved."
            ),
            "state_changes": "_sosCases[0]['status'] = 'dispatched'; _sosCases[0]['priority'] = 'CRITICAL'; _sosCases[0]['evidenceCount'] = 2;"
        },

        # MODULE 9
        {
            "num": "9",
            "name": "Central Administrator Command Center & Audit Service",
            "files": "she_shield/lib/screens/admin_command_center_screen.dart\nshe_shield/lib/services/admin_service.dart\nshe_shield/lib/services/audit_service.dart",
            "summary": "Platform-level governance console featuring two-layer authentication, high-risk unsafe zone perimeter controls, and an immutable audit logging service.",
            "components": [
                ("Two-Layer Admin Authentication", "Enforces dual credential verification: Layer 1 checks Admin Card ID ('ADM-99'); Layer 2 verifies Security Password ('ADM123')."),
                ("Unsafe Zone Perimeter Control", "Allows administrators to add, edit, and delete geofenced high-risk zones, defining zone name, center coordinates, radius (meters), and risk score."),
                ("Immutable Audit Log Viewer", "AuditService records every security-sensitive action (user login, SOS trigger, zone modification, evidence access) with an unalterable timestamp."),
                ("AI Threat Model Parameter Oversight", "Enables viewing and adjusting baseline threat sensitivity thresholds and nocturnal risk multipliers.")
            ],
            "under_the_hood": (
                "In AdminCommandCenterScreen, _verifyAdminCredentials() validates both credential layers before setting _isAuthenticated = true. "
                "Any administrative change (such as adding an unsafe zone via AdminZoneTile) automatically invokes AuditService.logEvent(event, user), "
                "appending an immutable dictionary entry to _logs for complete regulatory accountability."
            ),
            "state_changes": "_isAuthenticated = true; _logs.add({'event': 'ZONE_UPDATED', 'user': 'ADM-99', 'timestamp': '2026-10-23T...'});"
        },

        # MODULE 10
        {
            "num": "10",
            "name": "IoT Wearable & Hardware Integration Module",
            "files": "she_shield/lib/screens/wearable_pairing_screen.dart\nshe_shield/lib/services/database_service.dart",
            "summary": "Manages low-power Bluetooth Low Energy (BLE) peripheral connectivity with external panic buttons, smart jewelry, and fitness bands.",
            "components": [
                ("Device Pairing Center", "Scans and pairs with 4 distinct wearable form factors: 1. SheShield Smartwatch, 2. Smartband, 3. Concealed Pendant, 4. Micro Button Switch."),
                ("Telemetry & Battery Monitoring", "Displays real-time peripheral battery percentage (e.g. 94%), Bluetooth RSSI signal strength, and firmware version."),
                ("Wearable Hardware Trigger Binding", "Pressing the paired hardware button immediately sends a BLE beacon interrupt to the mobile client, triggering the SOS pipeline in <1 second.")
            ],
            "under_the_hood": (
                "WearablePairingScreen updates boolean flags in DatabaseService (_smartwatchConnected, _smartbandConnected, _buttonSwitchConnected). "
                "When a peripheral button click is received via platform channels, DatabaseService immediately routes the event to the emergency SOS engine, "
                "even when the smartphone screen is locked and tucked away in a handbag."
            ),
            "state_changes": "_smartwatchConnected = true; _buttonSwitchConnected = true; _pendantPaired = false;"
        },

        # MODULE 11
        {
            "num": "11",
            "name": "Backend API Gateway, Microservices & Data Layer",
            "files": "backend/app.py\nbackend/gateway.py\nbackend/auth.py\nbackend/telemetry_worker.py\nbackend/cloud_storage.py\nbackend/database/security.py",
            "summary": "Scalable Python WSGI microservices providing authentication, telemetry batching, cryptographic evidence storage, and mock integration hooks for national emergency networks.",
            "components": [
                ("API Gateway (gateway.py)", "Enforces global CORS policies, validates incoming JWT tokens, and routes traffic to downstream microservices."),
                ("Core REST APIs (app.py)", "Endpoints: /api/v1/status, /api/sos/broadcast, /api/travel/ping, /api/cyber/submit, /api/ai/threat-assess, /api/admin/incidents."),
                ("Telemetry Worker (telemetry_worker.py)", "Background worker that ingests and batches mobile location coordinates for route deviation monitoring."),
                ("Cloud Storage Service (cloud_storage.py)", "Uploads evidence blobs, computes SHA-256 digests, and generates presigned URLs."),
                ("Database Security (security.py)", "Implements SQL injection mitigation heuristics, identifier validation, and parameterized query standards."),
                ("National Emergency Hooks", "Architecture hooks for ERSS-112 (National Emergency), CCTNS (Police Crime Records), and CERT-In (Cyber Defense).")
            ],
            "under_the_hood": (
                "The backend is structured into modular microservices coordinated by gateway.py. "
                "Requests pass through JWT verification before hitting application endpoints in app.py. "
                "High-frequency GPS pings are offloaded to telemetry_worker.py, while evidence files are processed by cloud_storage.py "
                "to ensure cryptographic hashing before persistence in PostgreSQL."
            ),
            "state_changes": "JSON responses with status: 'alert_dispatched', 'tracking_active', 'submitted', 'uploaded'."
        },

        # MODULE 12
        {
            "num": "12",
            "name": "React.js Central Administrator Web Dashboard",
            "files": "admin_dashboard/src/App.jsx\nadmin_dashboard/src/components/AdminSidebar.jsx\nadmin_dashboard/package.json",
            "summary": "High-density desktop web console for emergency dispatchers and municipal supervisors to monitor active SOS alerts, travel deviations, and cyber complaints.",
            "components": [
                ("Real-Time KPI Metric Cards", "4 live metrics: Active SOS Alerts (3), Protected Users (1420), Resolved Complaints (289), and Safe Zones Monitored (45)."),
                ("Incident Priority Radar Feed", "Live table tracking active emergencies (INC-8091 SOS Broadcast / CRITICAL, INC-8090 Travel Deviation / HIGH, INC-8089 Cyber Harassment / MEDIUM)."),
                ("Dispatcher Action Panel", "Allows dispatchers to filter incidents by status (DISPATCHED, INVESTIGATING, UNDER REVIEW) and assign nearest response units."),
                ("System Health Indicator", "Green 'SYSTEM OPERATIONAL' badge confirming WebSocket gateway and database availability.")
            ],
            "under_the_hood": (
                "App.jsx uses React state hooks (useState) to manage metrics and incident feeds. "
                "In production, it establishes a WebSocket connection to the Flask backend's /api/dashboard/stats and /api/admin/incidents, "
                "re-rendering the incident list in real time whenever an emergency SOS or travel deviation event is committed."
            ),
            "state_changes": "stats.activeAlerts = 3; incidents[0].status = 'DISPATCHED'; incidents[0].priority = 'CRITICAL';"
        },

        # MODULE 13
        {
            "num": "13",
            "name": "Evaluation, Demo & Testing Lab Module",
            "files": "she_shield/lib/screens/demo_center_screen.dart\nshe_shield/lib/screens/help_center_screen.dart\nshe_shield/lib/screens/safety_articles_screen.dart",
            "summary": "Dedicated testing laboratory and public safety resource hub for evaluating app features during academic viva defense and live prototype demonstrations.",
            "components": [
                ("Demo & Viva Test Center", "Allows evaluators to simulate GPS coordinates, trigger mock travel route deviations, simulate BLE disconnects, and test cyber threat scans without physical danger."),
                ("Emergency Helpline Directory", "One-touch direct dialing to national emergency helplines: 112 (National Emergency), 1091 (Women Helpline), 181 (Women in Distress), 1930 (Cyber Crime)."),
                ("Self-Defense & Awareness Hub", "Curated safety guides, legal rights documentation, and situational awareness articles.")
            ],
            "under_the_hood": (
                "DemoCenterScreen exposes toggles that mutate DatabaseService._vivaPrototypeMode. "
                "Evaluators can inject simulated route offsets (e.g. offsetting GPS by 50m) to immediately observe how the Cab Guardian "
                "engine detects anomalies, degrades the safety index, and fires automated guardian alerts."
            ),
            "state_changes": "_vivaPrototypeMode = true; _cabDeviations = 1; _cabRiskIndex = 37;"
        }
    ]

    for m in modules:
        h2 = doc.add_heading(f"Module {m['num']}: {m['name']}", level=2)
        h2.runs[0].font.name = "Arial"
        h2.runs[0].font.size = Pt(13)
        h2.runs[0].font.bold = True
        h2.runs[0].font.color.rgb = RGBColor(76, 29, 149)

        # File Mapping Table
        t_f = doc.add_table(rows=2, cols=2)
        t_f.cell(0, 0).text = "Source Code Files:"
        t_f.cell(0, 1).text = m['files']
        t_f.cell(1, 0).text = "Functional Role:"
        t_f.cell(1, 1).text = m['summary']
        format_table(t_f, [Inches(1.8), Inches(5.4)], header_bg="581C87")
        doc.add_paragraph().paragraph_format.space_after = Pt(6)

        # Detailed Components
        p_c = doc.add_paragraph()
        r_c = p_c.add_run("Key Architectural Components & Features:")
        r_c.font.bold = True
        r_c.font.size = Pt(10)
        r_c.font.color.rgb = RGBColor(15, 23, 42)

        for c_title, c_desc in m['components']:
            p_item = doc.add_paragraph(style='List Bullet')
            r_it = p_item.add_run(f"{c_title}: ")
            r_it.font.bold = True
            r_it.font.size = Pt(9.5)
            r_it.font.color.rgb = RGBColor(67, 56, 202)
            r_id = p_item.add_run(c_desc)
            r_id.font.size = Pt(9.5)
            r_id.font.color.rgb = RGBColor(51, 65, 85)

        # Under the Hood Callout
        add_callout(doc, "What is Happening Under the Hood (Execution Flow):", m['under_the_hood'])

        # State Mutations
        p_st = doc.add_paragraph()
        r_sth = p_st.add_run("Reactive State Mutations (DatabaseService / State Store):\n")
        r_sth.font.bold = True
        r_sth.font.size = Pt(9)
        r_sth.font.color.rgb = RGBColor(100, 116, 139)
        r_stc = p_st.add_run(m['state_changes'])
        r_stc.font.name = "Courier New"
        r_stc.font.size = Pt(8.5)
        r_stc.font.color.rgb = RGBColor(30, 41, 59)

        doc.add_paragraph().paragraph_format.space_after = Pt(14)

    # ==========================================
    # COMPLETE DATA FLOW MATRIX
    # ==========================================
    doc.add_page_break()
    h_flow = doc.add_heading("14. End-to-End System Data Flow Matrix", level=1)
    h_flow.runs[0].font.color.rgb = RGBColor(76, 29, 149)

    p_fintro = doc.add_paragraph(
        "The following matrix summarizes how data originates, gets processed, and produces outputs across the entire SHE SHIELD platform:"
    )
    p_fintro.paragraph_format.space_after = Pt(8)

    t_matrix = doc.add_table(rows=6, cols=5)
    matrix_data = [
        ("Event / Trigger", "Client Origin", "Processing Logic", "Security & Encryption", "System Output / Destination"),
        ("Emergency SOS", "BLE button / Voice 'capcap' / Power key", "5s countdown, GPS acquisition, parallel fan-out", "TLS 1.3, JWT auth, SQLite local queue", "Guardian push + SMS link, Police 112 radar map"),
        ("Cab Transit Ping", "TravelMonitorScreen (every 5s)", "Haversine formula calculates deviation > 30m", "JWT auth, HTTPS REST ping", "Guardian detour warning, Risk Index degrade"),
        ("Cyber Harassment", "CyberReportScreen (Screenshot)", "OCR text parsing + PyTorch NLP threat model", "AES-256 cloud storage, SHA-256 hashing", "Threat score (92%), Police complaint PDF dossier"),
        ("Evidence Vault", "Continuous Blackbox Video/Audio", "Client-side SHA-256 hashing at recording stop", "AES-256-GCM cipher, immutable ledger", "Tamper Check PASS badge, Section 65B legal proof"),
        ("Admin Action", "AdminCommandCenterScreen", "Two-layer credential validation (Card ID + Pass)", "JWT admin claims, AuditService ledger", "Zone perimeter update, Immutable audit log record")
    ]
    for r_idx, row in enumerate(matrix_data):
        for c_idx, val in enumerate(row):
            t_matrix.cell(r_idx, c_idx).text = val
    format_table(t_matrix, [Inches(1.2), Inches(1.4), Inches(1.8), Inches(1.4), Inches(1.4)], header_bg="4C1D95")

    output_docx = "SheShield_Module_By_Module_Technical_Documentation.docx"
    doc.save(output_docx)
    print(f"Successfully generated {output_docx}!")

if __name__ == "__main__":
    build_module_documentation()
