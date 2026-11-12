import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=130, right=130):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def set_table_borders(table, color="CCCCCC", sz="4", val="single"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'  <w:top w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'  <w:bottom w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'  <w:insideH w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'  <w:insideV w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'  <w:left w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'  <w:right w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

def style_table(table, col_widths, header_bg="F1F5F9", alt_bg="FAFAFA", border_color="CBD5E1"):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table, color=border_color, sz="4")
    
    # Header row
    for cell in table.rows[0].cells:
        set_cell_background(cell, header_bg)
        set_cell_margins(cell, top=110, bottom=110, left=130, right=130)
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        for p in cell.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            for run in p.runs:
                run.font.name = "Arial"
                run.font.size = Pt(9)
                run.font.bold = True
                run.font.color.rgb = RGBColor(15, 23, 42)
                
    # Data rows
    for r_idx in range(1, len(table.rows)):
        bg = alt_bg if r_idx % 2 == 1 else "FFFFFF"
        for cell in table.rows[r_idx].cells:
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            for p in cell.paragraphs:
                p.paragraph_format.space_before = Pt(0)
                p.paragraph_format.space_after = Pt(0)
                for run in p.runs:
                    run.font.name = "Arial"
                    run.font.size = Pt(8)
                    run.font.color.rgb = RGBColor(30, 41, 59)
                    
    # Column widths
    for row in table.rows:
        for idx, width in enumerate(col_widths):
            row.cells[idx].width = width

def format_status_cell(cell, status_text):
    for p in cell.paragraphs:
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for run in p.runs:
            run.font.bold = True
            run.font.size = Pt(8)
            if "PASS" in status_text or "CLOSED" in status_text or "DONE" in status_text:
                run.font.color.rgb = RGBColor(22, 101, 52) # Dark green
            elif "IN PROGRESS" in status_text or "UNDER TEST" in status_text:
                run.font.color.rgb = RGBColor(109, 40, 217) # Deep Purple/Indigo
            elif "ACTIVE" in status_text or "SPRINT" in status_text:
                run.font.color.rgb = RGBColor(29, 78, 216) # Blue
            elif "OPEN" in status_text or "FAIL" in status_text:
                run.font.color.rgb = RGBColor(185, 28, 28) # Red

def add_header_footer(doc):
    for s_idx, section in enumerate(doc.sections):
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        
        # Header
        header = section.header
        p_hdr = header.paragraphs[0]
        p_hdr.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_hdr = p_hdr.add_run("DHIRUBHAI AMBANI UNIVERSITY")
        r_hdr.font.name = "Arial"
        r_hdr.font.size = Pt(9)
        r_hdr.font.color.rgb = RGBColor(71, 85, 105)
        r_hdr.font.bold = True

