# Prompt: Upgrade Existing Live Tracking System into a Modern, User-Friendly & Professional Application

You are a Senior Android (Kotlin) Engineer, ASP.NET Core Architect, UI/UX Designer, Product Designer, and Software Architect.

Your job is to improve an EXISTING production project.

## IMPORTANT RULES

* DO NOT create a new project.
* DO NOT remove any existing features.
* DO NOT break existing APIs.
* DO NOT rewrite working modules unnecessarily.
* Upgrade and improve the existing project.
* Keep backward compatibility.
* Reuse existing code whenever possible.
* Make the application modern, user-friendly, fast, beautiful, and professional.

---

# Main Goal

The application should feel like a premium enterprise mobile application.

Every screen should be simple.

Every action should require the minimum number of taps.

Users should be able to complete their work quickly without confusion.

Focus on productivity rather than adding unnecessary features.

---

# Overall Design Principles

Redesign the entire Android application using modern UI/UX principles.

Use:

* Material Design 3
* Clean Layout
* Modern Cards
* Rounded Corners
* Smooth Animations
* Lottie Animations
* Dynamic Colors
* Professional Icons
* Better Typography
* Proper Spacing
* Consistent Colors
* Skeleton Loading
* Shimmer Effects
* Pull To Refresh
* Swipe Gestures
* Bottom Sheet Dialogs
* Floating Action Button where appropriate
* Dark Mode Support
* Responsive Layout
* Fast Navigation
* Beautiful Empty States
* Better Error Screens
* Better Success Messages

Avoid clutter.

Every screen should have a clean and premium appearance.

---

# Improve User Experience

Reduce unnecessary clicks.

Reduce unnecessary forms.

Reduce unnecessary dialogs.

Make every workflow faster.

Every important action should be reachable within one or two taps.

Users should always know what to do next.

Use clear icons and labels.

Use larger touch areas.

Keep forms short.

Auto-fill data whenever possible.

Use GPS automatically.

Remember previous selections where appropriate.

Show loading indicators properly.

Never freeze the UI.

---

# Dashboard Improvements

Create a beautiful dashboard.

Display:

* User Photo
* Welcome Message
* Current Date
* Attendance Status
* Live GPS Status
* Internet Status
* Battery Status
* Today's Working Time
* Today's Visits
* Pending Follow-ups
* Quick Actions
* Recent Activities

The dashboard should immediately show the user's daily progress.

---

# Customer Module (Simple & Productive)

Do NOT create a heavy CRM.

Keep customer management simple.

Customer List:

* Search
* Simple Filter
* Add Customer
* Call
* Navigate
* Visit

Customer Card should display only:

* Customer Name
* Mobile Number
* Address
* Last Visit
* Next Follow-up

Customer Details:

* Name
* Mobile
* Address
* GPS Location
* Last Visit
* Next Follow-up
* Remarks

Buttons:

* Visit
* Call
* Navigate

Customer Add Form should contain only:

* Customer Name
* Mobile
* Address
* GPS (Auto Capture)
* Shop Photo (Optional)
* Remarks (Optional)

No unnecessary information like:

* Trade License
* NID
* TIN
* Email
* Owner Details
* Company Details

Keep it simple.

---

# Customer Visit Workflow

The visit process should be extremely fast.

Flow:

Select Customer

↓

Verify GPS

↓

Start Visit

↓

Enter Remarks

↓

Select Visit Status

↓

Select Next Follow-up Date

↓

Save

Optional:

Take Shop Photo

Everything should be completed within one minute.

---

# Follow-up Module

Create a clean follow-up system.

Categories:

* Today
* Tomorrow
* Upcoming
* Overdue

Customer Card should show:

* Customer Name
* Follow-up Date
* Call Button
* Visit Button
* Mark as Completed

Notification Reminder:

30 minutes before follow-up.

---

# Attendance

Improve attendance screens.

Better UI.

Better history.

Calendar View.

Working Hours.

Punch Status.

Selfie support should remain.

GPS validation should remain.

---

# Leave Module

Modern leave application.

Simple forms.

Better history.

Status timeline.

Remaining leave balance.

---

# Live Tracking

Keep the existing tracking system.

Improve only:

* Stability
* Battery Optimization
* Location Accuracy
* Better Background Service
* Better Notification
* Better Error Recovery

Do not change existing tracking logic.

---

# Performance Improvements

Optimize:

* RecyclerViews
* Image Loading
* API Calls
* Location Requests
* Battery Usage
* Memory Usage
* Startup Time

Improve scrolling performance.

Remove unnecessary network calls.

Cache frequently used data.

---

# Backend API Improvements

Keep all existing APIs.

Only extend where necessary.

Add APIs only for:

* Customers
* Customer Visits
* Follow-ups

Support:

* Pagination
* Searching
* Filtering
* Validation
* Proper Error Responses
* Logging

Maintain clean architecture.

---

# Database

Keep database simple.

Customers

* CustomerId
* Name
* Mobile
* Address
* Latitude
* Longitude
* Remarks
* CreatedDate
* IsActive

CustomerVisits

* VisitId
* CustomerId
* UserId
* VisitDate
* Latitude
* Longitude
* Remarks
* VisitStatus
* NextFollowUpDate

Do not overcomplicate the database.

---

# Code Quality

Refactor existing code where necessary.

Remove duplicate code.

Improve naming conventions.

Create reusable components.

Follow SOLID principles.

Keep code modular.

Use MVVM properly.

Improve Repository pattern.

Handle exceptions properly.

Use centralized API handling.

Improve session management.

Improve navigation.

Improve validation.

---

# UI Polish

Improve:

* Splash Screen
* Login Screen
* Dashboard
* Attendance
* Customer List
* Customer Details
* Visit Screen
* Leave Screens
* Profile
* Settings

Every screen should look consistent.

Every button should have proper feedback.

Every list should support empty state.

Every form should validate input before submission.

---

# Final Objective

Transform the existing application into a premium enterprise mobile application.

The application should be:

* Simple
* Fast
* User Friendly
* Professional
* Attractive
* Easy to Learn
* Easy to Use
* Productive
* Reliable
* Scalable

Do not introduce unnecessary complexity.

Focus on helping field employees complete their work faster with fewer taps and a better user experience.

Before implementing any feature, first analyze the existing codebase and reuse current architecture, APIs, database structure, and UI components wherever possible. Only introduce new code when required, ensuring full backward compatibility with the existing production system.
