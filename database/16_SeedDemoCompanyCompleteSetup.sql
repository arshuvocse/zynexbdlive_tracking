-- ============================================================================
-- Complete Setup for "Demo Company"
-- Database: WorkForce_DB
-- ============================================================================

USE [WorkForce_DB];
GO

SET NOCOUNT ON;

DECLARE @CompanyId INT;
DECLARE @OfficeLocationId INT;
DECLARE @ShiftId INT;
DECLARE @AdminUserId INT;
DECLARE @FieldUserId INT;
DECLARE @CasualLeaveId INT;
DECLARE @SickLeaveId INT;
DECLARE @AnnualLeaveId INT;

-- ----------------------------------------------------------------------------
-- ১. কোম্পানি তৈরি (myonline_tbl_Companies)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_Companies] WHERE [CompanyCode] = 'DEMO_COMPANY')
BEGIN
    INSERT INTO [dbo].[myonline_tbl_Companies] (
        [CompanyName],
        [CompanyCode],
        [ContactPerson],
        [ContactPhone],
        [ContactEmail],
        [MaxUserLimit],
        [PaymentDueDate],
        [IsActive],
        [BrandLogo],
        [CreatedAtUtc]
    )
    VALUES (
        N'Demo Company Ltd.',
        N'DEMO_COMPANY',
        N'Demo Operations Manager',
        N'01711001122',
        N'info@democompany.com',
        25,                                     -- Max User Limit
        DATEADD(YEAR, 1, GETUTCDATE()),         -- 1 year subscription
        1,                                      -- IsActive
        N'uploads/logos/demo_logo.png',         -- Brand Logo URL / Path
        GETUTCDATE()
    );
    
    SET @CompanyId = SCOPE_IDENTITY();
    PRINT '✅ Demo Company created with ID: ' + CAST(@CompanyId AS NVARCHAR(10));
END
ELSE
BEGIN
    SELECT @CompanyId = [CompanyId] FROM [dbo].[myonline_tbl_Companies] WHERE [CompanyCode] = 'DEMO_COMPANY';
    PRINT 'ℹ️ Demo Company already exists with ID: ' + CAST(@CompanyId AS NVARCHAR(10));
END

-- ----------------------------------------------------------------------------
-- ২. অফিস লোকেশন তৈরি (myonline_tbl_OfficeLocations)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_OfficeLocations] WHERE [CompanyId] = @CompanyId AND [Name] = N'Demo Head Office')
BEGIN
    INSERT INTO [dbo].[myonline_tbl_OfficeLocations] (
        [Name],
        [Address],
        [Latitude],
        [Longitude],
        [RadiusMeters],
        [IsActive],
        [CreatedAt],
        [CompanyId]
    )
    VALUES (
        N'Demo Head Office',
        N'Gulshan-2, Dhaka, Bangladesh',
        23.792500,                              -- Latitude
        90.407800,                              -- Longitude
        150,                                    -- Geofence Radius (meters)
        1,
        GETUTCDATE(),
        @CompanyId
    );

    SET @OfficeLocationId = SCOPE_IDENTITY();
    PRINT '✅ Demo Head Office created with ID: ' + CAST(@OfficeLocationId AS NVARCHAR(10));
END
ELSE
BEGIN
    SELECT @OfficeLocationId = [Id] FROM [dbo].[myonline_tbl_OfficeLocations] WHERE [CompanyId] = @CompanyId AND [Name] = N'Demo Head Office';
    PRINT 'ℹ️ Demo Head Office exists with ID: ' + CAST(@OfficeLocationId AS NVARCHAR(10));
END

-- ----------------------------------------------------------------------------
-- ৩. কোম্পানির ডিফল্ট শিফট তৈরি (myonline_tbl_Shifts)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_Shifts] WHERE [CompanyId] = @CompanyId AND [ShiftName] = N'Demo General Shift')
BEGIN
    INSERT INTO [dbo].[myonline_tbl_Shifts] (
        [ShiftName],
        [StartTime],
        [EndTime],
        [GracePeriodMinutes],
        [IsDefault],
        [IsActive],
        [CreatedAtUtc],
        [CompanyId]
    )
    VALUES (
        N'Demo General Shift',
        '09:00:00',                             -- 9:00 AM
        '18:00:00',                             -- 6:00 PM
        15,                                     -- 15 mins grace period
        1,                                      -- IsDefault
        1,                                      -- IsActive
        GETUTCDATE(),
        @CompanyId
    );

    SET @ShiftId = SCOPE_IDENTITY();
    PRINT '✅ Demo General Shift created with ID: ' + CAST(@ShiftId AS NVARCHAR(10));
