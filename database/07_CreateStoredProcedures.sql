/* ============================================================
   File: database/07_CreateStoredProcedures.sql
   LiveTrackingDB - COMPLETE PRODUCTION STORED PROCEDURES (CREATE OR ALTER)
   ============================================================ */

USE LiveTrackingDB;
GO

-- 1. sp_GetCustomerList
CREATE OR ALTER PROCEDURE dbo.sp_GetCustomerList
    @Search     NVARCHAR(150) = NULL,
    @ActiveOnly BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');

    WITH LastVisits AS
    (
        SELECT CustomerId, MAX(VisitDate) AS LastVisitDate
        FROM dbo.myonline_tbl_CustomerVisits
        GROUP BY CustomerId
    ),
    NextFollowUps AS
    (
        SELECT CustomerId, MIN(NextFollowUpDate) AS NextFollowUpDate
        FROM dbo.myonline_tbl_CustomerVisits
        WHERE NextFollowUpDate IS NOT NULL AND IsFollowUpCompleted = 0
        GROUP BY CustomerId
    )
    SELECT 
        c.CustomerId, c.Name, c.Mobile, c.Address, c.Latitude, c.Longitude, c.Remarks, c.CreatedDate, c.IsActive,
        lv.LastVisitDate, nfu.NextFollowUpDate
    FROM dbo.myonline_tbl_Customers c
    LEFT JOIN LastVisits lv ON lv.CustomerId = c.CustomerId
    LEFT JOIN NextFollowUps nfu ON nfu.CustomerId = c.CustomerId
    WHERE (@ActiveOnly = 0 OR c.IsActive = 1)
      AND (@Search IS NULL OR c.Name LIKE '%' + @Search + '%' OR c.Mobile LIKE '%' + @Search + '%' OR c.Address LIKE '%' + @Search + '%')
    ORDER BY c.CreatedDate DESC;
END
GO

-- 2. sp_GetCustomerById
CREATE OR ALTER PROCEDURE dbo.sp_GetCustomerById
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.CustomerId, c.Name, c.Mobile, c.Address, c.Latitude, c.Longitude, c.Remarks, c.CreatedDate, c.IsActive,
        (SELECT MAX(VisitDate) FROM dbo.myonline_tbl_CustomerVisits WHERE CustomerId = c.CustomerId) AS LastVisitDate,
        (SELECT MIN(NextFollowUpDate) FROM dbo.myonline_tbl_CustomerVisits WHERE CustomerId = c.CustomerId AND NextFollowUpDate IS NOT NULL AND IsFollowUpCompleted = 0) AS NextFollowUpDate
    FROM dbo.myonline_tbl_Customers c
    WHERE c.CustomerId = @CustomerId;
END
GO

-- 3. sp_CreateCustomer
CREATE OR ALTER PROCEDURE dbo.sp_CreateCustomer
    @Name            NVARCHAR(150),
    @Mobile          NVARCHAR(30),
    @Address         NVARCHAR(300),
    @Latitude        FLOAT,
    @Longitude       FLOAT,
    @Remarks         NVARCHAR(500) = NULL,
    @CreatedByUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.myonline_tbl_Customers (Name, Mobile, Address, Latitude, Longitude, Remarks, CreatedDate, IsActive, CreatedByUserId)
    VALUES (RTRIM(@Name), RTRIM(@Mobile), RTRIM(@Address), @Latitude, @Longitude, RTRIM(@Remarks), SYSUTCDATETIME(), 1, @CreatedByUserId);

    DECLARE @NewCustomerId INT = SCOPE_IDENTITY();
    EXEC dbo.sp_GetCustomerById @CustomerId = @NewCustomerId;
END
GO

-- 4. sp_GetCustomerVisits
CREATE OR ALTER PROCEDURE dbo.sp_GetCustomerVisits
    @CustomerId INT = NULL,
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        v.VisitId, v.CustomerId, c.Name AS CustomerName, v.UserId, u.Name AS UserName,
        v.VisitDate, v.Latitude, v.Longitude, v.Remarks, v.VisitStatus, v.NextFollowUpDate, v.ShopPhotoPath, v.IsFollowUpCompleted
    FROM dbo.myonline_tbl_CustomerVisits v
    INNER JOIN dbo.myonline_tbl_Customers c ON c.CustomerId = v.CustomerId
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = v.UserId
    WHERE (@CustomerId IS NULL OR v.CustomerId = @CustomerId)
      AND (@UserId IS NULL OR v.UserId = @UserId)
    ORDER BY v.VisitDate DESC;
