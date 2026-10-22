import os
import pptx
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

def build_presentation():
    prs = pptx.Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6]

    # Minimalist Palette
    C_BG = RGBColor(255, 255, 255)
    C_CARD_BG = RGBColor(248, 250, 252) # Soft slate-50
    C_CARD_BORDER = RGBColor(226, 232, 240) # Slate-200
    C_TEXT_MAIN = RGBColor(15, 23, 42) # Slate-900
    C_TEXT_MUTED = RGBColor(71, 85, 105) # Slate-600
    C_TEXT_SUBTLE = RGBColor(148, 163, 184) # Slate-400
    C_ACCENT_INDIGO = RGBColor(67, 56, 202) # Indigo-700
    C_LINE = RGBColor(203, 213, 225) # Divider line

    def add_slide_header(slide, title, category="SHE SHIELD — System Architecture & Design"):
        # Running header
        tb_run = slide.shapes.add_textbox(Inches(0.8), Inches(0.4), Inches(11.7), Inches(0.28))
        tf_run = tb_run.text_frame
        tf_run.word_wrap = True
        tf_run.margin_left = tf_run.margin_top = tf_run.margin_right = tf_run.margin_bottom = 0
        p_run = tf_run.paragraphs[0]
        p_run.text = category.upper()
        p_run.font.name = "Arial"
        p_run.font.size = Pt(9.5)
        p_run.font.bold = True
        p_run.font.color.rgb = C_TEXT_SUBTLE

        # Slide Title
        tb_t = slide.shapes.add_textbox(Inches(0.8), Inches(0.68), Inches(11.7), Inches(0.55))
        tf_t = tb_t.text_frame
        tf_t.word_wrap = True
        tf_t.margin_left = tf_t.margin_top = tf_t.margin_right = tf_t.margin_bottom = 0
        p_t = tf_t.paragraphs[0]
        p_t.text = title
        p_t.font.name = "Arial"
        p_t.font.size = Pt(22)
        p_t.font.bold = True
        p_t.font.color.rgb = C_TEXT_MAIN

        # Divider line
        line = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), Inches(1.3), Inches(11.7), Inches(0.015))
        line.fill.solid()
        line.fill.fore_color.rgb = C_LINE
        line.line.color.rgb = C_LINE

    def add_minimal_card(slide, x, y, w, h, title, points, accent_color=C_TEXT_MAIN, title_size=13, body_size=11):
        box = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, x, y, w, h)
        box.fill.solid()
        box.fill.fore_color.rgb = C_CARD_BG
        box.line.color.rgb = C_CARD_BORDER
        box.line.width = Pt(1)
        tf = box.text_frame
        tf.word_wrap = True
        tf.margin_left = Inches(0.22)
        tf.margin_top = Inches(0.18)
        tf.margin_right = Inches(0.22)
        tf.margin_bottom = Inches(0.18)
        
        p0 = tf.paragraphs[0]
        p0.text = title
        p0.font.name = "Arial"
        p0.font.size = Pt(title_size)
        p0.font.bold = True
        p0.font.color.rgb = accent_color
        
        for pt in points:
            p = tf.add_paragraph()
            p.text = "• " + pt
            p.font.name = "Arial"
            p.font.size = Pt(body_size)
            p.font.color.rgb = C_TEXT_MUTED
            p.space_before = Pt(4)

    # ==========================================
    # SLIDE 1: Title & Team Credentials
    # ==========================================
    s1 = prs.slides.add_slide(blank_layout)
    tb = s1.shapes.add_textbox(Inches(0.8), Inches(0.6), Inches(11.7), Inches(0.3))
    p = tb.text_frame.paragraphs[0]
    p.text = "WSSOA (IT644)  ·  PROJECT PRESENTATION I  ·  AUTUMN 2026"
    p.font.name = "Arial"
    p.font.size = Pt(10)
    p.font.bold = True
    p.font.color.rgb = C_TEXT_SUBTLE

    tb_title = s1.shapes.add_textbox(Inches(0.8), Inches(1.1), Inches(11.7), Inches(1.5))
    tf = tb_title.text_frame
    p0 = tf.paragraphs[0]
    p0.text = "SHE SHIELD"
    p0.font.name = "Arial"
    p0.font.size = Pt(36)
    p0.font.bold = True
    p0.font.color.rgb = C_TEXT_MAIN

    p1 = tf.add_paragraph()
    p1.text = "Design Document & Architecture Presentation"
    p1.font.name = "Arial"
    p1.font.size = Pt(18)
    p1.font.color.rgb = C_ACCENT_INDIGO
    p1.space_before = Pt(4)

    p2 = tf.add_paragraph()
    p2.text = "Cyber-Integrated Safety Platform for Women  ·  Dhirubhai Ambani University"
    p2.font.name = "Arial"
    p2.font.size = Pt(13)
    p2.font.color.rgb = C_TEXT_MUTED
    p2.space_before = Pt(2)

    line = s1.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), Inches(2.7), Inches(11.7), Inches(0.015))
    line.fill.solid()
    line.fill.fore_color.rgb = C_LINE
    line.line.color.rgb = C_LINE

    table_shape = s1.shapes.add_table(9, 4, Inches(0.8), Inches(2.9), Inches(11.7), Inches(4.0))
    t1 = table_shape.table
    col_w = [Inches(0.9), Inches(2.8), Inches(2.0), Inches(6.0)]
    for i, w in enumerate(col_w):
        t1.columns[i].width = w

    headers = ["Sr. No.", "Team Member", "Student ID", "Specific Project Engineering Role"]
    for i, h in enumerate(headers):
        cell = t1.cell(0, i)
        cell.fill.solid()
        cell.fill.fore_color.rgb = RGBColor(241, 245, 249)
        p = cell.text_frame.paragraphs[0]
        p.text = h
        p.font.name = "Arial"
        p.font.size = Pt(11)
        p.font.bold = True
        p.font.color.rgb = C_TEXT_MAIN

    team_data = [
        ("1", "Jainam Shah", "202512012", "Backend APIs (Flask REST Services, Dispatches & Hooks)"),
        ("2", "Maahir Shah", "202512022", "Database Architecture (PostgreSQL Schema & Redis Streaming)"),
        ("3", "Hitarth Shah", "202512042", "AI Threat Models (PyTorch NLP Classifier & Risk Scoring)"),
        ("4", "Jay Shah", "202512059", "DevOps & Integration (Docker, CI/CD & Gateway Telemetry)"),
        ("5", "Nirmal Patel", "202512102", "Authentication & RBAC (JWT Security & Access Control)"),
        ("6", "Priya Shah", "202512105", "Navigation & User Flow (Routing, State & Mobile UI Experience)"),
        ("7", "Jenil Shah", "202512110", "Cybersecurity (Evidence Vault, SHA-256 Hashing & Encryption)"),
        ("8", "Krisha Doshi", "202512112", "Mobile UI Engineering (Flutter, Material 3 & Responsive Screens)")
    ]
    for r_idx, row in enumerate(team_data):
        for c_idx, val in enumerate(row):
            cell = t1.cell(r_idx + 1, c_idx)
            cell.fill.solid()
            cell.fill.fore_color.rgb = C_BG if r_idx % 2 == 0 else C_CARD_BG
            p = cell.text_frame.paragraphs[0]
            p.text = val
            p.font.name = "Arial"
            p.font.size = Pt(10.5)
            p.font.color.rgb = C_TEXT_MAIN

    # ==========================================
    # SLIDE 2: Problem Definition & Market Gaps
    # ==========================================
    s2 = prs.slides.add_slide(blank_layout)
    add_slide_header(s2, "Problem Definition & Market Gaps", "2. Problem Analysis")

    prob_cards = [
        ("Gap 1: Single-Vector Focus (Physical vs Cyber)", [
            "Current apps only offer physical panic buttons.",
            "Completely ignore online blackmail, doxxing & cyberstalking.",
            "Zero unified link between physical transit & cyber defense."
        ], Inches(0.8), Inches(1.6), Inches(3.7), Inches(4.3)),
        ("Gap 2: Acute Stress & Panic Latency", [
            "Victims under attack cannot unlock phones or tap menus.",
            "Illuminating a screen or speaking aloud alerts assailants.",
            "Lack of stealth hardware & offline secret voice triggers."
        ], Inches(4.8), Inches(1.6), Inches(3.7), Inches(4.3)),
        ("Gap 3: Digital Evidence Destruction", [
            "Abusers delete chats or use disappearing message features.",
            "Screenshots lack cryptographic metadata & timestamps.",
            "Evidence is rejected in court under Section 65B requirements."
        ], Inches(8.8), Inches(1.6), Inches(3.7), Inches(4.3))
    ]
    for title, pts, x, y, w, h in prob_cards:
        add_minimal_card(s2, x, y, w, h, title, pts, accent_color=C_TEXT_MAIN, title_size=13.5, body_size=11)

    b_box = s2.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), Inches(6.2), Inches(11.7), Inches(0.6))
    b_box.fill.solid()
    b_box.fill.fore_color.rgb = RGBColor(241, 245, 249)
    b_box.line.color.rgb = C_CARD_BORDER
    p = b_box.text_frame.paragraphs[0]
    p.text = "Key Takeaway: Women need a proactive platform integrating instant stealth triggers with tamper-proof evidence preservation."
    p.font.name = "Arial"
    p.font.size = Pt(11)
    p.font.bold = True
    p.font.color.rgb = C_TEXT_MAIN

    # ==========================================
    # SLIDE 3: Proposed Solution — The SHE SHIELD Ecosystem
    # ==========================================
    s3 = prs.slides.add_slide(blank_layout)
    add_slide_header(s3, "Proposed Solution — The SHE SHIELD Ecosystem", "3. Solution Architecture")

    sol_cards = [
        ("Pillar 1: Physical SOS & Transit Tracking", [
            "Stealth Triggers: BLE pendant, voice 'capcap', power clicks.",
            "Sub-2s dispatch broadcasting GPS to Guardians & Police 112.",
            "Cab Guardian: Real-time route deviation alerts (>30m offset)."
        ], Inches(0.8), Inches(1.6), Inches(3.7), Inches(4.3)),
        ("Pillar 2: AI Cybercrime & OCR Ingestion", [
            "Screenshot Scanning: OCR extracts text, handles & timestamps.",
            "AI Threat Model: PyTorch NLP evaluates danger severity (92%).",
            "Auto-Police Dossier: Generates structured complaint reports."
        ], Inches(4.8), Inches(1.6), Inches(3.7), Inches(4.3)),
        ("Pillar 3: Cryptographic Evidence Vault", [
            "Blackbox Capture: Continuous audio/video during active trips.",
            "Client SHA-256 Digest: Hashed locally before leaving device.",
            "AES-256 Encryption: Legally tamper-proof for court admissibility."
        ], Inches(8.8), Inches(1.6), Inches(3.7), Inches(4.3))
    ]
    for title, pts, x, y, w, h in sol_cards:
        add_minimal_card(s3, x, y, w, h, title, pts, accent_color=C_ACCENT_INDIGO, title_size=13.5, body_size=11)

    b_box3 = s3.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), Inches(6.2), Inches(11.7), Inches(0.6))
    b_box3.fill.solid()
    b_box3.fill.fore_color.rgb = RGBColor(241, 245, 249)
    b_box3.line.color.rgb = C_CARD_BORDER
    p = b_box3.text_frame.paragraphs[0]
    p.text = "Core Flow: Stealth Trigger  →  Instant Multi-Target Alert  →  Continuous Route Tracking  →  Forensic Evidence Notarization"
    p.font.name = "Arial"
    p.font.size = Pt(11)
    p.font.bold = True
    p.font.color.rgb = C_TEXT_MAIN

    # ==========================================
    # SLIDE 4: Stakeholders & User Roles (RBAC)
    # ==========================================
    s4 = prs.slides.add_slide(blank_layout)
    add_slide_header(s4, "Stakeholders & User Roles (RBAC)", "4. Access Control & Personas")

    roles = [
        ("1. Women / Primary User", [
            "Trigger stealth SOS (<= 2s).",
            "Activate Cab & Walk Guardian.",
            "Report cyber harassment & chats.",
            "Access personal Evidence Vault."
        ], Inches(0.8), Inches(1.6), Inches(2.75), Inches(4.3)),
        ("2. Trusted Guardians", [
            "Receive live GPS waypoint stream.",
            "Instant route deviation push alerts.",
            "Automated offline SMS fallback links.",
            "Confirm safe trip arrivals."
        ], Inches(3.75), Inches(1.6), Inches(2.75), Inches(4.3)),
        ("3. Police & Responders", [
            "Live emergency incident radar map.",
            "Prioritized dispatch queue & triage.",
            "Access victim profile & GPS history.",
            "Download court-admissible dossiers."
        ], Inches(6.7), Inches(1.6), Inches(2.75), Inches(4.3)),
        ("4. System Administrators", [
            "Manage RBAC role permissions.",
            "Configure unsafe zone polygons.",
            "Inspect immutable audit logs.",
            "Oversee AI models & server health."
        ], Inches(9.65), Inches(1.6), Inches(2.85), Inches(4.3))
    ]
    for title, pts, x, y, w, h in roles:
        add_minimal_card(s4, x, y, w, h, title, pts, accent_color=C_TEXT_MAIN, title_size=12.5, body_size=10.5)

    b_box4 = s4.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.8), Inches(6.2), Inches(11.7), Inches(0.6))
    b_box4.fill.solid()
    b_box4.fill.fore_color.rgb = RGBColor(241, 245, 249)
    b_box4.line.color.rgb = C_CARD_BORDER
    p = b_box4.text_frame.paragraphs[0]
    p.text = "RBAC Security: Strict separation of privileges enforced via cryptographically signed JWT tokens on every API request."
    p.font.name = "Arial"
    p.font.size = Pt(11)
    p.font.bold = True
    p.font.color.rgb = C_TEXT_MAIN

    # ==========================================
    # SLIDE 5: Core Functional Requirements (BRD / SRS)
    # ==========================================
    s5 = prs.slides.add_slide(blank_layout)
    add_slide_header(s5, "Core Functional Requirements (BRD / SRS)", "5. Requirements Specification")

    req_table = s5.shapes.add_table(6, 4, Inches(0.8), Inches(1.6), Inches(11.7), Inches(5.0))
    t5 = req_table.table
    col_w5 = [Inches(1.2), Inches(2.8), Inches(4.5), Inches(3.2)]
    for i, w in enumerate(col_w5):
        t5.columns[i].width = w

    headers = ["Req ID", "Core Function", "Engineering Target & Logic", "Verification Criteria"]
    for i, h in enumerate(headers):
        cell = t5.cell(0, i)
        cell.fill.solid()
        cell.fill.fore_color.rgb = RGBColor(241, 245, 249)
        p = cell.text_frame.paragraphs[0]
        p.text = h
        p.font.name = "Arial"
        p.font.size = Pt(10.5)
        p.font.bold = True
        p.font.color.rgb = C_TEXT_MAIN

    req_data = [
        ("FR-01", "Instant SOS Dispatch", "Emergency signal latency <= 2 seconds from trigger to server ack.", "Sub-2s benchmark under LTE & BLE triggers"),
        ("FR-02", "Live GPS Stream", "Waypoint stream every 3–5 seconds with Kalman filtering.", "Smooth breadcrumb path on responder map"),
        ("FR-03", "Route Deviation Alerts", "Haversine offset detection flagging route detours >30 meters.", "Auto-notification to guardians upon detour"),
        ("FR-04", "Cyber Incident Logging", "OCR text parsing from screenshots + NLP threat risk scoring.", "Extracted text & score generated in <3s"),
        ("FR-05", "Evidence Hashing", "Client-side SHA-256 fingerprinting before file upload.", "Hash match check ensures zero file tampering")
    ]
    for r_idx, row in enumerate(req_data):
        for c_idx, val in enumerate(row):
            cell = t5.cell(r_idx + 1, c_idx)
            cell.fill.solid()
            cell.fill.fore_color.rgb = C_BG if r_idx % 2 == 0 else C_CARD_BG
            p = cell.text_frame.paragraphs[0]
            p.text = val
            p.font.name = "Arial"
            p.font.size = Pt(10)
            p.font.color.rgb = C_TEXT_MAIN

    # ==========================================
    # SLIDE 6: Non-Functional Requirements & Security Mandates
    # ==========================================
    s6 = prs.slides.add_slide(blank_layout)
    add_slide_header(s6, "Non-Functional Requirements & Security Mandates", "6. Quality & Security Standards")

    nfr_cards = [
        ("1. High Availability (99.9% Uptime)", [
            "Zero single-point-of-failure for emergency dispatch.",
            "Auto-scaling WSGI workers & Redis pub/sub queue.",
            "Health check monitoring with sub-30s pod recovery."
        ], Inches(0.8), Inches(1.6), Inches(5.6), Inches(2.2)),
        ("2. Location Privacy & Minimization", [
            "Strict adherence to DPDP Act (India) & GDPR principles.",
            "Automated 30-day scheduled purging of transit logs.",
            "End-to-end TLS 1.3 transit encryption for all telemetry."
        ], Inches(6.8), Inches(1.6), Inches(5.7), Inches(2.2)),
        ("3. Offline SMS Fallback Queue", [
            "Client detects cellular data loss automatically.",
            "Local SQLite queue caches GPS coordinates.",
            "Auto-dispatches SMS with live Google Maps link."
        ], Inches(0.8), Inches(4.1), Inches(5.6), Inches(2.3)),
        ("4. SHA-256 Evidence Integrity", [
            "Client-side hashing proves media was never altered.",
            "Guarantees legal admissibility under Evidence Act Sec 65B.",
            "Immutable audit log records hash, size & timestamp."
        ], Inches(6.8), Inches(4.1), Inches(5.7), Inches(2.3))
    ]
    for title, pts, x, y, w, h in nfr_cards:
        add_minimal_card(s6, x, y, w, h, title, pts, accent_color=C_TEXT_MAIN, title_size=13, body_size=10.5)

    # ==========================================
    # SLIDE 7: DESIGN COMPONENTS — Three-Tier System Architecture
    # ==========================================
    s7 = prs.slides.add_slide(blank_layout)
    add_slide_header(s7, "Design Components", "Design Components : Three-Tier System Architecture")

    # Image (Left)
    arch_img = "extracted_assets/three_tier_architecture.jpg"
    if os.path.exists(arch_img):
        s7.shapes.add_picture(arch_img, Inches(0.8), Inches(1.5), height=Inches(5.4))

    # Clean Explanation Cards (Right)
    tb_w = Inches(7.4)
    tb_x = Inches(5.1)
    
    tier_cards = [
        ("Tier 1: Frontend Layer (Mobile & Web)", [
            "Flutter Mobile App (Women): 60fps UI, stealth triggers, background sensors.",
            "React.js Web Command Dashboard: High-density radar for Police & Admins.",
            "Protocol: Secure HTTPS / RESTful communication."
        ], tb_x, Inches(1.5), tb_w, Inches(1.65)),
        ("Tier 2: Backend & AI Layer (Microservices & Threat Engine)", [
            "API Gateway: Centralized JWT Authentication, RBAC & Request Routing.",
            "Python Flask Microservices: Authentication, Emergency SOS, Travel Tracker, Cybercrime Intake.",
            "AI Threat Engine: Real-time Distress Audio Classifier & OCR Screenshot Scanner."
        ], tb_x, Inches(3.3), tb_w, Inches(1.8)),
        ("Tier 3: Database & Storage Layer (ACID & Cryptographic Vault)", [
            "Relational Database: Stores User Accounts, Roles, Complaint Logs & Emergency Sessions.",
            "Encrypted Evidence Vault: AES-256 File Encryption & SHA-256 Integrity Hashes."
        ], tb_x, Inches(5.25), tb_w, Inches(1.65))
    ]
    for title, pts, x, y, w, h in tier_cards:
        add_minimal_card(s7, x, y, w, h, title, pts, accent_color=C_ACCENT_INDIGO, title_size=12.5, body_size=10.5)

    # ==========================================
    # SLIDE 8: DESIGN COMPONENTS — Use Case Diagram
    # ==========================================
    s8 = prs.slides.add_slide(blank_layout)
    add_slide_header(s8, "Design Components", "Design Components : Use Case Model & System Boundary")

    # Image (Left)
    uc_img = "extracted_assets/use_case_diagram.jpg"
    if os.path.exists(uc_img):
        s8.shapes.add_picture(uc_img, Inches(0.8), Inches(1.5), height=Inches(5.4))

    # Clean Actor Cards (Right)
    uc_x = Inches(4.3)
    uc_w = Inches(8.2)

    actor_cards = [
        ("Actor 1: Woman (Primary User)", [
            "Trigger Emergency SOS: Initiates instant distress broadcast via stealth or button.",
            "Upload & Secure Evidence: Stores incident files in AES-256 Cryptographic Vault.",
            "Report Cybercrime Harassment: Submits screenshots and chat logs for AI evaluation.",
            "Track Travel & Cab Journey: Real-time route deviation & safe arrival monitoring."
        ], uc_x, Inches(1.5), uc_w, Inches(1.8)),
        ("Actor 2: Trusted Guardian", [
            "Receive Emergency SMS with Live GPS Link: Immediate offline/cellular coordinate alert.",
            "View Safety Status: Live breadcrumb tracking during active transit trips."
        ], uc_x, Inches(3.45), uc_w, Inches(1.4)),
        ("Actor 3: Police / Administrator", [
            "Manage Cases: Coordinate emergency dispatches and assign response units.",
            "Review Cybercrime Complaints: Access AI threat-scored dossiers and parsed OCR evidence.",
            "Monitor Live Emergency Alerts: Real-time geographic radar of active SOS sessions."
        ], uc_x, Inches(5.0), uc_w, Inches(1.9))
    ]
    for title, pts, x, y, w, h in actor_cards:
        add_minimal_card(s8, x, y, w, h, title, pts, accent_color=C_TEXT_MAIN, title_size=12.5, body_size=10.5)

    # ==========================================
    # SLIDE 9: DESIGN COMPONENTS — Emergency SOS Flow
    # ==========================================
    s9 = prs.slides.add_slide(blank_layout)
    add_slide_header(s9, "Design Components", "Design Components : Emergency SOS Execution Flow")

    # Image (Left)
    flow_img = "extracted_assets/sos_flow_diagram.jpg"
    if os.path.exists(flow_img):
        s9.shapes.add_picture(flow_img, Inches(0.8), Inches(1.5), height=Inches(5.4))

    # Flow Explanation (Right)
    fl_x = Inches(5.5)
    fl_w = Inches(7.0)

    flow_cards = [
        ("Phase 1: Distress Trigger & Telemetry Acquisition", [
            "Woman triggers SOS via physical button, BLE pendant, or voice phrase.",
            "Mobile app immediately captures high-precision GPS coordinates & device state."
        ], fl_x, Inches(1.5), fl_w, Inches(1.2)),
        ("Phase 2: Backend Ingestion & Persistent Storage", [
            "App sends emergency payload to Flask API gateway via secure REST endpoint.",
            "Emergency record is instantly committed to PostgreSQL database with UTC timestamp."
        ], fl_x, Inches(2.85), fl_w, Inches(1.2)),
        ("Phase 3: Parallel Broadcast (Fork Execution)", [
            "Branch A (Guardians): Automated SMS dispatched with live Google Maps coordinate link.",
            "Branch B (Police): Real-time emergency alert pushed onto Police Command Dashboard radar."
        ], fl_x, Inches(4.2), fl_w, Inches(1.35)),
        ("Phase 4: Confirmation & Safe Resolution (Join)", [
            "System renders visual SOS confirmation & haptic feedback to user.",
            "Live location tracking loop continues until the emergency session is safely resolved."
        ], fl_x, Inches(5.7), fl_w, Inches(1.2))
    ]
    for title, pts, x, y, w, h in flow_cards:
        add_minimal_card(s9, x, y, w, h, title, pts, accent_color=C_ACCENT_INDIGO, title_size=12.5, body_size=10.5)

    # ==========================================
    # SLIDE 10: Technology Stack Justification
    # ==========================================
    s10 = prs.slides.add_slide(blank_layout)
    add_slide_header(s10, "Technology Stack Justification", "9. Engineering Stack Rationale")

    tech_table = s10.shapes.add_table(6, 4, Inches(0.8), Inches(1.6), Inches(11.7), Inches(5.0))
    t10 = tech_table.table
    col_w10 = [Inches(2.0), Inches(1.8), Inches(2.6), Inches(5.3)]
    for i, w in enumerate(col_w10):
        t10.columns[i].width = w

    headers = ["Technology", "Layer", "Selection", "Why It Was Chosen for SHE SHIELD"]
    for i, h in enumerate(headers):
        cell = t10.cell(0, i)
        cell.fill.solid()
        cell.fill.fore_color.rgb = RGBColor(241, 245, 249)
        p = cell.text_frame.paragraphs[0]
        p.text = h
        p.font.name = "Arial"
        p.font.size = Pt(10.5)
        p.font.bold = True
        p.font.color.rgb = C_TEXT_MAIN

    tech_data = [
        ("Mobile Client", "Presentation", "Flutter 3.x (Dart)", "Single codebase for Android/iOS, 60fps UI, low-latency BLE sensor bindings."),
        ("Command Portal", "Presentation", "React.js + Tailwind", "High-density real-time radar for police dispatchers with WebSocket updates."),
        ("Backend Services", "Application APIs", "Python (Flask)", "Lightweight WSGI routing, native PyTorch/OpenCV AI integration, fast boot time."),
        ("Relational Store", "Database", "PostgreSQL", "Strict ACID compliance for user accounts, RBAC roles, audit logs & complaints."),
        ("Telemetry Stream", "Cache & Pub/Sub", "Redis", "Sub-millisecond latency for live GPS waypoint distribution and session queues.")
    ]
    for r_idx, row in enumerate(tech_data):
        for c_idx, val in enumerate(row):
            cell = t10.cell(r_idx + 1, c_idx)
            cell.fill.solid()
            cell.fill.fore_color.rgb = C_BG if r_idx % 2 == 0 else C_CARD_BG
            p = cell.text_frame.paragraphs[0]
            p.text = val
            p.font.name = "Arial"
            p.font.size = Pt(10)
            p.font.color.rgb = C_TEXT_MAIN

    # ==========================================
    # SLIDE 11: Security Architecture & Cryptographic Integrity
    # ==========================================
    s11 = prs.slides.add_slide(blank_layout)
    add_slide_header(s11, "Security Architecture & Cryptographic Integrity", "10. Defense-in-Depth & Legal Integrity")

    sec_cards = [
        ("1. Role-Based Access (JWT)", [
            "Cryptographically signed stateless tokens.",
            "Short-lived 15-minute access expiration.",
            "Granular permission scopes by user role."
        ], Inches(0.8), Inches(1.6), Inches(5.6), Inches(2.2)),
        ("2. AES-256-GCM Encryption", [
            "Authenticated Galois/Counter Mode cipher.",
            "Unique Initialization Vector (IV) per asset.",
            "Applied to evidence at rest and in transit."
        ], Inches(6.8), Inches(1.6), Inches(5.7), Inches(2.2)),
        ("3. Sliding-Window Rate Limiting", [
            "Redis-backed token bucket request tracking.",
            "Defends emergency APIs against DDoS floods.",
            "Prioritizes active emergency SOS traffic."
        ], Inches(0.8), Inches(4.1), Inches(5.6), Inches(2.3)),
        ("4. Section 65B Legal Admissibility", [
            "Client SHA-256 digest created at recording.",
            "Immutable ledger stores hash with timestamp.",
            "Provides bit-for-bit proof of non-tampering."
        ], Inches(6.8), Inches(4.1), Inches(5.7), Inches(2.3))
    ]
    for title, pts, x, y, w, h in sec_cards:
        add_minimal_card(s11, x, y, w, h, title, pts, accent_color=C_TEXT_MAIN, title_size=13, body_size=10.5)

    # ==========================================
    # SLIDE 12: Current Implementation Progress (Weeks 1–11)
    # ==========================================
    s12 = prs.slides.add_slide(blank_layout)
    add_slide_header(s12, "Current Implementation Progress (Weeks 1–11)", "11. Sprint Deliverables (GitHub Status)")

    prog_table = s12.shapes.add_table(7, 4, Inches(0.8), Inches(1.6), Inches(11.7), Inches(5.0))
    t12 = prog_table.table
    col_w12 = [Inches(2.0), Inches(4.2), Inches(3.8), Inches(1.7)]
    for i, w in enumerate(col_w12):
        t12.columns[i].width = w

    headers = ["Milestone", "Delivered Feature & Module", "GitHub Repository Artifact", "Status"]
    for i, h in enumerate(headers):
        cell = t12.cell(0, i)
        cell.fill.solid()
        cell.fill.fore_color.rgb = RGBColor(241, 245, 249)
        p = cell.text_frame.paragraphs[0]
        p.text = h
        p.font.name = "Arial"
        p.font.size = Pt(10.5)
        p.font.bold = True
        p.font.color.rgb = C_TEXT_MAIN

    prog_data = [
        ("M1: Foundations", "System architecture, UI design system, Provider state framework.", "lib/main.dart, lib/theme/app_theme.dart", "100% Live"),
        ("M2: Auth & RBAC", "User, Guardian, Responder, Admin registration and login guards.", "lib/screens/auth_screens.dart", "100% Live"),
        ("M3: SOS Center", "Multi-modal trigger engine, 5s countdown timer, volume double-click.", "lib/screens/sos_screens.dart", "100% Live"),
        ("M4: Travel Monitor", "Cab Guardian & Walk Guardian with 30m route offset deviation check.", "lib/screens/travel_monitor_screen.dart", "100% Live"),
        ("M5: Cybercrime Desk", "Cyber complaint intake, OCR screenshot scan, PyTorch threat score.", "lib/screens/cyber_screens.dart", "100% Live"),
        ("M6: Command Hub", "Admin Command Center, Responder live radar, and Evidence Locker.", "lib/screens/admin_command_center_screen.dart", "100% Live")
    ]
    for r_idx, row in enumerate(prog_data):
        for c_idx, val in enumerate(row):
            cell = t12.cell(r_idx + 1, c_idx)
            cell.fill.solid()
            cell.fill.fore_color.rgb = C_BG if r_idx % 2 == 0 else C_CARD_BG
            p = cell.text_frame.paragraphs[0]
            p.text = val
            p.font.name = "Arial"
            p.font.size = Pt(10)
            p.font.color.rgb = C_TEXT_MAIN

    # ==========================================
    # SLIDE 13: Next Steps (Weeks 12–16) & Q&A Conclusion
    # ==========================================
    s13 = prs.slides.add_slide(blank_layout)
    add_slide_header(s13, "Next Steps (Weeks 12–16) & Conclusion", "12. Project Roadmap & Q&A")

    roadmap_steps = [
        ("Weeks 12–13: End-to-End Integration", [
            "Connect Flutter mobile client, Flask microservices, and React admin desk.",
            "Harden WebSocket real-time synchronization under simulated network loss."
        ], Inches(0.8), Inches(1.6), Inches(5.6), Inches(2.2)),
        ("Week 14: GPS Geofencing Field Benchmarks", [
            "Test Haversine route deviation accuracy in dense urban multi-path corridors.",
            "Calibrate Kalman filter to eliminate GPS drift around high-rise buildings."
        ], Inches(6.8), Inches(1.6), Inches(5.7), Inches(2.2)),
        ("Week 15: High-Concurrency Load Testing", [
            "Simulate 5,000+ simultaneous emergency SOS trigger bursts using Locust.",
            "Conduct penetration testing and token vulnerability audits."
        ], Inches(0.8), Inches(4.1), Inches(5.6), Inches(2.3)),
        ("Week 16: Final Release & Viva Defense", [
            "Final production Docker containerization and signed APK release.",
            "Community pilot trial testing and Course Viva Voce evaluation."
        ], Inches(6.8), Inches(4.1), Inches(5.7), Inches(2.3))
    ]
    for title, pts, x, y, w, h in roadmap_steps:
        add_minimal_card(s13, x, y, w, h, title, pts, accent_color=C_TEXT_MAIN, title_size=13, body_size=10.5)

    output_path = "SheShield_Minimalist_Presentation.pptx"
    prs.save(output_path)
    print(f"Successfully generated {output_path} with {len(prs.slides)} slides (including Design Components)!")

if __name__ == "__main__":
    build_presentation()
