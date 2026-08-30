/* ==============================================================================
   File: OfficeLocation_And_AdminAccess_Complete_Setup.sql
   Description: Complete SQL Script for Office Location & Admin-wise Employee 
                Access Management (Tables, Constraints, Indexes & Stored Procedures)
   Target Database: LiveTrackingDB (or your active database)
   ============================================================================== */

-- ১. ডাটাবেস সিলেক্ট করুন (প্রয়োজনে নাম পরিবর্তন করুন)
IF DB_ID(N'LiveTrackingDB') IS NOT NULL
BEGIN
    USE LiveTrackingDB;
END
GO

PRINT '==============================================================================';
PRINT 'STEP 1: CREATING / UPDATING TABLES';
PRINT '==============================================================================';
GO

-- ------------------------------------------------------------------------------
-- ১.১. Office Locations Master Table (myonline_tbl_OfficeLocations)
-- ------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.myonline_tbl_OfficeLocations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_OfficeLocations
    (
        Id           INT IDENTITY(1,1) NOT NULL,
        Name         NVARCHAR(150)     NOT NULL, -- অফিসের নাম (যেমন: Dhaka Office)
        Latitude     FLOAT             NOT NULL, -- অক্ষাংশ
        Longitude    FLOAT             NOT NULL, -- দ্রাঘিমাংশ
        RadiusMeters FLOAT             NOT NULL CONSTRAINT DF_OfficeLocations_Radius DEFAULT (200), -- জিওফেন্স পরিধি (মিটারে)
        Address      NVARCHAR(500)     NULL,     -- পূর্ণ ঠিকানা
        IsActive     BIT               NOT NULL CONSTRAINT DF_OfficeLocations_IsActive DEFAULT (1),   -- সক্রিয় / নিষ্ক্রিয়
        CreatedAt    DATETIME2         NOT NULL CONSTRAINT DF_OfficeLocations_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_myonline_tbl_OfficeLocations PRIMARY KEY CLUSTERED (Id ASC)
    );
    PRINT '-> Created Table: dbo.myonline_tbl_OfficeLocations';
END
ELSE
BEGIN
    -- যদি টেবিল আগে থেকেই থাকে, Address কলাম চেক করে যোগ করা
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_OfficeLocations') AND name = N'Address')
    BEGIN
        ALTER TABLE dbo.myonline_tbl_OfficeLocations ADD Address NVARCHAR(500) NULL;
        PRINT '-> Added Address column to dbo.myonline_tbl_OfficeLocations';
    END
END
GO

-- ------------------------------------------------------------------------------
-- ১.২. নিশ্চিত করা: Users টেবিলে OfficeLocationId ও অন্যান্য কলাম রয়েছে
-- ------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.myonline_tbl_Users', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') AND name = N'OfficeLocationId')
    BEGIN
        ALTER TABLE dbo.myonline_tbl_Users ADD OfficeLocationId INT NULL;
        PRINT '-> Added OfficeLocationId column to dbo.myonline_tbl_Users';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') AND name = N'CreatedByAdminId')
    BEGIN
        ALTER TABLE dbo.myonline_tbl_Users ADD CreatedByAdminId INT NULL;
        PRINT '-> Added CreatedByAdminId column to dbo.myonline_tbl_Users';
    END
END
GO

-- ------------------------------------------------------------------------------
-- ১.৩. Admin-to-Multiple-Offices Mapping Table (myonline_tbl_AdminOfficeLocations)
-- ------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.myonline_tbl_AdminOfficeLocations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_AdminOfficeLocations
    (
        Id               INT IDENTITY(1,1) NOT NULL,
        AdminUserId      INT               NOT NULL, -- Admin-এর UserId (FK to Users)
        OfficeLocationId INT               NOT NULL, -- বরাদ্দকৃত OfficeLocation-এর Id (FK to OfficeLocations)
        AssignedAtUtc    DATETIME2         NOT NULL CONSTRAINT DF_AdminOfficeLocations_AssignedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_myonline_tbl_AdminOfficeLocations PRIMARY KEY CLUSTERED (Id ASC),
        CONSTRAINT FK_AdminOfficeLocations_Users FOREIGN KEY (AdminUserId) REFERENCES dbo.myonline_tbl_Users (Id) ON DELETE CASCADE,
        CONSTRAINT FK_AdminOfficeLocations_OfficeLocations FOREIGN KEY (OfficeLocationId) REFERENCES dbo.myonline_tbl_OfficeLocations (Id) ON DELETE CASCADE
    );

    CREATE UNIQUE NONCLUSTERED INDEX UQ_AdminOfficeLocations_Admin_Office 
    ON dbo.myonline_tbl_AdminOfficeLocations (AdminUserId, OfficeLocationId);

    PRINT '-> Created Table: dbo.myonline_tbl_AdminOfficeLocations';
