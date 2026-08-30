/* ============================================================
   File: database/09_FixDriverLocationsPingCrash.sql
   Fix: POST /api/locations/ping (every GPS tick from the Android
   foreground service) fails with 500 on the live server, while
   every other insert-based endpoint (users, customers, visits)
   works fine. The one thing unique to this table is the
   TRG_myonline_tbl_DriverLocations_SetLocation trigger, which
   writes a GEOGRAPHY column that the API/app never reads back.

   We could not get the exact server-side exception (no access
   to IIS/SQL Server logs from here), so this script removes the
   failure point defensively rather than guessing at one exact
   cause:
     1. Makes sure Location stays NULLable (in case schema drift
        made it NOT NULL on the live DB, which would make every
        EF Core insert fail since EF never sets that column).
     2. Wraps the trigger body in TRY/CATCH so a spatial
        computation error can never fail the parent INSERT --
        Location is cosmetic/unused by the API today, it should
        never be able to block a location ping from being saved.

   Safe to run multiple times.
   ============================================================ */
USE LiveTrackingDB;
GO

IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_DriverLocations') AND name = N'Location'
)
BEGIN
    ALTER TABLE dbo.myonline_tbl_DriverLocations ALTER COLUMN Location GEOGRAPHY NULL;
END
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER dbo.TRG_myonline_tbl_DriverLocations_SetLocation
ON dbo.myonline_tbl_DriverLocations
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        UPDATE dl
        SET dl.Location = GEOGRAPHY::Point(i.Latitude, i.Longitude, 4326)
        FROM dbo.myonline_tbl_DriverLocations dl
        INNER JOIN inserted i ON i.Id = dl.Id;
    END TRY
    BEGIN CATCH
        -- Location is a derived/cosmetic column the API never reads;
        -- never let it block the ping insert itself from succeeding.
        PRINT 'TRG_myonline_tbl_DriverLocations_SetLocation: ' + ERROR_MESSAGE();
    END CATCH
END
GO