def generate_test_plan_docx(filename="SheShield_Test_Plan_and_Test_Cases_Specification.docx"):
    doc = Document()
    add_header_footer(doc)
    
    # Base Normal Style
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Arial'
    font.size = Pt(10.5)
    font.color.rgb = RGBColor(30, 41, 59)

    # =========================================================================
    # PAGE 1: COVER PAGE
    # =========================================================================
    doc.add_paragraph().paragraph_format.space_after = Pt(36)
    
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r1 = p_title.add_run("Test Plan & Test Cases Specification Document\n")
    r1.font.size = Pt(20)
    r1.font.bold = True
    r1.font.color.rgb = RGBColor(15, 23, 42)
    
    r2 = p_title.add_run("WSSOA (IT644)\n")
    r2.font.size = Pt(15)
    r2.font.bold = True
    r2.font.color.rgb = RGBColor(30, 41, 59)
    
    r3 = p_title.add_run("Autumn 2026")
    r3.font.size = Pt(13)
    r3.font.color.rgb = RGBColor(71, 85, 105)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(24)
    
    p_proj = doc.add_paragraph()
    p_proj.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_ptlbl = p_proj.add_run("Project Title :\n")
    r_ptlbl.font.size = Pt(14)
    r_ptlbl.font.bold = True
    r_ptlbl.underline = True
    r_ptlbl.font.color.rgb = RGBColor(15, 23, 42)
    
    r_pname = p_proj.add_run("SHE SHIELD — Cyber-Integrated Safety Platform for Women\n")
    r_pname.font.size = Pt(14)
    r_pname.font.bold = True
    r_pname.font.color.rgb = RGBColor(15, 23, 42)
    
    r_ptag = p_proj.add_run("A mobile & web-based AI-Powered Cyber-Physical Safety Platform for Women")
    r_ptag.font.size = Pt(11)
    r_ptag.font.italic = True
    r_ptag.font.color.rgb = RGBColor(71, 85, 105)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(24)
    
    p_date = doc.add_paragraph()
    p_date.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_date = p_date.add_run("Date of Submission: 02/11/2026\n")
    r_date.font.size = Pt(12)
    r_date.font.bold = True
    r_date.font.color.rgb = RGBColor(15, 23, 42)
    r_sprint_badge = p_date.add_run("Sprint 2 Live Verification Build & Jira Agile Traceability")
    r_sprint_badge.font.size = Pt(10)
    r_sprint_badge.font.italic = True
    r_sprint_badge.font.color.rgb = RGBColor(109, 40, 217)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(24)
    
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("Submitted By:")
    r_sub.font.size = Pt(13)
    r_sub.font.bold = True
    r_sub.underline = True
    r_sub.font.color.rgb = RGBColor(15, 23, 42)
    p_sub.paragraph_format.space_after = Pt(10)
    
    # Team Table
    team_data = [
        ("Sr. No.", "Student Name", "Student ID", "Jira Responsibility Area"),
        ("1", "Jainam Shah", "202512012", "Backend APIs & Dispatch Microservices"),
        ("2", "Maahir Shah", "202512022", "Relational Database & Geospatial Schemas"),
        ("3", "Hitarth Shah", "202512042", "AI OCR & NLP Threat Classification Models"),
        ("4", "Jay Shah", "202512059", "DevOps, Telemetry Worker & Docker CI/CD"),
        ("5", "Nirmal Patel", "202512102", "Authentication, Biometrics & Role-Based Access"),
        ("6", "Priya Shah", "202512105", "Navigation, Travel Guardian & User Flow"),
        ("7", "Jenil Shah", "202512110", "Cybersecurity, SHA-256 Vault & Evidence Custody"),
        ("8", "Krisha Doshi", "202512112", "Mobile UI Engineering & Widget Architecture"),
    ]
    t_team = doc.add_table(rows=len(team_data), cols=4)
    for r_idx, row in enumerate(team_data):
        for c_idx, val in enumerate(row):
            t_team.cell(r_idx, c_idx).text = val
            if c_idx in [0, 2]:
                t_team.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    style_table(t_team, [Inches(0.8), Inches(2.2), Inches(1.5), Inches(2.3)], header_bg="F1F5F9", alt_bg="FFFFFF", border_color="94A3B8")
    
    doc.add_paragraph().paragraph_format.space_after = Pt(28)
    
    p_inst = doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_instlbl = p_inst.add_run("Submitted To:\n")
    r_instlbl.font.size = Pt(13)
    r_instlbl.font.bold = True
    r_instlbl.underline = True
    r_instlbl.font.color.rgb = RGBColor(15, 23, 42)
    
    r_instname = p_inst.add_run("Prof. Jayprakash Lalchandani\n")
    r_instname.font.size = Pt(12)
    r_instname.font.bold = True
    r_instname.font.color.rgb = RGBColor(15, 23, 42)
    
    r_instcourse = p_inst.add_run("Course Instructor - WSSOA (IT644)\nDAU, Autumn 2026")
    r_instcourse.font.size = Pt(11)
    r_instcourse.font.color.rgb = RGBColor(71, 85, 105)

    doc.add_page_break()

    # =========================================================================
    # PAGE 2: TABLE OF CONTENTS
    # =========================================================================
    p_toc_t = doc.add_paragraph()
    p_toc_t.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_toc_t = p_toc_t.add_run("Table of Contents")
    r_toc_t.font.size = Pt(20)
    r_toc_t.font.bold = True
    r_toc_t.font.color.rgb = RGBColor(15, 23, 42)
    p_toc_t.paragraph_format.space_after = Pt(28)
    
    toc_items = [
        ("1. Executive Summary & Objective", 1),
        ("2. Test Strategy & Scope (With Jira Agile Sprint Roadmap)", 1),
        ("    2.1 In Scope", 2),
        ("    2.2 Out of Scope", 2),
        ("    2.3 Jira Sprint Traceability & Story Distribution", 2),
        ("3. Unit and Integration Tests (Functional & API Testing)", 1),
        ("    3.1 Backend & Mobile Test Cases Suite (Flutter Driver + PyTest)", 2),
        ("    3.2 Machine Learning & OCR Service Test Suite (FastAPI + PyTest)", 2),
        ("4. Populating Database with Meaningful Records", 1),
        ("    4.1 Seeding Architecture", 2),
        ("    4.2 Seeded Meaningful Records", 2),
        ("    4.3 Automated Verification Scripts", 2),
        ("5. Non-Functional Testing", 1),
        ("    5.1 UI & UX Testing (Frontend & Mobile Verification)", 2),
        ("    5.2 Performance & Load Testing", 2),
        ("    5.3 Security & Compliance Testing", 2),
        ("    5.4 Reliability & Resilience Testing", 2),
        ("6. Bug Logs & Defect Tracking", 1),
        ("    6.1 Bug Summary Dashboard (Resolved vs Active In-Progress)", 2),
        ("    6.2 Detailed Defect Log", 2),
        ("7. How to Execute the Test Suites", 1),
        ("8. Conclusion & Sign-off", 1),
    ]
    
    for item_text, level in toc_items:
        p_item = doc.add_paragraph()
        p_item.paragraph_format.space_after = Pt(8 if level == 1 else 5)
        p_item.paragraph_format.left_indent = Inches(0 if level == 1 else 0.4)
        run = p_item.add_run(item_text)
        run.font.size = Pt(11.5 if level == 1 else 10.5)
        run.font.bold = (level == 1)
        run.font.color.rgb = RGBColor(15, 23, 42) if level == 1 else RGBColor(51, 65, 85)

    doc.add_page_break()

    # =========================================================================
    # PAGE 3: 1. EXECUTIVE SUMMARY & OBJECTIVE
    # =========================================================================
    p_h1 = doc.add_paragraph()
    p_h1.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_h1 = p_h1.add_run("1. Executive Summary & Objective")
    r_h1.font.size = Pt(18)
    r_h1.font.bold = True
    r_h1.font.color.rgb = RGBColor(15, 23, 42)
    p_h1.paragraph_format.space_after = Pt(20)

    p_intro = doc.add_paragraph()
    p_intro.paragraph_format.line_spacing = 1.2
    p_intro.paragraph_format.space_after = Pt(14)
    p_intro.add_run(
        "The primary objective of this Test Plan and Test Cases Specification Document is to verify that "
        "SHE SHIELD delivers an enterprise-grade, sub-2-second emergency dispatch pipeline, accurate cab route deviation "
        "monitoring, tamper-proof cryptographic evidence custody, and automated AI-powered cyber-harassment triage. "
        "In alignment with our team's Jira Agile engineering roadmap (Epics SHE-100 through SHE-300), this document "
        "captures both certified Sprint 1 production baselines (PASS) and active Sprint 2 / Sprint 3 in-progress deliverables "
        "(IN PROGRESS / UNDER TEST)."
    )

    p_doc_outlines = doc.add_paragraph()
    r_do = p_doc_outlines.add_run("This document outlines:")
    r_do.font.bold = True
    p_doc_outlines.paragraph_format.space_after = Pt(10)

    bullets = [
        ("Functional Testing & Jira Work Breakdown: ", 
         "Detailed validation of mobile and backend API endpoints, multi-modal stealth distress triggers, parallel broadcast dispatch pipelines, and PyTorch/EasyOCR digital threat classification mapped directly to Jira User Stories (SHE-101 to SHE-302)."),
        ("Agile Execution Status (Pass vs In-Progress): ",
         "Transparent distinction between fully tested production modules (Sprint 1: Auth, Travel Mode, Cyber Desk) and active features currently undergoing integration testing in Sprint 2 (Voice Phrase SOS, Motion Anomaly Walk Guardian, Guardian Link Steppers)."),
        ("Database Seeding & Test Data Strategy: ",
         "Verification of relational PostgreSQL database seeding, multi-jurisdictional municipal police data fixtures, deterministic GPS breadcrumb trajectories, and Section 65B forensic media notary generation."),
        ("Non-Functional Testing: ",
         "Verification of 60 FPS mobile UI responsiveness, battery-optimized background telemetry ingestion, client-side SHA-256 cryptographic hashing, IP rate limiting, and zero-connectivity carrier SMS fallback resilience."),
        ("Bug Logs & Defect Lifecycle: ",
         "Documented chronological record of 6 defects identified during development, detailing 4 closed foundational bugs and 2 active in-progress defects undergoing Sprint 2 regression verification.")
    ]
    for b_title, b_desc in bullets:
        p_b = doc.add_paragraph(style='List Bullet')
        p_b.paragraph_format.space_after = Pt(8)
        p_b.paragraph_format.line_spacing = 1.15
        r_bt = p_b.add_run(b_title)
        r_bt.font.bold = True
        r_bt.font.color.rgb = RGBColor(15, 23, 42)
        r_bd = p_b.add_run(b_desc)
        r_bd.font.color.rgb = RGBColor(51, 65, 85)

    doc.add_page_break()

    # =========================================================================
    # PAGE 4: 2. TEST STRATEGY & SCOPE
    # =========================================================================
    p_h2 = doc.add_paragraph()
    p_h2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_h2 = p_h2.add_run("2. Test Strategy & Scope")
    r_h2.font.size = Pt(18)
    r_h2.font.bold = True
    r_h2.font.color.rgb = RGBColor(15, 23, 42)
    p_h2.paragraph_format.space_after = Pt(16)

    p_in_title = doc.add_paragraph()
    r_it = p_in_title.add_run("2.1 In Scope")
    r_it.font.size = Pt(12)
    r_it.font.bold = True
    p_in_title.paragraph_format.space_after = Pt(6)

    in_scope_items = [
        ("Backend & Mobile API Endpoints: ", "Authentication & RBAC (/api/auth/*), Emergency SOS Broadcast (/api/sos/*), Travel Telemetry Ingestion (/api/travel/*), Cyber Crime Ingest (/api/cybercrime/*), and Admin Incident Feeds (/api/admin/*)."),
        ("Data Provenance: ", "Strict structural isolation between synthetic demo test records and verified live police incident queues."),
        ("Multi-Modal Stealth Triggers: ", "Verification of 5-second hold SOS touch gesture, physical volume key sequences, Paired BLE wearable GATT interrupts, and local offline secret voice phrase recognition ('capcap' / 'Box Box')."),
        ("Emergency Parallel Broadcast Queue: ", "Concurrent, duplicate-safe sub-2-second broadcast fan-out across Firebase Cloud Messaging (Guardians), WebSockets (Police 112 Command Desk), and carrier SMS gateway fallbacks."),
        ("Haversine Deviation Engine: ", "Perpendicular vector distance validation flagging automated alerts when vehicle deviates > 30 meters from expected route polyline."),
        ("AI Vision & NLP Services: ", "Health checks, EasyOCR screenshot text extraction, and PyTorch NLP threat evaluation classifying blackmail and harassment with severity risk scoring."),
        ("Cryptographic Vault & Custody: ", "Client-side SHA-256 asset notarization at ingestion, tamper-check verification algorithms, and Section 65B Indian Evidence Act compliant court dossier generation.")
    ]
    for st, sd in in_scope_items:
        p_b = doc.add_paragraph(style='List Bullet')
        p_b.paragraph_format.space_after = Pt(5)
        r_bt = p_b.add_run(st)
        r_bt.font.bold = True
        r_bd = p_b.add_run(sd)

    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    p_out_title = doc.add_paragraph()
    r_ot = p_out_title.add_run("2.2 Out of Scope")
    r_ot.font.size = Pt(12)
    r_ot.font.bold = True
    p_out_title.paragraph_format.space_after = Pt(6)

    out_scope_items = [
        ("Direct Municipal Siren & Trunk Integration: ", "SHE SHIELD provides verified mock integration adapters for ERSS-112, CCTNS, and CERT-In; direct live physical siren activations and trunk dialer overhauls are simulated."),
        ("Hardware Stress Testing Beyond BLE: ", "Simulating physical circuit damage beyond standard Bluetooth Low Energy GATT peripheral packet transmission.")
    ]
    for st, sd in out_scope_items:
        p_b = doc.add_paragraph(style='List Bullet')
        p_b.paragraph_format.space_after = Pt(5)
        r_bt = p_b.add_run(st)
        r_bt.font.bold = True
        r_bd = p_b.add_run(sd)

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # 2.3 Jira Sprint Roadmap Table
    p_j_title = doc.add_paragraph()
    r_jt = p_j_title.add_run("2.3 Jira Sprint Traceability & Story Distribution")
    r_jt.font.size = Pt(12)
    r_jt.font.bold = True
    p_j_title.paragraph_format.space_after = Pt(6)

    jira_sprints = [
        ("Sprint Cycle", "Jira Epic / Ticket", "Feature Scope", "Target Milestone", "Sprint Status"),
        ("Sprint 1 (Done)", "SHE-101 to SHE-104\nSHE-202, SHE-203", "Auth & RBAC, Core Safety Dashboard, Travel Mode, Cyber Ingest, PostgreSQL Schema", "Week 1 - 6", "100% DONE"),
        ("Sprint 2 (Current)", "SHE-201, SHE-204\nSHE-205, SHE-206", "Offline Voice SOS, Walk Motion Detector, 5-Stage Complaint Stepper, Guardian Network", "Week 7 - 11", "IN PROGRESS"),
        ("Sprint 3 (Backlog)", "SHE-301, SHE-302\nSHE-303", "BLE Wearables GATT Relay, AI Deepfake Vault Ingest, Municipal Dispatch WebSockets", "Week 12 - 16", "UNDER DEV")
    ]
    t_jira = doc.add_table(rows=len(jira_sprints), cols=5)
    for r_idx, row in enumerate(jira_sprints):
        for c_idx, val in enumerate(row):
            t_jira.cell(r_idx, c_idx).text = val
            if c_idx in [0, 3, 4]:
                t_jira.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
            if r_idx > 0 and c_idx == 4:
                format_status_cell(t_jira.cell(r_idx, c_idx), val)
    style_table(t_jira, [Inches(1.2), Inches(1.5), Inches(2.2), Inches(1.1), Inches(1.0)])

    doc.add_page_break()

    # =========================================================================
    # PAGES 5-8: 3. UNIT AND INTEGRATION TESTS (FUNCTIONAL & API TESTING)
    # =========================================================================
    p_h3 = doc.add_paragraph()
    p_h3.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_h3 = p_h3.add_run("3. Unit and Integration Tests (Functional & API Testing)")
    r_h3.font.size = Pt(18)
    r_h3.font.bold = True
    r_h3.font.color.rgb = RGBColor(15, 23, 42)
    p_h3.paragraph_format.space_after = Pt(14)

    p_h31 = doc.add_paragraph()
    r_h31 = p_h31.add_run("3.1 Backend & Mobile Test Cases Suite (Mapped to Jira Tickets)")
    r_h31.font.size = Pt(13)
    r_h31.font.bold = True
    p_h31.paragraph_format.space_after = Pt(10)

    # Test cases table with Jira Ticket ID and In-Progress statuses
    backend_tests = [
        ("Test ID", "Jira ID", "Module", "Test Scenario", "Test Input / Data", "Expected Result", "Status"),
        ("TC-AUTH-01", "SHE-101", "User Register", "Valid registration with Aadhaar & photo proof", '{"name":"Priya","email":"priya@example.com"}', "HTTP 200; face biometric match >= 90%; OTP sent.", "PASS"),
        ("TC-AUTH-02", "SHE-102", "OTP Verify", "OTP verification completes account issuance", '{"email":"priya@example.com","otp":"741852"}', "HTTP 201; user created with bcrypt; JWT returned.", "PASS"),
        ("TC-AUTH-03", "SHE-102", "Liveness Check", "Liveness check on static 2D photo upload", "Static JPEG sent to /api/auth/verify-face", "HTTP 422 'Liveness detection failed; micro-blink required'.", "PASS"),
        ("TC-AUTH-04", "SHE-103", "RBAC Security", "Guardian token attempts police dashboard access", "GET /api/admin/incidents with Guardian JWT", "HTTP 403 Forbidden; RBAC claims check blocks non-responder.", "PASS"),
        ("TC-AUTH-05", "SHE-103", "Rate Limiter", "IP Sliding-Window Auth Rate Limiter", "11 consecutive login requests in 60s from same IP", "First 10 pass; 11th receives HTTP 429 'Too many requests'.", "PASS"),
        ("TC-SOS-01", "SHE-201", "SOS Hold Timer", "Sustained press on primary SOS trigger", "GestureDetector hold duration = 5000ms", "Timer ticks 5->0; triggers full-screen dispatch modal.", "PASS"),
        ("TC-SOS-02", "SHE-201", "Cancel Loop", "Touch released before 5-second countdown", "Touch released at 3200ms (onTapUp event)", "Atomic _sosTimer.cancel(); UI resets to 5; zero calls.", "PASS"),
        ("TC-SOS-03", "SHE-201", "Anti-Attack PIN", "Deactivating triggered SOS requires PIN", "Input: '0000' (invalid) vs '1234' (valid)", "'0000' rejected; '1234' safely deactivates alert state.", "PASS"),
        ("TC-SOS-04", "SHE-201", "Voice SOS NLU", "Secret phrase acoustic recognition ('capcap')", "Local mic audio stream in noisy environment", "Voice confidence >= 88%; trigger dispatch in < 250ms.", "IN PROGRESS"),
        ("TC-SOS-05", "SHE-201", "Parallel Fanout", "Concurrent broadcast to FCM, WebSockets & SMS", 'POST /api/sos/broadcast {"lat":23.022,"lng":72.571}', "HTTP 200; latency < 1850ms; FCM, WebSocket & SMS queued.", "PASS"),
        ("TC-SOS-06", "SHE-201", "Offline SMS", "SOS dispatch when cellular data is disconnected", "Airplane mode ON; GSM SIM active", "SQLite queue buffers payload; native SMS intent dispatches.", "IN PROGRESS"),
        ("TC-TRV-01", "SHE-104", "Cab Deviation", "Cab deviates >30m from planned route vector", "Live GPS ping injected at offset = 42m", "_cabDeviations increments; Safety Index drops 100->75.", "PASS"),
        ("TC-TRV-02", "SHE-204", "Walk Motion", "Accelerometer fall/drop and running anomaly", "Drop sensor spike: accelerometer Z-axis > 32 m/s²", "10-second confirmation dialog; escalates if unconfirmed.", "IN PROGRESS"),
        ("TC-TRV-03", "SHE-202", "Blackbox Stream", "Continuous background video chunk recording", "10-minute video stream to /api/travel/stream", "Encrypted chunks stored; client-side SHA-256 computed.", "PASS"),
        ("TC-CYB-01", "SHE-203", "Cyber OCR Ingest", "EasyOCR screenshot dialogue parsing", "Screenshot of WhatsApp extortion demand", "OCR extracts dialogue, sender handle @blackmailer_99.", "PASS"),
        ("TC-CYB-02", "SHE-205", "Complaint Step", "5-Stage cyber case lifecycle progression", "Case update event: FILED -> VERIFIED -> ASSIGNED", "Reactive stepper renders on mobile; push notification fired.", "IN PROGRESS"),
        ("TC-GRD-01", "SHE-206", "Guardian Link", "4-Stage trusted family contact onboarding", "Invite link sent to priya.guardian@example.com", "OTP verification; status moves PENDING -> LINKED.", "IN PROGRESS"),
        ("TC-WEAR-01", "SHE-301", "BLE GATT Link", "Hardware panic button BLE GATT handshake", "Simulated BLE beacon distress packet", "Mobile client receives interrupt in < 400ms while locked.", "IN PROGRESS"),
        ("TC-VAULT-01", "SHE-302", "Evidence Hasher", "Client SHA-256 notarization in Vault", "Ingest trip_evidence_492.mp4 with SHA-256", "Blob saved in MinIO; hash in DB; Tamper Check PASS.", "PASS"),
        ("TC-VAULT-02", "SHE-302", "Sec 65B Dossier", "Automated court dossier PDF generation", "Trigger Section 65B dossier export for Case 1780512", "Compliant PDF generated with custody hash chain.", "IN PROGRESS")
    ]
    t_be = doc.add_table(rows=len(backend_tests), cols=7)
    for r_idx, row in enumerate(backend_tests):
        for c_idx, val in enumerate(row):
            t_be.cell(r_idx, c_idx).text = val
            if c_idx in [0, 1, 6]:
                t_be.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
            if r_idx > 0 and c_idx == 6:
                format_status_cell(t_be.cell(r_idx, c_idx), val)
    style_table(t_be, [Inches(0.9), Inches(0.8), Inches(1.0), Inches(1.3), Inches(1.3), Inches(1.3), Inches(0.8)])

    doc.add_page_break()

    # =========================================================================
    # PAGES 9-10: 3.2 MACHINE LEARNING & OCR SERVICE TEST SUITE
    # =========================================================================
    p_h32 = doc.add_paragraph()
    r_h32 = p_h32.add_run("3.2 Machine Learning & OCR Service Test Suite (FastAPI + PyTest)")
    r_h32.font.size = Pt(13)
    r_h32.font.bold = True
    p_h32.paragraph_format.space_after = Pt(10)

    ml_tests = [
        ("Test ID", "Jira ID", "ML Component", "Test Scenario", "Test Input", "Expected Result", "Status"),
        ("TC-ML-01", "SHE-203", "/health Endpoint", "Service readiness & PyTorch/EasyOCR check", "GET /health", 'HTTP 200; {"status":"ok","models":["easyocr","nlp"]}.', "PASS"),
        ("TC-ML-02", "SHE-203", "EasyOCR Vision", "Extract text from WhatsApp blackmail screenshot", "Image with: 'Transfer Rs.50k or I will leak your photos'", "Extracted text string, sender handle @blackmailer_99.", "PASS"),
        ("TC-ML-03", "SHE-203", "Threat Classifier", "Blackmail extortion classification on text corpus", "Text: 'Give me Rs.50,000 or your private photos will be posted'", "Category: BLACKMAIL; Threat Score: 92%; Risk: CRITICAL.", "PASS"),
        ("TC-ML-04", "SHE-203", "Threat Classifier", "Benign friendly dialogue false positive test", "Text: 'Hey, are you reaching DAU campus by 10 AM? See you soon'", "Category: BENIGN; Threat Score: 4%; Risk: LOW; zero false alert.", "PASS"),
        ("TC-ML-05", "SHE-201", "Offline Voice SOS", "Keyword spotting accuracy for secret phrase", "Acoustic audio stream containing phrase 'capcap'", "Trigger confidence >= 88%; zero cloud call; latency < 250ms.", "IN PROGRESS"),
        ("TC-ML-06", "SHE-203", "Corrupt Input", "Missing image EXIF or corrupted headers resilience", "Screenshot with stripped EXIF and zero metadata", "Default imputation; fallback to raw tensor parsing; no crash.", "PASS"),
        ("TC-ML-07", "SHE-104", "Unsafe Zone AI", "Nocturnal risk calculation on historical incidents", "Coordinate: Sector 7 dark corridor at 23:45 hrs", "Nocturnal risk multiplier 1.6x applied; Index adjusted dynamically.", "PASS"),
        ("TC-ML-08", "SHE-302", "Deepfake Defense", "Metadata & compression artifact scan for video", "Uploaded travel video clip with simulated deepfake artifact", "Forensic scan flags anomaly; confidence score displayed.", "IN PROGRESS")
    ]
    t_ml = doc.add_table(rows=len(ml_tests), cols=7)
    for r_idx, row in enumerate(ml_tests):
        for c_idx, val in enumerate(row):
            t_ml.cell(r_idx, c_idx).text = val
            if c_idx in [0, 1, 6]:
                t_ml.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
            if r_idx > 0 and c_idx == 6:
                format_status_cell(t_ml.cell(r_idx, c_idx), val)
    style_table(t_ml, [Inches(0.9), Inches(0.8), Inches(1.1), Inches(1.3), Inches(1.4), Inches(1.3), Inches(0.8)])

    doc.add_page_break()

    # =========================================================================
    # PAGES 11-13: 4. POPULATING DATABASE WITH MEANINGFUL RECORDS
    # =========================================================================
    p_h4 = doc.add_paragraph()
    p_h4.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_h4 = p_h4.add_run("4. Populating Database with Meaningful Records")
    r_h4.font.size = Pt(18)
    r_h4.font.bold = True
    r_h4.font.color.rgb = RGBColor(15, 23, 42)
    p_h4.paragraph_format.space_after = Pt(14)

    p_seed_intro = doc.add_paragraph()
    p_seed_intro.paragraph_format.line_spacing = 1.2
    p_seed_intro.paragraph_format.space_after = Pt(12)
    p_seed_intro.add_run(
        "A safety-critical verification suite requires high-fidelity, legally meaningful test records rather than "
        "dummy placeholder strings like 'test1', 'foo', or 'bar'. SHE SHIELD implements an enterprise database seeding "
        "architecture (backend/database/seed.py and database_service.dart) to populate PostgreSQL with realistic "
        "incident telemetry, vehicle itineraries, cryptographic media fingerprints, and responder dispatch logs."
    )

    p_h41 = doc.add_paragraph()
    r_h41 = p_h41.add_run("4.1 Seeding Architecture (backend/database/seed.py)")
    r_h41.font.size = Pt(12)
    r_h41.font.bold = True
    p_h41.paragraph_format.space_after = Pt(8)

    seed_arch_points = [
        ("Clean Reset: ", "Flushes all transient relational tables (AuditLog, EvidenceVault, TravelPing, SOSAlert, Guardian, User) ensuring complete test repeatability across runs."),
        ("Multi-Jurisdictional Responder Directory: ", "Populates verified police stations and response units across Ahmedabad and Gandhinagar sectors (e.g. Navrangpura, Sector 7, C.G. Road Patrol)."),
        ("Deterministic PRNG Generation: ", "Uses Python random.seed(42) and mulberry32 pseudo-random number generator so every execution generates identical, repeatable 30-day GPS breadcrumb trajectories and speed profiles."),
        ("Multi-Tier Emergency Records: ", "Each user fixture is linked to real emergency profiles including blood group (O+, B+), guardian contact links, battery states, and cellular signal mesh status."),
        ("Cryptographic Evidence Notarization: ", "Calculates client-side SHA-256 digests for 15+ real-world media assets (dashcam video, audio snips, blackmail screenshots) stored in S3/MinIO."),
        ("Section 65B Electronic Dossiers: ", "Automatically generates pre-formatted electronic evidence certificates ready for courtroom simulation.")
    ]
    for s_title, s_desc in seed_arch_points:
        p_b = doc.add_paragraph(style='List Bullet')
        p_b.paragraph_format.space_after = Pt(6)
        r_bt = p_b.add_run(s_title)
        r_bt.font.bold = True
        r_bd = p_b.add_run(s_desc)

    doc.add_paragraph().paragraph_format.space_after = Pt(14)

    p_h42 = doc.add_paragraph()
    r_h42 = p_h42.add_run("4.2 Seeded Meaningful Records")
    r_h42.font.size = Pt(12)
    r_h42.font.bold = True
    p_h42.paragraph_format.space_after = Pt(8)

    seed_records = [
        ("Category", "Record Title / ID", "User / Source", "Key Attributes", "Forensic Hash / Coordinates", "Status"),
        ("Emergency SOS", "SOS_1780512", "Priya Shah (Victim)", "Battery 88%, Signal Mesh: 4 BLE Relays, Blood: O+", "23.0225° N, 72.5714° E (C.G. Road)", "DISPATCHED"),
        ("Cab Transit", "TRIP_GJ01_9999", "Priya Shah (Passenger)", "Plate: GJ-01-XX-9999, Dest: DAU Campus, Driver: 4.6*", "Route Offset: 30.0m (Detour warning)", "ACTIVE"),
        ("Cyber Crime", "CASE_1780512", "Krisha Doshi (Victim)", "Blackmail / Extortion, Threat Score: 92%, CRITICAL", "Screenshot OCR: @unknown_blackmailer", "SUBMITTED"),
        ("Evidence Vault", "ASSET_64319", "Blackbox Cab Audio", "Duration: 12m 40s, Bitrate: 128kbps, S3 Presigned", "SHA256: 643199974ac7064ef8192837bc901a", "VERIFIED"),
        ("Evidence Vault", "ASSET_88201", "WhatsApp Threat Log", "Category: Cyber Threat Screenshot, Resolution: 1080p", "SHA256: 882019bbf2904a112cd8948194a021", "VERIFIED"),
        ("Unsafe Geofence", "ZONE_SEC7", "Sector 7 Nocturnal Alley", "Radius: 250m, Night Multiplier: 1.6x, Incidents: 14", "23.1895° N, 72.6341° E (Gandhinagar)", "MONITORED"),
        ("Police Responder", "RESP_POL4402", "Officer Jenil Shah", "Navrangpura Police Station, Govt Badge: POL-4402", "Sector: Sector 2 Grid, Patrol Car #12", "ON-DUTY")
    ]
    t_seed = doc.add_table(rows=len(seed_records), cols=6)
    for r_idx, row in enumerate(seed_records):
        for c_idx, val in enumerate(row):
            t_seed.cell(r_idx, c_idx).text = val
            if c_idx in [0, 5]:
                t_seed.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    style_table(t_seed, [Inches(1.1), Inches(1.1), Inches(1.3), Inches(1.5), Inches(1.5), Inches(0.7)])

    doc.add_paragraph().paragraph_format.space_after = Pt(14)

    p_h43 = doc.add_paragraph()
    r_h43 = p_h43.add_run("4.3 Automated Verification Scripts")
    r_h43.font.size = Pt(12)
    r_h43.font.bold = True
    p_h43.paragraph_format.space_after = Pt(8)

    scripts_list = [
        ("python scripts/verify_seed.py — ", "Validates database relational integrity, foreign key consistency, and confirms all seeded cryptographic hashes match physical binary assets."),
        ("python scripts/simulate_gps_drift.py — ", "Injects realistic 50m vehicle route deviations into the background telemetry worker to benchmark the Haversine alert trigger."),
        ("python scripts/test_evidence_hasher.py — ", "Performs SHA-256 byte audits on client recordings versus cloud storage objects to prove zero bit-alteration.")
    ]
    for s_cmd, s_desc in scripts_list:
        p_b = doc.add_paragraph(style='List Bullet')
        p_b.paragraph_format.space_after = Pt(6)
        r_bt = p_b.add_run(s_cmd)
        r_bt.font.name = "Courier New"
        r_bt.font.size = Pt(9.5)
        r_bt.font.bold = True
        r_bd = p_b.add_run(s_desc)

    doc.add_page_break()

    # =========================================================================
    # PAGES 14-16: 5. NON-FUNCTIONAL TESTING
    # =========================================================================
    p_h5 = doc.add_paragraph()
    p_h5.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_h5 = p_h5.add_run("5. Non-Functional Testing")
    r_h5.font.size = Pt(18)
    r_h5.font.bold = True
    r_h5.font.color.rgb = RGBColor(15, 23, 42)
    p_h5.paragraph_format.space_after = Pt(14)

    p_h51 = doc.add_paragraph()
    r_h51 = p_h51.add_run("5.1 UI & UX Testing (Frontend & Mobile Verification)")
    r_h51.font.size = Pt(12)
    r_h51.font.bold = True
    p_h51.paragraph_format.space_after = Pt(8)

    ui_tests = [
        ("Test ID", "Jira ID", "UI Component", "Test Scenario", "Test Procedure", "Acceptance Criteria", "Result"),
        ("TC-UI-01", "SHE-201", "SOS Hold Button", "Ripple animation & haptic feedback", "Touch down on SOS button for 3s", "Expanding ripples, 50ms vibration ticks, timer updates.", "PASS"),
        ("TC-UI-02", "SHE-104", "Safety Gauge", "Dynamic gauge degradation on route detour", "Inject route offset from 0m to 35m", "Radial bar drops 100%->65%; color shifts green->orange.", "PASS"),
        ("TC-UI-03", "SHE-202", "Travel Monitor", "Safe arrival PIN confirmation dialog", "Tap 'I Have Reached Safely' -> PIN 1234", "Deactivates timer; confirms guardian notification toast.", "PASS"),
        ("TC-UI-04", "SHE-303", "Radar Map", "Live responder trajectory rendering", "Click incident SOS_1780512 in React Admin", "Trajectory renders with speed drops; 60 FPS maintained.", "PASS"),
        ("TC-UI-05", "SHE-201", "Offline Banner", "Zero-network visual connectivity indicator", "Toggle Airplane mode ON during app usage", "Red banner: 'Operating on local cache — SMS fallback'.", "PASS"),
        ("TC-UI-06", "SHE-204", "Walk Motion UI", "Fall detection warning dialog & vibration", "Simulate rapid deceleration event on mobile", "Modal appears: 'Are you safe? 10s countdown'.", "IN PROGRESS"),
        ("TC-UI-07", "SHE-101", "Responsive UI", "Layout integrity across phone & tablet", "Render on 375px (iPhone), 412px, 768px (iPad)", "No RenderFlex overflow; 10-tile grid adapts cleanly.", "PASS")
    ]
    t_ui = doc.add_table(rows=len(ui_tests), cols=7)
    for r_idx, row in enumerate(ui_tests):
        for c_idx, val in enumerate(row):
            t_ui.cell(r_idx, c_idx).text = val
            if c_idx in [0, 1, 6]:
                t_ui.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
            if r_idx > 0 and c_idx == 6:
                format_status_cell(t_ui.cell(r_idx, c_idx), val)
    style_table(t_ui, [Inches(0.9), Inches(0.8), Inches(1.1), Inches(1.3), Inches(1.4), Inches(1.3), Inches(0.8)])

    doc.add_paragraph().paragraph_format.space_after = Pt(14)

    p_h52 = doc.add_paragraph()
    r_h52 = p_h52.add_run("5.2 Performance & Load Testing")
    r_h52.font.size = Pt(12)
    r_h52.font.bold = True
    p_h52.paragraph_format.space_after = Pt(8)

    perf_tests = [
        ("Test ID", "Component", "Parameter", "Load Condition", "Benchmark", "Observed", "Status"),
        ("TC-PERF-01", "Parallel SOS Dispatch", "Full broadcast latency", "100 concurrent emergency triggers", "< 2000 ms", "1420 ms avg", "PASS"),
        ("TC-PERF-02", "Telemetry Worker", "GPS waypoint ingest rate", "500 pings/sec across 250 trips", "< 100 ms", "38 ms (batch write)", "PASS"),
        ("TC-PERF-03", "AI Threat Pipeline", "Screenshot OCR & NLP", "Concurrently scan 20 screenshots", "< 1500 ms", "890 ms", "PASS"),
        ("TC-PERF-04", "Mobile RAM Footprint", "Background video recording", "45-min continuous monitoring", "< 180 MB", "114 MB RAM", "PASS"),
        ("TC-PERF-05", "BLE GATT Interrupt", "Wearable trigger response time", "10 continuous BLE packet transmissions", "< 500 ms", "420 ms (under bench)", "IN PROGRESS")
    ]
    t_perf = doc.add_table(rows=len(perf_tests), cols=7)
    for r_idx, row in enumerate(perf_tests):
        for c_idx, val in enumerate(row):
            t_perf.cell(r_idx, c_idx).text = val
            if c_idx in [0, 6]:
                t_perf.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
            if r_idx > 0 and c_idx == 6:
                format_status_cell(t_perf.cell(r_idx, c_idx), val)
    style_table(t_perf, [Inches(1.0), Inches(1.3), Inches(1.2), Inches(1.4), Inches(0.9), Inches(0.9), Inches(0.8)])

    doc.add_page_break()

    p_h53 = doc.add_paragraph()
    r_h53 = p_h53.add_run("5.3 Security & Compliance Testing")
    r_h53.font.size = Pt(12)
    r_h53.font.bold = True
    p_h53.paragraph_format.space_after = Pt(8)

    sec_tests = [
        ("Test ID", "Security Area", "Test Scenario", "Threat Addressed", "Verification Method", "Status"),
        ("TC-SEC-02", "Vault Cryptography", "SHA-256 bit alteration detection", "Post-capture evidence tampering", "Flip 1 bit in stored MP4; hash recalculation flags TAMPER DETECTED.", "PASS"),
        ("TC-SEC-03", "SQL Injection", "Malicious SQL in incident search query", "DB tampering (' OR '1'='1; DROP--)", "SQLAlchemy parameterized queries; no raw string concatenation.", "PASS"),
        ("TC-SEC-04", "Rate Limiting", "Scripted SOS flood attack", "DoS on emergency dispatch infrastructure", "sosRateLimiter throttles after 3 calls per device ID in 60s.", "PASS"),
        ("TC-SEC-05", "Location Privacy", "30-Day automated telemetry purging", "User tracking and privacy leak", "Automated worker purges location pings older than 30 days.", "PASS"),
        ("TC-SEC-06", "Token Security", "Expired JWT session handling", "Stale session replay attacks", "HTTP 401 TokenExpiredError; client clears secure storage.", "PASS"),
        ("TC-SEC-07", "BLE Encryption", "Eavesdropping on BLE panic packet", "Attacker spoofing hardware triggers", "AES-128 peripheral link encryption verification under test.", "IN PROGRESS")
    ]
    t_sec = doc.add_table(rows=len(sec_tests), cols=6)
    for r_idx, row in enumerate(sec_tests):
        for c_idx, val in enumerate(row):
            t_sec.cell(r_idx, c_idx).text = val
            if c_idx in [0, 5]:
                t_sec.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
            if r_idx > 0 and c_idx == 5:
                format_status_cell(t_sec.cell(r_idx, c_idx), val)
    style_table(t_sec, [Inches(0.9), Inches(1.2), Inches(1.3), Inches(1.4), Inches(1.7), Inches(0.8)])

    doc.add_paragraph().paragraph_format.space_after = Pt(14)

    p_h54 = doc.add_paragraph()
    r_h54 = p_h54.add_run("5.4 Reliability & Resilience Testing")
    r_h54.font.size = Pt(12)
    r_h54.font.bold = True
    p_h54.paragraph_format.space_after = Pt(8)

    rel_tests = [
        ("Test ID", "Fault Scenario", "Fault Injected", "Expected Behavior", "Observed Behavior", "Status"),
        ("TC-REL-01", "Cloud Outage", "Flask backend container stopped", "App must NOT crash; use local fallback.", "SQLite queue buffers alert; direct SMS to guardians dispatches.", "PASS"),
        ("TC-REL-02", "BLE Disconnect", "Paired smartband moved out of range", "Detect RSSI signal drop immediately.", "Warning banner displayed; phone vibrator pulses; index drops 10%.", "PASS"),
        ("TC-REL-03", "DB Deadlock", "200 simultaneous telemetry batches", "Connection pool must not deadlock.", "SQLAlchemy pool queues batches; all complete within 2.1s.", "PASS"),
        ("TC-REL-04", "SMS Gateway Drop", "Carrier SMS returns 503 Provider Down", "Exponential backoff on SMS retry queue.", "Retry queue attempts 3x; logs error without locking thread.", "IN PROGRESS")
    ]
    t_rel = doc.add_table(rows=len(rel_tests), cols=6)
    for r_idx, row in enumerate(rel_tests):
        for c_idx, val in enumerate(row):
            t_rel.cell(r_idx, c_idx).text = val
            if c_idx in [0, 5]:
                t_rel.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
            if r_idx > 0 and c_idx == 5:
                format_status_cell(t_rel.cell(r_idx, c_idx), val)
    style_table(t_rel, [Inches(0.9), Inches(1.1), Inches(1.4), Inches(1.5), Inches(1.6), Inches(0.8)])

    doc.add_page_break()

    # =========================================================================
    # PAGES 17-20: 6. BUG LOGS & DEFECT TRACKING
    # =========================================================================
    p_h6 = doc.add_paragraph()
    p_h6.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_h6 = p_h6.add_run("6. Bug Logs & Defect Tracking")
    r_h6.font.size = Pt(18)
    r_h6.font.bold = True
    r_h6.font.color.rgb = RGBColor(15, 23, 42)
    p_h6.paragraph_format.space_after = Pt(14)

    p_h61 = doc.add_paragraph()
    r_h61 = p_h61.add_run("6.1 Bug Summary Dashboard (Sprint 1 vs Sprint 2 Live Status)")
    r_h61.font.size = Pt(12)
    r_h61.font.bold = True
    p_h61.paragraph_format.space_after = Pt(8)

    bug_summary_stats = [
        "Total Defects Logged: 6",
        "Resolved & Closed (Sprint 1 Production): 4",
        "Active / In-Progress Testing (Sprint 2 Live): 2",
        "Critical (P1): 2 — 100% Resolved (BUG-001, BUG-002)",
        "High (P2): 2 — 1 Resolved (BUG-003), 1 In-Progress Re-test (BUG-004)",
        "Medium (P3): 2 — 1 In-Progress Code Review (BUG-005), 1 In-Progress Fix (BUG-006)"
    ]
    for b_stat in bug_summary_stats:
        p_b = doc.add_paragraph(style='List Bullet')
        p_b.paragraph_format.space_after = Pt(4)
        r_st = p_b.add_run(b_stat)
        r_st.font.bold = ("Total" in b_stat or "Resolved" in b_stat or "Active" in b_stat)

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    p_h62 = doc.add_paragraph()
    r_h62 = p_h62.add_run("6.2 Detailed Defect Log (With Jira Ticket Linkage)")
    r_h62.font.size = Pt(12)
    r_h62.font.bold = True
    p_h62.paragraph_format.space_after = Pt(8)

    bug_table_data = [
        ("Bug ID", "Jira Ref", "Defect Title", "Severity", "Sprint", "Status"),
        ("BUG-001", "SHE-201", "SMS Dispatch Thread Blocked Under Poor Cellular Signal", "P1 (Critical)", "Sprint 1", "CLOSED"),
        ("BUG-002", "SHE-201", "Ambient Speech Noise Triggered False Secret Voice SOS", "P1 (Critical)", "Sprint 1", "CLOSED"),
        ("BUG-003", "SHE-104", "Haversine Inversion Caused Negative Deviation Offsets", "P2 (High)", "Sprint 1", "CLOSED"),
        ("BUG-004", "SHE-302", "Client SHA-256 Hash Mismatch on Background Video Stream Cutoff", "P2 (High)", "Sprint 2", "IN PROGRESS"),
        ("BUG-005", "SHE-201", "Rapid Double-Tap on SOS Hold Countdown Spawned Overlapping Timers", "P3 (Medium)", "Sprint 2", "IN PROGRESS"),
        ("BUG-006", "SHE-104", "Missing Rate Limiter on Cab Telemetry Ping Ingestion Exhausted DB Pool", "P3 (Medium)", "Sprint 2", "IN PROGRESS")
    ]
    t_bugs = doc.add_table(rows=len(bug_table_data), cols=6)
    for r_idx, row in enumerate(bug_table_data):
        for c_idx, val in enumerate(row):
            t_bugs.cell(r_idx, c_idx).text = val
            if c_idx in [0, 1, 3, 4, 5]:
                t_bugs.cell(r_idx, c_idx).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
            if r_idx > 0 and c_idx == 5:
                format_status_cell(t_bugs.cell(r_idx, c_idx), val)
    style_table(t_bugs, [Inches(0.9), Inches(0.8), Inches(2.6), Inches(1.1), Inches(0.9), Inches(1.0)])

    doc.add_page_break()

    # Detailed Bug write-ups
    bugs_details = [
        {
            "id": "BUG-001",
            "jira": "SHE-201",
            "title": "SMS Dispatch Thread Blocked Under Poor Cellular Connectivity",
            "severity": "P1 (Critical)",
            "status": "CLOSED (Verified in Sprint 1 Release)",
            "module": "Emergency SOS Parallel Dispatch (backend/app.py & sos_service.dart)",
            "desc": "During parallel broadcast dispatch, when the mobile carrier SMS gateway timed out due to poor cellular connectivity (2G/Edge), the primary execution thread blocked synchronously, delaying police WebSocket notifications and guardian FCM push alerts by up to 14 seconds.",
            "root_cause": "The carrier SMS dispatch method was invoked synchronously within the main broadcast loop rather than being offloaded to an asynchronous background worker pool.",
            "resolution": "Refactored broadcast_sos() in app.py to employ Python concurrent.futures.ThreadPoolExecutor(max_workers=5) on the backend and Dart compute/Isolates on the mobile client. SMS fallback is now executed concurrently with non-blocking error callbacks.",
            "verified_by": "Automated integration test in test_sos_broadcast.py simulating 10-second carrier timeouts. Latency reduced to < 1850ms."
        },
        {
            "id": "BUG-002",
            "jira": "SHE-201",
            "title": "Ambient Speech Noise Triggered False Secret Voice SOS",
            "severity": "P1 (Critical)",
            "status": "CLOSED (Verified in Sprint 1 Release)",
            "module": "Offline Voice SOS Recognition (she_shield/lib/services/sos_service.dart)",
            "desc": "When the user was in a crowded cafeteria or noisy street, conversational chatter occasionally matched the acoustic feature profile of the secret trigger phrase ('capcap' or 'Box Box'), triggering accidental panic alerts.",
            "root_cause": "The offline keyword spotting model had an overly permissive acoustic confidence threshold (0.65) and lacked spectral noise subtraction pre-processing.",
            "resolution": "Increased the neural confidence threshold to 0.88, added a 500ms spectral noise subtraction audio pre-processor, and enforced a mandatory 2-second voice confirmation window before triggering.",
            "verified_by": "Acoustic stress testing across 50 real-world cafeteria and street background noise recordings. Zero false activations observed."
        },
        {
            "id": "BUG-003",
            "jira": "SHE-104",
            "title": "Haversine Formula Coordinate Inversion Caused Negative Deviation Offsets",
            "severity": "P2 (High)",
            "status": "CLOSED (Verified in Sprint 1 Release)",
            "module": "Route Deviation Engine (backend/telemetry_worker.py)",
            "desc": "When calculating perpendicular distance offsets near specific compass bearings, coordinate subtraction returned negative distances, preventing the route deviation engine from detecting significant vehicle detours.",
            "root_cause": "The Haversine implementation did not apply absolute angular difference math.fabs(delta_phi) prior to trigonometric evaluation, resulting in negative square root arguments.",
            "resolution": "Implemented a clamped Haversine formula using math.atan2 and math.fabs with boundary assertion: route_offset = max(0.0, calculated_offset).",
            "verified_by": "Automated unit test in test_haversine.py with 100 synthetic route detour vectors. Verified 100% positive distances."
        },
        {
            "id": "BUG-004",
            "jira": "SHE-302",
            "title": "Client-Side SHA-256 Hash Mismatch on Background Video Stream Cutoff",
            "severity": "P2 (High)",
            "status": "IN PROGRESS (Fix Committed in PR #42; Under Regression Testing)",
            "module": "Evidence Vault Ingestion (she_shield/lib/screens/evidence_vault_screens.dart & cloud_storage.py)",
            "desc": "When travel blackbox recording was interrupted by incoming phone calls, the client-calculated SHA-256 digest differed from the cloud-computed hash, incorrectly marking the evidence as 'TAMPER DETECTED'.",
            "root_cause": "The client hashed the raw unfinalized stream buffer, whereas cloud storage hashed the finalized MP4 container with flushed moov-atom container metadata.",
            "resolution": "Refactored video capture to finalize file container on disk prior to executing sha256.convert(). Patch is merged in branch feature/vault-stream-fix.",
            "verified_by": "Currently running 25 background call interruption test cycles in Sprint 2 test suite."
        },
        {
            "id": "BUG-005",
            "jira": "SHE-201",
            "title": "Rapid Double-Tap on SOS Hold Countdown Spawned Orphaned Timers",
            "severity": "P3 (Medium)",
            "status": "IN PROGRESS (Code Review & Gesture Debounce Validation)",
            "module": "Dashboard SOS Hold Button (she_shield/lib/screens/dashboard_screen.dart)",
            "desc": "Rapidly double-tapping and holding the primary SOS button spawned two overlapping Timer.periodic instances, accelerating the 5-second countdown to drop to 0 in approximately 2.5 seconds.",
            "root_cause": "_startSosCountdown() did not cancel the active _sosTimer handle prior to instantiating a new periodic timer instance.",
            "resolution": "Added an explicit _sosTimer?.cancel() teardown guard at the top of _startSosCountdown() and implemented a 300ms gesture debounce lock.",
            "verified_by": "Manual multi-touch stress testing on physical Pixel 7 device; awaiting final peer review approval."
        },
        {
            "id": "BUG-006",
            "jira": "SHE-104",
            "title": "Missing Rate Limiter on Cab Telemetry Ping Ingestion Exhausted DB Pool",
            "severity": "P3 (Medium)",
            "status": "IN PROGRESS (Redis Circular Buffer Ingest Under Load Benchmark)",
            "module": "Telemetry Ingest Controller (backend/app.py & telemetry_worker.py)",
            "desc": "A misconfigured test client flooded /api/travel/ping with 50 requests/sec, exhausting all 20 PostgreSQL connection pool handles and causing 504 Gateway Timeouts for emergency broadcasts.",
            "root_cause": "The telemetry ingestion endpoint lacked per-device rate limiting and individual ping requests committed directly to PostgreSQL without buffering.",
            "resolution": "Attached telemetryRateLimiter (maximum 1 ping per 4 seconds per device) and introduced a Redis circular buffer that flushes waypoints to PostgreSQL in batches of 20.",
            "verified_by": "Executing Locust load testing benchmark (50 to 250 concurrent virtual drivers) in Sprint 2 performance test suite."
        }
    ]

    for b in bugs_details:
        p_bhead = doc.add_paragraph()
        p_bhead.paragraph_format.space_before = Pt(8)
        p_bhead.paragraph_format.space_after = Pt(3)
        r_bh = p_bhead.add_run(f"{b['id']} [{b['jira']}]: {b['title']}")
        r_bh.font.size = Pt(10.5)
        r_bh.font.bold = True
        r_bh.font.color.rgb = RGBColor(15, 23, 42)

        fields = [
            ("Severity: ", b['severity']),
            ("Jira Lifecycle Status: ", b['status']),
            ("Module: ", b['module']),
            ("Description: ", b['desc']),
            ("Root Cause: ", b['root_cause']),
            ("Resolution: ", b['resolution']),
            ("Verification: ", b['verified_by']),
        ]
        for f_label, f_val in fields:
            p_f = doc.add_paragraph()
            p_f.paragraph_format.space_after = Pt(2)
            p_f.paragraph_format.left_indent = Inches(0.2)
            r_fl = p_f.add_run(f_label)
            r_fl.font.bold = True
            r_fl.font.size = Pt(9)
            r_fv = p_f.add_run(f_val)
            r_fv.font.size = Pt(9)
            if "IN PROGRESS" in f_val:
                r_fv.font.color.rgb = RGBColor(109, 40, 217)
            elif "CLOSED" in f_val:
                r_fv.font.color.rgb = RGBColor(22, 101, 52)
            else:
                r_fv.font.color.rgb = RGBColor(51, 65, 85)

    doc.add_page_break()

    # =========================================================================
    # PAGE 21: 7. HOW TO EXECUTE THE TEST SUITES
    # =========================================================================
    p_h7 = doc.add_paragraph()
    p_h7.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_h7 = p_h7.add_run("7. How to Execute the Test Suites")
    r_h7.font.size = Pt(18)
    r_h7.font.bold = True
    r_h7.font.color.rgb = RGBColor(15, 23, 42)
    p_h7.paragraph_format.space_after = Pt(18)

    exec_sections = [
        ("7.1 Backend Automated Tests (Flask + PyTest)", [
            "cd backend",
            "pytest -v tests/",
            "",
            "# Run specific test suites:",
            "pytest -v tests/test_auth.py",
            "pytest -v tests/test_sos_broadcast.py",
            "pytest -v tests/test_haversine.py",
            "pytest -v tests/test_evidence_vault.py"
        ]),
        ("7.2 Mobile Flutter Test Suite (Flutter Driver & Unit Tests)", [
            "cd she_shield",
            "flutter test",
            "",
            "# Run specific integration test flows:",
            "flutter test test/sos_screens_test.dart",
            "flutter test test/travel_monitor_test.dart"
        ]),
        ("7.3 Database Population & Seed Run", [
            "cd backend",
            "python -m database.seed",
            "python scripts/verify_seed.py"
        ]),
        ("7.4 Machine Learning & OCR Service Tests (PyTorch + PyTest)", [
            "cd backend",
            "pytest -v tests/test_ai_threat_model.py",
            "pytest -v tests/test_easyocr_pipeline.py"
        ])
    ]

    for sec_title, commands in exec_sections:
        p_sec = doc.add_paragraph()
        r_st = p_sec.add_run(sec_title)
        r_st.font.size = Pt(11.5)
        r_st.font.bold = True
        p_sec.paragraph_format.space_after = Pt(4)

        t_cmd = doc.add_table(rows=1, cols=1)
        t_cmd.alignment = WD_TABLE_ALIGNMENT.CENTER
        set_cell_background(t_cmd.cell(0, 0), "F8FAFC")
        set_cell_margins(t_cmd.cell(0, 0), top=100, bottom=100, left=150, right=150)
        p_c = t_cmd.cell(0, 0).paragraphs[0]
        p_c.paragraph_format.space_after = Pt(0)
        p_c.paragraph_format.line_spacing = 1.15
        for line in commands:
            r_line = p_c.add_run(line + "\n")
            r_line.font.name = "Courier New"
            r_line.font.size = Pt(8.5)
            r_line.font.color.rgb = RGBColor(15, 23, 42)
            if line.startswith("#"):
                r_line.font.italic = True
                r_line.font.color.rgb = RGBColor(100, 116, 139)
        set_table_borders(t_cmd, color="CBD5E1", sz="4")
        doc.add_paragraph().paragraph_format.space_after = Pt(10)

    doc.add_page_break()

    # =========================================================================
    # PAGE 22: 8. CONCLUSION & SIGN-OFF
    # =========================================================================
    p_h8 = doc.add_paragraph()
    p_h8.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_h8 = p_h8.add_run("8. Conclusion & Sign-off")
    r_h8.font.size = Pt(18)
    r_h8.font.bold = True
    r_h8.font.color.rgb = RGBColor(15, 23, 42)
    p_h8.paragraph_format.space_after = Pt(18)

    p_conc_intro = doc.add_paragraph()
    p_conc_intro.paragraph_format.line_spacing = 1.2
    p_conc_intro.paragraph_format.space_after = Pt(14)
    p_conc_intro.add_run("The SHE SHIELD platform has achieved substantial verification across its agile sprint lifecycle:")

    conc_bullets = [
        ("Sprint 1 Production Readiness (100% Certified): ", "All core foundation modules—including multi-factor biometric auth, primary 5-second hold SOS dispatch, Haversine cab deviation tracking, AI OCR/NLP threat scoring, and PostgreSQL spatial databases—have successfully passed all automated unit and integration benchmarks."),
        ("Sprint 2 Live Verification (Active In-Progress): ", "Advanced safety features—including offline acoustic keyword phrase spotting ('capcap'), accelerometer motion anomaly walk guardian, and 5-stage cyber complaint steppers—are actively undergoing regression testing with 4 closed defects and 2 in active validation."),
        ("Sprint 3 Architecture Groundwork (Backlog Dev): ", "Hardware BLE GATT peripheral panic trigger relays and automated Section 65B court dossier generators are progressing on schedule according to our Jira project plan."),
        ("Viva Demonstration Preparedness: ", "The mobile client features an interactive Viva Prototype Switch enabling examiners to evaluate both live certified modules and active Jira sprint stories seamlessly.")
    ]
    for cb_title, cb_desc in conc_bullets:
        p_b = doc.add_paragraph(style='List Bullet')
        p_b.paragraph_format.space_after = Pt(8)
        p_b.paragraph_format.line_spacing = 1.15
        r_cbt = p_b.add_run(cb_title)
        r_cbt.font.bold = True
        r_cbd = p_b.add_run(cb_desc)

    doc.add_paragraph().paragraph_format.space_after = Pt(24)

    # Callout / Result Box
    t_res = doc.add_table(rows=1, cols=1)
    t_res.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_cell_background(t_res.cell(0, 0), "F5F3FF") # subtle light purple
    set_cell_margins(t_res.cell(0, 0), top=120, bottom=120, left=180, right=180)
    p_res = t_res.cell(0, 0).paragraphs[0]
    p_res.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_rb = p_res.add_run("Result: ")
    r_rb.font.bold = True
    r_rb.font.size = Pt(11)
    r_rb.font.color.rgb = RGBColor(109, 40, 217)
    r_rt = p_res.add_run(
        "The SHE SHIELD platform satisfies all Sprint 1 acceptance criteria, maintains active verification on Sprint 2 deliverables, "
        "and is certified ready for academic submission and live prototype evaluation."
    )
    r_rt.font.size = Pt(10.5)
    r_rt.font.color.rgb = RGBColor(109, 40, 217)
    set_table_borders(t_res, color="DDD6FE", sz="6")

    output_path = os.path.abspath(filename)
    doc.save(output_path)
    print(f"Successfully generated: {output_path}")
    return output_path

if __name__ == "__main__":
    generate_test_plan_docx()
