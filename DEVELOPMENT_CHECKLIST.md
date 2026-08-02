# Full Development Lifecycle Checklist

## Phase 1 - Development Environment
Goal: Prepare the development environment.

Tasks:
- [x] Filesystem MCP
- [x] GitHub MCP
- [x] Fetch / Web Tools

---

## Phase 2 - Database
Goal: Allow AI to work directly with SQL Server.

Tasks:
- [x] Database Scripts Created (`01_CreateDatabase.sql`, `02_CreateTables.sql`, `03_SeedAdmin.sql`)
- [ ] Connect SQL Server / Execute SQL Queries directly via MCP or command line
- [ ] Verify Database Connection
- [ ] Read Tables & Stored Procedures
- [ ] Backup Database

---

## Phase 3 - Backend (ASP.NET Web API)
Goal: Allow AI to develop and maintain the Web API.

Tasks:
- [x] Open Solution / Project (`apis/LiveTracking.Api`)
- [x] Create Controllers & Services
- [x] Configure Dependency Injection
- [x] Configure JWT Authentication
- [x] Configure SignalR & Swagger
- [ ] Restore NuGet Packages (Resolving environment fallback issue)
- [ ] Build & Test APIs
- [ ] Generate API Documentation

---

## Phase 4 - Mobile App Development (Android / Flutter)
Goal: Develop and maintain the client tracking app.

Tasks:
- [x] Native Android Kotlin App structure in `apps/android`
- [x] Configure User & Admin flows
- [x] Configure Foreground Tracking Service & Fused Location Provider
- [x] Integrate REST & SignalR client
- [ ] Add Flutter app (if expanding to Flutter cross-platform)
- [ ] Build Release APK / App Bundle

---

## Phase 5 - Docker
Goal: Manage containerized deployment.

Tasks:
- [ ] Dockerfile setup
- [ ] Docker Compose setup for API and SQL Server
- [ ] Build & run Docker containers

---

## Phase 6 - AI Memory
Goal: Make AI remember the project.

Tasks:
- [x] Memory MCP installed
- [ ] Store Project Architecture & Schemas in Memory MCP Graph
- [ ] Store Coding Standards & Rules

---

## Phase 7 - Sequential Thinking
Goal: Enable step-by-step reasoning for complex features/bugs.

Tasks:
- [x] Sequential Thinking MCP installed
- [ ] Utilize multi-step reasoning for bug analysis & root cause analysis

---

## Phase 8 - GitHub & Version Control
Goal: Manage source code lifecycle.

Tasks:
- [x] Initialize Git Repository
- [x] Create Initial Commit & Set Main Branch
- [x] Add Remote Repository (`https://github.com/arshuvocse/zynexbdlive_tracking.git`)
- [x] Push Initial Code to Remote GitHub Repository
- [ ] Branching Strategy & Pull Requests

---

## Phase 9 - Production & Deployment
Goal: Deploy and monitor the application.

Tasks:
- [ ] Configure Environment Variables
- [ ] Build Release Artifacts
- [ ] Database Migration & Seed Verification
- [ ] Logging & Performance Monitoring
