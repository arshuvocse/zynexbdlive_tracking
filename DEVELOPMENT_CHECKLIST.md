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
- [x] Database Scripts Created (`database/01_CreateDatabase.sql`, `database/02_CreateTables.sql`, `database/03_SeedAdmin.sql`)
- [x] MS SQL MCP Server Configured (`@eamonboyle/mssql-mcp`)
- [ ] Connect SQL Server & Execute Database Migration Scripts
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
- [x] Restore NuGet Packages (Resolved NU1301 fallback issue with local `nuget.config`)
- [x] Build Project (`0 Error(s)`, `net8.0`)
- [ ] Run Web API & Test Endpoints (`POST /api/locations`, `GET /api/locations/active`, `POST /api/auth/login`)
- [ ] Generate API Documentation

---

## Phase 4 - Mobile App Development (Android / Flutter)
Goal: Develop and maintain the client tracking app.

Tasks:
- [x] Native Android Kotlin App structure in `apps/android`
- [x] Configure User & Admin flows
- [x] Configure Foreground Tracking Service & Fused Location Provider
- [x] Integrate REST & SignalR client
- [ ] Build Android APK / App Bundle

---

## Phase 5 - Docker
Goal: Allow AI to manage Docker.

Tasks:
- [x] Install Docker MCP (`@modelcontextprotocol/server-docker` added to `mcp_config.json`)
- [x] Create Dockerfile for ASP.NET Web API
- [x] Create `docker-compose.yml` for API & SQL Server
- [ ] Connect Docker Engine & Build Images
- [ ] Run Containers

---

## Phase 6 - AI Memory
Goal: Make AI remember the project.

Tasks:
- [x] Install Memory MCP
- [x] Store Project Information in Memory MCP Graph
- [x] Store Architecture & Schemas in Memory MCP
- [ ] Store Coding Standards & Rules

---

## Phase 7 - Sequential Thinking
Goal: Enable step-by-step reasoning for complex features/bugs.

Tasks:
- [x] Install Sequential Thinking MCP
- [x] Ready for Multi-step Reasoning & Bug Analysis

---

## Phase 8 - GitHub & Version Control
Goal: Manage source code lifecycle.

Tasks:
- [x] Initialize Git Repository
- [x] Create Initial Commit & Set Main Branch
- [x] Add Remote Repository (`https://github.com/arshuvocse/zynexbdlive_tracking.git`)
- [x] Push Initial Code to Remote GitHub Repository
- [x] Commit & Push Setup Improvements

---

## Phase 9 - Production & Deployment
Goal: Deploy and monitor the application.

Tasks:
- [ ] Configure Environment Variables
- [ ] Build Release Artifacts
- [ ] Deploy Docker Containers
- [ ] Database Migration & Seed Verification
- [ ] Logging & Performance Monitoring