END
GO

PRINT '==============================================================================';
PRINT 'STEP 2: CREATING / ALTERING STORED PROCEDURES (SPs)';
PRINT '==============================================================================';
GO

-- ------------------------------------------------------------------------------
-- SP 1: sp_GetOfficeLocations
-- নির্দিষ্ট Admin-এর জন্য নির্ধারিত অফিস অথবা সকল অফিস রিটার্ন করে
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_GetOfficeLocations
    @AdminUserId INT = NULL,
    @All         BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AssignedCount INT = 0;

    IF @AdminUserId IS NOT NULL AND @AdminUserId > 0
    BEGIN
        SELECT @AssignedCount = COUNT(*) 
        FROM dbo.myonline_tbl_AdminOfficeLocations 
        WHERE AdminUserId = @AdminUserId;
    END

    -- যদি নির্দিষ্ট Admin-এর জন্য অফিস বরাদ্দ থাকে এবং @All = 0 হয়, তবে শুধু বরাদ্দকৃত অফিসগুলো দেখাবে
    IF @AssignedCount > 0 AND @All = 0
    BEGIN
        SELECT 
            o.Id AS OfficeLocationId,
            o.Name,
            o.Latitude,
            o.Longitude,
            o.RadiusMeters,
            o.Address,
            o.IsActive,
            o.CreatedAt AS CreatedAtUtc
        FROM dbo.myonline_tbl_OfficeLocations o
        INNER JOIN dbo.myonline_tbl_AdminOfficeLocations a ON a.OfficeLocationId = o.Id
        WHERE a.AdminUserId = @AdminUserId
          AND o.IsActive = 1
        ORDER BY o.Name ASC;
    END
    ELSE
    BEGIN
        SELECT 
            o.Id AS OfficeLocationId,
            o.Name,
            o.Latitude,
            o.Longitude,
            o.RadiusMeters,
            o.Address,
            o.IsActive,
            o.CreatedAt AS CreatedAtUtc
        FROM dbo.myonline_tbl_OfficeLocations o
        WHERE (@All = 1 OR o.IsActive = 1)
        ORDER BY o.Name ASC;
    END
END
GO

-- ------------------------------------------------------------------------------
-- SP 2: sp_GetOfficeLocationById
-- নির্দিষ্ট অফিসের আইডি দিয়ে তথ্য দেখা
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_GetOfficeLocationById
    @OfficeLocationId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        o.Id AS OfficeLocationId,
        o.Name,
        o.Latitude,
        o.Longitude,
        o.RadiusMeters,
        o.Address,
        o.IsActive,
        o.CreatedAt AS CreatedAtUtc
    FROM dbo.myonline_tbl_OfficeLocations o
    WHERE o.Id = @OfficeLocationId;
END
GO

-- ------------------------------------------------------------------------------
-- SP 3: sp_CreateOfficeLocation
-- নতুন অফিস লোকেশন যুক্ত করা
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_CreateOfficeLocation
    @Name         NVARCHAR(150),
    @Latitude     FLOAT,
    @Longitude    FLOAT,
    @RadiusMeters FLOAT = 200.0,
    @Address      NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.myonline_tbl_OfficeLocations (Name, Latitude, Longitude, RadiusMeters, Address, IsActive, CreatedAt)
    VALUES (RTRIM(@Name), @Latitude, @Longitude, ISNULL(@RadiusMeters, 200.0), RTRIM(@Address), 1, SYSUTCDATETIME());

    DECLARE @NewId INT = SCOPE_IDENTITY();
    EXEC dbo.sp_GetOfficeLocationById @OfficeLocationId = @NewId;
END
GO