END
ELSE
BEGIN
    SELECT @ShiftId = [ShiftId] FROM [dbo].[myonline_tbl_Shifts] WHERE [CompanyId] = @CompanyId AND [ShiftName] = N'Demo General Shift';
    PRINT 'ℹ️ Demo General Shift exists with ID: ' + CAST(@ShiftId AS NVARCHAR(10));
END

-- ----------------------------------------------------------------------------
-- ৪. ছুটির ক্যাটাগরি তৈরি (myonline_tbl_LeaveTypes)
-- ----------------------------------------------------------------------------
-- 4.1 Casual Leave
IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_LeaveTypes] WHERE [CompanyId] = @CompanyId AND [Name] = N'Casual Leave')
BEGIN
    INSERT INTO [dbo].[myonline_tbl_LeaveTypes] ([Name], [DefaultDaysPerYear], [IsActive], [CreatedAt], [CompanyId])
    VALUES (N'Casual Leave', 10, 1, GETUTCDATE(), @CompanyId);
    SET @CasualLeaveId = SCOPE_IDENTITY();
END
ELSE
    SELECT @CasualLeaveId = [Id] FROM [dbo].[myonline_tbl_LeaveTypes] WHERE [CompanyId] = @CompanyId AND [Name] = N'Casual Leave';

-- 4.2 Sick Leave
IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_LeaveTypes] WHERE [CompanyId] = @CompanyId AND [Name] = N'Sick Leave')
BEGIN
    INSERT INTO [dbo].[myonline_tbl_LeaveTypes] ([Name], [DefaultDaysPerYear], [IsActive], [CreatedAt], [CompanyId])
    VALUES (N'Sick Leave', 14, 1, GETUTCDATE(), @CompanyId);
    SET @SickLeaveId = SCOPE_IDENTITY();
END
ELSE
    SELECT @SickLeaveId = [Id] FROM [dbo].[myonline_tbl_LeaveTypes] WHERE [CompanyId] = @CompanyId AND [Name] = N'Sick Leave';

-- 4.3 Annual Leave
IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_LeaveTypes] WHERE [CompanyId] = @CompanyId AND [Name] = N'Annual Leave')
BEGIN
    INSERT INTO [dbo].[myonline_tbl_LeaveTypes] ([Name], [DefaultDaysPerYear], [IsActive], [CreatedAt], [CompanyId])
    VALUES (N'Annual Leave', 15, 1, GETUTCDATE(), @CompanyId);
    SET @AnnualLeaveId = SCOPE_IDENTITY();
END
ELSE
    SELECT @AnnualLeaveId = [Id] FROM [dbo].[myonline_tbl_LeaveTypes] WHERE [CompanyId] = @CompanyId AND [Name] = N'Annual Leave';

PRINT '✅ Leave types initialized (Casual, Sick, Annual).';

-- ----------------------------------------------------------------------------
-- ৫. ডেমো কোম্পানি এক্সিকিউটিভ অ্যাডমিন অ্যাকাউন্ট (myonline_tbl_Users)
-- Username: demo_admin, Password: Admin@123
-- ----------------------------------------------------------------------------
DECLARE @AdminHash NVARCHAR(500) = N'AQAAAAIAAYagAAAAEJ1XXmuxBNeJZ53ZkaurF/sPassn7Rsro5YeWDT8SUZTrYj/FpWzxyZbD34butfQVA==';

IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_Users] WHERE [Username] = 'demo_admin')
BEGIN
    INSERT INTO [dbo].[myonline_tbl_Users] (
        [Name],
        [Username],
        [PasswordHash],
        [Role],
        [PhoneNumber],
        [CreatedAt],
        [IsActive],
        [OfficeLocationId],
        [ShiftId],
        [CompanyId]
    )
    VALUES (
        N'Demo Executive Admin',
        N'demo_admin',
        @AdminHash,
        N'Admin',
        N'01711001122',
        GETUTCDATE(),
        1,
        @OfficeLocationId,
        @ShiftId,
        @CompanyId
    );

    SET @AdminUserId = SCOPE_IDENTITY();
    PRINT '✅ Demo Admin user created (Username: demo_admin, ID: ' + CAST(@AdminUserId AS NVARCHAR(10)) + ')';
END
ELSE
BEGIN
    SELECT @AdminUserId = [Id] FROM [dbo].[myonline_tbl_Users] WHERE [Username] = 'demo_admin';
    PRINT 'ℹ️ Demo Admin user exists (ID: ' + CAST(@AdminUserId AS NVARCHAR(10)) + ')';
