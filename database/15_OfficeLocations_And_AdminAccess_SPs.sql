/* ==============================================================================
   File: database/15_OfficeLocations_And_AdminAccess_SPs.sql
   Description: Complete Table Definitions and Stored Procedures for 
                Office Locations & Admin-wise Employee Access Hierarchy
   ============================================================================== */

USE LiveTrackingDB;
GO

-- ==============================================================================
-- 1. TABLE DEFINITIONS
-- ==============================================================================

-- 1.1. Office Locations Master Table
IF OBJECT_ID(N'dbo.myonline_tbl_OfficeLocations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_OfficeLocations
    (
        Id           INT IDENTITY(1,1) NOT NULL,
        Name         NVARCHAR(150)     NOT NULL,
        Latitude     FLOAT             NOT NULL,
        Longitude    FLOAT             NOT NULL,
        RadiusMeters FLOAT             NOT NULL CONSTRAINT DF_myonline_tbl_OfficeLocations_Radius DEFAULT (200),
        Address      NVARCHAR(500)     NULL,
        IsActive     BIT               NOT NULL CONSTRAINT DF_myonline_tbl_OfficeLocations_IsActive DEFAULT (1),
        CreatedAt    DATETIME2         NOT NULL CONSTRAINT DF_myonline_tbl_OfficeLocations_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_myonline_tbl_OfficeLocations PRIMARY KEY CLUSTERED (Id ASC)
    );
    PRINT 'Created Table: dbo.myonline_tbl_OfficeLocations';
END
ELSE
BEGIN
    -- Ensure Address column exists if table was created previously
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_OfficeLocations') AND name = N'Address')
    BEGIN
        ALTER TABLE dbo.myonline_tbl_OfficeLocations ADD Address NVARCHAR(500) NULL;
        PRINT 'Added Address column to dbo.myonline_tbl_OfficeLocations';
    END
END
GO

-- 1.2. Admin-to-Multiple-Office-Locations Mapping Table
IF OBJECT_ID(N'dbo.myonline_tbl_AdminOfficeLocations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.myonline_tbl_AdminOfficeLocations
    (
        Id               INT IDENTITY(1,1) NOT NULL,
        AdminUserId      INT               NOT NULL,
        OfficeLocationId INT               NOT NULL,
        AssignedAtUtc    DATETIME2         NOT NULL CONSTRAINT DF_AdminOfficeLocations_AssignedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_myonline_tbl_AdminOfficeLocations PRIMARY KEY CLUSTERED (Id ASC),
        CONSTRAINT FK_AdminOfficeLocations_Users FOREIGN KEY (AdminUserId) REFERENCES dbo.myonline_tbl_Users (Id) ON DELETE CASCADE,
        CONSTRAINT FK_AdminOfficeLocations_OfficeLocations FOREIGN KEY (OfficeLocationId) REFERENCES dbo.myonline_tbl_OfficeLocations (Id) ON DELETE CASCADE
    );

    CREATE UNIQUE NONCLUSTERED INDEX UQ_AdminOfficeLocations_Admin_Office 
    ON dbo.myonline_tbl_AdminOfficeLocations (AdminUserId, OfficeLocationId);

    PRINT 'Created Table: dbo.myonline_tbl_AdminOfficeLocations';
END
GO


-- ==============================================================================
-- 2. STORED PROCEDURES (SPs) FOR OFFICE LOCATION & ADMIN ACCESS MANAGEMENT
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- SP 1: sp_GetOfficeLocations
-- Returns active office locations. If @AdminUserId is provided and that admin has
-- assigned offices, it filters only those offices. If unrestricted/super-admin, returns all.
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

    -- If specific admin has assigned offices and @All is false, filter by assigned offices
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
-- SP 5: sp_DeleteOfficeLocation (Soft Delete / Deactivate)
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
-- Returns the list of office locations assigned to a specific admin user.
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
-- SP 7: sp_GetUsersByAdminAccess
-- Returns the list of employees/users accessible to an admin based on assigned offices.
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_GetUsersByAdminAccess
    @AdminUserId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AssignedOffices TABLE (OfficeLocationId INT PRIMARY KEY);

    INSERT INTO @AssignedOffices (OfficeLocationId)
    SELECT OfficeLocationId
    FROM dbo.myonline_tbl_AdminOfficeLocations
    WHERE AdminUserId = @AdminUserId;

    -- If no records in AdminOfficeLocations, check single office in Users table
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
        @HasRestrictions = 0 -- Unrestricted/SuperAdmin sees all
        OR u.Id = @AdminUserId
        OR (u.OfficeLocationId IS NOT NULL AND u.OfficeLocationId IN (SELECT OfficeLocationId FROM @AssignedOffices))
    )
    ORDER BY u.Name ASC;
END
GO

-- ------------------------------------------------------------------------------
-- SP 8: sp_GetAttendanceByAdminAccess
-- Returns attendance records filtered by the admin's assigned office locations.
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
PRINT 'All Office Location & Admin Access Stored Procedures Created/Updated.';
PRINT '==============================================================================';
GO
