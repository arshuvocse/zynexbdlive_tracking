# SMART WORK FORCE (স্মার্ট ওয়ার্ক ফোর্স)
## Enterprise Field Workforce Monitoring & Live Tracking Platform
### Administrator Operational Manual / অ্যাডমিনিস্ট্রেটর অপারেশন ম্যানুয়াল

---

# PART 1: ADMINISTRATOR OPERATIONAL GUIDE (ENGLISH)

## 1. System Overview & Core Architecture
Smart Work Force is an end-to-end enterprise solution engineered to empower executives, HR managers, and team leaders with complete visibility over field operations, sales representatives, delivery personnel, and remote staff. Unlike legacy static tracking systems, Smart Work Force operates as an active **Executive Command Center**, automatically prioritizing operational anomalies that require immediate management attention.

The enterprise infrastructure comprises four synchronized layers:
* **Native Mobile Applications:** High-performance Kotlin Android application with dual-mode operational intelligence (Field User Mode and Executive Admin Mode).
* **Real-Time SignalR Event Hub:** WebSocket-driven bi-directional communication protocol delivering instantaneous location updates, online/offline transitions, and attendance events within milliseconds.
* **Enterprise Backend Engine:** ASP.NET Core 8 REST API secured with JSON Web Tokens (JWT), role-based claims verification, and asynchronous high-throughput processing.
* **Spatial Database Layer:** Microsoft SQL Server 2019+ utilizing spatial GEOGRAPHY indexes (`SIX_DriverLocations_Location`) for lightning-fast radius calculations, polygon geofencing, and historical playback queries.

---

## 2. Administrative Login & Initial Setup
1. **Launch Application:** Open the Smart Work Force application on your Android device or access the administrative portal.
2. **Enter Authorized Credentials:** Input your assigned Admin Username and Password. Default initial admin credentials must be updated immediately upon first login.
3. **Language Selection:** Tap the language selector toggle (`🌐 English / বাংলা`) at the top right header to switch the interface language at any time.
4. **Role Routing:** The system verifies administrative claims (`Role: Admin`). Upon successful token issuance, you are automatically directed to the Executive Command Center.

---

## 3. Executive Command Center (Overview Dashboard)
The Executive Dashboard is designed as an action-oriented mission control center. Instead of requiring administrators to dig through nested menus, the landing screen aggregates all critical metrics in real time.

### Key Performance Indicator (KPI) Widgets
| KPI Metric | Real-Time Meaning | Managerial Action |
| :--- | :--- | :--- |
| **Total Employees** | Total number of registered staff members. | Review active workforce headcount. |
| **Active Tracking Now** | Officers currently broadcasting live GPS signals. | Monitor real-time field presence. |
| **Today's Punch In** | Employees who completed morning attendance. | Verify punctuality vs total roster. |
| **Today's Absent** | Staff who failed to punch in after shift start. | Follow up with department heads. |
| **Today's Late** | Punched in past designated shift grace period. | Evaluate attendance discipline. |
| **Pending Leaves** | Leave applications awaiting administrative review. | Requires 1-tap Approve or Reject. |
| **Pending Follow-ups**| Customer meetings scheduled for today across team. | Ensure field officers complete scheduled visits. |

### 'Attention Required' Smart Alert Radar
Positioned prominently at the top of the dashboard, this automated intelligence hub scans the entire workforce every 30 seconds and dynamically flags high-priority operational exceptions:
* **GPS Disabled Alert:** Triggered instantly if a field officer turns off phone location services or revokes GPS permission during active duty hours.
* **No Location Updates (>3 Min):** Identifies officers who have gone silent or experienced network disconnections while on the clock.
* **Late Punch-In Notification:** Highlights staff members arriving after the allowed shift grace window.
* **Overdue Customer Follow-ups:** Alerts when a client meeting deadline has passed without visit submission.

*Every alert card includes direct quick-action buttons: `[Call Officer]`, `[Track on Map]`, `[Approve/Reject]`.*

---

