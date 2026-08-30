/* ============================================================
   File: database/13_AddLocationAddressColumn.sql
   Purpose: Add LocationAddress column to myonline_tbl_DriverLocations
   ============================================================ */
USE LiveTrackingDB;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_DriverLocations') 
    AND name = N'LocationAddress'
)
BEGIN
    ALTER TABLE dbo.myonline_tbl_DriverLocations 
    ADD LocationAddress NVARCHAR(500) NULL;
    PRINT 'LocationAddress column added to myonline_tbl_DriverLocations.';
END
ELSE
BEGIN
    PRINT 'LocationAddress column already exists in myonline_tbl_DriverLocations.';
END
GO