END
GO

-- 5. sp_RecordCustomerVisit
CREATE OR ALTER PROCEDURE dbo.sp_RecordCustomerVisit
    @CustomerId       INT,
    @UserId           INT,
    @Latitude         FLOAT,
    @Longitude        FLOAT,
    @Remarks          NVARCHAR(500) = NULL,
    @VisitStatus      NVARCHAR(50) = N'Completed',
    @NextFollowUpDate DATETIME2 = NULL,
    @ShopPhotoPath    NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.myonline_tbl_CustomerVisits 
    (CustomerId, UserId, VisitDate, Latitude, Longitude, Remarks, VisitStatus, NextFollowUpDate, ShopPhotoPath, IsFollowUpCompleted)
    VALUES 
    (@CustomerId, @UserId, SYSUTCDATETIME(), @Latitude, @Longitude, RTRIM(@Remarks), @VisitStatus, @NextFollowUpDate, @ShopPhotoPath, 0);

    SELECT SCOPE_IDENTITY() AS VisitId;
END
GO

-- 6. sp_InsertLocationPing
CREATE OR ALTER PROCEDURE dbo.sp_InsertLocationPing
    @UserId         INT,
    @Latitude       FLOAT,
    @Longitude      FLOAT,
    @Accuracy       FLOAT = NULL,
    @Speed          FLOAT = NULL,
    @Bearing        FLOAT = NULL,
    @RecordedAt     DATETIME2 = NULL,
    @DeviceBattery   INT = NULL,
    @NetworkType     NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @RecordedAt IS NULL SET @RecordedAt = SYSUTCDATETIME();

    INSERT INTO dbo.myonline_tbl_DriverLocations 
    (UserId, Latitude, Longitude, Accuracy, Speed, Bearing, RecordedAt, DeviceBattery, NetworkType)
    VALUES 
    (@UserId, @Latitude, @Longitude, @Accuracy, @Speed, @Bearing, @RecordedAt, @DeviceBattery, @NetworkType);

    SELECT SCOPE_IDENTITY() AS LocationId;
END
GO

-- 7. sp_GetLatestLocationPerUser
CREATE OR ALTER PROCEDURE dbo.sp_GetLatestLocationPerUser
AS
BEGIN
    SET NOCOUNT ON;
    WITH LatestPing AS
    (
        SELECT dl.*, ROW_NUMBER() OVER (PARTITION BY dl.UserId ORDER BY dl.RecordedAt DESC) AS rn
        FROM dbo.myonline_tbl_DriverLocations dl
    )
    SELECT 
        u.Id AS UserId, u.Username, u.Name AS FullName, u.Role, u.IsActive,
        lp.Latitude, lp.Longitude, lp.Accuracy, lp.Speed, lp.Bearing, lp.RecordedAt, lp.DeviceBattery, lp.NetworkType
    FROM dbo.myonline_tbl_Users u
    LEFT JOIN LatestPing lp ON lp.UserId = u.Id AND lp.rn = 1
    WHERE u.Role = N'User';
END
GO

-- 8. sp_GetLatestLocationByUserId
CREATE OR ALTER PROCEDURE dbo.sp_GetLatestLocationByUserId
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (1) 
        Id AS LocationId, UserId, Latitude, Longitude, Accuracy, Speed, Bearing, RecordedAt, DeviceBattery, NetworkType
    FROM dbo.myonline_tbl_DriverLocations
    WHERE UserId = @UserId
    ORDER BY RecordedAt DESC;
END
GO

-- 9. sp_GetDriverRouteHistory
CREATE OR ALTER PROCEDURE dbo.sp_GetDriverRouteHistory
    @UserId   INT,
    @FromDate DATETIME2,
    @ToDate   DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        u.Id AS UserId, u.Username, u.Name AS FullName, u.IsActive,
        dl.Latitude, dl.Longitude, dl.Accuracy, dl.Speed, dl.Bearing, dl.RecordedAt AS RecordedAtUtc
    FROM dbo.myonline_tbl_DriverLocations dl
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = dl.UserId
    WHERE dl.UserId = @UserId
      AND dl.RecordedAt >= @FromDate
      AND dl.RecordedAt < @ToDate
    ORDER BY dl.RecordedAt ASC;
END
GO

