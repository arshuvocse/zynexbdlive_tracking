/* ============================================================
   File: database/11_CreateRouteHistoryProcedure.sql
   LiveTrackingDB - Driver Route History (per user, per date range)
   ============================================================ */

USE LiveTrackingDB;
GO

-- sp_GetDriverRouteHistory: full set of GPS pings for one driver within
-- a date/time range, used to draw the route polyline on the admin map.
CREATE OR ALTER PROCEDURE dbo.sp_GetDriverRouteHistory
    @UserId   INT,
    @FromDate DATETIME2,
    @ToDate   DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.Id AS UserId,
        u.Username,
        u.Name AS FullName,
        u.IsActive,
        dl.Latitude,
        dl.Longitude,
        dl.Accuracy,
        dl.Speed,
        dl.Bearing,
        dl.RecordedAt AS RecordedAtUtc
    FROM dbo.myonline_tbl_DriverLocations dl
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = dl.UserId
    WHERE dl.UserId = @UserId
      AND dl.RecordedAt >= @FromDate
      AND dl.RecordedAt < @ToDate
    ORDER BY dl.RecordedAt ASC;
END
GO
