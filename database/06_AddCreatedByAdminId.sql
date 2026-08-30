-- ============================================================
-- Migration: Add CreatedByAdminId & PhoneNumber columns to myonline_tbl_Users
-- Run this in SSMS or any SQL tool against LiveTrackingDB
-- ============================================================

USE LiveTrackingDB;
GO

-- 1. Add PhoneNumber column (if not exists)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') 
    AND name = N'PhoneNumber'
)
BEGIN
    ALTER TABLE dbo.myonline_tbl_Users
        ADD PhoneNumber NVARCHAR(20) NULL;
    PRINT 'PhoneNumber column added successfully.';
END
ELSE
    PRINT 'PhoneNumber column already exists.';
GO

-- 2. Add CreatedByAdminId column (if not exists)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') 
    AND name = N'CreatedByAdminId'
)
BEGIN
    ALTER TABLE dbo.myonline_tbl_Users
        ADD CreatedByAdminId INT NULL;
    PRINT 'CreatedByAdminId column added successfully.';
END
ELSE
    PRINT 'CreatedByAdminId column already exists.';
GO

-- 3. Verify the columns
SELECT 
    c.name AS ColumnName, 
    t.name AS DataType, 
    c.is_nullable AS IsNullable
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.myonline_tbl_Users')
ORDER BY c.column_id;
GO

-- 4. Query to verify Owner -> User relationships
SELECT 
    admin.Id AS AdminId,
    admin.Name AS AdminName,
    admin.Username AS AdminUsername,
    u.Id AS UserId,
    u.Name AS UserName,
    u.Username AS UserUsername,
    u.PhoneNumber,
    o.Name AS AssignedOffice
FROM dbo.myonline_tbl_Users u
INNER JOIN dbo.myonline_tbl_Users admin ON u.CreatedByAdminId = admin.Id
LEFT JOIN dbo.myonline_tbl_OfficeLocations o ON u.OfficeLocationId = o.Id
ORDER BY admin.Name, u.Name;
GO