-- ------------------------------------------------------------------------------
-- SP 4: sp_UpdateOfficeLocation
-- অফিসের তথ্য আপডেট করা
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_UpdateOfficeLocation
    @OfficeLocationId INT,
    @Name             NVARCHAR(150),
    @Latitude         FLOAT,
    @Longitude        FLOAT,
    @RadiusMeters     FLOAT = 200.0,
    @Address          NVARCHAR(500) = NULL,
    @IsActive         BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.myonline_tbl_OfficeLocations
    SET 
        Name = RTRIM(@Name),
        Latitude = @Latitude,
        Longitude = @Longitude,
        RadiusMeters = ISNULL(@RadiusMeters, 200.0),
        Address = RTRIM(@Address),
        IsActive = @IsActive
    WHERE Id = @OfficeLocationId;

    EXEC dbo.sp_GetOfficeLocationById @OfficeLocationId = @OfficeLocationId;
END
GO

-- ------------------------------------------------------------------------------
-- SP 5: sp_DeleteOfficeLocation (Soft Delete)
-- অফিস নিষ্ক্রিয় করা
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_DeleteOfficeLocation
    @OfficeLocationId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.myonline_tbl_OfficeLocations
    SET IsActive = 0
    WHERE Id = @OfficeLocationId;

    SELECT @OfficeLocationId AS OfficeLocationId, 'Deactivated' AS Status;
END
GO

-- ------------------------------------------------------------------------------
-- SP 6: sp_GetAdminAssignedOffices
-- একজন Admin কোন কোন অফিস লোকেশনের দায়িত্ব পেয়েছেন তা দেখা
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_GetAdminAssignedOffices
    @AdminUserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        o.Id AS OfficeLocationId,
        o.Name,
        o.Latitude,
        o.Longitude,
        o.RadiusMeters,
        o.Address,
        o.IsActive,
        a.AssignedAtUtc
    FROM dbo.myonline_tbl_AdminOfficeLocations a
    INNER JOIN dbo.myonline_tbl_OfficeLocations o ON o.Id = a.OfficeLocationId
    WHERE a.AdminUserId = @AdminUserId
    ORDER BY o.Name ASC;
END
GO

-- ------------------------------------------------------------------------------
-- SP 7: sp_AssignAdminOfficeLocation
-- Admin-এর জন্য নির্দিষ্ট অফিস বরাদ্দ (Assign) করা
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_AssignAdminOfficeLocation
    @AdminUserId      INT,
    @OfficeLocationId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.myonline_tbl_AdminOfficeLocations 
        WHERE AdminUserId = @AdminUserId AND OfficeLocationId = @OfficeLocationId
    )
    BEGIN
        INSERT INTO dbo.myonline_tbl_AdminOfficeLocations (AdminUserId, OfficeLocationId, AssignedAtUtc)
        VALUES (@AdminUserId, @OfficeLocationId, SYSUTCDATETIME());
    END

    EXEC dbo.sp_GetAdminAssignedOffices @AdminUserId = @AdminUserId;
END
GO

-- ------------------------------------------------------------------------------
-- SP 8: sp_GetUsersByAdminAccess (প্রধান ফিল্টারিং প্রসিডিউর)
-- Admin-এর বরাদ্দকৃত অফিস অনুযায়ী অধীনস্থ কর্মচারীদের লিস্ট স্বয়ংক্রিয় ফিল্টার
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_GetUsersByAdminAccess
    @AdminUserId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AssignedOffices TABLE (OfficeLocationId INT PRIMARY KEY);

    -- Admin-এর মাল্টি-অফিস লিস্ট রিড করা
    INSERT INTO @AssignedOffices (OfficeLocationId)
    SELECT OfficeLocationId
    FROM dbo.myonline_tbl_AdminOfficeLocations
    WHERE AdminUserId = @AdminUserId;

    -- যদি ম্যাপিং টেবিলে না থাকে, তবে Users টেবিলের প্রাইমারি অফিস চেক করা
    IF NOT EXISTS (SELECT 1 FROM @AssignedOffices)
    BEGIN
        INSERT INTO @AssignedOffices (OfficeLocationId)
        SELECT OfficeLocationId
        FROM dbo.myonline_tbl_Users
        WHERE Id = @AdminUserId AND OfficeLocationId IS NOT NULL;
    END

    DECLARE @HasRestrictions BIT = CASE WHEN EXISTS (SELECT 1 FROM @AssignedOffices) THEN 1 ELSE 0 END;

    SELECT 
        u.Id AS UserId,
        u.Name AS FullName,
        u.Username,
        u.Role,
        u.PhoneNumber,
        u.IsActive,
        u.OfficeLocationId,
        o.Name AS OfficeLocationName,
        u.CreatedByAdminId,
        u.MaxUserLimit,
        u.BoundDeviceId,
        u.DeviceModel,
        u.CreatedAt
    FROM dbo.myonline_tbl_Users u
    LEFT JOIN dbo.myonline_tbl_OfficeLocations o ON o.Id = u.OfficeLocationId
    WHERE (
        @HasRestrictions = 0 -- SuperAdmin বা আন-অ্যাসাইনড Admin সব ইউজার দেখতে পাবে
        OR u.Id = @AdminUserId
        OR (u.OfficeLocationId IS NOT NULL AND u.OfficeLocationId IN (SELECT OfficeLocationId FROM @AssignedOffices))
    )
    ORDER BY u.Name ASC;
