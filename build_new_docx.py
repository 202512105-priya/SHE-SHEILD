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

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def format_docx_table(table, col_widths, header_bg="4C1D95", alt_bg="F5F3FF"):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
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
    for section in doc.sections:
        section.top_margin = Inches(0.75)
        section.bottom_margin = Inches(0.75)
        section.left_margin = Inches(0.75)
        section.right_margin = Inches(0.75)

    style = doc.styles['Normal']
    font = style.font
    font.name = 'Arial'
    font.size = Pt(11)
    font.color.rgb = RGBColor(30, 41, 59)

    # ==========================================
    # COVER PAGE
    # ==========================================
    p_inst = doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r_inst = p_inst.add_run("DHIRUBHAI AMBANI UNIVERSITY\nSchool of Technology & Computer Science\nAutumn Semester 2026")
    r_inst.font.size = Pt(10)
    r_inst.font.bold = True
    r_inst.font.color.rgb = RGBColor(100, 116, 139)

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

    p_course = doc.add_paragraph()
    p_course.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_c = p_course.add_run("WSSOA (IT644) : Web Services and Service-Oriented Architecture\nPROJECT PRESENTATION I SPECIFICATION & SLIDE DECK COMPANION")
    r_c.font.size = Pt(12)
    r_c.font.bold = True
    r_c.font.color.rgb = RGBColor(190, 24, 93)

    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t = p_title.add_run("SHE SHIELD")
    r_t.font.size = Pt(28)
    r_t.font.bold = True
    r_t.font.color.rgb = RGBColor(76, 29, 149)

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_s = p_sub.add_run("Cyber-Integrated Safety Platform for Women\n")
    r_s.font.size = Pt(15)
    r_s.font.bold = True
    r_s.font.color.rgb = RGBColor(124, 58, 237)
    r_s2 = p_sub.add_run("A Proactive, Multi-Modal Emergency Dispatch and Cryptographic Forensic Ecosystem")
    r_s2.font.size = Pt(11.5)
    r_s2.font.color.rgb = RGBColor(100, 116, 139)

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    p_subm = doc.add_paragraph()
    r_subm = p_subm.add_run("Project Team Credentials & Engineering Roles:")
    r_subm.font.bold = True
    r_subm.font.size = Pt(11.5)
    r_subm.font.color.rgb = RGBColor(76, 29, 149)

    table = doc.add_table(rows=9, cols=3)
    team_data = [
        ("Sr. No.", "Team Member", "Specific Engineering Role"),
        ("1", "Krisha Doshi", "Mobile UI Engineering (Flutter / Material 3)"),
        ("2", "Priya Shah", "Navigation & User Flow (Routing & State)"),
        ("3", "Jainam Shah", "Backend APIs (Flask REST Microservices)"),
        ("4", "Maahir Shah", "Database (PostgreSQL / Redis / Firestore)"),
        ("5", "Hitarth Shah", "AI Threat Models (PyTorch & NLP Classifier)"),
        ("6", "Jay Shah", "DevOps & Integration (Docker, CI/CD & Gateways)"),
        ("7", "Nirmal Patel", "Auth / RBAC (JWT & Role Permissions)"),
        ("8", "Jenil Shah", "Cybersecurity (SHA-256 Vault & AES Encryption)")
    ]
    for r_idx, row in enumerate(team_data):
        for c_idx, val in enumerate(row):
            table.cell(r_idx, c_idx).text = val
    format_docx_table(table, [Inches(0.9), Inches(2.6), Inches(3.5)])

    doc.add_page_break()

    # ==========================================
    # EXECUTIVE SUMMARY & SYSTEM ABSTRACT
    # ==========================================
    doc.add_heading("1. Executive Summary & System Abstract", level=1).runs[0].font.color.rgb = RGBColor(76, 29, 149)

    p_ab = doc.add_paragraph(
        "SHE SHIELD is an enterprise-grade, cyber-integrated personal safety ecosystem engineered to address the dual challenges "
        "faced by women in modern society: physical vulnerability during transit and digital vulnerability via cyber harassment, blackmail, "
        "and online abuse. While legacy personal safety applications function strictly as passive GPS dialers—requiring victims to unlock screens "
        "and navigate complex interfaces during acute physical distress—SheShield re-engineers emergency response around multi-modal stealth "
        "triggers, sub-2-second parallel broadcasting, and automated forensic evidence notarization.\n\n"
        "Architected as a 4-Tier Service-Oriented Framework, SheShield couples a responsive Flutter mobile client and React.js command portal "
        "with Python Flask microservices, PyTorch NLP threat intelligence, Tesseract/EasyOCR screenshot ingestion, PostgreSQL relational storage, "
        "and Redis in-memory pub/sub streaming. Furthermore, every recorded evidence stream and uploaded cyber threat asset is cryptographically "
        "hashed via client-side SHA-256 digests and encrypted with AES-256-GCM, establishing an unalterable chain-of-custody admissible in legal courts "
        "under Section 65B of the Indian Evidence Act."
    )
    p_ab.paragraph_format.line_spacing = 1.15
    p_ab.paragraph_format.space_after = Pt(12)

    # Document purpose note box
    t_box = doc.add_table(rows=1, cols=1)
    set_cell_background(t_box.cell(0, 0), "F5F3FF")
    set_cell_margins(t_box.cell(0, 0), top=120, bottom=120, left=180, right=180)
    p_box = t_box.cell(0, 0).paragraphs[0]
    r_box = p_box.add_run(
        "Document Purpose & Format Alignment:\nThis document serves as the comprehensive slide deck specification, architectural blueprint, "
        "and speaker companion for WSSOA (IT644) Project Presentation I. Each of the following sections corresponds directly to the 12 slides "
        "of the SheShield PowerPoint presentation, detailing the visual layout, tabular matrices, high-resolution architecture "
        "diagrams, technical implementation mapping, and verbatim speaker presentation notes."
    )
    r_box.font.size = Pt(10)
    r_box.font.color.rgb = RGBColor(88, 28, 135)
    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # ==========================================
    # SLIDE-BY-SLIDE COMPLETE PRESENTATION
    # ==========================================
    doc.add_heading("2. Slide-by-Slide Complete Presentation Walkthrough", level=1).runs[0].font.color.rgb = RGBColor(76, 29, 149)

    slides = [
        # Slide 1
        {
            "num": 1,
            "title": "Slide 1: Title & Team Credentials",
            "layout": "Header with Course, Title, Tagline, Dhirubhai Ambani University Logo, SheShield Vector Logo, and full 8-member Team Credentials Table.",
            "points": [
                "• Course: WSSOA (IT644) Project Presentation I, Autumn 2026, Dhirubhai Ambani University.",
                "• Title: SHE SHIELD — Cyber-Integrated Safety Platform for Women.",
                "• Subtitle: A Proactive, Multi-Modal Emergency Dispatch and Cryptographic Forensic Ecosystem.",
                "• Team Members & Roles: Krisha Doshi (Mobile UI Engineering), Priya Shah (Navigation & User Flow), Jainam Shah (Backend APIs), Maahir Shah (Database), Hitarth Shah (AI Threat Models), Jay Shah (DevOps & Integration), Nirmal Patel (Auth/RBAC), Jenil Shah (Cybersecurity)."
            ],
            "notes": (
                "Good afternoon respected professors and evaluators. Welcome to our Project Presentation I for IT644 (Web Services and Service-Oriented Architecture). "
                "Our team is proud to present 'SHE SHIELD'—a cyber-integrated safety platform for women. "
                "Our team of eight has divided core engineering responsibilities across mobile UI, navigation, backend microservices, database, AI threat modeling, DevOps, RBAC authentication, and cybersecurity to deliver an enterprise-grade life-safety solution."
            ),
            "image": None
        },
        # Slide 2
        {
            "num": 2,
            "title": "Slide 2: Problem Definition & Market Gaps",
            "layout": "Tri-Card Problem Analysis with Comparative Evaluation of Existing Market Failures.",
            "points": [
                "1. Single-Vector Focus (Physical vs Cyber): Existing apps only offer simple panic buttons and ignore cyber harassment, doxxing, sextortion, and online blackmail which affect millions of women.",
                "2. Acute Stress & Panic Latency: Victims under physical or psychological distress cannot unlock phones, enter biometrics, or navigate complex apps; stealth hardware and voice triggers are completely missing.",
                "3. Digital Evidence Destruction: Threat messages and blackmail chats are easily deleted or wiped using disappearing messaging features before victims can report them to the police; smartphone screenshots lack cryptographic integrity for court admissibility."
            ],
            "notes": (
                "Slide 2 exposes three critical market gaps in current women safety solutions. First, almost all existing applications focus solely on physical panic buttons, "
                "completely overlooking digital violence such as online harassment, doxxing, and extortion. Second, requiring a distressed victim to unlock a screen and navigate an app "
                "creates fatal panic latency. Third, digital threats are easily erased before law enforcement intervention, leaving victims without admissible evidence under Section 65B of the Evidence Act."
            ),
            "image": None
        },
        # Slide 3
        {
            "num": 3,
            "title": "Slide 3: Proposed Solution — The SHE SHIELD Ecosystem",
            "layout": "Tri-Pillar Solution Architecture Cards with Bottom Ecosystem Outcome Banner.",
            "points": [
                "• Pillar 1: Physical Emergency SOS Center + Real-Time Transit Tracking — Multi-modal stealth triggers (BLE wearable button, voice phrase 'capcap', volume/power combo), sub-2-second parallel dispatch, and Cab/Walk Guardian route deviation monitoring (>30m offset).",
                "• Pillar 2: AI-Powered Cybercrime Desk with OCR Screenshot Scanning — Automated OCR ingestion parsing threat screenshots, PyTorch NLP model calculating harassment threat indices (e.g. 92% Critical), and structured police complaint PDF generation.",
                "• Pillar 3: Tamper-Proof Cryptographic Evidence Vault — Continuous background blackbox audio/video recording, client-side SHA-256 digital hashing prior to cloud upload, and AES-256-GCM authenticated encryption for legal chain of custody."
            ],
            "notes": (
                "SheShield resolves these failures through three integrated pillars. In Pillar 1, our Physical SOS Center enables discreet sub-2-second alerting via BLE wearables or voice phrases, "
                "while Cab Guardian actively detects route diversions. In Pillar 2, our AI-powered Cybercrime Desk scans threat screenshots via OCR and assigns an NLP danger score. "
                "In Pillar 3, our Evidence Vault notarizes all audio, video, and screenshot evidence with SHA-256 hashes and AES-256 encryption, ensuring immutable proof for police and judicial proceedings."
            ),
            "image": None
        },
        # Slide 4
        {
            "num": 4,
            "title": "Slide 4: Stakeholders & User Roles (RBAC)",
            "layout": "Embedded RBAC Persona Flowchart Diagram and 4-Role Privilege Matrix Table.",
            "points": [
                "• Women / Primary User: Initiates stealth SOS triggers (<=2s), manages Cab/Walk Guardian, submits cyber harassment complaints, and accesses personal Evidence Vault.",
                "• Trusted Guardians: Receives real-time GPS waypoint streams, automated route deviation push alerts (>30m), automated SMS fallback links, and safe arrival confirmations.",
                "• Police / Emergency Responders: Accesses live emergency incident radar, victim medical/biometric profiles, route breadcrumbs, and court-ready incident dossiers.",
                "• System Administrators: Manages RBAC role assignments, high-risk unsafe zone polygons, immutable audit logs, and AI threat model calibration."
            ],
            "table_data": [
                ("Role Persona", "Primary System Privileges", "Security & Access Scope"),
                ("Women / Primary User", "Stealth SOS dispatch, Cab & Walk Guardian, Cybercrime reporting, Personal Vault access.", "Full read/write of own telemetry, contacts, and personal cryptographic evidence."),
                ("Trusted Guardians", "Receive real-time waypoint streams, route deviation push alerts, automated SMS links.", "Scoped read-only access to linked user's active SOS sessions and live transit breadcrumbs."),
                ("Police / Emergency Responders", "View live emergency case map, prioritize incidents, inspect victim profile & court dossier.", "Authorized access to active emergency distress sessions within geographic jurisdiction."),
                ("System Administrators", "Manage RBAC roles, audit log viewer, unsafe zone polygons, AI threat model parameters.", "Administrative system control, platform compliance, security monitoring, and server health.")
            ],
            "notes": (
                "Slide 4 details our Role-Based Access Control model. We define four distinct operational personas with strict security boundaries: "
                "the Primary User owns their telemetry and evidence; Trusted Guardians receive scoped live breadcrumbs only during active trips or SOS alerts; "
                "Police Responders receive real-time dispatch routes and court-ready dossiers; and System Administrators manage perimeters, audit logs, and compliance."
            ),
            "image": "extracted_assets/she_shield_stakeholders_rbac.png"
        },
        # Slide 5
        {
            "num": 5,
            "title": "Slide 5: Core Functional Requirements (BRD / SRS)",
            "layout": "Comprehensive 5-Row Functional Requirement Specification Matrix.",
            "points": [
                "• FR-01: Instant SOS Dispatch — Emergency signal processing from trigger to server acknowledgment in <= 2 seconds across 4G/LTE and BLE relay channels.",
                "• FR-02: Live GPS Waypoint Streams — Continuous waypoint capture at 3–5s intervals with speed, heading, and Kalman filtering for smooth tracking.",
                "• FR-03: Route Deviation Alerts — Heuristic Haversine algorithm flagging transit offsets >30m from planned route vector and notifying guardians.",
                "• FR-04: Cyber Incident Logging — Tesseract/EasyOCR parsing of screenshots and NLP threat severity score calculation under 3 seconds.",
                "• FR-05: Automated Evidence Hashing — Client-side SHA-256 fingerprinting stamped on all video/audio assets prior to cloud upload."
            ],
            "table_data": [
                ("Requirement ID", "Functional Feature", "Engineering Specification", "Verification Criteria"),
                ("FR-01", "Instant SOS Dispatch", "Emergency signal processing from trigger to server acknowledgment in <= 2 seconds.", "Sub-2s benchmark under 4G/LTE & BLE relay triggers."),
                ("FR-02", "Live GPS Waypoint Streams", "Continuous waypoint capture at 3–5s intervals with speed, heading, and Kalman smoothing.", "Live breadcrumbs rendered on guardian/responder maps without lag."),
                ("FR-03", "Route Deviation Alerts", "Heuristic Haversine algorithm flagging transit offsets >30m from planned route vector.", "Automated alert push to guardians when cab veers off polyline path."),
                ("FR-04", "Cyber Incident Logging", "Tesseract/EasyOCR parsing of screenshots and NLP threat severity score calculation.", "Accurate text extraction and risk score assignment in <3 seconds."),
                ("FR-05", "Automated Evidence Hashing", "Client-side SHA-256 fingerprinting stamped on all video/audio assets prior to upload.", "Cryptographic hash match verification between client and vault record.")
            ],
            "notes": (
                "Slide 5 outlines our life-safety functional requirements. In an emergency, latency kills: our requirement FR-01 mandates end-to-end SOS dispatch in under 2 seconds. "
                "FR-02 and FR-03 guarantee continuous waypoint transmission and route deviation detection whenever a vehicle strays more than 30 meters from its route. "
                "FR-04 and FR-05 ensure immediate OCR threat parsing and client-side evidence hashing before data ever leaves the mobile hardware."
            ),
            "image": None
        },
        # Slide 6
        {
            "num": 6,
            "title": "Slide 6: Non-Functional Requirements & Security Mandates",
            "layout": "Four Engineering Mandate Cards detailing Reliability, Privacy, Fault-Tolerance, and Integrity.",
            "points": [
                "• NFR-01: High Availability (99.9% Uptime SLA) — Auto-scaling WSGI workers, Redis queueing, and health-check monitoring ensuring 24/7 emergency dispatch availability.",
                "• NFR-02: Location Privacy & Data Minimization — Strict adherence to DPDP Act (India) and GDPR; automated 30-day scheduled purging of non-incident transit breadcrumbs.",
                "• NFR-03: Offline SMS Fallback Queue — Automatic detection of data loss on client devices; local SQLite coordinate queueing paired with carrier SMS gateway dispatch containing live Google Maps links.",
                "• NFR-04: SHA-256 Evidence Integrity — Tamper-proof digital fingerprinting guaranteeing legal admissibility under Section 65B of the Evidence Act."
            ],
            "notes": (
                "Slide 6 presents our non-functional requirements. Life-critical systems require enterprise reliability: we design for 99.9% availability with zero single-points-of-failure. "
                "To respect privacy and comply with the DPDP Act and GDPR, non-emergency location telemetry is automatically purged after 30 days. "
                "For low-connectivity areas, our offline SMS fallback triggers automatically, while client-side SHA-256 hashing guarantees forensic integrity."
            ),
            "image": None
        },
        # Slide 7
        {
            "num": 7,
            "title": "Slide 7: High-Level System Architecture (4-Tier Design)",
            "layout": "Embedded 4-Tier Architecture Diagram with Accompanying Technical Descriptions.",
            "points": [
                "• Tier 1: Presentation Layer — Flutter 3.x cross-platform mobile client (Android & iOS) with 60fps UI and BLE sensor access, alongside a React.js desktop console for emergency dispatchers.",
                "• Tier 2: API Gateway & Security Layer — JWT authentication filter, RBAC role-enforcement, IP rate limiting, TLS 1.3 encryption, and reverse-proxy routing.",
                "• Tier 3: Core Application & AI/OCR Microservices — Python Flask microservices handling parallel SOS dispatch, Haversine route deviation, PyTorch NLP threat classifier, and OCR screenshot pipeline.",
                "• Tier 4: Data & Storage Layer — PostgreSQL for ACID relational records (users, RBAC, complaints, audit logs), Redis for sub-ms GPS telemetry streams, and AES-256 cloud media vault."
            ],
            "notes": (
                "Slide 7 illustrates our 4-Tier Service-Oriented Architecture. By decoupling the presentation layer (Flutter and React) from the API gateway, "
                "application microservices, and data storage, we ensure horizontal scalability. Flask coordinates business logic and AI inference, "
                "while PostgreSQL provides ACID compliance for relational records and Redis provides sub-millisecond pub/sub streaming for live GPS coordinates."
            ),
            "image": "extracted_assets/she_shield_4tier_architecture.png"
        },
        # Slide 8
        {
            "num": 8,
            "title": "Slide 8: Architectural Diagrams & Data Pipelines",
            "layout": "Embedded Dual Pipeline Diagram: Emergency SOS Parallel Broadcast Flow & Evidence Vault Cryptographic Custody Chain.",
            "points": [
                "• Pipeline A: Emergency SOS Parallel Broadcast Flow — Stealth trigger event $\\rightarrow$ Edge telemetry acquisition $\\rightarrow$ Flask API parallel worker queue $\\rightarrow$ Concurrent broadcast to Linked Guardians (Push), Police Dispatch (ERSS-112 Map), and SMS Fallback Queue in <= 2 seconds.",
                "• Pipeline B: Evidence Vault Cryptographic Custody Chain — Background blackbox audio/video recording $\\rightarrow$ Client-side SHA-256 digest computation $\\rightarrow$ AES-256-GCM encryption in transit and at rest $\\rightarrow$ Immutable database ledger entry with timestamp and police dossier PDF export."
            ],
            "notes": (
                "Slide 8 highlights our two primary data pipelines. Pipeline A executes our parallel broadcast flow: upon trigger, the edge client captures GPS telemetry "
                "and passes it to a Redis pub/sub queue, fanning out alerts simultaneously to guardians, police terminals, and SMS carriers in under 2 seconds. "
                "Pipeline B executes our forensic custody chain: client-side SHA-256 hashing is performed before cloud upload, locking in tamper-proof legal validity."
            ),
            "image": "extracted_assets/she_shield_data_pipelines.png"
        },
        # Slide 9
        {
            "num": 9,
            "title": "Slide 9: Technology Stack Justification",
            "layout": "Comprehensive Technology Evaluation and Selection Rationale Matrix.",
            "points": [
                "• Flutter (Dart 3.x): Delivers 60fps native performance across Android and iOS from a single unified codebase, with direct platform channel access to Bluetooth LE peripherals and motion sensors.",
                "• Python (Flask): Lightweight WSGI microservices enabling rapid integration with PyTorch/OpenCV AI models, low CPU overhead, and asynchronous Celery/Redis worker queues.",
                "• React.js: High-density interactive dashboard for emergency police dispatchers with real-time WebSocket state management and modular dispatch panels.",
                "• PostgreSQL: Strict ACID compliance, relational integrity for RBAC roles, audit trails, and structured police complaints.",
                "• Redis: Sub-millisecond latency for live GPS waypoint broadcasting, temporary session caching, and sliding-window rate limiting."
            ],
            "table_data": [
                ("Technology Component", "Category", "Selected Technology", "Engineering Justification in SheShield"),
                ("Mobile Client", "Presentation", "Flutter (Dart 3.x)", "Native 60fps performance on Android & iOS, unified single codebase, low-latency BLE sensor access."),
                ("Command Portal", "Presentation", "React.js + Tailwind", "High-density responsive web console for emergency police dispatchers with real-time WebSocket state."),
                ("Backend Services", "Application APIs", "Python Flask Microservices", "Lightweight WSGI services, native integration with PyTorch/OpenCV AI models, asynchronous worker queues."),
                ("Relational Storage", "Database", "PostgreSQL", "Strict ACID compliance, relational integrity for RBAC roles, audit trails, and structured police complaints."),
                ("In-Memory Telemetry", "Cache & Streams", "Redis Pub/Sub", "Sub-millisecond latency for live GPS waypoint broadcasting, temporary session caching, and rate limiting.")
            ],
            "notes": (
                "Slide 9 defends our technology stack. Flutter allows us to maintain a single, type-safe mobile codebase while directly binding to BLE hardware. "
                "React provides an expansive desktop command center for police desks. Python Flask offers native compatibility with PyTorch and OCR libraries, "
                "while the combination of PostgreSQL and Redis ensures that structured relational records are durable and live GPS streams are blazingly fast."
            ),
            "image": None
        },
        # Slide 10
        {
            "num": 10,
            "title": "Slide 10: Security Architecture & Cryptographic Integrity",
            "layout": "Four Deep-Dive Cryptographic Security Pillars with Compliance Alignment.",
            "points": [
                "• Role-Based Access Control (RBAC) via Signed JWTs: Stateless tokens signed with RSA-256 enforcing strict permission scopes (Primary User, Guardian, Responder, Admin) with 15-minute token expiry.",
                "• AES-256-GCM Vault Encryption: Authenticated Galois/Counter Mode encryption safeguarding audio, video, and screenshot assets at rest and in transit with unique initialization vectors.",
                "• IP-Level & Token-Level Rate Limiting: Sliding-window rate limiters backed by Redis to defend emergency dispatch gateways against Distributed Denial of Service (DDoS) and brute force.",
                "• Section 65B Forensic Admissibility: Client-side SHA-256 hashing guarantees bit-level media authenticity, completely neutralizing evidentiary tampering claims in criminal courts."
            ],
            "notes": (
                "Slide 10 dives into our cybersecurity architecture. We enforce zero-trust security using cryptographically signed JWTs and strict RBAC boundaries. "
                "All vaulted media is protected with AES-256-GCM encryption, while sliding-window rate limiters prevent denial-of-service attacks on emergency gateways. "
                "Crucially, client-side SHA-256 hashing ensures that all evidence adheres strictly to Section 65B of the Indian Evidence Act."
            ),
            "image": None
        },
        # Slide 11
        {
            "num": 11,
            "title": "Slide 11: Current Implementation Progress (Weeks 1–11)",
            "layout": "Detailed Sprint Milestone Progress Table tracking Delivered Artifacts in GitHub.",
            "points": [
                "• Milestone 1: Foundations & Architecture Design (Weeks 1–2) — 100% Completed (lib/main.dart, lib/theme/app_theme.dart).",
                "• Milestone 2: User Authentication & RBAC Engine (Weeks 3–4) — 100% Completed (lib/screens/auth_screens.dart, police_admin_screens.dart).",
                "• Milestone 3: Emergency SOS Center & Stealth Triggers (Weeks 5–6) — 100% Completed (lib/screens/sos_screens.dart, lib/services/sos_service.dart).",
                "• Milestone 4: Travel Monitor & Cab Deviation Engine (Weeks 7–8) — 100% Completed (lib/screens/travel_monitor_screen.dart, database_service.dart).",
                "• Milestone 5: Cybercrime Reporting Desk & OCR Ingestion (Weeks 9–10) — 100% Completed (lib/screens/cyber_screens.dart, pdf_report_service.dart).",
                "• Milestone 6: React Police Command Desk & Admin Hub (Week 11) — 100% Completed (lib/screens/admin_command_center_screen.dart, vault_screens.dart).",
                "• Repository Status: All core code modules completed, verified, and live on the SheShield GitHub repository."
            ],
            "table_data": [
                ("Sprint Milestone", "Delivered Features & Modules", "Repository Artifacts (GitHub)", "Current Status"),
                ("Milestone 1: Foundations", "System architecture, UI wireframes, theme setup, Provider state framework.", "lib/main.dart, lib/theme/app_theme.dart", "100% Completed"),
                ("Milestone 2: Auth & RBAC", "User, Guardian, Responder, Admin registration and role-based route guard.", "lib/screens/auth_screens.dart, police_admin_screens.dart", "100% Completed"),
                ("Milestone 3: SOS Center", "Multi-modal trigger engine, 5s cancellable timer, volume button trigger, BLE sync.", "lib/screens/sos_screens.dart, lib/services/sos_service.dart", "100% Completed"),
                ("Milestone 4: Travel Monitor", "Cab Guardian & Walk Guardian with 30m route offset deviation calculation.", "lib/screens/travel_monitor_screen.dart, database_service.dart", "100% Completed"),
                ("Milestone 5: Cybercrime Desk", "Cyber complaint intake, OCR screenshot scan, PyTorch threat score, PDF export.", "lib/screens/cyber_screens.dart, pdf_report_service.dart", "100% Completed"),
                ("Milestone 6: Command Hub", "Admin Command Center, Responder live radar, and Evidence Locker vault.", "lib/screens/admin_command_center_screen.dart, vault_screens.dart", "100% Completed")
            ],
            "notes": (
                "Slide 11 reviews our implementation progress over Weeks 1 through 11. We have completed all six planned development milestones: "
                "our authentication and RBAC engine, multi-modal SOS trigger center, Cab Guardian route deviation engine, cybercrime OCR desk, "
                "and administrative command centers are 100% functional and checked into our project GitHub repository."
            ),
            "image": None
        },
        # Slide 12
        {
            "num": 12,
            "title": "Slide 12: Next Steps (Weeks 12–16) & Q&A Conclusion",
            "layout": "Chronological Roadmap Cards for Weeks 12–16 and Concluding Q&A Banner.",
            "points": [
                "• Weeks 12–13: Full End-to-End System Integration Testing across Flutter mobile client, Flask microservices, and React command desk.",
                "• Week 14: Real-World GPS Geofencing Benchmarks evaluating Haversine route deviation accuracy under dense urban multi-path conditions.",
                "• Week 15: High-Concurrency Load Testing simulating 5,000+ simultaneous emergency bursts with Locust/JMeter and security penetration audits.",
                "• Week 16: Final Production Release, Signed APK deployment, Community Pilot testing, and Course Viva Voce Defense.",
                "• Conclusion & Acknowledgments: SheShield delivers a proactive, forensically sound safety infrastructure for women. We invite questions from the panel."
            ],
            "notes": (
                "In conclusion, Slide 12 charts our roadmap for Weeks 12 through 16: conducting rigorous end-to-end integration, real-world urban GPS benchmarks, "
                "and high-concurrency load testing simulating 5,000 simultaneous emergency triggers. SheShield transforms personal safety into a proactive, "
                "tamper-proof ecosystem. We thank our course faculty and university evaluators, and we welcome your questions. Thank you!"
            ),
            "image": None
        }
    ]

    for item in slides:
        h2 = doc.add_heading(item['title'], level=2)
        h2.runs[0].font.color.rgb = RGBColor(76, 29, 149)

        p_meta = doc.add_paragraph()
        p_meta.add_run("Slide Visual Layout: ").font.bold = True
        p_meta.add_run(item['layout'] + "\n")

        p_c_lbl = doc.add_paragraph()
        p_c_lbl.add_run("Slide Content & Core Specifications:").font.bold = True
        for pt in item['points']:
            doc.add_paragraph(pt, style='List Bullet')

        if 'table_data' in item:
            headers = [h for h in item['table_data'][0]]
            t = doc.add_table(rows=len(item['table_data']), cols=len(headers))
            for r_idx, row in enumerate(item['table_data']):
                for c_idx, val in enumerate(row):
                    t.cell(r_idx, c_idx).text = val
            col_w = [Inches(1.8), Inches(2.7), Inches(2.5)] if len(headers) == 3 else [Inches(1.5), Inches(2.0), Inches(2.0), Inches(1.5)]
            format_docx_table(t, col_w)
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

        if item['image'] and os.path.exists(item['image']):
            p_img = doc.add_paragraph()
            p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_img.add_run().add_picture(item['image'], width=Inches(5.5))
            p_cap = doc.add_paragraph()
            p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r_cap = p_cap.add_run(f"Figure: Slide {item['num']} Architectural & Process Model")
            r_cap.font.size = Pt(9.5)
            r_cap.font.italic = True
            r_cap.font.color.rgb = RGBColor(100, 116, 139)
            doc.add_paragraph().paragraph_format.space_after = Pt(6)

        t_note = doc.add_table(rows=1, cols=1)
        set_cell_background(t_note.cell(0, 0), "F3E8FF")
        set_cell_margins(t_note.cell(0, 0), top=100, bottom=100, left=150, right=150)
        p_note = t_note.cell(0, 0).paragraphs[0]
        r_n_hdr = p_note.add_run("Verbatim Speaker Presentation Script (What to say during presentation):\n")
        r_n_hdr.font.bold = True
        r_n_hdr.font.size = Pt(9.5)
        r_n_hdr.font.color.rgb = RGBColor(107, 33, 168)
        r_n_txt = p_note.add_run('"' + item['notes'] + '"')
        r_n_txt.font.italic = True
        r_n_txt.font.size = Pt(9.5)
        r_n_txt.font.color.rgb = RGBColor(55, 48, 163)

        doc.add_paragraph().paragraph_format.space_after = Pt(14)

    output_docx = "SheShield_CyberIntegrated_SafetyPlatform.docx"
    doc.save(output_docx)
    print(f"Successfully generated {output_docx}!")

if __name__ == "__main__":
    build_docx()