## 4. Real-Time Live Tracking & Field Radar
The Live Tracking module features a full-screen interactive Google Map visualizing the exact geographical coordinates of all field staff simultaneously.

### Marker Status Color Codes
| Marker Indicator | Status Condition | Interpretation |
| :--- | :--- | :--- |
| 🟢 **Emerald Green** | Online & Moving | Officer is actively traveling; speed > 2 km/h; GPS ping within last 60 seconds. |
| 🔵 **Royal Blue** | Online & Stationary | Officer is stationary at a customer shop or meeting; GPS accurate; speed = 0. |
| ⚪ **Muted Gray** | Offline (> 3 Minutes) | No location packet received for > 3 minutes (poor network or battery dead). |
| 🔴 **Crimson Red** | GPS Disabled / Alert | Device GPS was turned off manually; immediate supervisor action required. |

### Interactive Marker Inspection
Tapping any employee pin on the map opens an expanded Executive Info Card containing:
* **Officer Profile:** Full Name, Mobile Number, Assigned Department, and Profile Picture.
* **Telemetry Metrics:** Current Speed (km/h), GPS Accuracy Radius (meters), Device Battery Percentage (%).
* **Timestamp & Address:** Exact time of latest location update and reverse-geocoded street address.
* **Action Hub:** `[Call Officer]` initiates direct voice call; `[Route History]` loads today's trail; `[Navigate]` opens Google Maps directions to the officer's exact spot.

---

## 5. Route History & Movement Playback Analysis
1. **Select Officer & Date:** Select the desired field officer and pick any date from the interactive calendar picker.
2. **Analyze Summary Metrics:** Displays Total Distance Traveled (km), First Location (Punch In), Last Location (Punch Out), Total Stops, and Average Speed.
3. **Interactive Route Polyline:** The complete travel path is rendered on Google Maps. Numbered pins denote stop locations where the officer remained stationary for over 5 minutes.
4. **Timeline Playback Simulation:** Use the playback bar with `[Play]`, `[Pause]`, and speed toggles (`1x`, `2x`, `4x`). A simulated marker moves along the actual road path.
5. **Stopover Duration Audit:** Tap any numbered stop pin to inspect Arrival Time, Departure Time, Total Duration at spot, and Nearest Landmark/Customer.

---

## 6. Smart Attendance & Geofencing Supervision
* **Biometric Selfie Photo:** Staff must take a live photo during punch-in. Administrators can tap thumbnail for full-resolution view.
* **Geofence Compliance:** Calculates distance between employee coordinates and assigned office location. Validates if employee is "Inside Office" (within radius) or on an authorized "Field Punch".
* **Shift Time & Grace Calculation:** Punches after shift start + grace window (e.g. 09:15 AM) are automatically tagged as **LATE** with exact minutes calculated.
* **Daily Duty Duration:** Automatically calculates total active working hours upon Punch Out.

---

## 7. Customer & Field Visit Supervision
* **Real-time Visit Feed:** Stream of customer meetings submitted by field officers throughout the day.
* **Meeting Documentation:** Review client name, contact person, meeting discussion remarks, and selected Visit Status (Interested, Order Placed, Quotation Given, Payment Collected, Closed).
* **Storefront Photo Proof:** Field staff capture an optional photo of the customer's shop or business card with embedded GPS watermark.
* **Follow-up Pipeline:** View scheduled future follow-up dates to ensure sales continuity.

---

## 8. Leave Management & Approval Workflow
1. **Review Pending Applications:** Open the Leave Management tab. Pending requests appear ordered by submission date.
2. **Inspect Entitlement & Balance:** View applicant's requested dates, leave type (Casual, Sick, Annual), stated reason, and current remaining leave balance.
3. **Decision & Notification:** Tap `[Approve]` or `[Reject]`. Include optional administrative notes. An immediate push notification is delivered to the employee's phone.

---

