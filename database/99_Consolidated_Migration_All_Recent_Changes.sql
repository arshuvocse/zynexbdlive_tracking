/* ============================================================================
   SCRIPT: 99_Consolidated_Migration_All_Recent_Changes.sql
   DATABASE: LiveTrackingDB (or SalesDisDB / Production DB)
   DESCRIPTION: Consolidated SQL script containing all recent tables, columns,
                constraints, triggers, stored procedures, and seed data.
   SAFE & IDEMPOTENT: Can be safely executed multiple times without errors.
   ============================================================================ */

USE LiveTrackingDB;
GO

PRINT '>>> Starting Consolidated Database Migration...';
GO

/* ============================================================================
   SECTION 1: TABLE ALTERATIONS & NEW COLUMNS
   ============================================================================ */

-- 1.1 Add PhoneNumber & CreatedByAdminId to myonline_tbl_Users
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'myonline_tbl_Users')
BEGIN
    -- PhoneNumber column
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') AND name = N'PhoneNumber'
    )
    BEGIN
        ALTER TABLE dbo.myonline_tbl_Users ADD PhoneNumber NVARCHAR(20) NULL;
        PRINT ' [+] myonline_tbl_Users: PhoneNumber column added.';
    END

    -- CreatedByAdminId column
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_Users') AND name = N'CreatedByAdminId'
    )
    BEGIN
        ALTER TABLE dbo.myonline_tbl_Users ADD CreatedByAdminId INT NULL;
        PRINT ' [+] myonline_tbl_Users: CreatedByAdminId column added.';
    END
END
GO

-- 1.2 Add LocationAddress to myonline_tbl_DriverLocations
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'myonline_tbl_DriverLocations')
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_DriverLocations') AND name = N'LocationAddress'
    )
    BEGIN
        ALTER TABLE dbo.myonline_tbl_DriverLocations ADD LocationAddress NVARCHAR(500) NULL;
        PRINT ' [+] myonline_tbl_DriverLocations: LocationAddress column added.';
    END

    -- Ensure Location geography column is nullable (if exists) to prevent insert crashes
    IF EXISTS (
        SELECT 1 FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_DriverLocations') AND name = N'Location'
    )
    BEGIN
        ALTER TABLE dbo.myonline_tbl_DriverLocations ALTER COLUMN Location GEOGRAPHY NULL;
        PRINT ' [+] myonline_tbl_DriverLocations: Location column confirmed NULLable.';
    END

    -- Ensure RecordedAt default constraint exists
    IF NOT EXISTS (
        SELECT 1 FROM sys.default_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.myonline_tbl_DriverLocations')
        AND parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'dbo.myonline_tbl_DriverLocations'), 'RecordedAt', 'ColumnId')
    )
    BEGIN
        ALTER TABLE dbo.myonline_tbl_DriverLocations
            ADD CONSTRAINT DF_myonline_tbl_DriverLocations_RecordedAt DEFAULT (SYSUTCDATETIME()) FOR RecordedAt;
        PRINT ' [+] myonline_tbl_DriverLocations: Default constraint DF_myonline_tbl_DriverLocations_RecordedAt added.';
    END
END
GO

-- 1.3 Fix TotalDays in myonline_tbl_LeaveApplications
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'myonline_tbl_LeaveApplications')
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'dbo.myonline_tbl_LeaveApplications') AND name = N'TotalDays'
    )
    BEGIN
        ALTER TABLE dbo.myonline_tbl_LeaveApplications ADD TotalDays DECIMAL(5,2) NULL;
        PRINT ' [+] myonline_tbl_LeaveApplications: TotalDays column added.';
    END
END
GO


/* ============================================================================
   SECTION 2: NEW TABLES
   ============================================================================ */

-- 2.1 SubscriptionPlans Table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SubscriptionPlans')
BEGIN
    CREATE TABLE dbo.SubscriptionPlans (
        PlanId          INT IDENTITY(1,1)   PRIMARY KEY CLUSTERED,
        PlanCode        NVARCHAR(50)        NOT NULL UNIQUE,
        TierName        NVARCHAR(50)        NOT NULL,
        Title           NVARCHAR(150)       NOT NULL,
        TitleBn         NVARCHAR(200)       NOT NULL,
        DurationMonths  INT                 NOT NULL,
        Price           DECIMAL(18,2)       NOT NULL,
        OriginalPrice   DECIMAL(18,2)       NOT NULL,
        DiscountPercent INT                 NOT NULL DEFAULT 0,
        DiscountText    NVARCHAR(150)       NULL,
        BadgeText       NVARCHAR(100)       NULL,
        BadgeTextBn     NVARCHAR(150)       NULL,
        FeaturesJson    NVARCHAR(MAX)       NOT NULL,
        IsActive        BIT                 NOT NULL DEFAULT 1,
        DisplayOrder    INT                 NOT NULL DEFAULT 0,
        CreatedDate     DATETIME2           NOT NULL DEFAULT GETUTCDATE()
    );
    PRINT ' [+] SubscriptionPlans table created successfully.';