END

-- ----------------------------------------------------------------------------
-- ৬. অ্যাডমিনের সাথে অফিস লোকেশন ম্যাপ করা (myonline_tbl_AdminOfficeLocations)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM [dbo].[myonline_tbl_AdminOfficeLocations] 
    WHERE [AdminUserId] = @AdminUserId AND [OfficeLocationId] = @OfficeLocationId
)
BEGIN
    INSERT INTO [dbo].[myonline_tbl_AdminOfficeLocations] ([AdminUserId], [OfficeLocationId], [AssignedAtUtc])
    VALUES (@AdminUserId, @OfficeLocationId, GETUTCDATE());
    PRINT '✅ Mapped Demo Head Office to demo_admin.';
END

-- ----------------------------------------------------------------------------
-- ৭. ডেমো ফিল্ড অফিসার তৈরি (myonline_tbl_Users)
-- Username: demo_officer1, Password: User@123
-- ----------------------------------------------------------------------------
DECLARE @UserHash NVARCHAR(500) = N'AQAAAAIAAYagAAAAEG3sPZ3sD/9k5mK9wV7tE3N1c7Z9X5qY7W2b1M3n4P5q6R7s8T9u0V1w2X3y4Z5A==';

IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_Users] WHERE [Username] = 'demo_officer1')
BEGIN
    INSERT INTO [dbo].[myonline_tbl_Users] (
        [Name],
        [Username],
        [PasswordHash],
        [Role],
        [PhoneNumber],
        [CreatedAt],
        [IsActive],
        [OfficeLocationId],
        [ShiftId],
        [CreatedByAdminId],
        [CompanyId]
    )
    VALUES (
        N'Demo Field Officer 1',
        N'demo_officer1',
        @UserHash,
        N'User',
        N'01811223344',
        GETUTCDATE(),
        1,
        @OfficeLocationId,
        @ShiftId,
        @AdminUserId,
        @CompanyId
    );

    SET @FieldUserId = SCOPE_IDENTITY();
    PRINT '✅ Demo Field Officer created (Username: demo_officer1, ID: ' + CAST(@FieldUserId AS NVARCHAR(10)) + ')';
END
ELSE
BEGIN
    SELECT @FieldUserId = [Id] FROM [dbo].[myonline_tbl_Users] WHERE [Username] = 'demo_officer1';
    PRINT 'ℹ️ Demo Field Officer exists (ID: ' + CAST(@FieldUserId AS NVARCHAR(10)) + ')';
END

-- ----------------------------------------------------------------------------
-- ৮. ফিল্ড অফিসারের জন্য লিভ ব্যালেন্স বরাদ্দ (myonline_tbl_LeaveBalances)
-- ----------------------------------------------------------------------------
DECLARE @CurrentYear INT = YEAR(GETUTCDATE());

IF @FieldUserId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_LeaveBalances] WHERE [UserId] = @FieldUserId AND [LeaveTypeId] = @CasualLeaveId AND [Year] = @CurrentYear)
        INSERT INTO [dbo].[myonline_tbl_LeaveBalances] ([UserId], [LeaveTypeId], [Year], [TotalDays], [UsedDays])
        VALUES (@FieldUserId, @CasualLeaveId, @CurrentYear, 10, 0);

    IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_LeaveBalances] WHERE [UserId] = @FieldUserId AND [LeaveTypeId] = @SickLeaveId AND [Year] = @CurrentYear)
        INSERT INTO [dbo].[myonline_tbl_LeaveBalances] ([UserId], [LeaveTypeId], [Year], [TotalDays], [UsedDays])
        VALUES (@FieldUserId, @SickLeaveId, @CurrentYear, 14, 0);

    IF NOT EXISTS (SELECT 1 FROM [dbo].[myonline_tbl_LeaveBalances] WHERE [UserId] = @FieldUserId AND [LeaveTypeId] = @AnnualLeaveId AND [Year] = @CurrentYear)
        INSERT INTO [dbo].[myonline_tbl_LeaveBalances] ([UserId], [LeaveTypeId], [Year], [TotalDays], [UsedDays])
        VALUES (@FieldUserId, @AnnualLeaveId, @CurrentYear, 15, 0);

    PRINT '✅ Leave balances assigned to demo_officer1 for year ' + CAST(@CurrentYear AS NVARCHAR(4));
END

PRINT '🎉 Demo Company complete setup executed successfully!';
GO