## 9. User & Employee Administration
* **Create New User:** Add Full Name, Username, Phone, Email, Temporary Password, and Role (User / Field Officer or Admin).
* **Office & Shift Assignment:** Assign employee to their specific office branch (for geofencing) and assigned duty shift schedule.
* **Password Reset:** Instantly reset forgotten employee passwords directly from the user card.
* **Account Enable / Disable:** Immediately revoke application access when an employee leaves the company.

---

## 10. System Setup & Master Configurations
* **Office Geofence Locations:** Add office branches by setting Latitude, Longitude, and Allowed Geofence Radius in meters (e.g. 50m to 200m).
* **Work Shift Schedules:** Define Shift Name, Start Time, End Time, Late Punch Grace Period (minutes), and Half-day thresholds.
* **Official Holiday Calendar:** Configure national holidays, corporate non-working days, and weekend schedules.

---

## 11. Performance Analytics & Export Reports
* **Attendance Summary Report:** Monthly present/absent/late statistics per employee for HR and payroll integration.
* **Travel & Mileage Summary:** Total kilometers logged per field representative for fuel/conveyance reimbursement audits.
* **Client Visit Leaderboard:** Ranks top-performing sales officers by total verified customer visits and conversion rates.
* **Data Export:** Export any dataset to Microsoft Excel (.xlsx) or formatted PDF reports with one click.

---

## 12. Administrative Troubleshooting & FAQs
* **Why does an employee show 'Offline' during work hours?** Ensure the employee has mobile data/Wi-Fi active, has enabled 'Allow all the time' location access, and excluded the app from battery saver restrictions.
* **How often is the live map refreshed?** Real-time updates are pushed instantaneously via SignalR. When an officer moves, their position updates within seconds.
* **Can an employee fake their GPS location?** Smart Work Force detects mock location providers and flags unnatural coordinate jumps. GPS accuracy is recorded with every ping.

---
---

# দ্বিতীয় অংশ: অ্যাডমিনিস্ট্রেটর অপারেশন ম্যানুয়াল (বাংলা সংস্করণ)

## ১. সিস্টেম পরিচিতি ও মূল কাঠামো
স্মার্ট ওয়ার্ক ফোর্স (Smart Work Force) হলো একটি অত্যাধুনিক এন্টারপ্রাইজ ফিল্ড ফোর্স ও লাইভ লোকেশন ট্র্যাকিং প্ল্যাটফর্ম। এটি প্রতিষ্ঠানের অ্যাডমিনিস্ট্রেটর, অপারেশন ম্যানেজার, এরিয়া ম্যানেজার এবং এইচআর টিমকে মাঠপর্যায়ের সকল কর্মকর্তা ও কর্মচারীদের দৈনন্দিন কার্যক্রম রিয়েল-টাইমে পর্যবেক্ষণ ও নিয়ন্ত্রণের পূর্ণ ক্ষমতা প্রদান করে।

সিস্টেমের মূল ৪টি প্রযুক্তিগত স্তর:
* **নেটিভ অ্যান্ড্রয়েড অ্যাপ:** দ্রুতগতির কোটলিন অ্যাপ যা অ্যাডমিন মোড এবং ইউজার মোড উভয় সাপোর্ট করে।
* **সিগন্যাল-আর (SignalR) লাইভ ব্রডকাস্ট:** মিলিসেকেন্ডের মধ্যে লাইভ লোকেশন আপডেট, অনলাইন/অফলাইন স্থিতি এবং পুশ নোটিফিকেশন আদান-প্রদান করে।
* **এন্টারপ্রাইজ ব্যাকএন্ড ইঞ্জিন:** ASP.NET Core 8 চালিত সুরক্ষিত ওয়েব এপিআই এবং সিকিউর জেডব্লিউটি (JWT) অথেনটিকেশন।
* **স্প্যাশিয়াল ডেটাবেজ লেয়ার:** মাইক্রোসফট এসকিউএল সার্ভার ২০১৯+ এর Spatial GEOGRAPHY ইনডেক্সিং প্রযুক্তি।

---