-- 10. sp_GetAttendanceHistory
CREATE OR ALTER PROCEDURE dbo.sp_GetAttendanceHistory
    @UserId   INT = NULL,
    @FromDate DATETIME2 = NULL,
    @ToDate   DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        a.Id AS AttendanceId, a.UserId, u.Name AS UserName, a.Type, a.Timestamp,
        a.Latitude, a.Longitude, a.IsWithinGeofence, a.SelfieImagePath AS SelfieUrl, a.Status, a.ShiftName
    FROM dbo.myonline_tbl_Attendances a
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = a.UserId
    WHERE (@UserId IS NULL OR a.UserId = @UserId)
      AND (@FromDate IS NULL OR a.Timestamp >= @FromDate)
      AND (@ToDate IS NULL OR a.Timestamp <= @ToDate)
    ORDER BY a.Timestamp DESC;
END
GO

-- 11. sp_GetAttendanceReportByMonthYear
CREATE OR ALTER PROCEDURE dbo.sp_GetAttendanceReportByMonthYear
    @UserId     INT = NULL,
    @AdminId    INT = NULL,
    @Month      INT = NULL,
    @Year       INT = NULL,
    @FromDate   DATETIME2 = NULL,
    @ToDate     DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        a.Id AS AttendanceId,
        a.UserId,
        u.Name AS FullName,
        u.Username,
        u.Role,
        u.PhoneNumber,
        a.Type,
        a.Timestamp AS RecordedAtUtc,
        a.Latitude,
        a.Longitude,
        a.IsWithinGeofence,
        a.SelfieImagePath AS SelfieUrl,
        a.Status,
        a.ShiftName
    FROM dbo.myonline_tbl_Attendances a
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = a.UserId
    WHERE 
        (@UserId IS NULL OR a.UserId = @UserId)
        AND (@AdminId IS NULL OR u.CreatedByAdminId = @AdminId OR u.Id = @AdminId)
        AND (@Year IS NULL OR YEAR(a.Timestamp) = @Year)
        AND (@Month IS NULL OR MONTH(a.Timestamp) = @Month)
        AND (@FromDate IS NULL OR a.Timestamp >= @FromDate)
        AND (@ToDate IS NULL OR a.Timestamp <= @ToDate)
    ORDER BY a.Timestamp DESC;
END
GO

-- 12. sp_GetMonthlyAttendanceSummary
CREATE OR ALTER PROCEDURE dbo.sp_GetMonthlyAttendanceSummary
    @UserId     INT = NULL,
    @Month      INT = NULL,
    @Year       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        u.Id AS UserId,
        u.Name AS FullName,
        u.Username,
        ISNULL(@Year, YEAR(SYSUTCDATETIME())) AS ReportYear,
        ISNULL(@Month, MONTH(SYSUTCDATETIME())) AS ReportMonth,
        COUNT(CASE WHEN a.Type = 'In' THEN 1 END) AS TotalDutyIn,
        COUNT(CASE WHEN a.Type = 'Out' THEN 1 END) AS TotalDutyOut,
        COUNT(DISTINCT CAST(a.Timestamp AS DATE)) AS TotalWorkingDays,
        COUNT(CASE WHEN a.IsWithinGeofence = 1 THEN 1 END) AS TotalWithinOffice,
        COUNT(CASE WHEN a.IsWithinGeofence = 0 THEN 1 END) AS TotalOutsideOffice
    FROM dbo.myonline_tbl_Users u
    LEFT JOIN dbo.myonline_tbl_Attendances a ON a.UserId = u.Id
        AND (@Year IS NULL OR YEAR(a.Timestamp) = @Year)
        AND (@Month IS NULL OR MONTH(a.Timestamp) = @Month)
    WHERE (@UserId IS NULL OR u.Id = @UserId)
    GROUP BY u.Id, u.Name, u.Username;
END
GO

-- 13. sp_GetLeaveApplications
CREATE OR ALTER PROCEDURE dbo.sp_GetLeaveApplications
    @UserId INT = NULL,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        la.Id AS LeaveApplicationId, la.UserId, u.Name AS UserName, la.LeaveTypeId, lt.Name AS LeaveTypeName,
        la.StartDate, la.EndDate, la.TotalDays, la.Reason, la.Status, la.AppliedAt, la.ReviewedAt, la.ReviewComment
    FROM dbo.myonline_tbl_LeaveApplications la
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = la.UserId
    INNER JOIN dbo.myonline_tbl_LeaveTypes lt ON lt.Id = la.LeaveTypeId
    WHERE (@UserId IS NULL OR la.UserId = @UserId)
      AND (@Status IS NULL OR la.Status = @Status)
    ORDER BY la.AppliedAt DESC;
