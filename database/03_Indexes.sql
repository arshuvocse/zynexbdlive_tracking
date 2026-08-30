/* ============================================================
   File: database/03_Indexes.sql
   LiveTrackingDB - Spatial Index Script
   ============================================================ */
USE LiveTrackingDB;
GO

IF EXISTS (
    SELECT 1 FROM sys.spatial_indexes
    WHERE name = N'SIX_myonline_tbl_DriverLocations_Location'
)
    DROP INDEX SIX_myonline_tbl_DriverLocations_Location
        ON dbo.myonline_tbl_DriverLocations;
GO

CREATE SPATIAL INDEX SIX_myonline_tbl_DriverLocations_Location
    ON dbo.myonline_tbl_DriverLocations (Location)
    USING GEOGRAPHY_AUTO_GRID
    WITH (CELLS_PER_OBJECT = 16);
GO
