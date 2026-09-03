# Project Development Checklist & Tooling Verification

## Phase 1 - Development Environment
- [x] Filesystem MCP (`@modelcontextprotocol/server-filesystem` mapped to `d:\Shuvo\zynexbd\live_tracking`)
- [x] GitHub MCP (`@modelcontextprotocol/server-github` authenticated via PAT)
- [x] Fetch MCP (`@modelcontextprotocol/server-fetch` active)

---

## Phase 2 - Database
Goal: Allow AI to work directly with SQL Server.

**Database Details:**
* **Server**: `NASA-PC\MSSQLSERVER2019`
* **User**: `sa`
* **Database**: `EProgramIntegration_DB`

Tasks:
- [x] Install SQL MCP (`@eamonboyle/mssql-mcp`)
- [x] Connect SQL Server (`NASA-PC\MSSQLSERVER2019`, user `sa`, database `EProgramIntegration_DB`)
- [x] Verify database connection (**28 Tables**, **37 Stored Procedures**)
- [x] Test SELECT, INSERT, UPDATE, DELETE (CRUD cycle executed and validated)
- [x] Read Stored Procedures (`sp_GetAllUsers`, `sp_GetAttendanceHistory`, `sp_GetLeaveApplications`, `sp_GetAttendanceReportByMonthYear`)
- [x] Execute Stored Procedures (Executed `sp_GetAllUsers` returning active user records)

---

## Phase 3 - Docker
Goal: Allow AI to manage Docker.

Tasks:
- [x] Install Docker MCP (`@modelcontextprotocol/server-docker` / `mcp-server-docker`)
- [x] Connect Docker Engine (Docker daemon verified and running)
- [x] List Containers (`livetracking_crm_api`, `varatia_web_api`, `smc_hris_db`, `varatia_mssql_db`)
- [x] Start Container (`docker start <container_id>`)
- [x] Stop Container (`docker stop <container_id>`)
- [x] Restart Container (`docker restart <container_id>`)
- [x] View Logs (`docker logs --tail 50 livetracking_crm_api`)
- [x] Execute Commands Inside Container (`docker exec livetracking_crm_api ls -la /app`)

---

## Phase 4 - AI Memory
Goal: Make AI remember the project.

Tasks:
- [x] Install Memory MCP (`@modelcontextprotocol/server-memory`)
- [x] Store Project Information (`LiveTrackingSystem` entity)
- [x] Store Coding Rules (`CodingRules` entity with C# 12 / .NET 8 / ISO 8601 UTC standards)
- [x] Store Folder Structure (`FolderStructure` architecture entity)
- [x] Store Database Information (`EProgramIntegration_DB` entity with tables & stored procedures)
- [x] Linked Entities & Tool Configurations in Knowledge Graph

---

## Phase 5 - Sequential Thinking
Goal: Enable step-by-step reasoning.

Tasks:
- [x] Install Sequential Thinking MCP (`@modelcontextprotocol/server-sequential-thinking`)
- [x] Enable Planning
- [x] Enable Task Breakdown
- [x] Enable Multi-step Reasoning

---

## Phase 6 - GitHub Automation
Goal: Version control & automation.

Tasks:
- [x] Repository Connected (`https://github.com/arshuvocse/zynexbdlive_tracking.git`)
- [x] Commit Changes (`git commit` / GitHub MCP `push_files`)
- [x] Push Changes (`git push origin main`)
- [x] Create Branch (`git branch` / GitHub MCP `create_branch`)
- [x] Create Pull Request (GitHub MCP `create_pull_request`)

---

## Phase 7 - Production & Deployment
Goal: Deployment and maintenance.

Tasks:
- [x] Docker Compose (`docker-compose.yml` port mapping `5080:8080` with host gateway)
- [x] Environment Variables (`appsettings.Production.json` and compose envs)
- [x] Backup Database command ready (`BACKUP DATABASE [EProgramIntegration_DB] TO DISK = ...`)
- [x] Monitor Logs (`docker logs -f live_tracking_api`)
- [x] Deploy Server (`docker compose up --build -d`)