END
GO

-- 14. sp_GetAllUsers
CREATE OR ALTER PROCEDURE dbo.sp_GetAllUsers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        u.Id AS UserId, u.Name AS FullName, u.Username, u.Role, u.PhoneNumber, u.IsActive, 
        u.CreatedAt, u.OfficeLocationId, u.ShiftId, u.MaxUserLimit, u.BoundDeviceId, u.DeviceModel, u.PaymentDueDate
    FROM dbo.myonline_tbl_Users u
    ORDER BY u.Name ASC;
END
GO

-- 15. sp_GetExecutiveDashboardSummary
CREATE OR ALTER PROCEDURE dbo.sp_GetExecutiveDashboardSummary
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TodayStart DATETIME2 = CAST(SYSUTCDATETIME() AS DATE);
    DECLARE @TodayEnd DATETIME2 = DATEADD(DAY, 1, @TodayStart);
    DECLARE @Cutoff15m DATETIME2 = DATEADD(MINUTE, -15, SYSUTCDATETIME());

    SELECT
        (SELECT COUNT(*) FROM dbo.myonline_tbl_Users WHERE Role = N'User') AS TotalUsers,
        (SELECT COUNT(*) FROM dbo.myonline_tbl_Users WHERE Role = N'User' AND IsActive = 1) AS ActiveUsers,
        (SELECT COUNT(DISTINCT UserId) FROM dbo.myonline_tbl_DriverLocations WHERE RecordedAt >= @Cutoff15m) AS OnlineTrackingUsers,
        (SELECT COUNT(DISTINCT UserId) FROM dbo.myonline_tbl_Attendances WHERE Type = N'In' AND Timestamp >= @TodayStart AND Timestamp < @TodayEnd) AS TodayPunchInCount,
        (SELECT COUNT(*) FROM dbo.myonline_tbl_LeaveApplications WHERE Status = N'Pending') AS PendingLeaveRequestsCount,
        (SELECT COUNT(*) FROM dbo.myonline_tbl_CustomerVisits WHERE NextFollowUpDate IS NOT NULL AND IsFollowUpCompleted = 0) AS PendingCustomerFollowUpsCount,
        (SELECT COUNT(*) FROM dbo.myonline_tbl_Customers WHERE IsActive = 1) AS TotalActiveCustomers;
END
GO

-- 16. sp_GetSubscriptionStatus
CREATE OR ALTER PROCEDURE dbo.sp_GetSubscriptionStatus
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AdminId INT = @UserId;
    DECLARE @UserRole NVARCHAR(20);
    
    SELECT @UserRole = Role, @AdminId = ISNULL(CreatedByAdminId, @UserId)
    FROM dbo.myonline_tbl_Users
    WHERE Id = @UserId;

    IF @UserRole = N'Admin'
        SET @AdminId = @UserId;

    SELECT TOP (1)
        u.Id AS AdminId,
        u.Name AS AdminName,
        u.Username AS AdminUsername,
        u.PhoneNumber AS AdminPhone,
        u.PaymentDueDate,
        ISNULL(DATEDIFF(DAY, CAST(SYSUTCDATETIME() AS DATE), CAST(ISNULL(u.PaymentDueDate, DATEADD(DAY, 30, SYSUTCDATETIME())) AS DATE)), 30) AS DaysRemaining,
        CASE WHEN u.PaymentDueDate IS NOT NULL AND u.PaymentDueDate < SYSUTCDATETIME() THEN 1 ELSE 0 END AS IsExpired,
        CASE 
            WHEN u.PaymentDueDate IS NOT NULL 
                 AND DATEDIFF(DAY, CAST(SYSUTCDATETIME() AS DATE), CAST(u.PaymentDueDate AS DATE)) <= 7 
                 AND u.PaymentDueDate >= SYSUTCDATETIME() THEN 1 
            ELSE 0 
        END AS IsWarningPeriod
    FROM dbo.myonline_tbl_Users u
    WHERE u.Id = @AdminId;
END
GO

-- 17. sp_UpdatePaymentDueDate
CREATE OR ALTER PROCEDURE dbo.sp_UpdatePaymentDueDate
    @AdminId INT,
    @NewDueDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.myonline_tbl_Users
    SET PaymentDueDate = @NewDueDate
    WHERE Id = @AdminId AND Role = N'Admin';

    EXEC dbo.sp_GetSubscriptionStatus @UserId = @AdminId;
END
GO
