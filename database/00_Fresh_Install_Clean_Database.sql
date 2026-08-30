/* ============================================================
   File: database/00_Fresh_Install_Clean_Database.sql
   LiveTrackingDB - COMPLETE FRESH INSTALL & CLEAN DATABASE SCRIPT
   
   Features included:
   1. Clean Drop / Reset of old tables & SPs (Safe Order)
   2. All 13 Core Tables with full column structures
   3. All Foreign Keys, Constraints, and Optimized Indexes
   4. Trigger for Geography coordinates sync
   5. Seed Data:
      - 3 Admin Accounts:
          1) admin (System Administrator) -> Pass: Admin@123
          2) moxxadmin (Moxx Admin)       -> Pass: Admin@123
          3) moxxadmin2 (Moxx Admin 2)     -> Pass: Admin@123
      - 1 Default Office Location (Headquarters)
      - 1 Default Shift (General Shift 09:00 - 18:00)
      - 3 Core Leave Types (Casual, Sick, Earned Leave)
      - 2026 Bangladesh Official Govt Holidays
      - Default App Version entry (v1.0)
   6. All 15+ Production Stored Procedures (CREATE OR ALTER)
   ============================================================ */

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'LiveTrackingDB')
BEGIN
    CREATE DATABASE LiveTrackingDB;
END
GO

ALTER DATABASE LiveTrackingDB SET RECOVERY SIMPLE;
GO

ALTER DATABASE LiveTrackingDB SET READ_COMMITTED_SNAPSHOT ON;
GO

USE LiveTrackingDB;
GO

/* ============================================================
   STEP 1: CLEAN / DROP EXISTING TABLES IN SAFE REVERSE FK ORDER
   ============================================================ */

