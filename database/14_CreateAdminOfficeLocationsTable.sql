-- ============================================================================
-- Migration: 14_CreateAdminOfficeLocationsTable.sql
-- Description: Create Admin-to-OfficeLocation mapping table and ensure Address
--              column on OfficeLocations table.
-- ============================================================================

-- 1. Ensure Address column in myonline_tbl_OfficeLocations
IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_OfficeLocations') 
    AND name = N'Address'
)
BEGIN
    ALTER TABLE dbo.myonline_tbl_OfficeLocations 
    ADD Address NVARCHAR(500) NULL;
    PRINT 'Added Address column to dbo.myonline_tbl_OfficeLocations';
END
GO

-- 2. Create myonline_tbl_AdminOfficeLocations table for Admin to Multiple Offices mapping
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

    PRINT 'Created table dbo.myonline_tbl_AdminOfficeLocations';
END
GO
