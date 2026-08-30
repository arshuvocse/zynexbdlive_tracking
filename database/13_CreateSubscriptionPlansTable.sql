-- ==========================================================
-- 13_CreateSubscriptionPlansTable.sql
-- Creates SubscriptionPlans table with dynamic discount tiers
-- ==========================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SubscriptionPlans')
BEGIN
    CREATE TABLE SubscriptionPlans (
        PlanId INT IDENTITY(1,1) PRIMARY KEY,
        PlanCode NVARCHAR(50) NOT NULL UNIQUE,
        TierName NVARCHAR(50) NOT NULL,
        Title NVARCHAR(100) NOT NULL,
        TitleBn NVARCHAR(100) NOT NULL,
        DurationMonths INT NOT NULL,
        Price DECIMAL(18,2) NOT NULL,
        OriginalPrice DECIMAL(18,2) NOT NULL,
        DiscountPercent INT NOT NULL DEFAULT 0,
        DiscountText NVARCHAR(100) NULL,
        BadgeText NVARCHAR(50) NULL,
        BadgeTextBn NVARCHAR(50) NULL,
        FeaturesJson NVARCHAR(MAX) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        DisplayOrder INT NOT NULL DEFAULT 0,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE()
    );
END
GO

-- Seed / Upsert Subscription Plans
IF NOT EXISTS (SELECT 1 FROM SubscriptionPlans WHERE PlanCode = 'REGULAR_1M')
BEGIN
    INSERT INTO SubscriptionPlans (PlanCode, TierName, Title, TitleBn, DurationMonths, Price, OriginalPrice, DiscountPercent, DiscountText, BadgeText, BadgeTextBn, FeaturesJson, IsActive, DisplayOrder)
    VALUES (
        'REGULAR_1M',
        'Regular',
        '1 Month Regular Plan',
        '১ মাস রেগুলার প্ল্যান',
        1,
        1000.00,
        1000.00,
        0,
        'Regular Price',
        'Starter',
        'শুরু করার জন্য',
        '["Live GPS Tracking & Route History","Real-time Attendance & Geofencing","Customer & Visit Logging","Standard Support"]',
        1,
        1
    );
END

IF NOT EXISTS (SELECT 1 FROM SubscriptionPlans WHERE PlanCode = 'SILVER_3M')
BEGIN
    INSERT INTO SubscriptionPlans (PlanCode, TierName, Title, TitleBn, DurationMonths, Price, OriginalPrice, DiscountPercent, DiscountText, BadgeText, BadgeTextBn, FeaturesJson, IsActive, DisplayOrder)
    VALUES (
        'SILVER_3M',
        'Silver',
        '3 Months Silver Pack',
        '৩ মাস সিলভার প্যাক',
        3,
        2500.00,
        3000.00,
        17,
        'Save ৳500 (17% OFF)',
        'Popular Offer',
        '🔥 আকর্ষণীয় অফার (জনপ্রিয়)',
        '["All Regular Features Included","3 Months Uninterrupted Access","Save ৳500 Total Discount","Priority Support Response","Daily Activity & Performance Reports"]',
        1,
        2
    );
END

IF NOT EXISTS (SELECT 1 FROM SubscriptionPlans WHERE PlanCode = 'GOLD_6M')
BEGIN
    INSERT INTO SubscriptionPlans (PlanCode, TierName, Title, TitleBn, DurationMonths, Price, OriginalPrice, DiscountPercent, DiscountText, BadgeText, BadgeTextBn, FeaturesJson, IsActive, DisplayOrder)
    VALUES (
        'GOLD_6M',
        'Gold',
        '6 Months Gold Pack',
        '৬ মাস গোল্ড প্যাক',
        6,
        4500.00,
        6000.00,
        25,
        'Save ৳1,500 (25% OFF)',
        'Best Value',
        '⭐ সেরা সাশ্রয়ী (বেস্ট ভ্যালু)',
        '["All Silver Features Included","6 Months Guaranteed Service","Save ৳1,500 Mega Discount","Real-time SignalR Alerts","VIP Account Manager"]',
        1,
        3
    );
END

IF NOT EXISTS (SELECT 1 FROM SubscriptionPlans WHERE PlanCode = 'PLATINUM_12M')
BEGIN
    INSERT INTO SubscriptionPlans (PlanCode, TierName, Title, TitleBn, DurationMonths, Price, OriginalPrice, DiscountPercent, DiscountText, BadgeText, BadgeTextBn, FeaturesJson, IsActive, DisplayOrder)
    VALUES (
        'PLATINUM_12M',
        'Platinum',
        '1 Year Platinum Super Saver',
        '১ বছর প্ল্যাটিনাম সুপার সেভার',
        12,
        8000.00,
        12000.00,
        33,
        'Save ৳4,000 (33% OFF)',
        'Mega Saver',
        '💎 মেগা সেভার (সর্বোচ্চ ছাড়)',
        '["Full Year 365 Days Access","Save ৳4,000 Huge Discount","Unlimited Employees Support","24/7 Dedicated Priority Hotline","Zero Interruption Guarantee"]',
        1,
        4
    );
END
GO