## ২. অ্যাডমিন লগইন ও প্রাথমিক প্রস্তুতি
1. **অ্যাপ ওপেন করুন:** অ্যান্ড্রয়েড ডিভাইসে স্মার্ট ওয়ার্ক ফোর্স অ্যাপ চালু করুন।
2. **ইউজারনেম ও পাসওয়ার্ড দিন:** আপনার জন্য নির্ধারিত অ্যাডমিন ইউজারনেম ও পাসওয়ার্ড দিয়ে 'লগইন' বাটনে চাপুন।
3. **ভাষা পরিবর্তন:** অ্যাপের ওপরের ডান কোণায় থাকা `🌐 English / বাংলা` বাটনে ট্যাপ করে যেকোনো সময় ভাষা পরিবর্তন করুন।
4. **ড্যাশবোর্ডে প্রবেশ:** অ্যাডমিন রোল ভেরিফাই হওয়ার পর সরাসরি 'এক্সিকিউটিভ কমান্ড সেন্টার' বা অ্যাডমিন ড্যাশবোর্ড প্রদর্শিত হবে।

---

## ৩. এক্সিকিউটিভ ড্যাশবোর্ড ও কমান্ড সেন্টার
অ্যাডমিন ড্যাশবোর্ডটি এমনভাবে ডিজাইন করা হয়েছে যেন যেকোনো সুপারভাইজার বা নির্বাহী এক নজরে পুরো মাঠের পরিস্থিতি বুঝতে পারেন।

### রিয়েল-টাইম কেপিআই (KPI) কার্ডসমূহ
| কেপিআই মেট্রিক | বাস্তব অর্থ | ব্যবস্থাপনাগত করণীয় |
| :--- | :--- | :--- |
| **মোট কর্মচারী** | প্রতিষ্ঠানে নিবন্ধিত সক্রিয় কর্মচারীর মোট সংখ্যা। | মোট জনবল পর্যবেক্ষণ। |
| **লাইভ ট্র্যাকিং সক্রিয়** | বর্তমানে যেসব অফিসারদের জিপিএস লোকেশন চালু রয়েছে। | মাঠে সক্রিয় কর্মীর সংখ্যা যাচাই। |
| **আজকের উপস্থিতি** | আজকে নির্ধারিত সময়ে সেলফি পাঞ্চ করে হাজিরা দেওয়া কর্মী। | উপস্থিতির শতকরা হার নির্ধারণ। |
| **আজকে অনুপস্থিত** | আজকে যারা এখনো হাজিরা দেননি বা অনুপস্থিত। | ডিপার্টমেন্ট ইনচার্জের সাথে যোগাযোগ। |
| **আজকে লেট** | নির্ধারিত শিফট সময়ের পরে দেরিতে উপস্থিতি দেওয়া কর্মী। | দেরিতে আসার কারণ যাচাই। |
| **ছুটির আবেদন** | অনুমোদনের অপেক্ষায় থাকা ছুটির দরখাস্ত। | পর্যালোচনা করে অনুমোদন/বাতিল। |
| **বকেয়া ফলো-আপ** | আজকের দিনের জন্য নির্ধারিত কাস্টমার মিটিং ও ফলো-আপ। | কর্মীরা ভিজিট শেষ করছে কি না তদারকি। |

### 'Attention Required' (জরুরি দৃষ্টি আকর্ষণ) রাডার
ড্যাশবোর্ডের শীর্ষে থাকা এই স্মার্ট রাডার স্বয়ংক্রিয়ভাবে ফিল্ডের অস্বাভাবিকতা শনাক্ত করে অ্যালার্ট দেয়:
* **জিপিএস বন্ধ অ্যালার্ট (GPS Disabled):** ডিউটি চলাকালীন কোনো ফিল্ড অফিসার ফোনের লোকেশন বন্ধ করলে তাৎক্ষণিক লাল অ্যালার্ট আসে।
* **লোকেশন আপডেট নেই (>৩ মিনিট):** নেটওয়ার্ক বিচ্ছিন্নতা বা মোবাইল বন্ধ থাকলে এটি নোটিফাই করে।
* **দেরিতে হাজিরা (Late Punch):** নির্ধারিত গ্রেস টাইমের পরে পাঞ্চ করলে সরাসরি নাম চলে আসে।
* **মিসড ফলো-আপ (Missed Follow-up):** নির্ধারিত সময়ে কাস্টমারের কাছে না পৌঁছালে ম্যানেজার দেখতে পান।

