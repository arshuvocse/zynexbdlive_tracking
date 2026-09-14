import os
import sys
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

from admin_doc_builder import (
    set_cell_background, set_cell_margins, add_callout,
    add_styled_table, add_header_footer, add_section_h1,
    add_section_h2, add_section_h3, add_p, add_bullet, add_num_step
)

def build_admin_document(output_path, include_en=True, include_bn=True):
    doc = Document()
    add_header_footer(doc, "Administrator Operations Manual")
    
    # Title Cover Header
    title_p = doc.add_paragraph()
    title_p.paragraph_format.space_before = Pt(20)
    title_p.paragraph_format.space_after = Pt(2)
    r_brand = title_p.add_run("SMART WORK FORCE")
    r_brand.bold = True
    r_brand.font.size = Pt(24)
    r_brand.font.name = "Segoe UI"
    r_brand.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A) # Navy
    
    sub_p = doc.add_paragraph()
    sub_p.paragraph_format.space_before = Pt(0)
    sub_p.paragraph_format.space_after = Pt(14)
    r_sub = sub_p.add_run("Enterprise Field Workforce Monitoring & Live Tracking Platform\nAdministrator Operational Guideline & User Manual")
    r_sub.font.size = Pt(13)
    r_sub.font.name = "Segoe UI"
    r_sub.font.color.rgb = RGBColor(0x47, 0x55, 0x69)
    
    # Metadata Table
    meta_headers = ["Document Attribute", "Details / Information"]
    meta_rows = [
        ["System Name", "Smart Work Force (Enterprise Edition)"],
        ["Target Audience", "System Administrators, Operations Managers, HR Supervisors, Area Managers"],
        ["Supported Platforms", "Android Enterprise App, ASP.NET Core 8 Web API, SignalR Live Hub, MS SQL Server"],
        ["Languages Included", "English (Global) & বাংলা (Bengali)"],
        ["Version & Release", "v2.0 • Production Ready"],
        ["Document Classification", "Confidential / Internal Enterprise Operations Manual"]
    ]
    add_styled_table(doc, [2.2, 4.3], meta_headers, meta_rows, header_bg="1E3A8A")
    
    add_callout(
        doc,
        "This manual provides step-by-step instructions for executive monitoring, real-time field tracking, biometric selfie attendance verification, customer visit oversight, and master system configurations. Keep this guide handy for daily administration.\n"
        "এই ম্যানুয়ালটিতে এক্সিকিউটিভ ড্যাশবোর্ড পরিচালনা, লাইভ ট্র্যাকিং, সেলফি হাজিরা ভেরিফিকেশন, কাস্টমার ভিজিট তদারকি এবং শিফট/অফিস কনফিগারেশনের পূর্ণাঙ্গ গাইডলাইন অন্তর্ভুক্ত রয়েছে।",
        title="EXECUTIVE NOTICE / প্রাতিষ্ঠানিক নোটিশ",
        border_hex="0F766E",
        bg_hex="F0FDF4"
    )
    
    # -------------------------------------------------------------
    # ENGLISH SECTION
    # -------------------------------------------------------------
    if include_en:
        add_section_h1(doc, "PART 1: ADMINISTRATOR OPERATIONAL GUIDE (ENGLISH)")
        
        # 1. System Overview & Architecture
        add_section_h2(doc, "1. System Overview & Core Architecture")
        add_p(doc, "Smart Work Force is an end-to-end enterprise solution engineered to empower executives, HR managers, and team leaders with complete visibility over field operations, sales representatives, delivery personnel, and remote staff. Unlike legacy static tracking systems, Smart Work Force operates as an active Executive Command Center, automatically prioritizing operational anomalies that require immediate management attention.")
        
        add_p(doc, "The enterprise infrastructure comprises four synchronized layers:")
        add_bullet(doc, "Native Mobile Applications", "High-performance Kotlin Android application with dual-mode operational intelligence (Field User Mode and Executive Admin Mode).")
        add_bullet(doc, "Real-Time SignalR Event Hub", "WebSocket-driven bi-directional communication protocol delivering instantaneous location updates, online/offline transitions, and attendance events within milliseconds.")
        add_bullet(doc, "Enterprise Backend Engine", "ASP.NET Core 8 REST API secured with JSON Web Tokens (JWT), role-based claims verification, and asynchronous high-throughput processing.")
        add_bullet(doc, "Spatial Database Layer", "Microsoft SQL Server 2019+ utilizing spatial GEOGRAPHY indexes (`SIX_DriverLocations_Location`) for lightning-fast radius calculations, polygon geofencing, and historical playback queries.")
        
        # 2. Administrative Login & Initial Setup
        add_section_h2(doc, "2. Administrative Login & Initial Setup")
        add_p(doc, "Administrators access the system through the Smart Work Force mobile client or administrative web console. Follow the standard authentication procedure:")
        add_num_step(doc, 1, "Launch Application", "Open the Smart Work Force application on your Android device or access the administrative portal.")
        add_num_step(doc, 2, "Enter Authorized Credentials", "Input your assigned Admin Username and Password. Default initial admin credentials must be updated immediately upon first login.")
        add_num_step(doc, 3, "Language Selection", "Tap the language selector toggle (`🌐 English / বাংলা`) at the top right header to switch the interface language at any time.")
        add_num_step(doc, 4, "Role Routing", "The system verifies administrative claims (`Role: Admin`). Upon successful token issuance, you are automatically directed to the Executive Command Center.")
        
        # 3. Executive Command Center
        add_section_h2(doc, "3. Executive Command Center (Overview Dashboard)")
        add_p(doc, "The Executive Dashboard is designed as an action-oriented mission control center. Instead of requiring administrators to dig through nested menus, the landing screen aggregates all critical metrics in real time.")
        
        add_section_h3(doc, "Key Performance Indicator (KPI) Widgets")
        kpi_headers = ["KPI Metric", "Real-Time Meaning", "Managerial Action"]
        kpi_rows = [
            ["Total Employees", "Total number of registered staff members.", "Review active workforce headcount."],
            ["Active Tracking Now", "Officers currently broadcasting live GPS signals.", "Monitor real-time field presence."],
            ["Today's Punch In", "Employees who completed morning attendance.", "Verify punctuality vs total roster."],
            ["Today's Absent", "Staff who failed to punch in after shift start.", "Follow up with department heads."],
            ["Today's Late", "Punched in past designated shift grace period.", "Evaluate attendance discipline."],
            ["Pending Leaves", "Leave applications awaiting administrative review.", "Requires 1-tap Approve or Reject."],
            ["Pending Follow-ups", "Customer meetings scheduled for today across team.", "Ensure field officers complete scheduled visits."]
        ]
        add_styled_table(doc, [1.8, 2.5, 2.2], kpi_headers, kpi_rows)
        
        add_section_h3(doc, "'Attention Required' Smart Alert Radar")
        add_p(doc, "Positioned prominently at the top of the dashboard, this automated intelligence hub scans the entire workforce every 30 seconds and dynamically flags high-priority operational exceptions:")
        add_bullet(doc, "GPS Disabled Alert", "Triggered instantly if a field officer turns off phone location services or revokes GPS permission during active duty hours.")
        add_bullet(doc, "No Location Updates (>3 Min)", "Identifies officers who have gone silent or experienced network disconnections while on the clock.")
        add_bullet(doc, "Late Punch-In Notification", "Highlights staff members arriving after the allowed shift grace window.")
        add_bullet(doc, "Overdue Customer Follow-ups", "Alerts when a client meeting deadline has passed without visit submission.")
        add_p(doc, "Every alert card in this section includes direct quick-action buttons: [Call Officer], [Track on Map], [Approve/Reject]. This empowers supervisors to resolve bottlenecks in seconds.")
        
        # 4. Real-Time Live Tracking Map
        add_section_h2(doc, "4. Real-Time Live Tracking & Field Radar")
        add_p(doc, "The Live Tracking module features a full-screen interactive Google Map visualizing the exact geographical coordinates of all field staff simultaneously. Location updates stream continuously via SignalR without requiring manual page refresh.")
        
        add_section_h3(doc, "Marker Status Color Codes")
        marker_headers = ["Marker Indicator", "Status Condition", "Interpretation"]
        marker_rows = [
            ["🟢 Emerald Green", "Online & Moving", "Officer is actively traveling; speed > 2 km/h; GPS ping within last 60 seconds."],
            ["🔵 Royal Blue", "Online & Stationary", "Officer is stationary at a customer shop or meeting; GPS accurate; speed = 0."],
            ["⚪ Muted Gray", "Offline (> 3 Minutes)", "No location packet received for > 3 minutes (poor network or battery dead)."],
            ["🔴 Crimson Red", "GPS Disabled / Alert", "Device GPS was turned off manually; immediate supervisor action required."]
        ]
        add_styled_table(doc, [1.8, 1.8, 2.9], marker_headers, marker_rows)
        
        add_section_h3(doc, "Interactive Marker Inspection")
        add_p(doc, "Tapping any employee pin on the map opens an expanded Executive Info Card containing:")
        add_bullet(doc, "Officer Profile", "Full Name, Mobile Number, Assigned Department, and Profile Picture.")
        add_bullet(doc, "Telemetry Metrics", "Current Speed (km/h), GPS Accuracy Radius (meters), Device Battery Percentage (%).")
        add_bullet(doc, "Timestamp & Address", "Exact time of latest location update and reverse-geocoded street address.")
        add_bullet(doc, "Action Hub", "[Call Officer] initiates direct voice call; [Route History] loads today's trail; [Navigate] opens Google Maps directions to the officer's exact spot.")
        
        # 5. Route History & Playback Analysis
        add_section_h2(doc, "5. Route History & Movement Playback Analysis")
        add_p(doc, "The Route History module enables administrators to audit historical field movements, verify genuine travel claims, detect unnecessary detours, and evaluate client visit durations.")
        
        add_num_step(doc, 1, "Select Officer & Date", "Select the desired field officer and pick any date from the interactive calendar picker.")
        add_num_step(doc, 2, "Analyze Summary Metrics", "The system instantly computes and displays: Total Distance Traveled (km), First Location (Punch In), Last Location (Punch Out), Total Stops, and Average Speed.")
        add_num_step(doc, 3, "Interactive Route Polyline", "The complete travel path is rendered on Google Maps. Numbered pins denote stop locations where the officer remained stationary for over 5 minutes.")
        add_num_step(doc, 4, "Timeline Playback Simulation", "Use the bottom playback bar with [Play], [Pause], and speed toggles (1x, 2x, 4x). A simulated vehicle marker moves along the actual road path taken, showing time of day at each checkpoint.")
        add_num_step(doc, 5, "Stopover Duration Audit", "Tap any numbered stop pin to inspect: Arrival Time, Departure Time, Total Duration at spot, and Nearest Landmark/Customer.")
        
        # 6. Smart Attendance & Geofencing Supervision
        add_section_h2(doc, "6. Smart Attendance & Geofencing Supervision")
        add_p(doc, "Smart Work Force eliminates attendance fraud through dual-factor verification: Live Biometric Selfie Capture + Satellite GPS Geofencing.")
        
        add_section_h3(doc, "Attendance Verification Parameters")
        add_bullet(doc, "Biometric Selfie Photo", "Staff must take a live photo during punch-in. Administrators can tap the thumbnail to inspect the full-resolution face photo.")
        add_bullet(doc, "Geofence Compliance", "The system calculates distance between employee's coordinates and their assigned office location. If within radius (e.g. 100m), status marks 'Inside Office'. If on outdoor duty, it marks 'Field Punch' with exact GPS coordinates.")
        add_bullet(doc, "Shift Time & Grace Calculation", "Punches recorded after shift start + grace window (e.g. 09:15 AM for a 09:00 AM shift) are automatically tagged as 'LATE' with exact minutes calculated.")
        add_bullet(doc, "Daily Duty Duration", "Upon Punch Out, the system computes total active working hours (excluding breaks).")
        
        # 7. Customer Visits & Dealer Supervision
        add_section_h2(doc, "7. Customer & Field Visit Supervision")
        add_p(doc, "For organizations with sales, distribution, or field maintenance staff, the Customer Visits module tracks daily market coverage:")
        add_bullet(doc, "Real-time Visit Feed", "Stream of customer meetings submitted by field officers throughout the day.")
        add_bullet(doc, "Meeting Documentation", "Review client name, contact person, meeting discussion remarks, and selected Visit Status (Interested, Order Placed, Quotation Given, Payment Collected, Closed).")
        add_bullet(doc, "Storefront Photo Proof", "Field staff capture an optional photo of the customer's shop or business card with embedded GPS watermark.")
        add_bullet(doc, "Follow-up Pipeline", "View scheduled future follow-up dates to ensure sales continuity.")
        
        # 8. Leave Management Workflow
        add_section_h2(doc, "8. Leave Management & Approval Workflow")
        add_p(doc, "Streamline leave administration without paper forms or email delays:")
        add_num_step(doc, 1, "Review Pending Applications", "Open the Leave Management tab. Pending requests appear ordered by submission date.")
        add_num_step(doc, 2, "Inspect Entitlement & Balance", "View applicant's requested dates, leave type (Casual, Sick, Annual), stated reason, and current remaining leave balance.")
        add_num_step(doc, 3, "Decision & Notification", "Tap [Approve] or [Reject]. You may include optional administrative notes. An immediate push notification is delivered to the employee's phone.")
        
        # 9. User & Employee Administration
        add_section_h2(doc, "9. User & Employee Administration")
        add_p(doc, "Full lifecycle management of employee accounts:")
        add_bullet(doc, "Create New User", "Add Full Name, Username, Phone, Email, Temporary Password, and Role (User / Field Officer or Admin).")
        add_bullet(doc, "Office & Shift Assignment", "Assign employee to their specific office branch (for geofencing) and assigned duty shift schedule.")
        add_bullet(doc, "Password Reset", "Instantly reset forgotten employee passwords directly from the user card.")
        add_bullet(doc, "Account Enable / Disable", "Immediately revoke application access when an employee leaves the company.")
        
        # 10. System Setup & Master Configurations
        add_section_h2(doc, "10. System Setup & Master Configurations")
        add_p(doc, "Configure your organizational structure under administrative settings:")
        add_bullet(doc, "Office Geofence Locations", "Add office branches by setting Latitude, Longitude, and Allowed Geofence Radius in meters (e.g. 50m to 200m).")
        add_bullet(doc, "Work Shift Schedules", "Define Shift Name, Start Time, End Time, Late Punch Grace Period (minutes), and Half-day thresholds.")
        add_bullet(doc, "Official Holiday Calendar", "Configure national holidays, corporate non-working days, and weekend schedules.")
        
        # 11. Performance Analytics & Reports
        add_section_h2(doc, "11. Performance Analytics & Export Reports")
        add_p(doc, "Generate actionable business intelligence from field data:")
        add_bullet(doc, "Attendance Summary Report", "Monthly present/absent/late statistics per employee for HR and payroll integration.")
        add_bullet(doc, "Travel & Mileage Summary", "Total kilometers logged per field representative for fuel/conveyance reimbursement audits.")
        add_bullet(doc, "Client Visit Leaderboard", "Ranks top-performing sales officers by total verified customer visits and conversion rates.")
        add_bullet(doc, "Data Export", "Export any dataset to Microsoft Excel (.xlsx) or formatted PDF reports with one click.")
        
        # 12. Troubleshooting & Admin FAQs
        add_section_h2(doc, "12. Administrative Troubleshooting & FAQs")
        add_bullet(doc, "Why does an employee show 'Offline' during work hours?", "Ensure the employee has mobile data/Wi-Fi active, has enabled 'Allow all the time' location access, and excluded the app from battery saver restrictions.")
        add_bullet(doc, "How often is the live map refreshed?", "Real-time updates are pushed instantaneously via SignalR. When an officer moves, their position updates within seconds.")
        add_bullet(doc, "Can an employee fake their GPS location?", "Smart Work Force detects mock location providers and flags unnatural coordinate jumps. GPS accuracy is recorded with every ping.")
        
        doc.add_page_break()
    
    # -------------------------------------------------------------
    # BANGLA SECTION
    # -------------------------------------------------------------
    if include_bn:
        add_section_h1(doc, "দ্বিতীয় অংশ: অ্যাডমিনিস্ট্রেটর অপারেশন ম্যানুয়াল (বাংলা সংস্করণ)")
        
        # ১. পরিচিতি ও মূল আর্কিটেকচার
        add_section_h2(doc, "১. সিস্টেম পরিচিতি ও মূল কাঠামো")
        add_p(doc, "স্মার্ট ওয়ার্ক ফোর্স (Smart Work Force) হলো একটি অত্যাধুনিক এন্টারপ্রাইজ ফিল্ড ফোর্স ও লাইভ লোকেশন ট্র্যাকিং প্ল্যাটফর্ম। এটি প্রতিষ্ঠানের অ্যাডমিনিস্ট্রেটর, অপারেশন ম্যানেজার, এরিয়া ম্যানেজার এবং এইচআর টিমকে মাঠপর্যায়ের সকল কর্মকর্তা ও কর্মচারীদের দৈনন্দিন কার্যক্রম রিয়েল-টাইমে পর্যবেক্ষণ ও নিয়ন্ত্রণের পূর্ণ ক্ষমতা প্রদান করে।")
        
        add_p(doc, "সিস্টেমের মূল ৪টি প্রযুক্তিগত স্তর:")
        add_bullet(doc, "নেটিভ অ্যান্ড্রয়েড অ্যাপ", "অত্যাধুনিক ও দ্রুতগতির কোটলিন অ্যাপ যা অ্যাডমিন মোড এবং ইউজার মোড উভয় সাপোর্ট করে।")
        add_bullet(doc, "সিগন্যাল-আর (SignalR) লাইভ ব্রডকাস্ট", "মিলিসেকেন্ডের মধ্যে লাইভ লোকেশন আপডেট, অনলাইন/অফলাইন স্থিতি এবং পুশ নোটিফিকেশন আদান-প্রদান করে।")
        add_bullet(doc, "এন্টারপ্রাইজ ব্যাকএন্ড ইঞ্জিন", "ASP.NET Core 8 চালিত সুরক্ষিত ওয়েব এপিআই এবং সিকিউর জেডব্লিউটি (JWT) অথেনটিকেশন।")
        add_bullet(doc, "স্প্যাশিয়াল ডেটাবেজ লেয়ার", "মাইক্রোসফট এসকিউএল সার্ভার ২০১৯+ এর Spatial GEOGRAPHY ইনডেক্সিং প্রযুক্তি, যা নিখুঁত জিওফেন্স ও রুট হিসাব করে।")
        
        # ২. অ্যাডমিন লগইন ও প্রাথমিক সেটআপ
        add_section_h2(doc, "২. অ্যাডমিন লগইন ও প্রাথমিক প্রস্তুতি")
        add_p(doc, "অ্যাডমিনিস্ট্রেটর হিসেবে সিস্টেমে প্রবেশের নিয়মাবলী:")
        add_num_step(doc, 1, "অ্যাপ ওপেন করুন", "অ্যান্ড্রয়েড ডিভাইসে স্মার্ট ওয়ার্ক ফোর্স অ্যাপ চালু করুন।")
        add_num_step(doc, 2, "ইউজারনেম ও পাসওয়ার্ড দিন", "আপনার জন্য নির্ধারিত অ্যাডমিন ইউজারনেম ও পাসওয়ার্ড দিয়ে 'লগইন' বাটনে চাপুন।")
        add_num_step(doc, 3, "ভাষা পরিবর্তন (Language Switch)", "অ্যাপের ওপরের ডান কোণায় থাকা '🌐 English / বাংলা' বাটনে ট্যাপ করে যেকোনো সময় ভাষা পরিবর্তন করতে পারবেন।")
        add_num_step(doc, 4, "ড্যাশবোর্ডে প্রবেশ", "অ্যাডমিন রোল ভেরিফাই হওয়ার পর সরাসরি 'এক্সিকিউটিভ কমান্ড সেন্টার' বা অ্যাডমিন ড্যাশবোর্ড প্রদর্শিত হবে।")
        
        # ৩. এক্সিকিউটিভ কমান্ড সেন্টার
        add_section_h2(doc, "৩. এক্সিকিউটিভ ড্যাশবোর্ড ও কমান্ড সেন্টার")
        add_p(doc, "অ্যাডমিন ড্যাশবোর্ডটি এমনভাবে ডিজাইন করা হয়েছে যেন যেকোনো সুপারভাইজার বা নির্বাহী এক নজরে পুরো মাঠের পরিস্থিতি বুঝতে পারেন এবং দ্রুত সিদ্ধান্ত নিতে পারেন।")
        
        add_section_h3(doc, "রিয়েল-টাইম কেপিআই (KPI) কার্ডসমূহ")
        kpi_bn_headers = ["কেপিআই মেট্রিক", "বাস্তব অর্থ", "ব্যবস্থাপনাগত করণীয়"]
        kpi_bn_rows = [
            ["মোট কর্মচারী (Total Staff)", "প্রতিষ্ঠানে নিবন্ধিত সক্রিয় কর্মচারীর মোট সংখ্যা।", "মোট জনবল পর্যবেক্ষণ।"],
            ["লাইভ ট্র্যাকিং সক্রিয় (Active Now)", "বর্তমানে যেসব অফিসারদের জিপিএস লোকেশন চালু রয়েছে।", "মাঠে সক্রিয় কর্মীর সংখ্যা যাচাই।"],
            ["আজকের উপস্থিতি (Today's Present)", "আজকে নির্ধারিত সময়ে সেলফি পাঞ্চ করে হাজিরা দেওয়া কর্মী।", "উপস্থিতির শতকরা হার নির্ধারণ।"],
            ["আজকে অনুপস্থিত (Today's Absent)", "আজকে যারা এখনো হাজিরা দেননি বা অনুপস্থিত।", "ডিপার্টমেন্ট ইনচার্জের সাথে যোগাযোগ।"],
            ["আজকে লেট (Today's Late)", "নির্ধারিত শিফট সময়ের পরে দেরিতে উপস্থিতি দেওয়া কর্মী।", "দেরিতে আসার কারণ যাচাই।"],
            ["ছুটির আবেদন (Pending Leaves)", "অনুমোদনের অপেক্ষায় থাকা ছুটির দরখাস্ত।", "পর্যালোচনা করে অনুমোদন/বাতিল।"],
            ["বকেয়া ফলো-আপ (Pending Follow-up)", "আজকের দিনের জন্য নির্ধারিত কাস্টমার মিটিং ও ফলো-আপ।", "কর্মীরা ভিজিট শেষ করছে কি না তদারকি।"]
        ]
        add_styled_table(doc, [2.0, 2.4, 2.1], kpi_bn_headers, kpi_bn_rows)
        
        add_section_h3(doc, "'Attention Required' (জরুরি দৃষ্টি আকর্ষণ) রাডার")
        add_p(doc, "ড্যাশবোর্ডের শীর্ষে থাকা এই স্মার্ট রাডার স্বয়ংক্রিয়ভাবে ফিল্ডের যেকোনো অস্বাভাবিকতা শনাক্ত করে অ্যালার্ট দেয়:")
        add_bullet(doc, "জিপিএস বন্ধ অ্যালার্ট (GPS Disabled)", "ডিউটি চলাকালীন কোনো ফিল্ড অফিসার ফোনের লোকেশন বন্ধ করলে তাৎক্ষণিক লাল অ্যালার্ট আসে।")
        add_bullet(doc, "লোকেশন আপডেট নেই (>৩ মিনিট)", "নেটওয়ার্ক বিচ্ছিন্নতা বা মোবাইল বন্ধ থাকলে এটি নোটিফাই করে।")
        add_bullet(doc, "দেরিতে হাজিরা (Late Punch)", "নির্ধারিত গ্রেস টাইমের পরে পাঞ্চ করলে সরাসরি নাম চলে আসে।")
        add_bullet(doc, "মিসড ফলো-আপ (Missed Follow-up)", "নির্ধারিত সময়ে কাস্টমারের কাছে না পৌঁছালে ম্যানেজার দেখতে পান।")
        add_p(doc, "প্রতিটি অ্যালার্ট কার্ডের সাথে সরাসরি [কল করুন], [ম্যাপে ট্র্যাক করুন], [অনুমোদন/বাতিল] বাটন থাকে।")
        
        # ৪. রিয়েল-টাইম লাইভ ট্র্যাকিং ম্যাপ
        add_section_h2(doc, "৪. রিয়েল-টাইম লাইভ ট্র্যাকিং ও ফিল্ড মনিটরিং")
        add_p(doc, "লাইভ ট্র্যাকিং মডিউলে পুরো স্ক্রিন জুড়ে গুগল ম্যাপের মাধ্যমে মাঠপর্যায়ের সকল কর্মীর অবস্থান লাইভ দেখা যায়। পেজ রিফ্রেশ করার প্রয়োজন হয় না, সিগন্যাল-আর প্রযুক্তির মাধ্যমে স্বয়ংক্রিয়ভাবে পিন নড়াচড়া করে।")
        
        add_section_h3(doc, "ম্যাপ মার্কারের রঙের অর্থ")
        marker_bn_headers = ["মার্কার রঙ", "অবস্থা", "ব্যাখ্যা ও অর্থ"]
        marker_bn_rows = [
            ["🟢 উজ্জ্বল সবুজ (Green)", "সক্রিয় ও চলমান", "অফিসার ডিউটিতে রয়েছেন এবং গতি ২ কিমি/ঘণ্টার বেশি। জিপিএস সক্রিয়।"],
            ["🔵 রয়েল ব্লু (Blue)", "অনলাইন ও স্থির", "অফিসার কোনো দোকানে বা কাস্টমারের সাথে মিটিংয়ে স্থির আছেন। গতি ০ কিমি।"],
            ["⚪ হালকা ধূসর (Gray)", "অফলাইন (>৩ মিনিট)", "গত ৩ মিনিটের মধ্যে সার্ভারে কোনো সিগন্যাল আসেনি (নেটওয়ার্ক সমস্যা হতে পারে)।"],
            ["🔴 গাঢ় লাল (Red)", "জিপিএস বন্ধ / অ্যালার্ট", "ফোনের জিপিএস বন্ধ করা হয়েছে। তাৎক্ষণিক কল করে কারণ জানতে হবে।"]
        ]
        add_styled_table(doc, [1.8, 1.8, 2.9], marker_bn_headers, marker_bn_rows)
        
        add_section_h3(doc, "মার্কারের ওপর ট্যাপ করলে প্রাপ্ত তথ্য")
        add_bullet(doc, "অফিসারের পরিচিতি", "নাম, মোবাইল নম্বর, পদবি ও ছবি।")
        add_bullet(doc, "ডিভাইস টেলিমেট্রি", "বর্তমান গতি (কিমি/ঘণ্টা), জিপিএস সঠিকতার রেডিয়াস (মিটার) এবং ফোনের ব্যাটারি চার্জ (%)।")
        add_bullet(doc, "সময় ও ঠিকানা", "সর্বশেষ সিগন্যাল পাঠানোর সময় এবং এলাকার পূর্ণাঙ্গ ঠিকানা।")
        add_bullet(doc, "এক ক্লিকে অ্যাকশন", "[কল করুন] বাটনে চাপলে সরাসরি ফোন কল হবে; [রুট হিস্ট্রি] চাপলে আজকের ভ্রমণ পথ দেখাবে; [নেভিগেট] চাপলে কর্মীর অবস্থান পর্যন্ত গুগল ম্যাপের পথনির্দেশনা চালু হবে।")
        
        # ৫. রুট হিস্ট্রি ও প্লেব্যাক বিশ্লেষণ
        add_section_h2(doc, "৫. রুট হিস্ট্রি ও মুভমেন্ট প্লেব্যাক বিশ্লেষণ")
        add_p(doc, "রুট হিস্ট্রি মডিউলের মাধ্যমে যেকোনো কর্মীর যেকোনো দিনের পূর্ণাঙ্গ যাতায়াত পথ পরীক্ষা করা যায়:")
        add_num_step(doc, 1, "কর্মচারী ও তারিখ নির্বাচন", "নির্দিষ্ট অফিসারকে সিলেক্ট করুন এবং ক্যালেন্ডার থেকে তারিখ নির্বাচন করুন।")
        add_num_step(doc, 2, "ভ্রমণ সারাংশ দেখুন", "সিস্টেম স্বয়ংক্রিয়ভাবে প্রদর্শন করবে: মোট ভ্রমণ দূরত্ব (কিলোমিটার), প্রথম অবস্থান (পাঞ্চ ইন), শেষ অবস্থান (পাঞ্চ আউট), মোট যাত্রাবিরতি সংখ্যা এবং গড় গতি।")
        add_num_step(doc, 3, "ইন্টারেক্টিভ রুট পলিলাইন", "পুরো রাস্তার ম্যাপে নীল রেখা দ্বারা ভ্রমণপথ আঁকা হয়। ৫ মিনিটের বেশি যেসব জায়গায় দাঁড়িয়ে ছিলেন, সেখানে স্টপ নম্বর পিন বসে।")
        add_num_step(doc, 4, "ভিডিও প্লেব্যাক কন্ট্রোল", "নিচের প্লে বারে [Play], [Pause] এবং স্পিড (1x, 2x, 4x) দিয়ে সারাদিনের মুভমেন্ট ভিডিওর মতো প্লে করে দেখা যায়।")
        add_num_step(doc, 5, "স্টপ ডিউরেশন যাচাই", "যেকোনো স্টপ পিনে ট্যাপ করলে কয়টায় পৌঁছেছিলেন, কয়টায় বের হয়েছেন এবং কত মিনিট অবস্থান করেছিলেন তা জানা যায়।")
        
        # ৬. স্মার্ট উপস্থিতি ও জিওফেন্স ম্যানেজমেন্ট
        add_section_h2(doc, "৬. স্মার্ট উপস্থিতি ও জিওফেন্স তদারকি")
        add_p(doc, "ভুয়া বা প্রক্সি হাজিরা সম্পূর্ণ রোধে স্মার্ট ওয়ার্ক ফোর্সে রয়েছে ডুয়াল সিকিউরিটি:")
        add_bullet(doc, "লাইভ সেলফি ফটো", "হাজিরা দেওয়ার সময় অফিসারকে তাৎক্ষণিক সেলফি তুলতে হয়। অ্যাডমিন ফটো থাম্বনেইলে ক্লিক করে পূর্ণাঙ্গ ছবি দেখতে পারেন।")
        add_bullet(doc, "জিওফেন্স কমপ্লায়েন্স", "কর্মচারী অফিসের নির্ধারিত রেডিয়াস (যেমন ১০০ মিটার) এর ভেতরে আছেন কি না তা যাচাই করে 'অফিস হাজিরা' অথবা 'ফিল্ড হাজিরা' হিসেবে মার্ক করে।")
        add_bullet(doc, "শিফট সময় ও লেট নির্ধারণ", "গ্রেস টাইমের (যেমন সকাল ৯:১৫) পরে হাজিরা দিলে স্বয়ংক্রিয়ভাবে 'LATE' স্ট্যাটাস বসে এবং কত মিনিট লেট হয়েছে তা রেকর্ড হয়।")
        add_bullet(doc, "কাজের ঘণ্টা", "ডিউটি আউট করার পর মোট কর্মঘণ্টা ক্যালকুলেট হয়।")
        
        # ৭. কাস্টমার ও ফিল্ড ভিজিট তদারকি
        add_section_h2(doc, "৭. কাস্টমার ও ফিল্ড ভিজিট তদারকি")
        add_p(doc, "মাঠপর্যায়ের সেলস ও মার্কেটিং টিম সারাদিনে কোন কোন দোকানে বা ক্লায়েন্টের কাছে ভিজিট করেছে তা রিয়েল-টাইমে জানা যায়:")
        add_bullet(doc, "লাইভ ভিজিট স্ট্রিম", "ভিজিট সম্পন্ন হওয়া মাত্র অ্যাডমিন প্যানেলে তালিকা চলে আসে।")
        add_bullet(doc, "আলোচনার সারসংক্ষেপ ও স্ট্যাটাস", "কাস্টমারের নাম, যোগাযোগের ব্যক্তি, আলোচনার বিষয় এবং স্ট্যাটাস (অর্ডার নেওয়া হয়েছে, কোটেশন দেওয়া হয়েছে, ফলো-আপ লাগবে, পেমেন্ট সংগ্রহ ইত্যাদি)।")
        add_bullet(doc, "দোকানের লাইভ ছবি", "ফিল্ড অফিসার কাস্টমারের দোকানের যে ছবি তুলেছেন তা জিপিএস ওয়াটারমার্কসহ প্রদর্শিত হয়।")
        add_bullet(doc, "ভবিষ্যৎ ফলো-আপ পাইপলাইন", "পরবর্তী ফলো-আপের তারিখ পর্যবেক্ষণ করে সেলস পাইপলাইন ট্র্যাক করা যায়।")
        
        # ৮. ছুটি ব্যবস্থাপনা ও অনুমোদন
        add_section_h2(doc, "৮. ছুটি ব্যবস্থাপনা ও অনুমোদন প্রক্রিয়া")
        add_num_step(doc, 1, "আবেদন পর্যালোচনা", "ছুটি ম্যানেজমেন্ট ট্যাবে গিয়ে পেন্ডিং আবেদনের তালিকা দেখুন।")
        add_num_step(doc, 2, "ছুটির ধরন ও ব্যালেন্স চেক", "কর্মচারীর ছুটির ধরন (নৈমিত্তিক, অসুস্থতা, বাৎসরিক), তারিখের ব্যপ্তি, কারণ এবং তার অবশিষ্ট ছুটির ব্যালেন্স দেখতে পাবেন।")
        add_num_step(doc, 3, "অনুমোদন বা বাতিল", "[Approve] বা [Reject] বাটনে এক ক্লিকে সিদ্ধান্ত দিন। তাৎক্ষণিক কর্মীর ফোনে পুশ নোটিফিকেশন পৌঁছে যাবে।")
        
        # ৯. কর্মকর্তা ও ইউজার প্রশাসন
        add_section_h2(doc, "৯. কর্মকর্তা ও ইউজার অ্যাকাউন্ট প্রশাসন")
        add_bullet(doc, "নতুন ইউজার তৈরি", "কর্মচারীর নাম, ইউজারনেম, মোবাইল নম্বর, ইমেইল, পাসওয়ার্ড এবং পদবি (User/Field Officer অথবা Admin) দিয়ে অ্যাকাউন্ট তৈরি করুন।")
        add_bullet(doc, "অফিস ও শিফট অ্যাসাইন", "কর্মীকে তার নির্দিষ্ট ব্রাঞ্চ বা অফিস লোকেশন এবং ডিউটি শিফটে যুক্ত করুন।")
        add_bullet(doc, "পাসওয়ার্ড রিসেট", "কোনো কর্মী পাসওয়ার্ড ভুলে গেলে অ্যাডমিন সরাসরি নতুন পাসওয়ার্ড সেট করে দিতে পারেন।")
        add_bullet(doc, "অ্যাকাউন্ট সক্রিয়/নিষ্ক্রিয়", "চাকরি ছাড়লে বা সাময়িক সাসপেনশনে এক ক্লিকে অ্যাকাউন্ট নিষ্ক্রিয় করা যায়।")
        
        # ১০. সিস্টেম কনফিগারেশন
        add_section_h2(doc, "১০. সিস্টেম কনফিগারেশন (অফিস, শিফট ও ছুটি)")
        add_bullet(doc, "অফিস লোকেশন ও জিওফেন্স", "প্রতিষ্ঠানের হেড অফিস ও শাখা অফিসসমূহের অক্ষাংশ (Latitude), দ্রাঘিমাংশ (Longitude) এবং গ্রহণযোগ্য রেডিয়াস (যেমন ১০০ মিটার) সেট করুন।")
        add_bullet(doc, "শিফট শিডিউলিং", "শিফটের শুরুর সময়, শেষ সময়, লেট হাজিরা গ্রেস পিরিয়ড (যেমন ১৫ মিনিট) নির্ধারণ করুন।")
        add_bullet(doc, "সরকারি ছুটির তালিকা", "বছরের সরকারি ও প্রাতিষ্ঠানিক ছুটির দিনসমূহ ক্যালেন্ডারে যুক্ত করুন।")
        
        # ১১. পারফরম্যান্স রিপোর্ট ও এক্সপোর্ট
        add_section_h2(doc, "১১. পারফরম্যান্স রিপোর্ট ও এক্সপোর্ট")
        add_bullet(doc, "মাসিক হাজিরা রিপোর্ট", "পে-রোল প্রসেসিং ও বেতনের জন্য কর্মীদের মাসিক উপস্থিতির পূর্ণ বিবরণ।")
        add_bullet(doc, "ট্রাভেল ও মাইলেজ রিপোর্ট", "টিএ/ডিএ বিল নিরীক্ষার জন্য কোন অফিসার কত কিলোমিটার পথ ভ্রমণ করেছেন তার রিপোর্ট।")
        add_bullet(doc, "ভিজিট লিডারবোর্ড", "সর্বোচ্চ ভিজিট সম্পন্নকারী কর্মকর্তাদের তালিকা ও পারফরম্যান্স রেটিং।")
        add_bullet(doc, "এক্সেল ও পিডিএফ এক্সপোর্ট", "যেকোনো রিপোর্ট এক ক্লিকে মাইক্রোসফট এক্সেল (.xlsx) বা প্রিন্ট-রেডি পিডিএফ (.pdf) ফরম্যাটে ডাউনলোড করুন।")
        
        # ১২. সাধারণ প্রশ্নোত্তর (FAQ)
        add_section_h2(doc, "১২. সাধারণ সমস্যা ও সমাধান (FAQ)")
        add_bullet(doc, "কর্মচারীকে অফলাইন দেখালে করণীয় কী?", "নিশ্চিত করুন কর্মীর ফোনে ইন্টারনেট চালু আছে, লোকেশন 'Allow all the time' দেওয়া আছে এবং ব্যাটারি সেভার বন্ধ করা আছে।")
        add_bullet(doc, "লাইভ ম্যাপ কতক্ষণ পরপর আপডেট হয়?", "সিগন্যাল-আর মাধ্যমে তাৎক্ষণিক আপডেট হয়। অফিসার চলাচলের সাথে সাথে প্রতি মিনিটে স্বয়ংক্রিয়ভাবে নতুন লোকেশন বসে।")
        add_bullet(doc, "ভুয়া জিপিএস লোকেশন ব্যবহার সম্ভব কি না?", "সিস্টেমে ফেক/মক লোকেশন ডিটেকশন রয়েছে। অস্বাভাবিক মুভমেন্ট হলে সিস্টেম স্বয়ংক্রিয়ভাবে ফ্ল্যাগ করে।")

    # Save Master Document
    doc.save(output_path)
    print(f"Successfully generated: {output_path}")

if __name__ == "__main__":
    out_dir = r"d:\Shuvo\zynexbd\live_tracking"
    doc_dir = r"d:\Shuvo\zynexbd\live_tracking\LiveTrackingSystem\Documentation"
    
    # 1. Master Dual-Language Admin Document
    master_admin_path = os.path.join(out_dir, "Smart_WorkForce_Admin_Guideline.docx")
    build_admin_document(master_admin_path, include_en=True, include_bn=True)
    
    # Also save copy in Documentation directory
    master_admin_doc_path = os.path.join(doc_dir, "Smart_WorkForce_Admin_Guideline.docx")
    build_admin_document(master_admin_doc_path, include_en=True, include_bn=True)
    
    # 2. Standalone English Admin Document
    en_admin_path = os.path.join(out_dir, "Smart_WorkForce_Admin_Guideline_English.docx")
    build_admin_document(en_admin_path, include_en=True, include_bn=False)
    
    # 3. Standalone Bangla Admin Document
    bn_admin_path = os.path.join(out_dir, "Smart_WorkForce_Admin_Guideline_Bangla.docx")
    build_admin_document(bn_admin_path, include_en=False, include_bn=True)
    
    print("All Admin guidelines generated successfully!")
