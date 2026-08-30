/* ============================================================
   File: database/08_FixLeaveApplicationsTotalDays.sql
   Fix: myonline_tbl_LeaveApplications is missing the TotalDays
   column that LiveTracking.Api's LeaveApplication model expects,
   which causes every leave-related endpoint (apply, history,
   admin list, approve/reject, admin summary) to fail with a
   500 "Invalid column name 'TotalDays'" error.

   Safe to run multiple times.
   ============================================================ */
USE LiveTrackingDB;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_LeaveApplications') AND name = N'TotalDays'
)
BEGIN
    ALTER TABLE dbo.myonline_tbl_LeaveApplications
        ADD TotalDays INT NOT NULL
            CONSTRAINT DF_myonline_tbl_LeaveApplications_TotalDays DEFAULT (0);

    -- Backfill existing rows from StartDate/EndDate so old applications show a real value.
    UPDATE dbo.myonline_tbl_LeaveApplications
    SET TotalDays = DATEDIFF(DAY, StartDate, EndDate) + 1
    WHERE TotalDays = 0;
END
GO