IF OBJECT_ID(N'dbo.myonline_tbl_Notifications', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_Notifications;
IF OBJECT_ID(N'dbo.myonline_tbl_CustomerVisits', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_CustomerVisits;
IF OBJECT_ID(N'dbo.myonline_tbl_Customers', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_Customers;
IF OBJECT_ID(N'dbo.myonline_tbl_LeaveApplications', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_LeaveApplications;
IF OBJECT_ID(N'dbo.myonline_tbl_LeaveBalances', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_LeaveBalances;
IF OBJECT_ID(N'dbo.myonline_tbl_LeaveTypes', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_LeaveTypes;
IF OBJECT_ID(N'dbo.myonline_tbl_Attendances', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_Attendances;
IF OBJECT_ID(N'dbo.myonline_tbl_DriverLocations', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_DriverLocations;
IF OBJECT_ID(N'dbo.myonline_tbl_Users', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_Users;
IF OBJECT_ID(N'dbo.myonline_tbl_Shifts', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_Shifts;
IF OBJECT_ID(N'dbo.myonline_tbl_OfficeLocations', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_OfficeLocations;
IF OBJECT_ID(N'dbo.myonline_tbl_Holidays', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_Holidays;
IF OBJECT_ID(N'dbo.myonline_tbl_AppVersions', N'U') IS NOT NULL DROP TABLE dbo.myonline_tbl_AppVersions;
GO

/* ============================================================
   STEP 2: CREATE ALL 13 CORE TABLES
   ============================================================ */

-- 1. Office Locations
CREATE TABLE dbo.myonline_tbl_OfficeLocations
(
    Id              INT             IDENTITY(1,1)   NOT NULL,
    Name            NVARCHAR(150)                   NOT NULL,
    Latitude        FLOAT                           NOT NULL,
    Longitude       FLOAT                           NOT NULL,
    RadiusMeters    FLOAT                           NOT NULL CONSTRAINT DF_OfficeLocations_Radius DEFAULT (200),
    IsActive        BIT                             NOT NULL CONSTRAINT DF_OfficeLocations_IsActive DEFAULT (1),
    CreatedAt       DATETIME2                       NOT NULL CONSTRAINT DF_OfficeLocations_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_myonline_tbl_OfficeLocations PRIMARY KEY CLUSTERED (Id ASC)
);
GO

-- 2. Shifts
CREATE TABLE dbo.myonline_tbl_Shifts
(
    ShiftId            INT             IDENTITY(1,1)   NOT NULL,
    ShiftName          NVARCHAR(100)                   NOT NULL,
    StartTime          NVARCHAR(20)                    NOT NULL CONSTRAINT DF_Shifts_StartTime DEFAULT ('09:00:00'),
    EndTime            NVARCHAR(20)                    NOT NULL CONSTRAINT DF_Shifts_EndTime DEFAULT ('18:00:00'),
    GracePeriodMinutes INT                             NOT NULL CONSTRAINT DF_Shifts_Grace DEFAULT (15),
    IsDefault          BIT                             NOT NULL CONSTRAINT DF_Shifts_IsDefault DEFAULT (0),
    IsActive           BIT                             NOT NULL CONSTRAINT DF_Shifts_IsActive DEFAULT (1),
    CreatedByAdminId   INT                             NULL,
    CreatedAtUtc       DATETIME2                       NOT NULL CONSTRAINT DF_Shifts_CreatedAtUtc DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_myonline_tbl_Shifts PRIMARY KEY CLUSTERED (ShiftId ASC)
);
GO

-- 3. Users
CREATE TABLE dbo.myonline_tbl_Users
(
    Id                 INT             IDENTITY(1,1)   NOT NULL,
    Name               NVARCHAR(150)                   NOT NULL,
    Username           NVARCHAR(100)                   NOT NULL,
    PasswordHash       NVARCHAR(300)                   NOT NULL,
    Role               NVARCHAR(20)                    NOT NULL CONSTRAINT DF_Users_Role DEFAULT ('User'),
    PhoneNumber        NVARCHAR(30)                    NULL,
    CreatedAt          DATETIME2                       NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    IsActive           BIT                             NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
    OfficeLocationId   INT                             NULL,
    ShiftId            INT                             NULL,
    CreatedByAdminId   INT                             NULL,
    MaxUserLimit       INT                             NULL CONSTRAINT DF_Users_MaxUserLimit DEFAULT (10),
    BoundDeviceId      NVARCHAR(200)                   NULL,
    DeviceModel        NVARCHAR(200)                   NULL,
    PaymentDueDate     DATETIME2                       NULL,

    CONSTRAINT PK_myonline_tbl_Users PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT UQ_myonline_tbl_Users_Username UNIQUE (Username),
    CONSTRAINT CK_myonline_tbl_Users_Role CHECK (Role IN (N'Admin', N'User')),
    CONSTRAINT FK_myonline_tbl_Users_OfficeLocations FOREIGN KEY (OfficeLocationId) REFERENCES dbo.myonline_tbl_OfficeLocations (Id),
    CONSTRAINT FK_myonline_tbl_Users_Shifts FOREIGN KEY (ShiftId) REFERENCES dbo.myonline_tbl_Shifts (ShiftId)
);
GO

-- 4. Driver Locations (Live Tracking & History)
CREATE TABLE dbo.myonline_tbl_DriverLocations
(
    Id              BIGINT          IDENTITY(1,1)   NOT NULL,
    UserId          INT                             NOT NULL,
    Latitude        FLOAT                           NOT NULL,
    Longitude       FLOAT                           NOT NULL,
    Location        GEOGRAPHY                       NULL,
    Accuracy        FLOAT                           NULL,
    Speed           FLOAT                           NULL,
    Bearing         FLOAT                           NULL,
    RecordedAt      DATETIME2                       NOT NULL CONSTRAINT DF_DriverLocations_RecordedAt DEFAULT (SYSUTCDATETIME()),
    DeviceBattery   INT                             NULL,
    NetworkType     NVARCHAR(20)                    NULL,

    CONSTRAINT PK_myonline_tbl_DriverLocations PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT FK_myonline_tbl_DriverLocations_Users FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users (Id) ON DELETE CASCADE
);
CREATE NONCLUSTERED INDEX IX_myonline_tbl_DriverLocations_UserId_RecordedAt ON dbo.myonline_tbl_DriverLocations (UserId, RecordedAt DESC);
GO

-- Trigger: Keep Geography Column in sync
CREATE OR ALTER TRIGGER dbo.TRG_myonline_tbl_DriverLocations_SetLocation
ON dbo.myonline_tbl_DriverLocations
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE dl
        SET dl.Location = GEOGRAPHY::Point(i.Latitude, i.Longitude, 4326)
        FROM dbo.myonline_tbl_DriverLocations dl
        INNER JOIN inserted i ON i.Id = dl.Id;
    END TRY
    BEGIN CATCH
        -- Geography calculation fallback (silent)
    END CATCH
END
GO

-- 5. Attendance Records
CREATE TABLE dbo.myonline_tbl_Attendances
(
    Id                  BIGINT          IDENTITY(1,1)   NOT NULL,
    UserId              INT                             NOT NULL,
    Type                NVARCHAR(10)                    NOT NULL, -- 'In' or 'Out'
    Timestamp           DATETIME2                       NOT NULL CONSTRAINT DF_Attendances_Timestamp DEFAULT (SYSUTCDATETIME()),
    SelfieImagePath     NVARCHAR(400)                   NOT NULL,
    Latitude            FLOAT                           NOT NULL,
    Longitude           FLOAT                           NOT NULL,
    IsWithinGeofence    BIT                             NOT NULL CONSTRAINT DF_Attendances_IsWithinGeofence DEFAULT (0),
    Status              NVARCHAR(50)                    NULL CONSTRAINT DF_Attendances_Status DEFAULT ('On Time'),
    ShiftName           NVARCHAR(100)                   NULL CONSTRAINT DF_Attendances_ShiftName DEFAULT ('General Shift'),
    CreatedAt           DATETIME2                       NOT NULL CONSTRAINT DF_Attendances_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_myonline_tbl_Attendances PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT FK_myonline_tbl_Attendances_Users FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users (Id) ON DELETE CASCADE,
    CONSTRAINT CK_myonline_tbl_Attendances_Type CHECK (Type IN (N'In', N'Out'))
);
CREATE NONCLUSTERED INDEX IX_myonline_tbl_Attendances_UserId_Timestamp ON dbo.myonline_tbl_Attendances (UserId, Timestamp DESC);
GO

-- 6. Leave Types
CREATE TABLE dbo.myonline_tbl_LeaveTypes
(
    Id                  INT             IDENTITY(1,1)   NOT NULL,
    Name                NVARCHAR(100)                   NOT NULL,
    DefaultDaysPerYear  INT                             NOT NULL CONSTRAINT DF_LeaveTypes_DefaultDays DEFAULT (0),
    IsActive            BIT                             NOT NULL CONSTRAINT DF_LeaveTypes_IsActive DEFAULT (1),
    CreatedAt           DATETIME2                       NOT NULL CONSTRAINT DF_LeaveTypes_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_myonline_tbl_LeaveTypes PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT UQ_myonline_tbl_LeaveTypes_Name UNIQUE (Name)
);
GO

-- 7. Leave Balances
CREATE TABLE dbo.myonline_tbl_LeaveBalances
(
    Id              INT             IDENTITY(1,1)   NOT NULL,
    UserId          INT                             NOT NULL,
    LeaveTypeId     INT                             NOT NULL,
    Year            INT                             NOT NULL,
    TotalDays       INT                             NOT NULL,
    UsedDays        INT                             NOT NULL CONSTRAINT DF_LeaveBalances_UsedDays DEFAULT (0),

    CONSTRAINT PK_myonline_tbl_LeaveBalances PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT FK_myonline_tbl_LeaveBalances_Users FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users (Id) ON DELETE CASCADE,
    CONSTRAINT FK_myonline_tbl_LeaveBalances_LeaveTypes FOREIGN KEY (LeaveTypeId) REFERENCES dbo.myonline_tbl_LeaveTypes (Id),
    CONSTRAINT UQ_myonline_tbl_LeaveBalances_User_Type_Year UNIQUE (UserId, LeaveTypeId, Year)
);
GO

-- 8. Leave Applications
CREATE TABLE dbo.myonline_tbl_LeaveApplications
(
    Id              INT             IDENTITY(1,1)   NOT NULL,
    UserId          INT                             NOT NULL,
    LeaveTypeId     INT                             NOT NULL,
    StartDate       DATE                            NOT NULL,
    EndDate         DATE                            NOT NULL,
    TotalDays       INT                             NOT NULL CONSTRAINT DF_LeaveApps_TotalDays DEFAULT (1),
    Reason          NVARCHAR(500)                   NOT NULL,
    Status          NVARCHAR(20)                    NOT NULL CONSTRAINT DF_LeaveApps_Status DEFAULT (N'Pending'),
    AppliedAt       DATETIME2                       NOT NULL CONSTRAINT DF_LeaveApps_AppliedAt DEFAULT (SYSUTCDATETIME()),
    ReviewedBy      INT                             NULL,
    ReviewedAt      DATETIME2                       NULL,
    ReviewComment   NVARCHAR(500)                   NULL,

    CONSTRAINT PK_myonline_tbl_LeaveApplications PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT FK_myonline_tbl_LeaveApplications_Users FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users (Id) ON DELETE CASCADE,
    CONSTRAINT FK_myonline_tbl_LeaveApplications_LeaveTypes FOREIGN KEY (LeaveTypeId) REFERENCES dbo.myonline_tbl_LeaveTypes (Id),
    CONSTRAINT FK_myonline_tbl_LeaveApplications_ReviewedBy FOREIGN KEY (ReviewedBy) REFERENCES dbo.myonline_tbl_Users (Id),
    CONSTRAINT CK_myonline_tbl_LeaveApplications_Status CHECK (Status IN (N'Pending', N'Approved', N'Rejected', N'Cancelled')),
    CONSTRAINT CK_myonline_tbl_LeaveApplications_DateRange CHECK (EndDate >= StartDate)
);
CREATE NONCLUSTERED INDEX IX_myonline_tbl_LeaveApplications_UserId_Status ON dbo.myonline_tbl_LeaveApplications (UserId, Status);
GO

-- 9. Customers
CREATE TABLE dbo.myonline_tbl_Customers
(
    CustomerId      INT             IDENTITY(1,1)   NOT NULL,
    Name            NVARCHAR(150)                   NOT NULL,
    Mobile          NVARCHAR(30)                    NOT NULL,
    Address         NVARCHAR(300)                   NOT NULL,
    Latitude        FLOAT                           NOT NULL,
    Longitude       FLOAT                           NOT NULL,
    Remarks         NVARCHAR(500)                   NULL,
    CreatedDate     DATETIME2                       NOT NULL CONSTRAINT DF_Customers_CreatedDate DEFAULT (SYSUTCDATETIME()),
    IsActive        BIT                             NOT NULL CONSTRAINT DF_Customers_IsActive DEFAULT (1),
    CreatedByUserId INT                             NULL,

    CONSTRAINT PK_myonline_tbl_Customers PRIMARY KEY CLUSTERED (CustomerId ASC)
);
CREATE NONCLUSTERED INDEX IX_myonline_tbl_Customers_Name_Mobile ON dbo.myonline_tbl_Customers (Name, Mobile);
GO

-- 10. Customer Visits
CREATE TABLE dbo.myonline_tbl_CustomerVisits
(
    VisitId              BIGINT          IDENTITY(1,1)   NOT NULL,
    CustomerId           INT                             NOT NULL,
    UserId               INT                             NOT NULL,
    VisitDate            DATETIME2                       NOT NULL CONSTRAINT DF_CustomerVisits_VisitDate DEFAULT (SYSUTCDATETIME()),
    Latitude             FLOAT                           NOT NULL,
    Longitude            FLOAT                           NOT NULL,
    Remarks              NVARCHAR(500)                   NULL,
    VisitStatus          NVARCHAR(50)                    NOT NULL CONSTRAINT DF_CustomerVisits_Status DEFAULT (N'Completed'),
    NextFollowUpDate     DATETIME2                       NULL,
    ShopPhotoPath        NVARCHAR(400)                   NULL,
    IsFollowUpCompleted  BIT                             NOT NULL CONSTRAINT DF_CustomerVisits_IsFollowUpCompleted DEFAULT (0),

    CONSTRAINT PK_myonline_tbl_CustomerVisits PRIMARY KEY CLUSTERED (VisitId ASC),
    CONSTRAINT FK_myonline_tbl_CustomerVisits_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.myonline_tbl_Customers (CustomerId) ON DELETE CASCADE,
    CONSTRAINT FK_myonline_tbl_CustomerVisits_Users FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users (Id)
);
CREATE NONCLUSTERED INDEX IX_myonline_tbl_CustomerVisits_UserId_VisitDate ON dbo.myonline_tbl_CustomerVisits (UserId, VisitDate DESC);
CREATE NONCLUSTERED INDEX IX_myonline_tbl_CustomerVisits_NextFollowUpDate ON dbo.myonline_tbl_CustomerVisits (NextFollowUpDate);
GO

-- 11. Holidays (2026 Calendar & Company Holidays)
CREATE TABLE dbo.myonline_tbl_Holidays
(
    HolidayId       INT             IDENTITY(1,1)   NOT NULL,
    Name            NVARCHAR(150)                   NOT NULL,
    Date            DATETIME2                       NOT NULL,
    Year            INT                             NOT NULL,
    IsRecurring     BIT                             NOT NULL CONSTRAINT DF_Holidays_IsRecurring DEFAULT (0),
    IsActive        BIT                             NOT NULL CONSTRAINT DF_Holidays_IsActive DEFAULT (1),
    Description     NVARCHAR(250)                   NULL,

    CONSTRAINT PK_myonline_tbl_Holidays PRIMARY KEY CLUSTERED (HolidayId ASC)
);
GO

-- 12. App Version Management
CREATE TABLE dbo.myonline_tbl_AppVersions
(
    Id              INT             IDENTITY(1,1)   NOT NULL,
    Platform        NVARCHAR(30)                    NOT NULL CONSTRAINT DF_AppVersions_Platform DEFAULT ('Android'),
    VersionCode     INT                             NOT NULL,
    VersionName     NVARCHAR(50)                    NOT NULL,
    MinVersionCode  INT                             NOT NULL CONSTRAINT DF_AppVersions_MinVersionCode DEFAULT (1),
    IsForceUpdate   BIT                             NOT NULL CONSTRAINT DF_AppVersions_IsForceUpdate DEFAULT (0),
    DownloadUrl     NVARCHAR(1000)                  NOT NULL,
    Title           NVARCHAR(200)                   NOT NULL CONSTRAINT DF_AppVersions_Title DEFAULT ('New Update Available'),
    ReleaseNotes    NVARCHAR(MAX)                   NULL,
    IsActive        BIT                             NOT NULL CONSTRAINT DF_AppVersions_IsActive DEFAULT (1),
    CreatedAt       DATETIME2                       NOT NULL CONSTRAINT DF_AppVersions_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_myonline_tbl_AppVersions PRIMARY KEY CLUSTERED (Id ASC)
);
CREATE NONCLUSTERED INDEX IX_AppVersions_Platform_Active_Code ON dbo.myonline_tbl_AppVersions(Platform, IsActive, VersionCode);
GO

-- 13. In-App Notifications
CREATE TABLE dbo.myonline_tbl_Notifications
(
    Id              INT             IDENTITY(1,1)   NOT NULL,
    UserId          INT                             NULL, -- NULL for Broadcast
    TargetRole      NVARCHAR(20)                    NOT NULL CONSTRAINT DF_Notifications_TargetRole DEFAULT ('All'),
    Title           NVARCHAR(200)                   NOT NULL,
    Message         NVARCHAR(1000)                  NOT NULL,
    Type            NVARCHAR(50)                    NOT NULL CONSTRAINT DF_Notifications_Type DEFAULT ('General'),
    ReferenceId     NVARCHAR(100)                   NULL,
    IsRead          BIT                             NOT NULL CONSTRAINT DF_Notifications_IsRead DEFAULT (0),
    CreatedAt       DATETIME2                       NOT NULL CONSTRAINT DF_Notifications_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_myonline_tbl_Notifications PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT FK_Notifications_Users FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users(Id) ON DELETE SET NULL
);
CREATE NONCLUSTERED INDEX IX_Notifications_User_Read_Created ON dbo.myonline_tbl_Notifications(UserId, IsRead, CreatedAt DESC);
CREATE NONCLUSTERED INDEX IX_Notifications_TargetRole_Created ON dbo.myonline_tbl_Notifications(TargetRole, CreatedAt DESC);
GO

/* ============================================================
   STEP 3: SEED ESSENTIAL PRODUCTION DATA
   ============================================================ */

-- 3.1 Default Office Location (HQ)
INSERT INTO dbo.myonline_tbl_OfficeLocations (Name, Latitude, Longitude, RadiusMeters, IsActive)
VALUES (N'Headquarters', 23.8103, 90.4125, 200, 1);
GO

-- 3.2 Default General Shift (09:00 AM - 06:00 PM)
INSERT INTO dbo.myonline_tbl_Shifts (ShiftName, StartTime, EndTime, GracePeriodMinutes, IsDefault, IsActive, CreatedAtUtc)
VALUES (N'General Shift', '09:00:00', '18:00:00', 15, 1, 1, SYSUTCDATETIME());
GO

-- 3.3 Admin Users
-- BCrypt password hash for "Admin@123": $2a$11$3euPcmQFCiblsZeEu5s7p.9wVsZeS/AoEg1UZ9YEfKgOK5Xy8oXpu
INSERT INTO dbo.myonline_tbl_Users 
(Name, Username, PasswordHash, Role, PhoneNumber, IsActive, OfficeLocationId, ShiftId, MaxUserLimit, PaymentDueDate)
VALUES
(N'System Administrator', N'admin', N'$2a$11$3euPcmQFCiblsZeEu5s7p.9wVsZeS/AoEg1UZ9YEfKgOK5Xy8oXpu', N'Admin', N'01700000001', 1, 1, 1, 100, DATEADD(YEAR, 1, SYSUTCDATETIME())),
(N'Moxx Admin', N'moxxadmin', N'$2a$11$3euPcmQFCiblsZeEu5s7p.9wVsZeS/AoEg1UZ9YEfKgOK5Xy8oXpu', N'Admin', N'01700000002', 1, 1, 1, 50, DATEADD(YEAR, 1, SYSUTCDATETIME())),
(N'Moxx Admin 2', N'moxxadmin2', N'$2a$11$3euPcmQFCiblsZeEu5s7p.9wVsZeS/AoEg1UZ9YEfKgOK5Xy8oXpu', N'Admin', N'01700000003', 1, 1, 1, 50, DATEADD(YEAR, 1, SYSUTCDATETIME()));
GO

-- 3.4 Leave Types
INSERT INTO dbo.myonline_tbl_LeaveTypes (Name, DefaultDaysPerYear, IsActive)
VALUES 
(N'Casual Leave', 14, 1),
(N'Sick Leave', 14, 1),
(N'Earned Leave', 10, 1);
GO

-- 3.5 Bangladesh Official Govt Holidays 2026
INSERT INTO dbo.myonline_tbl_Holidays (Name, Date, Year, IsRecurring, IsActive, Description)
VALUES 
(N'International Mother Language Day', '2026-02-21', 2026, 1, 1, N'National Holiday'),
(N'Shab-e-Barat', '2026-03-20', 2026, 0, 1, N'Religious Holiday'),
(N'Independence Day', '2026-03-26', 2026, 1, 1, N'National Holiday'),
(N'Eid-ul-Fitr Holiday', '2026-03-29', 2026, 0, 1, N'Public Holiday'),
(N'Eid-ul-Fitr', '2026-03-30', 2026, 0, 1, N'Public Holiday'),
(N'Eid-ul-Fitr Holiday', '2026-03-31', 2026, 0, 1, N'Public Holiday'),
(N'Pahela Baishakh', '2026-04-14', 2026, 1, 1, N'Bengali New Year'),
(N'May Day', '2026-05-01', 2026, 1, 1, N'International Workers Day'),
(N'Buddha Purnima', '2026-05-31', 2026, 0, 1, N'Religious Holiday'),
(N'Eid-ul-Adha Holiday', '2026-06-06', 2026, 0, 1, N'Public Holiday'),
(N'Eid-ul-Adha', '2026-06-07', 2026, 0, 1, N'Public Holiday'),
(N'Eid-ul-Adha Holiday', '2026-06-08', 2026, 0, 1, N'Public Holiday'),
(N'Ashura', '2026-07-06', 2026, 0, 1, N'Religious Holiday'),
(N'National Mourning Day', '2026-08-15', 2026, 1, 1, N'National Holiday'),
(N'Janmashtami', '2026-08-25', 2026, 0, 1, N'Religious Holiday'),
(N'Eid-e-Miladunnabi', '2026-09-04', 2026, 0, 1, N'Religious Holiday'),
(N'Durga Puja', '2026-10-20', 2026, 0, 1, N'Religious Holiday'),
(N'Victory Day', '2026-12-16', 2026, 1, 1, N'National Holiday'),
(N'Christmas Day', '2026-12-25', 2026, 1, 1, N'Religious Holiday');
GO

-- 3.6 Default App Version Entry
INSERT INTO dbo.myonline_tbl_AppVersions 
(Platform, VersionCode, VersionName, MinVersionCode, IsForceUpdate, DownloadUrl, Title, ReleaseNotes, IsActive)
VALUES 
(N'Android', 1, N'1.0', 1, 0, N'http://104.215.157.203:120/downloads/app-release.apk', N'Welcome to Live Tracking v1.0', N'Initial release with live tracking, attendance with selfie, shifts and visits.', 1);
GO

/* ============================================================
   STEP 4: CREATE ALL PRODUCTION STORED PROCEDURES
   ============================================================ */

-- 4.1 Customer List
CREATE OR ALTER PROCEDURE dbo.sp_GetCustomerList
    @Search     NVARCHAR(150) = NULL,
    @ActiveOnly BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');

    WITH LastVisits AS
    (
        SELECT CustomerId, MAX(VisitDate) AS LastVisitDate
        FROM dbo.myonline_tbl_CustomerVisits
        GROUP BY CustomerId
    ),
    NextFollowUps AS
    (
        SELECT CustomerId, MIN(NextFollowUpDate) AS NextFollowUpDate
        FROM dbo.myonline_tbl_CustomerVisits
        WHERE NextFollowUpDate IS NOT NULL AND IsFollowUpCompleted = 0
        GROUP BY CustomerId
    )
    SELECT 
        c.CustomerId, c.Name, c.Mobile, c.Address, c.Latitude, c.Longitude, c.Remarks, c.CreatedDate, c.IsActive,
        lv.LastVisitDate, nfu.NextFollowUpDate
    FROM dbo.myonline_tbl_Customers c
    LEFT JOIN LastVisits lv ON lv.CustomerId = c.CustomerId
    LEFT JOIN NextFollowUps nfu ON nfu.CustomerId = c.CustomerId
    WHERE (@ActiveOnly = 0 OR c.IsActive = 1)
      AND (@Search IS NULL OR c.Name LIKE '%' + @Search + '%' OR c.Mobile LIKE '%' + @Search + '%' OR c.Address LIKE '%' + @Search + '%')
    ORDER BY c.CreatedDate DESC;
END
GO

-- 4.2 Customer By Id
CREATE OR ALTER PROCEDURE dbo.sp_GetCustomerById
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.CustomerId, c.Name, c.Mobile, c.Address, c.Latitude, c.Longitude, c.Remarks, c.CreatedDate, c.IsActive,
        (SELECT MAX(VisitDate) FROM dbo.myonline_tbl_CustomerVisits WHERE CustomerId = c.CustomerId) AS LastVisitDate,
        (SELECT MIN(NextFollowUpDate) FROM dbo.myonline_tbl_CustomerVisits WHERE CustomerId = c.CustomerId AND NextFollowUpDate IS NOT NULL AND IsFollowUpCompleted = 0) AS NextFollowUpDate
    FROM dbo.myonline_tbl_Customers c
    WHERE c.CustomerId = @CustomerId;
END
GO

-- 4.3 Create Customer
CREATE OR ALTER PROCEDURE dbo.sp_CreateCustomer
    @Name            NVARCHAR(150),
    @Mobile          NVARCHAR(30),
    @Address         NVARCHAR(300),
    @Latitude        FLOAT,
    @Longitude       FLOAT,
    @Remarks         NVARCHAR(500) = NULL,
    @CreatedByUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.myonline_tbl_Customers (Name, Mobile, Address, Latitude, Longitude, Remarks, CreatedDate, IsActive, CreatedByUserId)
    VALUES (RTRIM(@Name), RTRIM(@Mobile), RTRIM(@Address), @Latitude, @Longitude, RTRIM(@Remarks), SYSUTCDATETIME(), 1, @CreatedByUserId);

    DECLARE @NewCustomerId INT = SCOPE_IDENTITY();
    EXEC dbo.sp_GetCustomerById @CustomerId = @NewCustomerId;
END
GO

-- 4.4 Get Customer Visits
CREATE OR ALTER PROCEDURE dbo.sp_GetCustomerVisits
    @CustomerId INT = NULL,
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        v.VisitId, v.CustomerId, c.Name AS CustomerName, v.UserId, u.Name AS UserName,
        v.VisitDate, v.Latitude, v.Longitude, v.Remarks, v.VisitStatus, v.NextFollowUpDate, v.ShopPhotoPath, v.IsFollowUpCompleted
    FROM dbo.myonline_tbl_CustomerVisits v
    INNER JOIN dbo.myonline_tbl_Customers c ON c.CustomerId = v.CustomerId
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = v.UserId
    WHERE (@CustomerId IS NULL OR v.CustomerId = @CustomerId)
      AND (@UserId IS NULL OR v.UserId = @UserId)
    ORDER BY v.VisitDate DESC;
END
GO

-- 4.5 Record Customer Visit
CREATE OR ALTER PROCEDURE dbo.sp_RecordCustomerVisit
    @CustomerId       INT,
    @UserId           INT,
    @Latitude         FLOAT,
    @Longitude        FLOAT,
    @Remarks          NVARCHAR(500) = NULL,
    @VisitStatus      NVARCHAR(50) = N'Completed',
    @NextFollowUpDate DATETIME2 = NULL,
    @ShopPhotoPath    NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.myonline_tbl_CustomerVisits 
    (CustomerId, UserId, VisitDate, Latitude, Longitude, Remarks, VisitStatus, NextFollowUpDate, ShopPhotoPath, IsFollowUpCompleted)
    VALUES 
    (@CustomerId, @UserId, SYSUTCDATETIME(), @Latitude, @Longitude, RTRIM(@Remarks), @VisitStatus, @NextFollowUpDate, @ShopPhotoPath, 0);

    SELECT SCOPE_IDENTITY() AS VisitId;
END
GO

-- 4.6 Insert GPS Location Ping
CREATE OR ALTER PROCEDURE dbo.sp_InsertLocationPing
    @UserId         INT,
    @Latitude       FLOAT,
    @Longitude      FLOAT,
    @Accuracy       FLOAT = NULL,
    @Speed          FLOAT = NULL,
    @Bearing        FLOAT = NULL,
    @RecordedAt     DATETIME2 = NULL,
    @DeviceBattery   INT = NULL,
    @NetworkType     NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @RecordedAt IS NULL SET @RecordedAt = SYSUTCDATETIME();

    INSERT INTO dbo.myonline_tbl_DriverLocations 
    (UserId, Latitude, Longitude, Accuracy, Speed, Bearing, RecordedAt, DeviceBattery, NetworkType)
    VALUES 
    (@UserId, @Latitude, @Longitude, @Accuracy, @Speed, @Bearing, @RecordedAt, @DeviceBattery, @NetworkType);

    SELECT SCOPE_IDENTITY() AS LocationId;
END
GO

-- 4.7 Get Latest Location Per User
CREATE OR ALTER PROCEDURE dbo.sp_GetLatestLocationPerUser
AS
BEGIN
    SET NOCOUNT ON;
    WITH LatestPing AS
    (
        SELECT dl.*, ROW_NUMBER() OVER (PARTITION BY dl.UserId ORDER BY dl.RecordedAt DESC) AS rn
        FROM dbo.myonline_tbl_DriverLocations dl
    )
    SELECT 
        u.Id AS UserId, u.Username, u.Name AS FullName, u.Role, u.IsActive,
        lp.Latitude, lp.Longitude, lp.Accuracy, lp.Speed, lp.Bearing, lp.RecordedAt, lp.DeviceBattery, lp.NetworkType
    FROM dbo.myonline_tbl_Users u
    LEFT JOIN LatestPing lp ON lp.UserId = u.Id AND lp.rn = 1
    WHERE u.Role = N'User';
END
GO

-- 4.8 Get Latest Location By Single User Id
CREATE OR ALTER PROCEDURE dbo.sp_GetLatestLocationByUserId
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (1) 
        Id AS LocationId, UserId, Latitude, Longitude, Accuracy, Speed, Bearing, RecordedAt, DeviceBattery, NetworkType
    FROM dbo.myonline_tbl_DriverLocations
    WHERE UserId = @UserId
    ORDER BY RecordedAt DESC;
END
GO

-- 4.9 Driver Route History (For Drawing Route Polyline on Map)
CREATE OR ALTER PROCEDURE dbo.sp_GetDriverRouteHistory
    @UserId   INT,
    @FromDate DATETIME2,
    @ToDate   DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        u.Id AS UserId, u.Username, u.Name AS FullName, u.IsActive,
        dl.Latitude, dl.Longitude, dl.Accuracy, dl.Speed, dl.Bearing, dl.RecordedAt AS RecordedAtUtc
    FROM dbo.myonline_tbl_DriverLocations dl
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = dl.UserId
    WHERE dl.UserId = @UserId
      AND dl.RecordedAt >= @FromDate
      AND dl.RecordedAt < @ToDate
    ORDER BY dl.RecordedAt ASC;
END
GO

-- 4.10 Attendance History
CREATE OR ALTER PROCEDURE dbo.sp_GetAttendanceHistory
    @UserId   INT = NULL,
    @FromDate DATETIME2 = NULL,
    @ToDate   DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        a.Id AS AttendanceId, a.UserId, u.Name AS UserName, a.Type, a.Timestamp,
        a.Latitude, a.Longitude, a.IsWithinGeofence, a.SelfieImagePath AS SelfieUrl, a.Status, a.ShiftName
    FROM dbo.myonline_tbl_Attendances a
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = a.UserId
    WHERE (@UserId IS NULL OR a.UserId = @UserId)
      AND (@FromDate IS NULL OR a.Timestamp >= @FromDate)
      AND (@ToDate IS NULL OR a.Timestamp <= @ToDate)
    ORDER BY a.Timestamp DESC;
END
GO

-- 4.11 Attendance Report Filtered By Month/Year
CREATE OR ALTER PROCEDURE dbo.sp_GetAttendanceReportByMonthYear
    @UserId     INT = NULL,
    @AdminId    INT = NULL,
    @Month      INT = NULL,
    @Year       INT = NULL,
    @FromDate   DATETIME2 = NULL,
    @ToDate     DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        a.Id AS AttendanceId,
        a.UserId,
        u.Name AS FullName,
        u.Username,
        u.Role,
        u.PhoneNumber,
        a.Type,
        a.Timestamp AS RecordedAtUtc,
        a.Latitude,
        a.Longitude,
        a.IsWithinGeofence,
        a.SelfieImagePath AS SelfieUrl,
        a.Status,
        a.ShiftName
    FROM dbo.myonline_tbl_Attendances a
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = a.UserId
    WHERE 
        (@UserId IS NULL OR a.UserId = @UserId)
        AND (@AdminId IS NULL OR u.CreatedByAdminId = @AdminId OR u.Id = @AdminId)
        AND (@Year IS NULL OR YEAR(a.Timestamp) = @Year)
        AND (@Month IS NULL OR MONTH(a.Timestamp) = @Month)
        AND (@FromDate IS NULL OR a.Timestamp >= @FromDate)
        AND (@ToDate IS NULL OR a.Timestamp <= @ToDate)
    ORDER BY a.Timestamp DESC;
END
GO

-- 4.12 Monthly Attendance Summary Stats
CREATE OR ALTER PROCEDURE dbo.sp_GetMonthlyAttendanceSummary
    @UserId     INT = NULL,
    @Month      INT = NULL,
    @Year       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        u.Id AS UserId,
        u.Name AS FullName,
        u.Username,
        ISNULL(@Year, YEAR(SYSUTCDATETIME())) AS ReportYear,
        ISNULL(@Month, MONTH(SYSUTCDATETIME())) AS ReportMonth,
        COUNT(CASE WHEN a.Type = 'In' THEN 1 END) AS TotalDutyIn,
        COUNT(CASE WHEN a.Type = 'Out' THEN 1 END) AS TotalDutyOut,
        COUNT(DISTINCT CAST(a.Timestamp AS DATE)) AS TotalWorkingDays,
        COUNT(CASE WHEN a.IsWithinGeofence = 1 THEN 1 END) AS TotalWithinOffice,
        COUNT(CASE WHEN a.IsWithinGeofence = 0 THEN 1 END) AS TotalOutsideOffice
    FROM dbo.myonline_tbl_Users u
    LEFT JOIN dbo.myonline_tbl_Attendances a ON a.UserId = u.Id
        AND (@Year IS NULL OR YEAR(a.Timestamp) = @Year)
        AND (@Month IS NULL OR MONTH(a.Timestamp) = @Month)
    WHERE (@UserId IS NULL OR u.Id = @UserId)
    GROUP BY u.Id, u.Name, u.Username;
END
GO

-- 4.13 Leave Applications List
CREATE OR ALTER PROCEDURE dbo.sp_GetLeaveApplications
    @UserId INT = NULL,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        la.Id AS LeaveApplicationId, la.UserId, u.Name AS UserName, la.LeaveTypeId, lt.Name AS LeaveTypeName,
        la.StartDate, la.EndDate, la.TotalDays, la.Reason, la.Status, la.AppliedAt, la.ReviewedAt, la.ReviewComment
    FROM dbo.myonline_tbl_LeaveApplications la
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = la.UserId
    INNER JOIN dbo.myonline_tbl_LeaveTypes lt ON lt.Id = la.LeaveTypeId
    WHERE (@UserId IS NULL OR la.UserId = @UserId)
      AND (@Status IS NULL OR la.Status = @Status)
    ORDER BY la.AppliedAt DESC;
END
GO

-- 4.14 All Users List
CREATE OR ALTER PROCEDURE dbo.sp_GetAllUsers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        u.Id AS UserId, u.Name AS FullName, u.Username, u.Role, u.PhoneNumber, u.IsActive, 
        u.CreatedAt, u.OfficeLocationId, u.ShiftId, u.MaxUserLimit, u.BoundDeviceId, u.DeviceModel, u.PaymentDueDate
    FROM dbo.myonline_tbl_Users u
    ORDER BY u.Name ASC;
END
GO

-- 4.15 Executive Dashboard Summary
CREATE OR ALTER PROCEDURE dbo.sp_GetExecutiveDashboardSummary
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TodayStart DATETIME2 = CAST(SYSUTCDATETIME() AS DATE);
    DECLARE @TodayEnd DATETIME2 = DATEADD(DAY, 1, @TodayStart);
    DECLARE @Cutoff15m DATETIME2 = DATEADD(MINUTE, -15, SYSUTCDATETIME());

    SELECT
        (SELECT COUNT(*) FROM dbo.myonline_tbl_Users WHERE Role = N'User') AS TotalUsers,
        (SELECT COUNT(*) FROM dbo.myonline_tbl_Users WHERE Role = N'User' AND IsActive = 1) AS ActiveUsers,
        (SELECT COUNT(DISTINCT UserId) FROM dbo.myonline_tbl_DriverLocations WHERE RecordedAt >= @Cutoff15m) AS OnlineTrackingUsers,
        (SELECT COUNT(DISTINCT UserId) FROM dbo.myonline_tbl_Attendances WHERE Type = N'In' AND Timestamp >= @TodayStart AND Timestamp < @TodayEnd) AS TodayPunchInCount,
        (SELECT COUNT(*) FROM dbo.myonline_tbl_LeaveApplications WHERE Status = N'Pending') AS PendingLeaveRequestsCount,
        (SELECT COUNT(*) FROM dbo.myonline_tbl_CustomerVisits WHERE NextFollowUpDate IS NOT NULL AND IsFollowUpCompleted = 0) AS PendingCustomerFollowUpsCount,
        (SELECT COUNT(*) FROM dbo.myonline_tbl_Customers WHERE IsActive = 1) AS TotalActiveCustomers;
END
GO

-- 4.16 Subscription Status SP (Called by SubscriptionController & Background Reminders)
CREATE OR ALTER PROCEDURE dbo.sp_GetSubscriptionStatus
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AdminId INT = @UserId;
    DECLARE @UserRole NVARCHAR(20);
    
    SELECT @UserRole = Role, @AdminId = ISNULL(CreatedByAdminId, @UserId)
    FROM dbo.myonline_tbl_Users
    WHERE Id = @UserId;

    IF @UserRole = N'Admin'
        SET @AdminId = @UserId;

    SELECT TOP (1)
        u.Id AS AdminId,
        u.Name AS AdminName,
        u.Username AS AdminUsername,
        u.PhoneNumber AS AdminPhone,
        u.PaymentDueDate,
        ISNULL(DATEDIFF(DAY, CAST(SYSUTCDATETIME() AS DATE), CAST(ISNULL(u.PaymentDueDate, DATEADD(DAY, 30, SYSUTCDATETIME())) AS DATE)), 30) AS DaysRemaining,
        CASE WHEN u.PaymentDueDate IS NOT NULL AND u.PaymentDueDate < SYSUTCDATETIME() THEN 1 ELSE 0 END AS IsExpired,
        CASE 
            WHEN u.PaymentDueDate IS NOT NULL 
                 AND DATEDIFF(DAY, CAST(SYSUTCDATETIME() AS DATE), CAST(u.PaymentDueDate AS DATE)) <= 7 
                 AND u.PaymentDueDate >= SYSUTCDATETIME() THEN 1 
            ELSE 0 
        END AS IsWarningPeriod
    FROM dbo.myonline_tbl_Users u
    WHERE u.Id = @AdminId;
END
GO

-- 4.17 Update Payment Due Date SP
CREATE OR ALTER PROCEDURE dbo.sp_UpdatePaymentDueDate
    @AdminId INT,
    @NewDueDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.myonline_tbl_Users
    SET PaymentDueDate = @NewDueDate
    WHERE Id = @AdminId AND Role = N'Admin';

    EXEC dbo.sp_GetSubscriptionStatus @UserId = @AdminId;
END
GO

PRINT '======================================================';
PRINT 'LiveTrackingDB Fresh Install Completed Successfully!';
PRINT '3 Admins Seeded: admin, moxxadmin, moxxadmin2 (Pass: Admin@123)';
PRINT 'Default Office HQ, Shift, Holidays, and SPs Created.';
PRINT '======================================================';
