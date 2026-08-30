/* ============================================================
   File: database/12_FixDriverLocationsTriggerAndColumns.sql
   Purpose: Fix 500 Internal Server Error on Location Ping
   ============================================================ */
USE LiveTrackingDB;
GO

-- 1. If TRG_myonline_tbl_DriverLocations_SetLocation trigger exists, drop it to ensure zero insert blocking
IF OBJECT_ID(N'dbo.TRG_myonline_tbl_DriverLocations_SetLocation', N'TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.TRG_myonline_tbl_DriverLocations_SetLocation;
    PRINT 'TRG_myonline_tbl_DriverLocations_SetLocation trigger dropped successfully.';
END
GO

-- 2. Ensure Location column is NULLable if present
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_DriverLocations') AND name = N'Location'
)
BEGIN
    ALTER TABLE dbo.myonline_tbl_DriverLocations ALTER COLUMN Location GEOGRAPHY NULL;
    PRINT 'Location column set to NULLable.';
END
GO

-- 3. Ensure RecordedAt column has default constraint
IF NOT EXISTS (
    SELECT 1 FROM sys.default_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.myonline_tbl_DriverLocations')
    AND parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'dbo.myonline_tbl_DriverLocations'), 'RecordedAt', 'ColumnId')
)
BEGIN
    ALTER TABLE dbo.myonline_tbl_DriverLocations
        ADD CONSTRAINT DF_myonline_tbl_DriverLocations_RecordedAt DEFAULT (SYSUTCDATETIME()) FOR RecordedAt;
    PRINT 'DF_myonline_tbl_DriverLocations_RecordedAt added.';
END
GO
