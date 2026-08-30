/* ============================================================
   File: database/05_AttendanceLeaveTables.sql
   LiveTrackingDB - Selfie Attendance + Leave Management
   All tables use the myonline_tbl_ prefix as required.
   ============================================================ */
USE LiveTrackingDB;
GO

/* ------------------------------------------------------------
   1. myonline_tbl_OfficeLocations
   ------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.myonline_tbl_OfficeLocations', N'U') IS NOT NULL
    DROP TABLE dbo.myonline_tbl_OfficeLocations;
GO

CREATE TABLE dbo.myonline_tbl_OfficeLocations
(
    Id              INT             IDENTITY(1,1)   NOT NULL,
    Name            NVARCHAR(150)                   NOT NULL,
    Latitude        FLOAT                           NOT NULL,
    Longitude       FLOAT                           NOT NULL,
    RadiusMeters    FLOAT                           NOT NULL
                        CONSTRAINT DF_myonline_tbl_OfficeLocations_RadiusMeters DEFAULT (200),
    IsActive        BIT                             NOT NULL
                        CONSTRAINT DF_myonline_tbl_OfficeLocations_IsActive DEFAULT (1),
    CreatedAt       DATETIME2                       NOT NULL
                        CONSTRAINT DF_myonline_tbl_OfficeLocations_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_myonline_tbl_OfficeLocations PRIMARY KEY CLUSTERED (Id ASC)
);
GO

/* ------------------------------------------------------------
   2. Add OfficeLocationId to Users (admin assigns office to user)
   ------------------------------------------------------------ */
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') AND name = N'OfficeLocationId'
)
BEGIN
    ALTER TABLE dbo.myonline_tbl_Users
        ADD OfficeLocationId INT NULL
            CONSTRAINT FK_myonline_tbl_Users_OfficeLocations
                REFERENCES dbo.myonline_tbl_OfficeLocations (Id);
END
GO

