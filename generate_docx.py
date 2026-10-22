import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def format_docx_table(table, col_widths, header_bg="4C1D95", alt_bg="F5F3FF"):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    # Header row
    for idx, cell in enumerate(table.rows[0].cells):
        set_cell_background(cell, header_bg)
        set_cell_margins(cell, top=120, bottom=120, left=150, right=150)
        for p in cell.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for run in p.runs:
                run.font.bold = True
                run.font.color.rgb = RGBColor(255, 255, 255)
                run.font.name = "Arial"
                run.font.size = Pt(10)
    
    # Data rows
    for r_idx in range(1, len(table.rows)):
        row = table.rows[r_idx]
        bg = alt_bg if r_idx % 2 == 1 else "FFFFFF"
        for c_idx, cell in enumerate(row.cells):
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=100, bottom=100, left=150, right=150)
            for p in cell.paragraphs:
                for run in p.runs:
                    run.font.name = "Arial"
                    run.font.size = Pt(9.5)
                    run.font.color.rgb = RGBColor(30, 41, 59)
                    
    for row in table.rows:
        for idx, width in enumerate(col_widths):
            row.cells[idx].width = width

def build_docx():
    doc = Document()
    
    # Set standard page margins (0.75 in)
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(0.75)
        section.bottom_margin = Inches(0.75)
        section.left_margin = Inches(0.75)
        section.right_margin = Inches(0.75)
        
    # Set default style font
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Arial'
    font.size = Pt(11)
    font.color.rgb = RGBColor(30, 41, 59)

    # ==========================================
    # COVER PAGE
    # ==========================================
    # University Header
    p_inst = doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r_inst = p_inst.add_run("DHIRUBHAI AMBANI UNIVERSITY\nSchool of Technology & Computer Science\nAutumn Semester 2026")
    r_inst.font.size = Pt(10)
    r_inst.font.bold = True
    r_inst.font.color.rgb = RGBColor(100, 116, 139)

    # University Logo & SheShield Logo side-by-side or stacked
    dau_logo = "extracted_assets/slide_1_shape_5.png"
    shield_logo = "extracted_assets/she_shield_logo.jpg"
    
    p_logo = doc.add_paragraph()
    p_logo.alignment = WD_ALIGN_PARAGRAPH.CENTER
    if os.path.exists(dau_logo):
        p_logo.add_run().add_picture(dau_logo, width=Inches(2.4))
    if os.path.exists(shield_logo):
        p_logo.add_run("     ")
        p_logo.add_run().add_picture(shield_logo, width=Inches(2.0))

    doc.add_paragraph().paragraph_format.space_after = Pt(8)

    # Course & Presentation Title
    p_course = doc.add_paragraph()
    p_course.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_c = p_course.add_run("WSSOA (IT644) : Web Services and Service-Oriented Architecture\nPROJECT PRESENTATION I DOCUMENTATION")
    r_c.font.size = Pt(13)
    r_c.font.bold = True
    r_c.font.color.rgb = RGBColor(219, 39, 119)

    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t = p_title.add_run("SHE SHIELD")
    r_t.font.size = Pt(30)
    r_t.font.bold = True
    r_t.font.color.rgb = RGBColor(76, 29, 149)

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_s = p_sub.add_run("Proactive AI-Powered Women Safety & Emergency Response Ecosystem\n")
    r_s.font.size = Pt(15)
    r_s.font.bold = True
    r_s.font.color.rgb = RGBColor(124, 58, 237)
    r_s2 = p_sub.add_run("A Cross-Platform Smart Safety, Real-Time Geo-Tracking, and Cryptographic Evidence Platform")
    r_s2.font.size = Pt(12)
    r_s2.font.color.rgb = RGBColor(100, 116, 139)

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # Team Members Table
    p_subm = doc.add_paragraph()
    r_subm = p_subm.add_run("Submitted By:")
    r_subm.font.bold = True
    r_subm.font.size = Pt(12)
    r_subm.font.color.rgb = RGBColor(76, 29, 149)

    table = doc.add_table(rows=9, cols=3)
    team_data = [
        ("Sr. No.", "Student Name", "Student ID"),
        ("1", "Diya Jain", "202512014"),
        ("2", "Piyush Tanwani", "202512021"),
        ("3", "Divyesh Dandwani", "202512043"),
        ("4", "Harshil Dodwani", "202512044"),
        ("5", "Vivek Dhanwani", "202512045"),
        ("6", "Yash Gangwani", "202512048"),
        ("7", "Aman Rohera", "202512049"),
        ("8", "Priya Shah", "202512100")
    ]
    for r_idx, row in enumerate(team_data):
        for c_idx, val in enumerate(row):
            table.cell(r_idx, c_idx).text = val
    format_docx_table(table, [Inches(1.0), Inches(3.6), Inches(2.4)])

    doc.add_page_break()

    # ==========================================
    # EXECUTIVE SUMMARY & ARCHITECTURAL ABSTRACT
    # ==========================================
    h1 = doc.add_heading("1. Executive Summary & Architectural Overview", level=1)
    h1.runs[0].font.color.rgb = RGBColor(76, 29, 149)

    p_ab = doc.add_paragraph(
        "SHE SHIELD is a comprehensive, cyber-integrated personal safety ecosystem engineered to proactively prevent distress, "
        "eliminate panic latency, and establish tamper-proof forensic accountability for women. While traditional emergency "
        "applications rely strictly on manual touch actions (which are frequently unfeasible during acute physical confrontations), "
        "SheShield incorporates multi-modal stealth triggering mechanisms—including Bluetooth Low Energy (BLE) wearable pendants, "
        "offline secret voice phrase detection ('capcap'), and hardware button combinations that operate silently with zero screen illumination.\n\n"
        "Beyond reactive distress signaling, SheShield features continuous journey intelligence via the 'Cab Guardian' and 'Walk Guardian' "
        "modules. These microservices monitor real-time vehicle trajectories against expected polylines, automatically flagging unauthorized route "
        "deviations, nocturnal isolation, and proximity to historical crime hotspots. Concurrently, all captured telemetry, audio, and video "
        "streams are notarized within a cryptographic Evidence Locker via SHA-256 digital hashing, establishing an immutable chain of custody "
        "admissible in judicial proceedings. By synthesizing cross-platform Flutter clients with Python Flask microservices, Cloud Firestore, "
        "and integration hooks for national emergency frameworks (ERSS-112, CCTNS, CERT-In), SheShield bridges the critical gap between "
        "distressed citizens, family guardians, and public safety agencies."
    )
    p_ab.paragraph_format.line_spacing = 1.15
    p_ab.paragraph_format.space_after = Pt(14)

    # Document Structure Note Box
    t_box = doc.add_table(rows=1, cols=1)
    set_cell_background(t_box.cell(0, 0), "F5F3FF")
    set_cell_margins(t_box.cell(0, 0), top=120, bottom=120, left=180, right=180)
    p_box = t_box.cell(0, 0).paragraphs[0]
    r_box = p_box.add_run(
        "Document Purpose & Format Alignment:\nThis document serves as the comprehensive slide deck specification, architectural blueprint, "
        "and speaker companion for WSSOA (IT644) Project Presentation I. Each of the following sections corresponds directly to the 12 slides "
        "of the accompanying SheShield PowerPoint presentation, detailing the visual layout, tabular matrices, high-resolution architecture "
        "diagrams, technical implementation mapping, and verbatim speaker presentation notes."
    )
    r_box.font.size = Pt(10)
    r_box.font.color.rgb = RGBColor(88, 28, 135)
    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # ==========================================
    # SLIDE-BY-SLIDE PRESENTATION WALKTHROUGH
    # ==========================================
    doc.add_heading("2. Slide-by-Slide Presentation Walkthrough & Technical Details", level=1).runs[0].font.color.rgb = RGBColor(76, 29, 149)

    slides_content = [
        # SLIDE 1
        {
            "slide_num": 1,
            "title": "Title Slide : Course & Project Header",
            "layout": "Two-Column Header with Dhirubhai Ambani University Logo, SheShield Vector Emblem, Title Text, and Registered Team Roster Table.",
            "content": [
                "• Course Title: WSSOA (IT644) Project Presentation I, Autumn 2026",
                "• Project Name: SHE SHIELD — Proactive AI-Powered Women Safety & Emergency Response Ecosystem",
                "• Project Tagline: A cross-platform smart safety, real-time geo-tracking, and cryptographic evidence platform",
                "• Academic Institution: Dhirubhai Ambani University, Gandhinagar, Gujarat",
                "• Submitted By: 8 Team Members (Diya Jain, Piyush Tanwani, Divyesh Dandwani, Harshil Dodwani, Vivek Dhanwani, Yash Gangwani, Aman Rohera, Priya Shah)."
            ],
            "notes": (
                "Good afternoon respected professors and peers. Welcome to our Project Presentation I for IT644 (Web Services and Service-Oriented Architecture). "
                "Our team is proud to introduce 'SheShield'—a proactive, AI-driven women's safety ecosystem engineered to bridge emergency telemetry, "
                "stealth panic alerting, and cryptographic forensic verification into a unified service-oriented architecture."
            ),
            "image": None
        },
        # SLIDE 2
        {
            "slide_num": 2,
            "title": "Slide 2 : Problem Definition (Traditional Journey vs. Inherent Problems)",
            "layout": "Comparative Two-Column Card Grid: 'The Traditional Women's Safety Journey' (5 chronological stages) vs. 'Problems Faced During This Process' (5 acute friction points).",
            "content": [
                "Stage 1: Commuting or Traveling Alone — Navigating isolated corridors, poorly illuminated roadways, or solitary commercial cab rides late at night.",
                "Stage 2: Encountering Threat or Distress — Facing imminent stalking, verbal intimidation, unwarranted physical proximity, or unauthorized vehicle route diversions.",
                "Stage 3: Attempting Emergency Response — Frantically attempting to wake a locked smartphone, enter PIN/biometrics, locate emergency dials, or type distress SMS while in acute panic.",
                "Stage 4: Latency & Coordinate Uncertainty — Family guardians and police receive delayed alerts lacking precise live GPS breadcrumbs, altitude, or ambient acoustic context.",
                "Stage 5: Post-Incident Forensic Hurdles — Recorded phone audio/video is easily confiscated, destroyed, or challenged in judicial courtrooms due to lack of verified chain-of-custody."
            ],
            "table_data": [
                ("Problem Vector", "Real-World Vulnerability", "Consequence in Distress"),
                ("Panic Latency", "Unlocking a mobile screen and opening an app takes 15–30 critical seconds.", "Victims are physically incapacitated before an alert is dispatched."),
                ("Navigation Blindspots", "Standard navigation apps only show maps; they do not detect driver detours.", "Stalking and abduction routes proceed unnoticed by guardians."),
                ("Fragile Evidence", "Smartphone recordings lack cryptographic seals and are easily wiped by assailants.", "Perpetrators escape conviction due to inadmissible evidence in court."),
                ("Fragmented Silos", "Family members, nearby civic volunteers, and ERSS-112 operate without a common picture.", "Conflicting response efforts and fatal dispatch delays occur."),
                ("Cyber Harassment", "Digital blackmail, extortion, and image morphing lack immediate threat triage.", "Victims suffer ongoing trauma without automated legal filing.")
            ],
            "notes": (
                "When analyzing the real-world trajectory of personal distress, we identified five critical breaking points. The most devastating is 'Panic Latency': "
                "requiring a victim to unlock their phone, navigate to an emergency dialer, and speak aloud is fundamentally flawed during an attack. "
                "Furthermore, existing navigation software treats transit passively—failing to notify family members when a cab deviates from its route. "
                "Finally, evidence collected on personal devices is often destroyed or dismissed in court due to broken chain-of-custody. SheShield resolves each vector."
            ),
            "image": None
        },
        # SLIDE 3
        {
            "slide_num": 3,
            "title": "Slide 3 : Proposed Solution (Core Architectural Pillars & Outcomes)",
            "layout": "Central Definition Banner, 2x2 Grid of Rounded Feature Cards, and Full-Width Bottom 'Expected Outcome' Ribbon.",
            "content": [
                "1. Multi-Modal Emergency SOS & Stealth Triggers: Initiates instant alerts via concealed Bluetooth LE wearable buttons, offline voice phrase recognition ('capcap'), power/volume double clicks, or silent mode with zero screen backlight.",
                "2. Real-Time Travel & Geo-Fencing Guardian: Continuous background 'Cab Guardian' and 'Walk Guardian' calculating route deviations, offset thresholds, nocturnal safety indexes, and live guardian breadcrumbs.",
                "3. Tamper-Proof Digital Evidence Vault: Automatic background audio/video recording immediately notarized via SHA-256 cryptographic hashing to guarantee courtroom legal admissibility.",
                "4. Unified Multi-Role Command & Response Network: Dedicated situational consoles for At-Risk Users, Linked Family Guardians, ERSS-112 Emergency Responders, and Police Administrators.",
                "Expected Outcome: Compresses emergency dispatch latency from minutes to milliseconds, prevents transit deviations proactively, provides discreet stealth defense, and ensures incontrovertible forensic evidence."
            ],
            "notes": (
                "Our proposed solution, SheShield, re-engineers women's safety around proactive defense rather than reactive desperation. "
                "First, we decentralize triggers across discreet hardware wearables, offline voice recognition, and physical button presses. "
                "Second, our Travel Guardian actively monitors cab routes, alerting guardians the moment a vehicle veers off track. "
                "Third, all captured evidence is instantly hashed with SHA-256 algorithms before cloud upload, creating an unalterable forensic record. "
                "Finally, our service-oriented backend synchronizes users, guardians, and civic police into a single real-time operational grid."
            ),
            "image": None
        },
        # SLIDE 4
        {
            "slide_num": 4,
            "title": "Slide 4 : System Workflow (End-to-End Incident Lifecycle)",
            "layout": "Left: High-Resolution Workflow Flowchart Graphic. Right: Structured Summary of 6 Key Architectural Stages and Dual Bottom Pillars.",
            "content": [
                "Stage 1: Threat Detection & Stealth Trigger — Multi-channel ingestion from BLE wearable buttons, whisper-level voice recognition ('capcap'), volume/power double-clicks, or tactile screen controls.",
                "Stage 2: Edge Telemetry & Location Ingestion — Instant GPS coordinate acquisition, device battery telemetry, local offline coordinate caching, and geohash indexing.",
                "Stage 3: Multi-Tier Alert Dispatch Engine — Concurrent dispatch of high-priority WebSocket alerts to family guardians and background SMS fallback queues containing Google Maps URLs.",
                "Stage 4: AI Risk Assessment & Geo-Spatial Analytics — Edge & cloud evaluation of nocturnal risk factors, street illumination indexes, route deviation calculations, and crime hotspot cross-matching.",
                "Stage 5: Cryptographic Evidence Preservation — Continuous background audio/video recording streaming directly to the Evidence Locker, stamped with immutable SHA-256 cryptographic signatures.",
                "Stage 6: Responder Command Center & Live Routing — Live GPS breadcrumb tracking, responder dispatch routing, incident triage, and court-ready dossier compilation."
            ],
            "notes": (
                "Slide 4 illustrates our end-to-end incident lifecycle. When a distress trigger occurs—whether via a hidden BLE wearable ring or voice detection—"
                "the edge client immediately captures telemetry, writes coordinates to local storage in case network drops, and fires both WebSocket alerts "
                "and an SMS fallback. Meanwhile, our geo-spatial engine calculates route offsets, and the blackbox evidence recorder stamps audio/video files "
                "with cryptographic SHA-256 digests. Both family guardians and police dispatchers view the live breadcrumbs simultaneously on their respective consoles."
            ),
            "image": "extracted_assets/she_shield_workflow.png"
        },
        # SLIDE 5
        {
            "slide_num": 5,
            "title": "Slide 5 : Project Scope (In-Scope, Out-of-Scope & System Boundaries)",
            "layout": "Two Prominent Colored Cards: In-Scope (Lavender) vs. Out-of-Scope (Rose-Tinted), anchored by a bottom Project Boundary statement.",
            "content": [
                "In Scope :",
                "• Multi-modal SOS dispatch (BLE wearable buttons, secret voice phrases, hardware keys, tactile UI).",
                "• High-precision GPS tracking, breadcrumb history, and offline coordinate caching with automated SMS fallback.",
                "• Cab Guardian & Walk Guardian modules featuring dynamic route deviation calculation and offset warnings.",
                "• AI Unsafe Zone Engine computing nocturnal composite risk scores based on time, lighting, and historical crime clusters.",
                "• Cryptographic Evidence Locker generating SHA-256 digital digests for tamper-proof audio/video assets.",
                "• Role-based portals: User Dashboard, Family Guardian Portal, Emergency Responder Hub, Police Admin Center.",
                "• Cyber Crime Reporting suite with automated NLP threat assessment, screenshot ingest, and complaint tracking.",
                "• Architectural integration hooks for ERSS-112, CCTNS police records, and CERT-In cyber threat databases.",
                "Out of Scope :",
                "• Physical armed deployment or field tactical command of law enforcement personnel.",
                "• Proprietary semiconductor or silicon IoT hardware manufacturing (utilizes commercial Bluetooth LE standards).",
                "• Formal courtroom litigation, judicial prosecution, or legal sentencing.",
                "• Guaranteed real-time tracking in deep subterranean basements entirely devoid of GNSS, cellular GSM/SMS, or BLE mesh relays.",
                "Project Boundary : SheShield acts as the rapid telemetry, automated alerting, intelligence evaluation, and tamper-proof evidence bridge; on-ground physical rescue and law enforcement remain under authorized civic agencies."
            ],
            "notes": (
                "Slide 5 clearly demarcates our project boundary. SheShield provides the intelligence, alerting, telemetry synchronization, and cryptographic "
                "evidence preservation framework. We intentionally do not manufacture proprietary silicon—leveraging open BLE and standard smartphone sensors. "
                "Similarly, on-ground tactical deployment and judicial adjudication remain within the jurisdictional authority of civic police and courts."
            ),
            "image": None
        },
        # SLIDE 6
        {
            "slide_num": 6,
            "title": "Slide 6 : System Architecture (Service-Oriented Tier Breakdown)",
            "layout": "Left/Top: High-Resolution Architecture Flow Diagram. Right/Bottom: Detailed Descriptions of Presentation, Backend, Application, Data, and Integration Tiers.",
            "content": [
                "• Presentation Tier: Flutter 3.x, Dart, Material 3 theming, Provider state management, and responsive layouts tailored for mobile and command dashboards.",
                "• Backend API Tier: Python Flask REST microservices, Flask-CORS middleware, Firebase Admin SDK, and token-based role verification.",
                "• Application Services Core: SOS Dispatch Engine, Cab Deviation Analyzer, AI Unsafe Zone Evaluator, and Forensic Evidence Hasher.",
                "• Data & Storage Tier: Cloud Firestore for reactive real-time document synchronization, Firebase Storage for encrypted media, and SQLite for offline caching.",
                "• Integration & Telemetry Tier: Architectural hooks for Emergency Response Support System (ERSS-112), CCTNS criminal database, CERT-In cyber threat feed, and Twilio SMS gateways."
            ],
            "notes": (
                "From a Service-Oriented Architecture perspective, SheShield separates concerns cleanly across five decoupled layers. "
                "The presentation layer in Flutter communicates via authenticated REST endpoints and WebSocket listeners with our Python Flask microservices. "
                "The Application Services Core encapsulates our proprietary algorithms—including route offset calculations and SHA-256 hashing. "
                "Underneath, Cloud Firestore ensures microsecond-level synchronization across guardian and police consoles, with fallback hooks to national emergency services."
            ),
            "image": "extracted_assets/she_shield_architecture.png"
        },
        # SLIDE 7
        {
            "slide_num": 7,
            "title": "Slide 7 : Frontend and Backend Technologies Matrix",
            "layout": "Side-by-side Dual Matrices: 6 Frontend Technologies on the Left vs. 6 Backend & AI Technologies on the Right.",
            "content": [
                "Detailed technical justifications for every primary library and tool utilized across the SheShield codebase."
            ],
            "fe_table": [
                ("Technology", "Why It Is Used in SheShield"),
                ("Flutter", "Builds high-performance native user interfaces for Android and iOS using a single unified codebase."),
                ("Dart", "Provides sound type safety and asynchronous event streams essential for emergency telemetry."),
                ("Provider", "Manages reactive state cleanly across SOS countdowns, travel monitoring, and live location updates."),
                ("Material 3", "Creates accessible, high-contrast UI components with responsive glassmorphic cards and buttons."),
                ("Flutter BLE", "Enables low-latency communication with Bluetooth LE panic buttons and wearable smart pendants."),
                ("Geolocator", "Captures high-precision GPS coordinates, breadcrumb paths, and speed telemetry in real time.")
            ],
            "be_table": [
                ("Technology", "Why It Is Used in SheShield"),
                ("Python Flask", "Runs lightweight, scalable REST microservices handling emergency routing and alert dispatch."),
                ("Flask-CORS", "Secures cross-origin API communication between mobile clients, responder maps, and admin consoles."),
                ("Firebase Admin SDK", "Provides privileged server-side access to Cloud Firestore collections and user security rules."),
                ("PyTorch & Transformers", "Powers NLP models to classify cyber harassment severity and assess digital blackmail threats."),
                ("OpenCV", "Processes uploaded forensic evidence screenshots and inspects visual file authenticity."),
                ("hashlib (SHA-256)", "Computes immutable cryptographic digests of recorded evidence to guarantee court admissibility.")
            ],
            "notes": (
                "Slide 7 outlines our technology choices. On the frontend, Flutter and Dart give us a single, type-safe codebase with 60fps rendering, "
                "while Provider coordinates reactive states like the 5-second SOS countdown. On the backend, Python Flask handles lightweight REST endpoints, "
                "Firebase Admin SDK manages granular Firestore permissions, PyTorch evaluates cyber harassment severity, and Python's hashlib generates "
                "SHA-256 cryptographic digests for forensic evidence preservation."
            ),
            "image": None
        },
        # SLIDE 8
        {
            "slide_num": 8,
            "title": "Slide 8 : Database, AI, Data Processing & Integration Matrix",
            "layout": "Comprehensive 12-Row Full-Width Table matching reference Slide 8 layout.",
            "content": [
                "Comprehensive specification of storage engines, AI microservices, background dispatch queues, and government integration adapters."
            ],
            "full_table": [
                ("Technology / Component", "Category", "Why It Is Used in SheShield"),
                ("Cloud Firestore", "Data Storage & Real-Time Sync", "Stores user profiles, SOS alerts, travel sessions, and syncs live telemetry across all roles."),
                ("Firebase Auth", "Authentication & Identity", "Secures multi-role authentication (User, Guardian, Responder, Admin) with biometric support."),
                ("Python (Flask)", "Backend Microservices", "Coordinates emergency dispatch, evidence hashing verification, and external API gateways."),
                ("PyTorch & Transformers", "AI Threat Intelligence", "Evaluates cyber crime complaints using NLP to calculate threat scores (e.g. 92% blackmail)."),
                ("AI Unsafe Zone Service", "Geo-Spatial AI Analytics", "Computes dynamic composite risk scores using time of night, illumination, and crime records."),
                ("Cab Deviation Engine", "Heuristic Route Analytics", "Calculates vehicle route offsets from expected polyline and triggers deviation alerts."),
                ("SHA-256 Crypto Engine", "Evidence Integrity & Forensics", "Generates cryptographic fingerprints for captured audio/video to ensure court admissibility."),
                ("ERSS-112 Integration Hook", "National Emergency Integration", "Connects SheShield alert payloads with India's Emergency Response Support System (112)."),
                ("CCTNS Sync Hook", "Law Enforcement Integration", "Prepares crime dossiers and incident records for Crime and Criminal Tracking Network & Systems."),
                ("CERT-In Webhook Hook", "Cyber Threat Intelligence", "Automates escalation of severe online blackmail, doxxing, and cyber harassment cases."),
                ("Twilio SMS Fallback", "Redundant Emergency Alerting", "Dispatches instant SMS with live Google Maps coordinates when mobile data is offline."),
                ("Docker Compose", "Service Management", "Packages and runs application microservices, databases, and mock government gateways.")
            ],
            "notes": (
                "Slide 8 provides our full stack integration matrix. Notice our dual focus: real-time situational processing via Cloud Firestore and Flask, "
                "paired with deep AI analytics. Our AI Unsafe Zone Engine calculates localized threat scores based on nocturnal factors and crime density, "
                "while our PyTorch NLP models assign threat percentages to cyber complaints. Furthermore, mock integration adapters ensure our schema "
                "is future-ready for national frameworks like ERSS-112 and CCTNS."
            ),
            "image": None
        },
        # SLIDE 9
        {
            "slide_num": 9,
            "title": "Slide 9 : Database Design and Data Management (Schema & Collections)",
            "layout": "Left: High-Resolution Conceptual ER & Document Hierarchy Diagram. Right: 8-Row Collection Purpose Matrix.",
            "content": [
                "Cloud Firestore NoSQL collections organized hierarchically with document-level security rules enforcing role boundaries."
            ],
            "schema_table": [
                ("Table / Collection Name", "Purpose in SheShield"),
                ("User", "Stores user account details, Aadhaar/face verification status, and safety preferences."),
                ("Guardians", "Maintains linked emergency contacts, kinship relations, and notification priority order."),
                ("SOSEvents", "Logs emergency alerts, trigger mechanisms (voice/BLE/button), live GPS, and status."),
                ("TravelTrips", "Records Cab Guardian & Walk Guardian trips, vehicle plates, route offsets, and risk scores."),
                ("EvidenceVault", "Catalogs encrypted audio/video assets alongside SHA-256 hashes for legal chain of custody."),
                ("CyberComplaints", "Archives cyber abuse reports, screenshots, AI threat severity scores, and police status."),
                ("UnsafeZones", "Defines geofenced high-risk corridors, historical incident density, and advisory rules."),
                ("AuditLogs", "Preserves an immutable chronological ledger of administrative actions and SOS events.")
            ],
            "notes": (
                "Slide 9 outlines our data architecture. The root collection is 'User', containing biometric verification flags and role definitions. "
                "Directly linked are 'Guardians', 'SOSEvents', and 'TravelTrips'. Every trip records vehicle plate numbers, destination coordinates, "
                "and cumulative route deviation counts. The 'EvidenceVault' collection stores asset URIs paired with their SHA-256 digest strings, "
                "guaranteeing an auditable, tamper-evident relationship between physical emergency sessions and digital forensic evidence."
            ),
            "image": "extracted_assets/she_shield_database_design.png"
        },
        # SLIDE 10
        {
            "slide_num": 10,
            "title": "Slide 10 : Smart Safety Intelligence and AI Capabilities",
            "layout": "Top/Center: Comprehensive Tree Diagram mapping Sensor Inputs -> AI Engines -> Response Vectors. Bottom: Core Intelligence Capabilities Summary.",
            "content": [
                "1. Multi-Modal Stealth Trigger Intelligence: Local acoustic feature matching listening for user-defined phrases ('capcap', 'Box Box') without cloud latency, coupled with BLE beacon proximity detection.",
                "2. Predictive Geo-Spatial Risk Scoring: Evaluates dynamic user telemetry against localized factors: nocturnal hours (10 PM+), street lighting deficiency, isolated route vectors, and historical police crime hotspots.",
                "3. Heuristic Cab Deviation & Stalking Engine: Calculates continuous Haversine distance offsets between vehicle GPS and polyline path; triggers automatic warning alarms and guardian notifications upon threshold breach (e.g. 30m offset).",
                "4. NLP-Driven Cyber Threat Assessment: Analyzes digital harassment, blackmail messages, and extortion screenshots using transformer models, outputting quantified threat indices (e.g. 92% Critical) and auto-generating police complaint PDFs.",
                "5. Cryptographic Evidence Chain-of-Custody: Client-side SHA-256 hashing executed at the moment of recording completion, preventing any claim of video/audio tampering during criminal court proceedings."
            ],
            "notes": (
                "Slide 10 dives into our AI and intelligence architecture. Rather than relying on simple static buttons, SheShield operates "
                "continuous intelligence engines. Our offline voice recognition detects secret trigger phrases locally on the edge device, "
                "ensuring rapid execution even without an active data connection. In transit, our Cab Deviation Engine computes real-time "
                "route offsets, warning guardians before an abduction or detour can escalate. Finally, our NLP model triages cyber harassment "
                "complaints, categorizing threats and generating structured police dossiers automatically."
            ),
            "image": "extracted_assets/she_shield_intelligence.png"
        },
        # SLIDE 11
        {
            "slide_num": 11,
            "title": "Slide 11 : Challenges Faced and System Limitations",
            "layout": "Comparative Two-Section Layout: Left Table of 6 Technical Challenges & Engineering Mitigations vs. Right Card of 5 Inherent System Limitations.",
            "content": [
                "Comprehensive reflection on development hurdles, production constraints, and engineering resolutions."
            ],
            "challenges_table": [
                ("Challenge Encountered", "Technical Resolution in SheShield"),
                ("Low / Intermittent Cellular Coverage", "Implemented SQLite offline coordinate caching and automated SMS fallback queues with Google Maps links."),
                ("Accidental / False SOS Triggers", "Engineered a 5-second cancellable audio-haptic countdown timer with high-contrast cancellation controls."),
                ("Urban GPS Signal Drift & Multipath", "Applied Kalman filtering to smooth breadcrumbs and established a calibrated 30m deviation tolerance window."),
                ("Mobile OS Background App Killing", "Configured Android Foreground Services with persistent notifications and wakelocks during active trips."),
                ("Forensic Evidence Court Admissibility", "Automated client-side SHA-256 cryptographic hashing immediately upon ingest to eliminate tampering claims."),
                ("Multi-Stakeholder Alert Congestion", "Designed strict role-based Firestore listeners to synchronize users, guardians, and police without duplicate notifications.")
            ],
            "limitations_list": [
                ("Hardware Battery Dependency:", "Stealth BLE wearable buttons and smart pendants require periodic charging and active pairing range."),
                ("Cellular SMS Network Latency:", "Delivery speed of emergency SMS alerts depends on local telecom network congestion and carrier signal strength."),
                ("Civic ERSS-112 API Readiness:", "Direct digital dispatch into police terminals relies on civic emergency API availability and official authorization."),
                ("Severe Ambient Acoustic Noise:", "Extreme industrial or construction noise can occasionally impede whisper-level voice recognition."),
                ("Route Polyline Granularity:", "Cab deviation alerts depend on the precision of baseline map routing and accurate destination inputs.")
            ],
            "notes": (
                "Slide 11 provides a candid engineering evaluation of our challenges and limitations. Operating in life-safety environments requires "
                "addressing mobile OS constraints: we implemented Android foreground services to prevent background termination during trips. "
                "To mitigate accidental triggers, we built a 5-second cancellable timer. Furthermore, we recognize system boundaries: emergency SMS "
                "is subject to telecom latency, and stealth BLE wearables depend on battery charge. By acknowledging these constraints, we designed "
                "multi-layered fallbacks throughout the system."
            ),
            "image": None
        },
        # SLIDE 12
        {
            "slide_num": 12,
            "title": "Slide 12 : Conclusion, Roadmap & Acknowledgments (Thank You)",
            "layout": "Centered University & Project Emblems, Presentation Concluding Remarks, Future Roadmap Highlights, and Q&A Invitation.",
            "content": [
                "• Future Roadmap: Autonomous drone dispatch integration for nocturnal corridors, zero-knowledge biometric verification for anonymous reporting, decentralized blockchain evidence notarization, and municipal CCTV smart-city integration.",
                "• Summary Conclusion: SheShield bridges technology and social impact, offering a proactive, multi-modal, and court-admissible safety infrastructure for women.",
                "• Team & Course: WSSOA (IT644) Autumn 2026, Dhirubhai Ambani University, Gandhinagar, Gujarat.",
                "• Floor Open for Evaluator Questions & Answers."
            ],
            "notes": (
                "In conclusion, SheShield transforms women's safety from passive hope to proactive, verifiable protection. "
                "We thank our course instructors and university evaluators for their guidance throughout this project. "
                "We are now ready and excited to take your questions and provide a live demonstration of our Flutter application, "
                "Flask microservices, and cryptographic evidence vault. Thank you!"
            ),
            "image": None
        }
    ]

    for item in slides_content:
        h2 = doc.add_heading(f"Slide {item['slide_num']}: {item['title']}", level=2)
        h2.runs[0].font.color.rgb = RGBColor(76, 29, 149)

        # Meta info
        p_meta = doc.add_paragraph()
        r_l_lbl = p_meta.add_run("Visual Layout & Design: ")
        r_l_lbl.font.bold = True
        p_meta.add_run(item['layout'] + "\n")

        # Slide Content Bullet Points
        p_c_lbl = doc.add_paragraph()
        p_c_lbl.add_run("Slide Content & Visual Elements:").font.bold = True
        for point in item['content']:
            doc.add_paragraph(point, style='List Bullet')

        # Tables if present
        if 'table_data' in item:
            t = doc.add_table(rows=len(item['table_data']) + 1, cols=3)
            headers = ["Problem Vector", "Real-World Vulnerability", "Consequence in Distress"]
            for c_idx, h in enumerate(headers):
                t.cell(0, c_idx).text = h
            for r_idx, row in enumerate(item['table_data']):
                for c_idx, val in enumerate(row):
                    t.cell(r_idx + 1, c_idx).text = val
            format_docx_table(t, [Inches(1.8), Inches(2.6), Inches(2.6)])
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

        if 'fe_table' in item:
            p_fe = doc.add_paragraph()
            p_fe.add_run("Frontend Technologies Matrix:").font.bold = True
            t_fe = doc.add_table(rows=len(item['fe_table']), cols=2)
            for r_idx, row in enumerate(item['fe_table']):
                for c_idx, val in enumerate(row):
                    t_fe.cell(r_idx, c_idx).text = val
            format_docx_table(t_fe, [Inches(2.0), Inches(5.0)])
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

            p_be = doc.add_paragraph()
            p_be.add_run("Backend & AI Technologies Matrix:").font.bold = True
            t_be = doc.add_table(rows=len(item['be_table']), cols=2)
            for r_idx, row in enumerate(item['be_table']):
                for c_idx, val in enumerate(row):
                    t_be.cell(r_idx, c_idx).text = val
            format_docx_table(t_be, [Inches(2.0), Inches(5.0)], header_bg="BE185D")
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

        if 'full_table' in item:
            t_full = doc.add_table(rows=len(item['full_table']), cols=3)
            for r_idx, row in enumerate(item['full_table']):
                for c_idx, val in enumerate(row):
                    t_full.cell(r_idx, c_idx).text = val
            format_docx_table(t_full, [Inches(2.2), Inches(2.2), Inches(2.6)])
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

        if 'schema_table' in item:
            t_sch = doc.add_table(rows=len(item['schema_table']), cols=2)
            for r_idx, row in enumerate(item['schema_table']):
                for c_idx, val in enumerate(row):
                    t_sch.cell(r_idx, c_idx).text = val
            format_docx_table(t_sch, [Inches(2.0), Inches(5.0)])
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

        if 'challenges_table' in item:
            p_cht = doc.add_paragraph()
            p_cht.add_run("Challenges Faced & Engineering Resolutions:").font.bold = True
            t_ch = doc.add_table(rows=len(item['challenges_table']), cols=2)
            for r_idx, row in enumerate(item['challenges_table']):
                for c_idx, val in enumerate(row):
                    t_ch.cell(r_idx, c_idx).text = val
            format_docx_table(t_ch, [Inches(2.5), Inches(4.5)])
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

            p_lim = doc.add_paragraph()
            p_lim.add_run("System Limitations:").font.bold = True
            for title, desc in item['limitations_list']:
                p_l = doc.add_paragraph(style='List Bullet')
                r_lt = p_l.add_run(title + " ")
                r_lt.font.bold = True
                p_l.add_run(desc)
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

        # Embedded Image if present
        if item['image'] and os.path.exists(item['image']):
            p_img = doc.add_paragraph()
            p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_img.add_run().add_picture(item['image'], width=Inches(5.5))
            p_cap = doc.add_paragraph()
            p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r_cap = p_cap.add_run(f"Figure: Architecture / Workflow Diagram for Slide {item['slide_num']}")
            r_cap.font.size = Pt(9.5)
            r_cap.font.italic = True
            r_cap.font.color.rgb = RGBColor(100, 116, 139)
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

        # Speaker Presentation Script Box
        t_note = doc.add_table(rows=1, cols=1)
        set_cell_background(t_note.cell(0, 0), "F3E8FF") # Soft purple
        set_cell_margins(t_note.cell(0, 0), top=100, bottom=100, left=150, right=150)
        p_note = t_note.cell(0, 0).paragraphs[0]
        r_n_hdr = p_note.add_run("Verbatim Speaker Presentation Script (What to say):\n")
        r_n_hdr.font.bold = True
        r_n_hdr.font.size = Pt(9.5)
        r_n_hdr.font.color.rgb = RGBColor(107, 33, 168)
        r_n_txt = p_note.add_run('"' + item['notes'] + '"')
        r_n_txt.font.italic = True
        r_n_txt.font.size = Pt(9.5)
        r_n_txt.font.color.rgb = RGBColor(55, 48, 163)

        doc.add_paragraph().paragraph_format.space_after = Pt(14)

    # ==========================================
    # APPENDIX: CODEBASE & ARCHITECTURAL MAPPING
    # ==========================================
    doc.add_page_break()
    h_app = doc.add_heading("3. Technical Implementation & Codebase Mapping Appendix", level=1)
    h_app.runs[0].font.color.rgb = RGBColor(76, 29, 149)

    p_app_intro = doc.add_paragraph(
        "The following matrix maps the presentation components directly to the implemented source code modules within "
        "the SheShield project repository, demonstrating concrete architectural adherence."
    )
    p_app_intro.paragraph_format.space_after = Pt(10)

    t_map = doc.add_table(rows=9, cols=3)
    map_data = [
        ("Presentation Feature", "Implemented Code File / Service", "Technical Architectural Role"),
        ("Multi-Modal SOS Triggers", "lib/screens/sos_screens.dart\nlib/services/sos_service.dart", "State management for 5s cancellable countdown, volume trigger & silent dispatch."),
        ("Travel & Cab Guardian", "lib/screens/travel_monitor_screen.dart\nlib/services/database_service.dart", "Active route tracking, 30m offset deviation engine & ambient evidence modal."),
        ("AI Unsafe Zone Evaluation", "lib/services/ai_unsafe_zone.dart", "Heuristic risk score calculation based on nocturnal hours & historical hotspots."),
        ("Cryptographic Evidence Vault", "lib/screens/evidence_vault_screens.dart\nbackend/app.py", "Background blackbox video capture & SHA-256 digital hashing for legal proof."),
        ("Cyber Crime Reporting", "lib/screens/cyber_screens.dart\nbackend/app.py", "NLP threat severity scoring, screenshot upload & structured complaint triage."),
        ("Police / Responder Console", "lib/screens/responder_dashboard_screen.dart\nlib/screens/police_admin_screens.dart", "Emergency case queue, real-time GPS breadcrumb map & responder status."),
        ("Admin Command Center", "lib/screens/admin_command_center_screen.dart\nlib/services/admin_service.dart", "Two-layer credential authentication, audit log viewer & zone perimeter control."),
        ("Government Integration Hooks", "backend/app.py (lines 48–87)", "Future-ready REST endpoints for ERSS-112, CCTNS database & CERT-In webhooks.")
    ]
    for r_idx, row in enumerate(map_data):
        for c_idx, val in enumerate(row):
            t_map.cell(r_idx, c_idx).text = val
    format_docx_table(t_map, [Inches(1.8), Inches(2.7), Inches(2.5)])

    # Output file
    output_docx = "SheShield_Project_Presentation.docx"
    doc.save(output_docx)
    print(f"Successfully generated {output_docx}!")

if __name__ == "__main__":
    build_docx()
