/* ============================================================
   File: database/02_CreateTables.sql
   LiveTrackingDB - Table Creation Script
   All tables use the myonline_tbl_ prefix as required.
   ============================================================ */
USE LiveTrackingDB;
GO

/* ------------------------------------------------------------
   1. myonline_tbl_Users
   ------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.myonline_tbl_Users', N'U') IS NOT NULL
    DROP TABLE dbo.myonline_tbl_Users;
GO

CREATE TABLE dbo.myonline_tbl_Users
(
    Id              INT             IDENTITY(1,1)   NOT NULL,
    Name            NVARCHAR(150)                   NOT NULL,
    Username        NVARCHAR(100)                   NOT NULL,
    PasswordHash    NVARCHAR(300)                   NOT NULL,
    Role            NVARCHAR(20)                    NOT NULL
                        CONSTRAINT DF_myonline_tbl_Users_Role DEFAULT ('User'),
    CreatedAt       DATETIME2                       NOT NULL
                        CONSTRAINT DF_myonline_tbl_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    IsActive        BIT                             NOT NULL
                        CONSTRAINT DF_myonline_tbl_Users_IsActive DEFAULT (1),

    CONSTRAINT PK_myonline_tbl_Users PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT UQ_myonline_tbl_Users_Username UNIQUE (Username),
    CONSTRAINT CK_myonline_tbl_Users_Role CHECK (Role IN (N'Admin', N'User'))
);
GO

/* ------------------------------------------------------------
   2. myonline_tbl_DriverLocations
   ------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.myonline_tbl_DriverLocations', N'U') IS NOT NULL
    DROP TABLE dbo.myonline_tbl_DriverLocations;
GO

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
    RecordedAt      DATETIME2                       NOT NULL
                        CONSTRAINT DF_myonline_tbl_DriverLocations_RecordedAt DEFAULT (SYSUTCDATETIME()),
    DeviceBattery   INT                             NULL,
    NetworkType     NVARCHAR(20)                    NULL,

    CONSTRAINT PK_myonline_tbl_DriverLocations PRIMARY KEY CLUSTERED (Id ASC),
    CONSTRAINT FK_myonline_tbl_DriverLocations_Users FOREIGN KEY (UserId)
        REFERENCES dbo.myonline_tbl_Users (Id)
        ON DELETE CASCADE
);
GO

/* Non-clustered index to speed up "latest location per user" queries */
CREATE NONCLUSTERED INDEX IX_myonline_tbl_DriverLocations_UserId_RecordedAt
    ON dbo.myonline_tbl_DriverLocations (UserId, RecordedAt DESC);
GO

/* ------------------------------------------------------------
   Trigger: keep Location (GEOGRAPHY) in sync with Lat/Lng on insert/update
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER dbo.TRG_myonline_tbl_DriverLocations_SetLocation
ON dbo.myonline_tbl_DriverLocations
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dl
    SET dl.Location = GEOGRAPHY::Point(i.Latitude, i.Longitude, 4326)
    FROM dbo.myonline_tbl_DriverLocations dl
    INNER JOIN inserted i ON i.Id = dl.Id;
END
GO
