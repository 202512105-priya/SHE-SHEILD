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

def format_minimal_table(table, col_widths, header_bg="F1F5F9", alt_bg="F8FAFC"):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for cell in table.rows[0].cells:
        set_cell_background(cell, header_bg)
        set_cell_margins(cell, top=100, bottom=100, left=140, right=140)
        for p in cell.paragraphs:
            for run in p.runs:
                run.font.name = "Arial"
                run.font.size = Pt(9.5)
                run.font.bold = True
                run.font.color.rgb = RGBColor(15, 23, 42)
    for r_idx in range(1, len(table.rows)):
        bg = alt_bg if r_idx % 2 == 1 else "FFFFFF"
        for cell in table.rows[r_idx].cells:
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=80, bottom=80, left=140, right=140)
            for p in cell.paragraphs:
                for run in p.runs:
                    run.font.name = "Arial"
                    run.font.size = Pt(9)
                    run.font.color.rgb = RGBColor(51, 65, 85)
    for row in table.rows:
        for idx, width in enumerate(col_widths):
            row.cells[idx].width = width

def build_docx():
    doc = Document()
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        header = section.header
        p_hdr = header.paragraphs[0]
        p_hdr.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        r_hdr = p_hdr.add_run("SHE SHIELD – Design Document & Slide Deck Specification")
        r_hdr.font.name = "Arial"
        r_hdr.font.size = Pt(8.5)
        r_hdr.font.italic = True
        r_hdr.font.color.rgb = RGBColor(148, 163, 184)

    style = doc.styles['Normal']
    font = style.font
    font.name = 'Arial'
    font.size = Pt(10.5)
    font.color.rgb = RGBColor(30, 41, 59)

    # COVER PAGE
    doc.add_paragraph().paragraph_format.space_after = Pt(36)
    p_t = doc.add_paragraph()
    p_t.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t = p_t.add_run("SHE SHIELD\n")
    r_t.font.name = "Times New Roman"
    r_t.font.size = Pt(32)
    r_t.font.bold = True
    r_t.font.color.rgb = RGBColor(15, 23, 42)

    r_sub = p_t.add_run("Design Document & Presentation Deck\n\n")
    r_sub.font.name = "Times New Roman"
    r_sub.font.size = Pt(18)
    r_sub.font.italic = True
    r_sub.font.color.rgb = RGBColor(51, 65, 85)

    r_tag = p_t.add_run("Cyber-Integrated Safety Platform for Women")
    r_tag.font.name = "Times New Roman"
    r_tag.font.size = Pt(13)
    r_tag.font.italic = True
    r_tag.font.color.rgb = RGBColor(100, 116, 139)

    doc.add_paragraph().paragraph_format.space_after = Pt(36)

    p_subm = doc.add_paragraph()
    p_subm.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_subm = p_subm.add_run("Team Members\n\nSUBMITTED BY\n")
    r_subm.font.name = "Arial"
    r_subm.font.size = Pt(11)
    r_subm.font.bold = True
    r_subm.font.color.rgb = RGBColor(15, 23, 42)

    team_members = [
        "Jainam Shah – 202512012 (Backend APIs)",
        "Maahir Shah – 202512022 (Database Architecture)",
        "Hitarth Shah – 202512042 (AI Threat Models)",
        "Jay Shah – 202512059 (DevOps & Integration)",
        "Nirmal Patel – 202512102 (Authentication & RBAC)",
        "Priya Shah – 202512105 (Navigation & User Flow)",
        "Jenil Shah – 202512110 (Cybersecurity & Vault)",
        "Krisha Doshi – 202512112 (Mobile UI Engineering)"
    ]
    p_members = doc.add_paragraph()
    p_members.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for m in team_members:
        r = p_members.add_run(m + "\n")
        r.font.name = "Arial"
        r.font.size = Pt(10)
        r.font.color.rgb = RGBColor(51, 65, 85)

    doc.add_paragraph().paragraph_format.space_after = Pt(28)

    p_meta = doc.add_paragraph()
    p_meta.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_meta = p_meta.add_run("Course: WSSOA (IT644)  ·  Autumn Semester 2026\nDhirubhai Ambani University, Gandhinagar\nDate of Submission: 29/08/2026  ·  Document Version: 1.0")
    r_meta.font.name = "Arial"
    r_meta.font.size = Pt(10)
    r_meta.font.color.rgb = RGBColor(100, 116, 139)

    doc.add_page_break()

    # SLIDES WALKTHROUGH
    slides_data = [
        {
            "num": 1,
            "title": "Slide 1: Title & Team Credentials",
            "section": "1. Project Overview & Credentials",
            "flow": "Project Declaration  →  Team Organization  →  Engineering Ownership",
            "points": [
                "Title: SHE SHIELD — Cyber-Integrated Safety Platform for Women.",
                "Course: WSSOA (IT644) Project Presentation I, Autumn 2026, Dhirubhai Ambani University.",
                "Engineering Roles: Clean 8-member ownership covering Mobile UI, Navigation, Backend APIs, Database, AI Models, DevOps, Auth/RBAC, and Cybersecurity."
            ],
            "script": "Good afternoon professors and peers. Welcome to our Project Presentation I for IT644. We present SHE SHIELD, a cyber-integrated safety platform for women developed by our eight-member team at Dhirubhai Ambani University.",
            "image": None
        },
        {
            "num": 2,
            "title": "Slide 2: Problem Definition & Market Gaps",
            "section": "2. Problem Analysis",
            "flow": "Market Gap 1 (Physical vs Cyber)  →  Market Gap 2 (Panic Latency)  →  Market Gap 3 (Evidence Destruction)",
            "points": [
                "Gap 1 (Single-Vector Focus): Existing apps handle only physical panic buttons and completely ignore cyber harassment, doxxing, and online blackmail.",
                "Gap 2 (Panic Latency): Victims under attack cannot unlock screens or navigate apps; stealth triggers (BLE, voice phrase 'capcap') are missing.",
                "Gap 3 (Digital Evidence Loss): Chats and threats are deleted before reporting; screenshots lack cryptographic integrity for court admissibility under Section 65B."
            ],
            "script": "Existing safety apps have three fatal flaws: they ignore cyber harassment, they require complex screen interactions that fail during acute panic, and digital evidence is easily erased before police reporting.",
            "image": None
        },
        {
            "num": 3,
            "title": "Slide 3: Proposed Solution — The SHE SHIELD Ecosystem",
            "section": "3. Solution Architecture",
            "flow": "Stealth Trigger  →  Instant Multi-Target Alert  →  Continuous Route Tracking  →  Forensic Evidence Notarization",
            "points": [
                "Pillar 1 (Physical SOS & Transit): BLE wearable button, voice 'capcap', power double-click, sub-2s dispatch, and Cab Guardian route deviation alerts (>30m).",
                "Pillar 2 (AI Cybercrime & OCR): OCR extracts blackmail text and timestamps; PyTorch NLP evaluates danger severity (e.g. 92%) and builds structured police dossiers.",
                "Pillar 3 (Cryptographic Evidence Vault): Continuous background blackbox recording, client-side SHA-256 digital fingerprinting, and AES-256 cloud encryption for court validity."
            ],
            "script": "SHE SHIELD bridges physical transit safety with cyber protection through three pillars: stealth multi-modal triggers with Cab Guardian route monitoring, AI-powered cybercrime OCR intake, and a tamper-proof cryptographic evidence vault.",
            "image": None
        },
        {
            "num": 4,
            "title": "Slide 4: Stakeholders & User Roles (RBAC)",
            "section": "4. Stakeholders & Role-Based Access Control",
            "flow": "Primary User (Trigger & Report)  ↔  Guardian (Live Telemetry)  ↔  Police (Dispatch & Dossier)  ↔  Admin (Audit & Rules)",
            "points": [
                "Women / Primary User: Dispatches stealth SOS (<= 2s), activates Cab/Walk Guardian, submits cyber reports, accesses personal Evidence Vault.",
                "Trusted Guardians: Receives live GPS waypoint streams, route deviation push alerts (>30m), automated SMS fallback links, confirms safe arrivals.",
                "Police & Responders: Live emergency radar map, prioritized incident queue, victim medical/biometric profiles, court-ready incident dossiers.",
                "System Administrators: Manages RBAC role permissions, high-risk unsafe zone polygons, immutable audit logs, AI model parameters."
            ],
            "script": "We implement strict Role-Based Access Control: Women control their personal telemetry and evidence; Guardians receive scoped live breadcrumbs only during active trips; Responders access geographic incident maps; and Administrators enforce security.",
            "image": None
        },
        {
            "num": 5,
            "title": "Slide 5: Core Functional Requirements (BRD / SRS)",
            "section": "5. Functional Requirements Specification",
            "flow": "FR-01 (<=2s Dispatch)  →  FR-02 (Live Stream)  →  FR-03 (Deviation Alert)  →  FR-04 (Cyber Triage)  →  FR-05 (Evidence Hashing)",
            "points": [
                "FR-01 (Instant SOS Dispatch): Sub-2-second dispatch latency (<= 2s) from trigger event to server acknowledgement.",
                "FR-02 (Live GPS Streams): High-frequency waypoint stream every 3–5 seconds with Kalman filtering.",
                "FR-03 (Route Deviation Alerts): Haversine distance algorithm flagging transit diversions exceeding 30 meters.",
                "FR-04 (Cyber Incident Logging): OCR screenshot text parsing and NLP threat severity calculation under 3 seconds.",
                "FR-05 (Evidence Hashing): Client-side SHA-256 digital fingerprinting calculated prior to cloud upload."
            ],
            "script": "Our life-safety requirements mandate sub-2-second emergency dispatch latency, continuous 3-second GPS waypoint updates, automatic 30-meter cab deviation detection, and instant client-side SHA-256 evidence hashing.",
            "image": None
        },
        {
            "num": 6,
            "title": "Slide 6: Non-Functional Requirements & Security Mandates",
            "section": "6. Non-Functional Requirements & Compliance",
            "flow": "99.9% Availability  →  30-Day Location Privacy  →  Offline SMS Fallback  →  SHA-256 Legal Integrity",
            "points": [
                "NFR-01 (High Availability): 99.9% uptime SLA on emergency endpoints via auto-scaling WSGI workers and Redis queues.",
                "NFR-02 (Location Privacy): DPDP Act & GDPR compliance with automated 30-day scheduled purging of non-incident breadcrumbs.",
                "NFR-03 (Offline SMS Fallback): Local SQLite coordinate queueing and automated SMS fallback with Google Maps links.",
                "NFR-04 (SHA-256 Integrity): Immutable cryptographic audit trail guaranteeing court admissibility under Section 65B of Evidence Act."
            ],
            "script": "Non-functional mandates ensure 99.9% emergency availability, automated 30-day purging of location logs for privacy compliance under DPDP regulations, offline SMS fallbacks when cellular data drops, and Section 65B evidence integrity.",
            "image": None
        },
        # SLIDE 7: DESIGN COMPONENTS - System Architecture
        {
            "num": 7,
            "title": "Slide 7: Design Components — Three-Tier System Architecture",
            "section": "7. Design Components : Three-Tier System Architecture",
            "flow": "Tier 1: Frontend (Flutter & React)  →  Tier 2: Backend & AI (Flask & PyTorch/OCR)  →  Tier 3: Database & Storage (AES-256 Vault & Relational DB)",
            "points": [
                "Tier 1 (Frontend Layer): Flutter Mobile App for women (60fps, BLE triggers, background telemetry) + React.js Web Command Dashboard for police & administrators via HTTPS/REST.",
                "Tier 2 (Backend & AI Layer): Central API Gateway enforcing JWT authentication & security  →  Python Flask Microservices (Auth, Emergency SOS, Travel Tracker, Cybercrime Intake)  ↔  AI Threat Engine (Distress Audio Classifier & OCR Screenshot Scanner).",
                "Tier 3 (Database & Storage Layer): Relational Database storing user accounts, roles, complaint logs, and emergency sessions  +  Encrypted Evidence Vault enforcing AES-256 file encryption & SHA-256 integrity hashes."
            ],
            "script": "Our primary design component is this Three-Tier System Architecture. Tier 1 delivers native mobile and web command interfaces. Tier 2 orchestrates Flask microservices and AI threat scanning behind a JWT gateway. Tier 3 secures persistent relational data and AES-256 encrypted evidence assets.",
            "image": "extracted_assets/three_tier_architecture.jpg"
        },
        # SLIDE 8: DESIGN COMPONENTS - Use Case Diagram
        {
            "num": 8,
            "title": "Slide 8: Design Components — Use Case Model & System Boundary",
            "section": "8. Design Components : Use Case Model & System Boundary",
            "flow": "Woman User (4 Use Cases)  |  Trusted Guardian (2 Use Cases)  |  Police/Admin (3 Use Cases)",
            "points": [
                "Woman (Primary User): Trigger Emergency SOS, Upload & Secure Evidence, Report Cybercrime Harassment, Track Travel & Cab Journey.",
                "Trusted Guardian: Receive Emergency SMS with Live GPS Link, View Real-Time Safety Status.",
                "Police / Administrator: Manage Emergency Cases, Review Cybercrime Complaints, Monitor Live Emergency Alerts on Command Radar."
            ],
            "script": "This design component illustrates our Use Case Model across the SHE SHIELD system boundary. Each actor has clearly defined, focused capabilities: women manage transit and emergency triggers, guardians monitor journeys, and police respond to active alerts.",
            "image": "extracted_assets/use_case_diagram.jpg"
        },
        # SLIDE 9: DESIGN COMPONENTS - Emergency SOS Flow
        {
            "num": 9,
            "title": "Slide 9: Design Components — Emergency SOS Flow",
            "section": "9. Design Components : Emergency SOS Flow",
            "flow": "Woman Triggers SOS  →  App Captures GPS  →  Alert to Backend  →  Save in Database  →  Fork (Guardian SMS + Police Dashboard)  →  Display Confirmation",
            "points": [
                "Phase 1 (Initiation & Telemetry): Woman triggers SOS via button, BLE, or voice  →  App captures GPS location coordinates.",
                "Phase 2 (Ingestion & Storage): App dispatches alert payload to backend  →  Emergency session committed to relational database.",
                "Phase 3 (Parallel Execution Fork): Simultaneously sends SMS with live location link to Trusted Guardian  AND  shows real-time emergency alert on Police Dashboard.",
                "Phase 4 (Join & Confirmation): Displays visual SOS confirmation to the woman and maintains tracking until safely resolved."
            ],
            "script": "Here is our Emergency SOS execution flow. From the moment distress is triggered and GPS is acquired, the backend commits the record and immediately forks into two parallel channels: dispatching an SMS link to guardians and illuminating the police dashboard simultaneously.",
            "image": "extracted_assets/sos_flow_diagram.jpg"
        },
        # Slide 10
        {
            "num": 10,
            "title": "Slide 10: Technology Stack Justification",
            "section": "10. Technology Stack Justification",
            "flow": "Flutter (60fps Mobile)  +  React.js (Police Desk)  +  Flask (AI-Ready APIs)  +  PostgreSQL (ACID Data)  +  Redis (Sub-ms GPS)",
            "points": [
                "Flutter (Dart 3.x): Single codebase for Android & iOS, 60fps native performance, direct platform bindings to BLE wearable pendants.",
                "React.js: High-density interactive dashboard for emergency dispatchers with real-time WebSocket state management.",
                "Python Flask: Lightweight WSGI microservices, native integration with PyTorch/OpenCV AI models, asynchronous worker queues.",
                "PostgreSQL: Strict ACID compliance, relational integrity for RBAC roles, audit trails, and structured police complaints.",
                "Redis: Sub-millisecond latency for live GPS waypoint distribution and session queues."
            ],
            "script": "Our technology choices are purpose-built for life-safety: Flutter for fast, native mobile interactions; React for high-density police dispatching; Flask for seamless AI integration; and PostgreSQL plus Redis for durable and ultra-fast data handling.",
            "image": None
        },
        # Slide 11
        {
            "num": 11,
            "title": "Slide 11: Security Architecture & Cryptographic Integrity",
            "section": "11. Security Architecture & Legal Validity",
            "flow": "JWT RBAC Tokens  →  AES-256-GCM Vault  →  Sliding-Window Rate Limiting  →  Section 65B Court Admissibility",
            "points": [
                "Role-Based Access Control via JWT: Stateless RSA-256 signed tokens enforcing granular permission scopes with 15-minute token expiry.",
                "AES-256-GCM Vault Encryption: Authenticated Galois/Counter Mode cipher protecting all vaulted audio, video, and screenshot assets.",
                "IP-Level & Token-Level Rate Limiting: Sliding-window rate limiters backed by Redis to defend emergency dispatch gateways against DDoS attacks.",
                "Section 65B Forensic Admissibility: Client-side SHA-256 hashing guarantees bit-level media authenticity, completely eliminating evidence tampering claims."
            ],
            "script": "Security by design is enforced across the platform: cryptographically signed JWT tokens, authenticated AES-256-GCM vault encryption, Redis sliding-window rate limiters, and client-side SHA-256 hashing for courtroom evidentiary admissibility.",
            "image": None
        },
        # Slide 12
        {
            "num": 12,
            "title": "Slide 12: Current Implementation Progress (Weeks 1–11)",
            "section": "12. Implementation Progress & GitHub Milestones",
            "flow": "M1 (Architecture)  →  M2 (Auth & RBAC)  →  M3 (SOS Center)  →  M4 (Travel Monitor)  →  M5 (Cybercrime Desk)  →  M6 (Command Hub)",
            "points": [
                "Milestone 1 (Foundations): System architecture, UI wireframes, theme setup, Provider state framework (100% Completed).",
                "Milestone 2 (Auth & RBAC): User, Guardian, Responder, Admin registration and role-based route guard (100% Completed).",
                "Milestone 3 (SOS Center): Multi-modal trigger engine, 5s cancellable timer, volume button trigger, BLE sync (100% Completed).",
                "Milestone 4 (Travel Monitor): Cab Guardian & Walk Guardian with 30m route offset deviation calculation (100% Completed).",
                "Milestone 5 (Cybercrime Desk): Cyber complaint intake, OCR screenshot scan, PyTorch threat score, PDF export (100% Completed).",
                "Milestone 6 (Command Hub): Admin Command Center, Responder live radar, and Evidence Locker vault (100% Completed).",
                "Repository Status: All core code modules completed, verified, and live on the SheShield GitHub repository."
            ],
            "script": "Over Weeks 1 through 11, our team achieved 100% completion across all six planned milestones. All modules—from stealth SOS triggering and Cab Guardian to cybercrime OCR scanning and admin command consoles—are functional and tracked on GitHub.",
            "image": None
        },
        # Slide 13
        {
            "num": 13,
            "title": "Slide 13: Next Steps (Weeks 12–16) & Q&A Conclusion",
            "section": "13. Project Roadmap & Conclusion",
            "flow": "Weeks 12-13 (Integration)  →  Week 14 (Field Benchmarks)  →  Week 15 (Load Tests)  →  Week 16 (Release & Viva Defense)",
            "points": [
                "Weeks 12–13 (End-to-End Integration): Connect Flutter mobile client, Flask microservices, and React admin desk under simulated network loss.",
                "Week 14 (GPS Geofencing Benchmarks): Field-test Haversine route deviation accuracy and calibrate Kalman filtering in dense urban areas.",
                "Week 15 (High-Concurrency Load Testing): Simulate 5,000+ simultaneous emergency SOS trigger bursts using Locust and conduct penetration audits.",
                "Week 16 (Final Release & Viva Defense): Production Docker containerization, signed APK release, community pilot trials, and Viva Voce evaluation."
            ],
            "script": "Our next steps focus on rigorous end-to-end integration, real-world urban GPS deviation benchmarks, and high-concurrency load testing simulating 5,000 simultaneous alerts. Thank you for your time, and we welcome your questions.",
            "image": None
        }
    ]

    for item in slides_data:
        h2 = doc.add_heading(item['section'], level=2)
        h2.runs[0].font.name = "Arial"
        h2.runs[0].font.size = Pt(13)
        h2.runs[0].font.bold = True
        h2.runs[0].font.color.rgb = RGBColor(15, 23, 42)

        p_fl = doc.add_paragraph()
        r_f_lbl = p_fl.add_run("Execution Flow: ")
        r_f_lbl.font.bold = True
        r_f_lbl.font.size = Pt(9.5)
        r_f_lbl.font.color.rgb = RGBColor(67, 56, 202)
        r_flow = p_fl.add_run(item['flow'])
        r_flow.font.size = Pt(9.5)
        r_flow.font.color.rgb = RGBColor(71, 85, 105)

        for pt in item['points']:
            p_pt = doc.add_paragraph(style='List Bullet')
            r_pt = p_pt.add_run(pt)
            r_pt.font.name = "Arial"
            r_pt.font.size = Pt(9.5)
            r_pt.font.color.rgb = RGBColor(30, 41, 59)

        if item['image'] and os.path.exists(item['image']):
            p_img = doc.add_paragraph()
            p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_img.add_run().add_picture(item['image'], width=Inches(4.8))
            p_cap = doc.add_paragraph()
            p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r_cap = p_cap.add_run(f"Figure: {item['title']}")
            r_cap.font.size = Pt(8.5)
            r_cap.font.italic = True
            r_cap.font.color.rgb = RGBColor(148, 163, 184)

        t_note = doc.add_table(rows=1, cols=1)
        set_cell_background(t_note.cell(0, 0), "F8FAFC")
        set_cell_margins(t_note.cell(0, 0), top=80, bottom=80, left=140, right=140)
        p_n = t_note.cell(0, 0).paragraphs[0]
        r_nh = p_n.add_run("Speaker Script (Natural, concise verbal delivery):\n")
        r_nh.font.bold = True
        r_nh.font.size = Pt(9)
        r_nh.font.color.rgb = RGBColor(30, 41, 59)
        r_nt = p_n.add_run('"' + item['script'] + '"')
        r_nt.font.italic = True
        r_nt.font.size = Pt(9)
        r_nt.font.color.rgb = RGBColor(71, 85, 105)

        doc.add_paragraph().paragraph_format.space_after = Pt(10)

    output_docx = "SheShield_Minimalist_Design_Document.docx"
    doc.save(output_docx)
    print(f"Successfully generated {output_docx}!")

if __name__ == "__main__":
    build_docx()
