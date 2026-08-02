# Live Location Tracking System

Three parts: MS SQL Server database, ASP.NET Core 8 Web API + SignalR, and a native Kotlin Android app (User/Driver mode + Admin mode).

## 1. Database

Run in order against `NASA-PC\MSSQLSERVER2019` (sqlcmd, SSMS, or Azure Data Studio) with `sa` / `sa1234#`:

```
database/01_CreateDatabase.sql
database/02_CreateTables.sql
database/03_SeedAdmin.sql
```

- Tables: `myonline_tbl_Users`, `myonline_tbl_DriverLocations` (both prefixed as required).
- `Location` is `GEOGRAPHY`, kept in sync with `Latitude`/`Longitude` by a trigger, with a spatial index (`SIX_..._Location`).
- Seeded admin: username `admin`, password `Admin@123` — **change this in production** (create a fresh admin via the API and deactivate the seed one, or update its hash).

## 2. Backend API (`apis/LiveTracking.Api`)

.NET 8, EF Core (SqlServer + NetTopologySuite), JWT auth, SignalR.

```
cd apis/LiveTracking.Api
dotnet restore
dotnet run
```

Swagger UI at `http://localhost:5000/swagger`.

Key endpoints:
- `POST /api/auth/login` → `{ token, role, userId, name, expiresAt }`
- `POST /api/locations` (User/Admin, JWT) → driver posts `{ latitude, longitude }` every 60s; broadcasts to Admins via SignalR
- `GET /api/locations/active` (Admin) → latest location per user + `isOnline` (offline if no update in `Tracking:OfflineThresholdMinutes`, default 3)
- `GET /api/users` / `POST /api/users` (Admin) → manage drivers/admins
- SignalR hub: `/hubs/location`, event `ReceiveLocationUpdate`; Admin clients auto-join the "Admins" group

**Before shipping:** replace `Jwt:Key` in `appsettings.json` with a strong random secret (32+ chars), and prefer `dotnet user-secrets` / environment variables over committing real credentials.

> Note: this environment's global NuGet config has a stale Visual Studio fallback-folder path, which blocked `dotnet restore` when I verified the project here. It's a machine-level config issue unrelated to the code — `dotnet restore` should work normally on a machine with a standard .NET SDK/VS install. If you hit `NU1301: local source ... doesn't exist`, check `C:\Program Files (x86)\NuGet\Config\Microsoft.VisualStudio.FallbackLocation.config` for a `fallbackPackageFolders` entry pointing at a path that doesn't exist, and remove/fix it (needs admin rights).

## 3. Android App (`apps/android`)

Kotlin, single APK containing both User and Admin flows (routed by role after login).

- Update `apps/android/app/build.gradle.kts`:
  - `API_BASE_URL` / `SIGNALR_HUB_URL` — `10.0.2.2` targets the emulator's host machine; use your machine's LAN IP for real devices, e.g. `http://192.168.x.x:5000/`.
- Add a real Google Maps API key in `AndroidManifest.xml` (`com.google.android.geo.API_KEY`), replacing `YOUR_GOOGLE_MAPS_API_KEY`.
- Replace the placeholder launcher icon (`@android:drawable/sym_def_app_icon` in the manifest) with a real one before release.

### User (Driver) flow
1. `LoginActivity` authenticates, stores the JWT in `EncryptedSharedPreferences` (`SessionManager`).
2. Role `User` → `UserHomeActivity`, which requests location + notification permissions, then starts `TrackingForegroundService`.
3. The foreground service uses `FusedLocationProviderClient` to fetch a location and `POST /api/locations` every 60 seconds, backed by a persistent low-priority notification (required for reliable delivery under Doze/App Standby). It prompts to exempt the app from battery optimization (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).
4. `BootRestartReceiver` resumes tracking after a reboot if a driver was already logged in.

### Admin flow
1. Role `Admin` → `AdminDashboardActivity`: Google Map with live markers (green = online, red = offline >3 min), fed by an initial REST snapshot, live SignalR pushes, and a 60s poll fallback.
2. FAB opens a "Create User" dialog (`POST /api/users`) for provisioning driver/admin accounts.

### Permissions requested
`ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE` (+ `FOREGROUND_SERVICE_LOCATION`), `POST_NOTIFICATIONS`, `WAKE_LOCK`, `INTERNET`, `RECEIVE_BOOT_COMPLETED`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