/* ------------------------------------------------------------
   3. myonline_tbl_Attendances
   ------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.myonline_tbl_Attendances', N'U') IS NOT NULL
    DROP TABLE dbo.myonline_tbl_Attendances;
GO

CREATE TABLE dbo.myonline_tbl_Attendances
(
    Id                  BIGINT          IDENTITY(1,1)   NOT NULL,
    UserId              INT                             NOT NULL,
    Type                NVARCHAR(10)                    NOT NULL,
    Timestamp           DATETIME2                       NOT NULL
                            CONSTRAINT DF_myonline_tbl_Attendances_Timestamp DEFAULT (SYSUTCDATETIME()),
    SelfieImagePath     NVARCHAR(400)                   NOT NULL,
    Latitude            FLOAT                           NOT NULL,
    Longitude           FLOAT                           NOT NULL,
    IsWithinGeofence    BIT                             NOT NULL
                            CONSTRAINT DF_myonline_tbl_Attendances_IsWithinGeofence DEFAULT (0),
    CreatedAt           DATETIME2                       NOT NULL
                            CONSTRAINT DF_myonline_tbl_Attendances_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_myonline_tbl_Attendances PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT FK_myonline_tbl_Attendances_Users FOREIGN KEY (UserId)
        REFERENCES dbo.myonline_tbl_Users (Id)
        ON DELETE CASCADE,
    CONSTRAINT CK_myonline_tbl_Attendances_Type CHECK (Type IN (N'In', N'Out'))
);
GO

CREATE NONCLUSTERED INDEX IX_myonline_tbl_Attendances_UserId_Timestamp
    ON dbo.myonline_tbl_Attendances (UserId, Timestamp DESC);
GO

/* ------------------------------------------------------------
   4. myonline_tbl_LeaveTypes
   ------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.myonline_tbl_LeaveTypes', N'U') IS NOT NULL
    DROP TABLE dbo.myonline_tbl_LeaveTypes;
GO

CREATE TABLE dbo.myonline_tbl_LeaveTypes
(
    Id                      INT             IDENTITY(1,1)   NOT NULL,
    Name                    NVARCHAR(100)                   NOT NULL,
    DefaultDaysPerYear      INT                             NOT NULL
                                CONSTRAINT DF_myonline_tbl_LeaveTypes_DefaultDaysPerYear DEFAULT (0),
    IsActive                BIT                             NOT NULL
                                CONSTRAINT DF_myonline_tbl_LeaveTypes_IsActive DEFAULT (1),
    CreatedAt               DATETIME2                       NOT NULL
                                CONSTRAINT DF_myonline_tbl_LeaveTypes_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_myonline_tbl_LeaveTypes PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT UQ_myonline_tbl_LeaveTypes_Name UNIQUE (Name)
);
GO

/* ------------------------------------------------------------
   5. myonline_tbl_LeaveBalances
   ------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.myonline_tbl_LeaveBalances', N'U') IS NOT NULL
    DROP TABLE dbo.myonline_tbl_LeaveBalances;
GO

CREATE TABLE dbo.myonline_tbl_LeaveBalances
(
    Id              INT             IDENTITY(1,1)   NOT NULL,
    UserId          INT                             NOT NULL,
    LeaveTypeId     INT                             NOT NULL,
    Year            INT                             NOT NULL,
    TotalDays       INT                             NOT NULL,
    UsedDays        INT                             NOT NULL
                        CONSTRAINT DF_myonline_tbl_LeaveBalances_UsedDays DEFAULT (0),

    CONSTRAINT PK_myonline_tbl_LeaveBalances PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT FK_myonline_tbl_LeaveBalances_Users FOREIGN KEY (UserId)
        REFERENCES dbo.myonline_tbl_Users (Id)
        ON DELETE CASCADE,
    CONSTRAINT FK_myonline_tbl_LeaveBalances_LeaveTypes FOREIGN KEY (LeaveTypeId)
        REFERENCES dbo.myonline_tbl_LeaveTypes (Id),
    CONSTRAINT UQ_myonline_tbl_LeaveBalances_User_Type_Year UNIQUE (UserId, LeaveTypeId, Year)
);
GO

/* ------------------------------------------------------------
   6. myonline_tbl_LeaveApplications
   ------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.myonline_tbl_LeaveApplications', N'U') IS NOT NULL
    DROP TABLE dbo.myonline_tbl_LeaveApplications;
GO

CREATE TABLE dbo.myonline_tbl_LeaveApplications
(
    Id              INT             IDENTITY(1,1)   NOT NULL,
    UserId          INT                             NOT NULL,
    LeaveTypeId     INT                             NOT NULL,
    StartDate       DATE                            NOT NULL,
    EndDate         DATE                            NOT NULL,
    TotalDays       INT                             NOT NULL
                        CONSTRAINT DF_myonline_tbl_LeaveApplications_TotalDays DEFAULT (0),
    Reason          NVARCHAR(500)                   NOT NULL,
    Status          NVARCHAR(20)                    NOT NULL
                        CONSTRAINT DF_myonline_tbl_LeaveApplications_Status DEFAULT (N'Pending'),
    AppliedAt       DATETIME2                       NOT NULL
                        CONSTRAINT DF_myonline_tbl_LeaveApplications_AppliedAt DEFAULT (SYSUTCDATETIME()),
    ReviewedBy      INT                             NULL,
    ReviewedAt      DATETIME2                       NULL,
    ReviewComment   NVARCHAR(500)                   NULL,

    CONSTRAINT PK_myonline_tbl_LeaveApplications PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT FK_myonline_tbl_LeaveApplications_Users FOREIGN KEY (UserId)
        REFERENCES dbo.myonline_tbl_Users (Id)
        ON DELETE CASCADE,
    CONSTRAINT FK_myonline_tbl_LeaveApplications_LeaveTypes FOREIGN KEY (LeaveTypeId)
        REFERENCES dbo.myonline_tbl_LeaveTypes (Id),
    CONSTRAINT FK_myonline_tbl_LeaveApplications_ReviewedBy FOREIGN KEY (ReviewedBy)
        REFERENCES dbo.myonline_tbl_Users (Id),
    CONSTRAINT CK_myonline_tbl_LeaveApplications_Status
        CHECK (Status IN (N'Pending', N'Approved', N'Rejected', N'Cancelled')),
    CONSTRAINT CK_myonline_tbl_LeaveApplications_DateRange CHECK (EndDate >= StartDate)
);
GO

CREATE NONCLUSTERED INDEX IX_myonline_tbl_LeaveApplications_UserId_Status
    ON dbo.myonline_tbl_LeaveApplications (UserId, Status);
GO