END
ELSE
BEGIN
    -- Ensure columns have large enough NVARCHAR sizes
    ALTER TABLE dbo.SubscriptionPlans ALTER COLUMN Title NVARCHAR(150) NOT NULL;
    ALTER TABLE dbo.SubscriptionPlans ALTER COLUMN TitleBn NVARCHAR(200) NOT NULL;
    ALTER TABLE dbo.SubscriptionPlans ALTER COLUMN BadgeText NVARCHAR(100) NULL;
    ALTER TABLE dbo.SubscriptionPlans ALTER COLUMN BadgeTextBn NVARCHAR(150) NULL;
    ALTER TABLE dbo.SubscriptionPlans ALTER COLUMN DiscountText NVARCHAR(150) NULL;
    PRINT ' [+] SubscriptionPlans column sizes updated.';
END
GO


/* ============================================================================
   SECTION 3: TRIGGER CLEANUP (Fixes Ping 500 Crash)
   ============================================================================ */

-- Drop blocking/crashing spatial trigger on DriverLocations if present
IF OBJECT_ID(N'dbo.TRG_myonline_tbl_DriverLocations_SetLocation', N'TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.TRG_myonline_tbl_DriverLocations_SetLocation;
    PRINT ' [+] TRG_myonline_tbl_DriverLocations_SetLocation trigger dropped.';
END
GO


/* ============================================================================
   SECTION 4: STORED PROCEDURES
   ============================================================================ */

-- 4.1 sp_GetDriverRouteHistory: Returns full route history with LocationAddress
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
        dl.RecordedAt AS RecordedAtUtc,
        dl.LocationAddress
    FROM dbo.myonline_tbl_DriverLocations dl
    INNER JOIN dbo.myonline_tbl_Users u ON u.Id = dl.UserId
    WHERE dl.UserId = @UserId
      AND dl.RecordedAt >= @FromDate
      AND dl.RecordedAt < @ToDate
    ORDER BY dl.RecordedAt ASC;
END
GO
PRINT ' [+] Stored Procedure dbo.sp_GetDriverRouteHistory created/updated.';
GO

-- 4.2 sp_GetLatestDriverLocations: Returns latest location per driver with LocationAddress
CREATE OR ALTER PROCEDURE dbo.sp_GetLatestDriverLocations
    @AdminId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH RankedLocations AS (
        SELECT 
            dl.UserId,
            dl.Latitude,
            dl.Longitude,
            dl.Accuracy,
            dl.Speed,
            dl.Bearing,
            dl.RecordedAt AS RecordedAtUtc,
            dl.LocationAddress,
            ROW_NUMBER() OVER(PARTITION BY dl.UserId ORDER BY dl.RecordedAt DESC) AS rn
        FROM dbo.myonline_tbl_DriverLocations dl
    )
    SELECT
        u.Id AS UserId,
        u.Username,
        u.Name AS FullName,
        u.IsActive,
        rl.Latitude,
        rl.Longitude,
        rl.Accuracy,
        rl.Speed,
        rl.Bearing,
        rl.RecordedAtUtc,
        rl.LocationAddress
    FROM dbo.myonline_tbl_Users u
    LEFT JOIN RankedLocations rl ON u.Id = rl.UserId AND rl.rn = 1
    WHERE u.Role != 'Admin'
      AND (@AdminId IS NULL OR u.CreatedByAdminId = @AdminId OR u.CreatedByAdminId IS NULL)
    ORDER BY u.Name ASC;
END
GO
PRINT ' [+] Stored Procedure dbo.sp_GetLatestDriverLocations created/updated.';
GO


/* ============================================================================
   SECTION 5: SEED DATA (Subscription Plans)
   ============================================================================ */

-- Regular 1 Month Plan
IF NOT EXISTS (SELECT 1 FROM dbo.SubscriptionPlans WHERE PlanCode = 'REGULAR_1M')
BEGIN
    INSERT INTO dbo.SubscriptionPlans (PlanCode, TierName, Title, TitleBn, DurationMonths, Price, OriginalPrice, DiscountPercent, DiscountText, BadgeText, BadgeTextBn, FeaturesJson, IsActive, DisplayOrder)
    VALUES (
        'REGULAR_1M',
        'Regular',
        '1 Month Regular Plan',
        N'১ মাস রেগুলার প্ল্যান',
        1,
        1000.00,
        1000.00,
        0,
        'Regular Price',
        'Starter',
        N'শুরু করার জন্য',
        '["Live GPS Tracking & Route History","Real-time Attendance & Geofencing","Customer & Visit Logging","Standard Support"]',
        1,
        1
    );
    PRINT ' [+] Seeded Subscription Plan: REGULAR_1M';
END

-- Silver 3 Months Plan
IF NOT EXISTS (SELECT 1 FROM dbo.SubscriptionPlans WHERE PlanCode = 'SILVER_3M')
BEGIN
    INSERT INTO dbo.SubscriptionPlans (PlanCode, TierName, Title, TitleBn, DurationMonths, Price, OriginalPrice, DiscountPercent, DiscountText, BadgeText, BadgeTextBn, FeaturesJson, IsActive, DisplayOrder)
    VALUES (
        'SILVER_3M',
        'Silver',
        '3 Months Silver Pack',
        N'৩ মাস সিলভার প্যাক',
        3,
        2500.00,
        3000.00,
        17,
        'Save ৳500 (17% OFF)',
        'Popular Offer',
        N'🔥 আকর্ষণীয় অফার (জনপ্রিয়)',
        '["All Regular Features Included","3 Months Uninterrupted Access","Save ৳500 Total Discount","Priority Support Response","Daily Activity & Performance Reports"]',
        1,
        2
    );
    PRINT ' [+] Seeded Subscription Plan: SILVER_3M';
END

-- Gold 6 Months Plan
IF NOT EXISTS (SELECT 1 FROM dbo.SubscriptionPlans WHERE PlanCode = 'GOLD_6M')
BEGIN
    INSERT INTO dbo.SubscriptionPlans (PlanCode, TierName, Title, TitleBn, DurationMonths, Price, OriginalPrice, DiscountPercent, DiscountText, BadgeText, BadgeTextBn, FeaturesJson, IsActive, DisplayOrder)
    VALUES (
        'GOLD_6M',
        'Gold',
        '6 Months Gold Pack',
        N'৬ মাস গোল্ড প্যাক',
        6,
        4500.00,
        6000.00,
        25,
        'Save ৳1,500 (25% OFF)',
        'Best Value',
        N'⭐ সেরা সাশ্রয়ী (বেস্ট ভ্যালু)',
        '["All Silver Features Included","6 Months Guaranteed Service","Save ৳1,500 Mega Discount","Real-time SignalR Alerts","VIP Account Manager"]',
        1,
        3
    );
    PRINT ' [+] Seeded Subscription Plan: GOLD_6M';
END

-- Platinum 12 Months Plan
IF NOT EXISTS (SELECT 1 FROM dbo.SubscriptionPlans WHERE PlanCode = 'PLATINUM_12M')
BEGIN
    INSERT INTO dbo.SubscriptionPlans (PlanCode, TierName, Title, TitleBn, DurationMonths, Price, OriginalPrice, DiscountPercent, DiscountText, BadgeText, BadgeTextBn, FeaturesJson, IsActive, DisplayOrder)
    VALUES (
        'PLATINUM_12M',
        'Platinum',
        '1 Year Platinum Super Saver',
        N'১ বছর প্ল্যাটিনাম সুপার সেভার',
        12,
        8000.00,
        12000.00,
        33,
        'Save ৳4,000 (33% OFF)',
        'Mega Saver',
        N'💎 মেগা সেভার (সর্বোচ্চ ছাড়)',
        '["Full Year 365 Days Access","Save ৳4,000 Huge Discount","Unlimited Employees Support","24/7 Dedicated Priority Hotline","Zero Interruption Guarantee"]',
        1,
        4
    );
    PRINT ' [+] Seeded Subscription Plan: PLATINUM_12M';
END
GO

PRINT '>>> Migration Completed Successfully! All recent changes applied.';
GO