END
GO

-- ------------------------------------------------------------------------------
-- SP 9: sp_GetAttendanceByAdminAccess
-- Admin-এর বরাদ্দকৃত অফিসের কর্মচারীদের হাজিরা রিপোর্ট ফিল্টার
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_GetAttendanceByAdminAccess
    @AdminUserId INT,
    @UserId      INT = NULL,
    @Year        INT = NULL,
    @Month       INT = NULL,
    @FromDate    DATETIME2 = NULL,
    @ToDate      DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AssignedOffices TABLE (OfficeLocationId INT PRIMARY KEY);

    INSERT INTO @AssignedOffices (OfficeLocationId)
    SELECT OfficeLocationId
    FROM dbo.myonline_tbl_AdminOfficeLocations
    WHERE AdminUserId = @AdminUserId;

    IF NOT EXISTS (SELECT 1 FROM @AssignedOffices)
    BEGIN
        INSERT INTO @AssignedOffices (OfficeLocationId)
        SELECT OfficeLocationId
        FROM dbo.myonline_tbl_Users
        WHERE Id = @AdminUserId AND OfficeLocationId IS NOT NULL;
    END

    DECLARE @HasRestrictions BIT = CASE WHEN EXISTS (SELECT 1 FROM @AssignedOffices) THEN 1 ELSE 0 END;

    SELECT 
        a.Id AS AttendanceId,
        a.UserId,
        u.Name AS FullName,
        u.Username,
        a.Type,
        a.Timestamp AS RecordedAtUtc,
        a.Latitude,
        a.Longitude,
        a.IsWithinGeofence,
        a.SelfieImagePath AS SelfieUrl,
        ISNULL(a.Status, N'On Time') AS Status,
        ISNULL(a.ShiftName, N'General Shift') AS ShiftName,
        o.Name AS OfficeLocationName
    FROM dbo.myonline_tbl_Attendances a
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = a.UserId
    LEFT JOIN dbo.myonline_tbl_OfficeLocations o ON o.Id = u.OfficeLocationId
    WHERE (
        @HasRestrictions = 0
        OR u.Id = @AdminUserId
        OR (u.OfficeLocationId IS NOT NULL AND u.OfficeLocationId IN (SELECT OfficeLocationId FROM @AssignedOffices))
    )
    AND (@UserId IS NULL OR a.UserId = @UserId)
    AND (@Year IS NULL OR YEAR(a.Timestamp) = @Year)
    AND (@Month IS NULL OR MONTH(a.Timestamp) = @Month)
    AND (@FromDate IS NULL OR a.Timestamp >= @FromDate)
    AND (@ToDate IS NULL OR a.Timestamp <= @ToDate)
    ORDER BY a.Timestamp DESC;
END
GO

PRINT '==============================================================================';
PRINT 'STEP 3: SEEDING DEFAULT HEADQUARTERS (IF EMPTY)';
PRINT '==============================================================================';
GO

IF NOT EXISTS (SELECT 1 FROM dbo.myonline_tbl_OfficeLocations WHERE Id = 1)
BEGIN
    SET IDENTITY_INSERT dbo.myonline_tbl_OfficeLocations ON;
    INSERT INTO dbo.myonline_tbl_OfficeLocations (Id, Name, Latitude, Longitude, RadiusMeters, Address, IsActive)
    VALUES (1, N'Headquarters (Dhaka)', 23.8103, 90.4125, 200.0, N'Gulshan, Dhaka, Bangladesh', 1);
    SET IDENTITY_INSERT dbo.myonline_tbl_OfficeLocations OFF;
    PRINT '-> Seeded Default Office Location: Id = 1';
END
GO

PRINT '==============================================================================';
PRINT 'COMPLETE SETUP EXECUTED SUCCESSFULLY!';
PRINT '==============================================================================';
GO