---

## ৪. রিয়েল-টাইম লাইভ ট্র্যাকিং ও ফিল্ড মনিটরিং
লাইভ ট্র্যাকিং মডিউলে পুরো স্ক্রিন জুড়ে গুগল ম্যাপের মাধ্যমে মাঠপর্যায়ের সকল কর্মীর অবস্থান লাইভ দেখা যায়।

### ম্যাপ মার্কারের রঙের অর্থ
| মার্কার রঙ | অবস্থা | ব্যাখ্যা ও অর্থ |
| :--- | :--- | :--- |
| 🟢 **উজ্জ্বল সবুজ** | সক্রিয় ও চলমান | অফিসার ডিউটিতে রয়েছেন এবং গতি ২ কিমি/ঘণ্টার বেশি। |
| 🔵 **রয়েল ব্লু** | অনলাইন ও স্থির | অফিসার কোনো দোকানে বা কাস্টমারের সাথে মিটিংয়ে স্থির আছেন। গতি ০ কিমি। |
| ⚪ **হালকা ধূসর** | অফলাইন (>৩ মিনিট) | গত ৩ মিনিটের মধ্যে কোনো সিগন্যাল আসেনি (নেটওয়ার্ক সমস্যা হতে পারে)। |
| 🔴 **গাঢ় লাল** | জিপিএস বন্ধ / অ্যালার্ট | ফোনের জিপিএস বন্ধ করা হয়েছে। তাৎক্ষণিক অ্যাকশন প্রয়োজন। |

### মার্কারের ওপর ট্যাপ করলে প্রাপ্ত তথ্য
* **অফিসারের পরিচিতি:** নাম, মোবাইল নম্বর, পদবি ও ছবি।
* **ডিভাইস টেলিমেট্রি:** বর্তমান গতি (কিমি/ঘণ্টা), জিপিএস সঠিকতার রেডিয়াস (মিটার) এবং ফোনের ব্যাটারি চার্জ (%)।
* **সময় ও ঠিকানা:** সর্বশেষ সিগন্যাল পাঠানোর সময় এবং এলাকার পূর্ণাঙ্গ ঠিকানা।
* **এক ক্লিকে অ্যাকশন:** `[কল করুন]` বাটনে চাপলে সরাসরি ফোন কল; `[রুট হিস্ট্রি]` চাপলে আজকের ভ্রমণ পথ; `[নেভিগেট]` চাপলে গুগল ম্যাপে পথনির্দেশনা।

---

## ৫. রুট হিস্ট্রি ও মুভমেন্ট প্লেব্যাক বিশ্লেষণ
1. **কর্মচারী ও তারিখ নির্বাচন:** নির্দিষ্ট অফিসারকে সিলেক্ট করুন এবং ক্যালেন্ডার থেকে তারিখ নির্বাচন করুন।
2. **ভ্রমণ সারাংশ দেখুন:** মোট ভ্রমণ দূরত্ব (কিলোমিটার), প্রথম অবস্থান (পাঞ্চ ইন), শেষ অবস্থান (পাঞ্চ আউট), মোট যাত্রাবিরতি সংখ্যা এবং গড় গতি।
3. **ইন্টারেক্টিভ রুট পলিলাইন:** পুরো রাস্তার ম্যাপে নীল রেখা দ্বারা ভ্রমণপথ আঁকা হয়। ৫ মিনিটের বেশি বিরতির জায়গায় স্টপ নম্বর পিন বসে।
4. **ভিডিও প্লেব্যাক কন্ট্রোল:** নিচের প্লে বারে `[Play]`, `[Pause]` এবং স্পিড (`1x`, `2x`, `4x`) দিয়ে সারাদিনের মুভমেন্ট ভিডিওর মতো প্লে করে দেখা যায়।
5. **স্টপ ডিউরেশন যাচাই:** যেকোনো স্টপ পিনে ট্যাপ করলে কয়টায় পৌঁছেছিলেন, কয়টায় বের হয়েছেন এবং কত মিনিট অবস্থান করেছিলেন তা জানা যায়।

