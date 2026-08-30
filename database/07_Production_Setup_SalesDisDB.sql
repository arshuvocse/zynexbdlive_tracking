-- ============================================================
-- Production Database Setup Script for Live Tracking System
-- Database: SalesDisDB_Unicorn_DB_bak
-- Server: E-ProgramDBAPP\MSSQLSERVER2019
-- ============================================================

USE SalesDisDB_Unicorn_DB_bak;
GO

-- 1. Office Locations Table
IF OBJECT_ID(N'dbo.myonline_tbl_OfficeLocations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_OfficeLocations
    (
        Id              INT             IDENTITY(1,1)   NOT NULL,
        Name            NVARCHAR(150)                   NOT NULL,
        Latitude        FLOAT                           NOT NULL,
        Longitude       FLOAT                           NOT NULL,
        RadiusMeters    FLOAT                           NOT NULL CONSTRAINT DF_myonline_tbl_OfficeLocations_Radius DEFAULT (200),
        IsActive        BIT                             NOT NULL CONSTRAINT DF_myonline_tbl_OfficeLocations_IsActive DEFAULT (1),
        CreatedAt       DATETIME2                       NOT NULL CONSTRAINT DF_myonline_tbl_OfficeLocations_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_myonline_tbl_OfficeLocations PRIMARY KEY CLUSTERED (Id ASC)
    );
    PRINT 'myonline_tbl_OfficeLocations created.';
END
GO

-- 2. Users Table
IF OBJECT_ID(N'dbo.myonline_tbl_Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_Users
    (
        Id              INT             IDENTITY(1,1)   NOT NULL,
        Name            NVARCHAR(150)                   NOT NULL,
        Username        NVARCHAR(100)                   NOT NULL,
        PasswordHash    NVARCHAR(300)                   NOT NULL,
        Role            NVARCHAR(20)                    NOT NULL CONSTRAINT DF_myonline_tbl_Users_Role DEFAULT ('User'),
        CreatedAt       DATETIME2                       NOT NULL CONSTRAINT DF_myonline_tbl_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
        IsActive        BIT                             NOT NULL CONSTRAINT DF_myonline_tbl_Users_IsActive DEFAULT (1),
        OfficeLocationId INT                            NULL,
        PhoneNumber     NVARCHAR(20)                    NULL,
        CreatedByAdminId INT                            NULL,
        CONSTRAINT PK_myonline_tbl_Users PRIMARY KEY CLUSTERED (Id ASC),
        CONSTRAINT UQ_myonline_tbl_Users_Username UNIQUE (Username),
        CONSTRAINT CK_myonline_tbl_Users_Role CHECK (Role IN (N'Admin', N'User')),
        CONSTRAINT FK_myonline_tbl_Users_OfficeLocations FOREIGN KEY (OfficeLocationId) REFERENCES dbo.myonline_tbl_OfficeLocations (Id)
    );
    PRINT 'myonline_tbl_Users created.';
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') AND name = N'PhoneNumber')
        ALTER TABLE dbo.myonline_tbl_Users ADD PhoneNumber NVARCHAR(20) NULL;
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') AND name = N'CreatedByAdminId')
        ALTER TABLE dbo.myonline_tbl_Users ADD CreatedByAdminId INT NULL;
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') AND name = N'OfficeLocationId')
        ALTER TABLE dbo.myonline_tbl_Users ADD OfficeLocationId INT NULL;
    PRINT 'myonline_tbl_Users columns verified/updated.';
END
GO

-- 3. Customers Table
IF OBJECT_ID(N'dbo.myonline_tbl_Customers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_Customers
    (
        CustomerId      INT             IDENTITY(1,1)   NOT NULL,
        Name            NVARCHAR(200)                   NOT NULL,
        Mobile          NVARCHAR(50)                    NOT NULL,
        Address         NVARCHAR(500)                   NOT NULL,
        Latitude        FLOAT                           NOT NULL,
        Longitude       FLOAT                           NOT NULL,
        Remarks         NVARCHAR(500)                   NULL,
        CreatedDate     DATETIME2                       NOT NULL CONSTRAINT DF_myonline_tbl_Customers_CreatedDate DEFAULT (SYSUTCDATETIME()),
        IsActive        BIT                             NOT NULL CONSTRAINT DF_myonline_tbl_Customers_IsActive DEFAULT (1),
        CreatedByUserId INT                             NULL,
        CONSTRAINT PK_myonline_tbl_Customers PRIMARY KEY CLUSTERED (CustomerId ASC)
    );
    PRINT 'myonline_tbl_Customers created.';
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Customers') AND name = N'CreatedByUserId')
        ALTER TABLE dbo.myonline_tbl_Customers ADD CreatedByUserId INT NULL;
    PRINT 'myonline_tbl_Customers columns verified.';
END
GO

-- 4. Customer Visits Table
IF OBJECT_ID(N'dbo.myonline_tbl_CustomerVisits', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_CustomerVisits
    (
        VisitId         BIGINT          IDENTITY(1,1)   NOT NULL,
        CustomerId      INT                             NOT NULL,
        UserId          INT                             NOT NULL,
        VisitDate       DATETIME2                       NOT NULL CONSTRAINT DF_myonline_tbl_CustomerVisits_VisitDate DEFAULT (SYSUTCDATETIME()),
        Latitude        FLOAT                           NOT NULL,
        Longitude       FLOAT                           NOT NULL,
        Remarks         NVARCHAR(1000)                  NULL,
        VisitStatus     NVARCHAR(50)                    NOT NULL CONSTRAINT DF_myonline_tbl_CustomerVisits_Status DEFAULT ('Completed'),
        NextFollowUpDate DATETIME2                      NULL,
        ShopPhotoPath   NVARCHAR(500)                   NULL,
        IsFollowUpCompleted BIT                         NOT NULL CONSTRAINT DF_myonline_tbl_CustomerVisits_FollowUpCompleted DEFAULT (0),
        CONSTRAINT PK_myonline_tbl_CustomerVisits PRIMARY KEY CLUSTERED (VisitId ASC),
        CONSTRAINT FK_myonline_tbl_CustomerVisits_Customer FOREIGN KEY (CustomerId) REFERENCES dbo.myonline_tbl_Customers (CustomerId),
        CONSTRAINT FK_myonline_tbl_CustomerVisits_User FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users (Id)
    );
    PRINT 'myonline_tbl_CustomerVisits created.';
END
GO

-- 5. Attendance Records Table
IF OBJECT_ID(N'dbo.myonline_tbl_Attendances', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_Attendances
    (
        AttendanceId    BIGINT          IDENTITY(1,1)   NOT NULL,
        UserId          INT                             NOT NULL,
        Type            NVARCHAR(10)                    NOT NULL, -- 'In' or 'Out'
        Latitude        FLOAT                           NOT NULL,
        Longitude       FLOAT                           NOT NULL,
        SelfiePath      NVARCHAR(500)                   NULL,
        IsWithinGeofence BIT                            NOT NULL CONSTRAINT DF_myonline_tbl_Attendances_Geofence DEFAULT (0),
        CreatedAt       DATETIME2                       NOT NULL CONSTRAINT DF_myonline_tbl_Attendances_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_myonline_tbl_Attendances PRIMARY KEY CLUSTERED (AttendanceId ASC),
        CONSTRAINT CK_myonline_tbl_Attendances_Type CHECK (Type IN (N'In', N'Out')),
        CONSTRAINT FK_myonline_tbl_Attendances_User FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users (Id)
    );
    PRINT 'myonline_tbl_Attendances created.';
END
GO

-- 6. Location Histories Table (Live GPS Tracking)
IF OBJECT_ID(N'dbo.myonline_tbl_DriverLocations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_DriverLocations
    (
        Id              BIGINT          IDENTITY(1,1)   NOT NULL,
        UserId          INT                             NOT NULL,
        Latitude        FLOAT                           NOT NULL,
        Longitude       FLOAT                           NOT NULL,
        SpeedKmh        FLOAT                           NULL,
        HeadingDegrees  FLOAT                           NULL,
        RecordedAtUtc   DATETIME2                       NOT NULL CONSTRAINT DF_myonline_tbl_DriverLocations_RecordedAt DEFAULT (SYSUTCDATETIME()),
        ReceivedAtUtc   DATETIME2                       NOT NULL CONSTRAINT DF_myonline_tbl_DriverLocations_ReceivedAt DEFAULT (SYSUTCDATETIME()),
        BatteryPercent  INT                             NULL,
        IsCharging      BIT                             NULL,
        AccuracyMeters  FLOAT                           NULL,
        CONSTRAINT PK_myonline_tbl_DriverLocations PRIMARY KEY CLUSTERED (Id ASC),
        CONSTRAINT FK_myonline_tbl_DriverLocations_User FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users (Id)
    );
    CREATE NONCLUSTERED INDEX IX_myonline_tbl_DriverLocations_UserId_RecordedAtUtc
        ON dbo.myonline_tbl_DriverLocations (UserId ASC, RecordedAtUtc DESC);
    PRINT 'myonline_tbl_DriverLocations created.';
END
GO

-- 7. Leave Management Tables
IF OBJECT_ID(N'dbo.myonline_tbl_LeaveTypes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_LeaveTypes
    (
        LeaveTypeId     INT             IDENTITY(1,1)   NOT NULL,
        Name            NVARCHAR(50)                    NOT NULL,
        DefaultAnnualQuota INT                          NOT NULL CONSTRAINT DF_myonline_tbl_LeaveTypes_Quota DEFAULT (14),
        IsPaid          BIT                             NOT NULL CONSTRAINT DF_myonline_tbl_LeaveTypes_IsPaid DEFAULT (1),
        CONSTRAINT PK_myonline_tbl_LeaveTypes PRIMARY KEY CLUSTERED (LeaveTypeId ASC)
    );
    INSERT INTO dbo.myonline_tbl_LeaveTypes (Name, DefaultAnnualQuota, IsPaid) VALUES 
        (N'Casual Leave', 14, 1),
        (N'Sick Leave', 14, 1),
        (N'Annual Leave', 15, 1);
    PRINT 'myonline_tbl_LeaveTypes created with default seed.';
END
GO

IF OBJECT_ID(N'dbo.myonline_tbl_LeaveApplications', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_LeaveApplications
    (
        ApplicationId   BIGINT          IDENTITY(1,1)   NOT NULL,
        UserId          INT                             NOT NULL,
        LeaveTypeId     INT                             NOT NULL,
        StartDate       DATE                            NOT NULL,
        EndDate         DATE                            NOT NULL,
        Reason          NVARCHAR(500)                   NULL,
        Status          NVARCHAR(20)                    NOT NULL CONSTRAINT DF_myonline_tbl_LeaveApplications_Status DEFAULT ('Pending'),
        ApprovedByUserId INT                            NULL,
        ActionDateUtc   DATETIME2                       NULL,
        CreatedAtUtc    DATETIME2                       NOT NULL CONSTRAINT DF_myonline_tbl_LeaveApplications_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_myonline_tbl_LeaveApplications PRIMARY KEY CLUSTERED (ApplicationId ASC),
        CONSTRAINT CK_myonline_tbl_LeaveApplications_Status CHECK (Status IN (N'Pending', N'Approved', N'Rejected')),
        CONSTRAINT FK_myonline_tbl_LeaveApplications_User FOREIGN KEY (UserId) REFERENCES dbo.myonline_tbl_Users (Id),
        CONSTRAINT FK_myonline_tbl_LeaveApplications_Type FOREIGN KEY (LeaveTypeId) REFERENCES dbo.myonline_tbl_LeaveTypes (LeaveTypeId)
    );
    PRINT 'myonline_tbl_LeaveApplications created.';
END
GO

PRINT '============================================================';
PRINT 'All Production Tables & Columns successfully configured!';
PRINT '============================================================';
GO
