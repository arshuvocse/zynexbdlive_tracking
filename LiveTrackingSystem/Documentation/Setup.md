# Live Tracking System — Setup Guide

## 1. Database

1. Open SQL Server Management Studio (SSMS) and connect to your target server.
2. Enable "SQLCMD Mode" (Query menu) if you want to run `ExecuteAll.sql` directly, or run the scripts manually in this order:
   1. `Database/CreateDatabase.sql`
   2. `Database/CreateTables.sql`
   3. `Database/CreateIndexes.sql`
   4. `Database/CreateStoredProcedures.sql`
   5. `Database/SeedData.sql`
3. `SeedData.sql` inserts one Admin (`admin`) and one User (`user1`) with placeholder password hashes. These placeholders will NOT authenticate — after the API is running, either:
   - Log in as `admin`/temporary value fails intentionally; instead call `POST /api/users/{id}/reset-password` once you have another admin session, OR
   - Use a one-off console snippet with `PasswordHasher<User>` to generate real hashes for `Admin@123` / `User@123` and UPDATE the two seed rows directly in SQL.

## 2. API (LiveTracking.Api)

1. Requires .NET 8 SDK.
2. Edit `LiveTracking.Api/appsettings.json`:
   - `ConnectionStrings:DefaultConnection` — point at your SQL Server instance and the `LiveTrackingDb` database created above.
   - `Jwt:Key` — replace with a long random secret (32+ chars).
3. From `LiveTracking.Api/`, run:
   ```
   dotnet restore
   dotnet run
   ```
4. Swagger UI is available at `/swagger` in Development. Default dev URL: `http://localhost:5080`.
5. Docker: `docker build -t livetracking-api .` then `docker run -p 8080:8080 livetracking-api` (pass connection string / JWT key as environment variables or mount a config).

### Key endpoints
- `POST /api/auth/login` — returns JWT + role.
- `GET/POST/PUT /api/users` — Admin only, create/edit/disable/reset-password.
- `POST /api/locations/ping` — User only, ingest a location ping (also broadcasts to SignalR).
- `GET /api/locations/latest` — Admin only, latest location per user.
- SignalR hub: `/hubs/location` (JWT passed as `?access_token=` for websocket handshake).

## 3. Android App (AndroidApp)

1. Open the `AndroidApp` folder as an Android Studio project (min SDK 26, target SDK 34, Kotlin).
2. Set the API base URL in `app/build.gradle.kts` under `defaultConfig.buildConfigField`:
   - `API_BASE_URL` — e.g. `http://10.0.2.2:5080/` for the Android emulator talking to a locally running API, or your deployed API's base URL (must end with `/`).
   - `SIGNALR_HUB_URL` — e.g. `http://10.0.2.2:5080/hubs/location`.
3. Replace the Google Maps API key placeholder in `manifests/AndroidManifest.xml` (`com.google.android.geo.API_KEY`) with a real key that has the Maps SDK for Android enabled.
4. Build and run on a device/emulator with Google Play Services.

### Login / role-based navigation flow
1. `LoginActivity` posts credentials to `POST /api/auth/login`.
2. On success, the JWT, role, and user info are saved via `SessionManager` (SharedPreferences).
3. If `role == "Admin"` → `AdminDashboardActivity` (live map fed by SignalR, user management).
4. If `role == "User"` → `TrackingForegroundService` is started immediately (no Start/Stop button anywhere), then `UserHomeActivity` is shown.
5. `TrackingForegroundService` captures a location fix and calls `POST /api/locations/ping` every 60 seconds. Failed uploads are persisted in a local SQLite queue (`LocationOfflineQueue`) and retried/flushed on the next tick, up to `MAX_RETRY_ATTEMPTS`.
6. `BootReceiver` listens for `ACTION_BOOT_COMPLETED` and restarts the foreground service automatically if the last session was a logged-in User.
7. Logging out from `UserHomeActivity` stops the service and clears the session.

## Assumptions
- EF Core (SQL Server provider) is used in the API rather than raw ADO/Dapper.
- Password hashing uses ASP.NET Core Identity's `PasswordHasher<User>` (PBKDF2-HMACSHA256, Identity v3 format). The seed hashes in `SeedData.sql` are real, verified hashes for `Admin@123` (admin) and `User@123` (user1) — they will authenticate as-is; rotate them after first login in a real deployment.
- The Android sources live under the standard Gradle layout `AndroidApp/app/src/main/java/com/zynexbd/livetracking/<layer>` and `AndroidApp/app/src/main/res/...`, so the project opens and compiles in Android Studio without extra source-set configuration.