---

## ৬. স্মার্ট উপস্থিতি ও জিওফেন্স তদারকি
* **লাইভ সেলফি ফটো:** হাজিরা দেওয়ার সময় অফিসারকে তাৎক্ষণিক সেলফি তুলতে হয়। অ্যাডমিন ফটো থাম্বনেইলে ক্লিক করে পূর্ণাঙ্গ ছবি দেখতে পারেন।
* **জিওফেন্স কমপ্লায়েন্স:** কর্মচারী অফিসের নির্ধারিত রেডিয়াস (যেমন ১০০ মিটার) এর ভেতরে আছেন কি না তা যাচাই করে 'অফিস হাজিরা' অথবা 'ফিল্ড হাজিরা' হিসেবে মার্ক করে।
* **শিফট সময় ও লেট নির্ধারণ:** গ্রেস টাইমের (যেমন সকাল ৯:১৫) পরে হাজিরা দিলে স্বয়ংক্রিয়ভাবে 'LATE' স্ট্যাটাস বসে এবং কত মিনিট লেট হয়েছে তা রেকর্ড হয়।
* **কাজের ঘণ্টা:** ডিউটি আউট করার পর মোট কর্মঘণ্টা ক্যালকুলেট হয়।

---

## ৭. কাস্টমার ও ফিল্ড ভিজিট তদারকি
* **লাইভ ভিজিট স্ট্রিম:** ভিজিট সম্পন্ন হওয়া মাত্র অ্যাডমিন প্যানেলে তালিকা চলে আসে।
* **আলোচনার সারসংক্ষেপ ও স্ট্যাটাস:** কাস্টমারের নাম, যোগাযোগের ব্যক্তি, আলোচনার বিষয় এবং স্ট্যাটাস (অর্ডার নেওয়া হয়েছে, কোটেশন দেওয়া হয়েছে, ফলো-আপ লাগবে, পেমেন্ট সংগ্রহ ইত্যাদি)।
* **দোকানের লাইভ ছবি:** ফিল্ড অফিসার কাস্টমারের দোকানের যে ছবি তুলেছেন তা জিপিএস ওয়াটারমার্কসহ প্রদর্শিত হয়।
* **ভবিষ্যৎ ফলো-আপ পাইপলাইন:** পরবর্তী ফলো-আপের তারিখ পর্যবেক্ষণ করে সেলস পাইপলাইন ট্র্যাক করা যায়।

---

## ৮. ছুটি ব্যবস্থাপনা ও অনুমোদন প্রক্রিয়া
1. **আবেদন পর্যালোচনা:** ছুটি ম্যানেজমেন্ট ট্যাবে গিয়ে পেন্ডিং আবেদনের তালিকা দেখুন।
2. **ছুটির ধরন ও ব্যালেন্স চেক:** কর্মচারীর ছুটির ধরন (নৈমিত্তিক, অসুস্থতা, বাৎসরিক), তারিখের ব্যপ্তি, কারণ এবং অবশিষ্ট ব্যালেন্স দেখতে পাবেন।
3. **অনুমোদন বা বাতিল:** `[Approve]` বা `[Reject]` বাটনে এক ক্লিকে সিদ্ধান্ত দিন। তাৎক্ষণিক কর্মীর ফোনে পুশ নোটিফিকেশন পৌঁছে যাবে।

---

## ৯. কর্মকর্তা ও ইউজার অ্যাকাউন্ট প্রশাসন
* **নতুন ইউজার তৈরি:** কর্মচারীর নাম, ইউজারনেম, মোবাইল নম্বর, ইমেইল, পাসওয়ার্ড এবং পদবি দিয়ে অ্যাকাউন্ট তৈরি করুন।
* **অফিস ও শিফট অ্যাসাইন:** কর্মীকে তার নির্দিষ্ট ব্রাঞ্চ বা অফিস লোকেশন এবং ডিউটি শিফটে যুক্ত করুন।
* **পাসওয়ার্ড রিসেট:** কোনো কর্মী পাসওয়ার্ড ভুলে গেলে অ্যাডমিন সরাসরি নতুন পাসওয়ার্ড সেট করে দিতে পারেন।
* **অ্যাকাউন্ট সক্রিয়/নিষ্ক্রিয়:** চাকরি ছাড়লে বা সাময়িক সাসপেনশনে এক ক্লিকে অ্যাকাউন্ট নিষ্ক্রিয় করা যায়।

---

## ১০. সিস্টেম কনফিগারেশন (অফিস, শিফট ও ছুটি)
* **অফিস লোকেশন ও জিওফেন্স:** প্রতিষ্ঠানের হেড অফিস ও শাখা অফিসসমূহের অক্ষাংশ, দ্রাঘিমাংশ এবং গ্রহণযোগ্য রেডিয়াস (যেমন ১০০ মিটার) সেট করুন।
* **শিফট শিডিউলিং:** শিফটের শুরুর সময়, শেষ সময়, লেট হাজিরা গ্রেস পিরিয়ড (যেমন ১৫ মিনিট) নির্ধারণ করুন।
* **সরকারি ছুটির তালিকা:** বছরের সরকারি ও প্রাতিষ্ঠানিক ছুটির দিনসমূহ ক্যালেন্ডারে যুক্ত করুন।

---

## ১১. পারফরম্যান্স রিপোর্ট ও এক্সপোর্ট
* **মাসিক হাজিরা রিপোর্ট:** পে-রোল প্রসেসিং ও বেতনের জন্য কর্মীদের মাসিক উপস্থিতির পূর্ণ বিবরণ।
* **ট্রাভেল ও মাইলেজ রিপোর্ট:** টিএ/ডিএ বিল নিরীক্ষার জন্য কোন অফিসার কত কিলোমিটার পথ ভ্রমণ করেছেন তার রিপোর্ট।
* **ভিজিট লিডারবোর্ড:** সর্বোচ্চ ভিজিট সম্পন্নকারী কর্মকর্তাদের তালিকা ও পারফরম্যান্স রেটিং।
* **এক্সেল ও পিডিএফ এক্সপোর্ট:** যেকোনো রিপোর্ট এক ক্লিকে মাইক্রোসফট এক্সেল (.xlsx) বা প্রিন্ট-রেডি পিডিএফ (.pdf) ফরম্যাটে ডাউনলোড করুন।

---

## ১২. সাধারণ সমস্যা ও সমাধান (FAQ)
* **কর্মচারীকে অফলাইন দেখালে করণীয় কী?** নিশ্চিত করুন কর্মীর ফোনে ইন্টারনেট চালু আছে, লোকেশন 'Allow all the time' দেওয়া আছে এবং ব্যাটারি সেভার বন্ধ করা আছে।
* **লাইভ ম্যাপ কতক্ষণ পরপর আপডেট হয়?** সিগন্যাল-আর মাধ্যমে তাৎক্ষণিক আপডেট হয়। অফিসার চলাচলের সাথে সাথে প্রতি মিনিটে স্বয়ংক্রিয়ভাবে নতুন লোকেশন বসে।
* **ভুয়া জিপিএস লোকেশন ব্যবহার সম্ভব কি না?** সিস্টেমে ফেক/মক লোকেশন ডিটেকশন রয়েছে। অস্বাভাবিক মুভমেন্ট হলে সিস্টেম স্বয়ংক্রিয়ভাবে ফ্ল্যাগ করে।
