-- ==========================================================
-- Insert Script: App Version Update v1.3 (VersionCode 4)
-- Table: myonline_tbl_AppVersions
-- Database: EProgramIntegration_DB / LiveTrackingDb
-- ==========================================================

USE WorkForce_DB;
GO

-- ১. পূর্ববর্তী পুরোনো অ্যাক্টিভ ভার্সন ডিঅ্যাক্টিভেট করা (Optional কিন্তু ভালো প্র্যাকটিস)
UPDATE dbo.myonline_tbl_AppVersions 
SET IsActive = 0 
WHERE Platform = 'Android' AND VersionCode < 4;

-- ২. নতুন ভার্সন ১.৩ (VersionCode 4) ইনসার্ট করা
-- (ক) গ্লোবাল রিলিজ (সব কোম্পানির জন্য প্রযোজ্য CompanyId = NULL)
IF NOT EXISTS (SELECT 1 FROM dbo.myonline_tbl_AppVersions WHERE Platform = 'Android' AND VersionCode = 4 AND CompanyId IS NULL)
BEGIN
    INSERT INTO dbo.myonline_tbl_AppVersions 
    (
        Platform,
        VersionCode,
        VersionName,
        MinVersionCode,
        IsForceUpdate,
        DownloadUrl,
        Title,
        ReleaseNotes,
        IsActive,
        CompanyId,
        CreatedAt
    )
    VALUES 
    (
        'Android',
        4,
        '1.3',
        3, -- MinVersionCode: ৩ এর নিচের ভার্সনগুলোকে আপডেট করতে বাধ্য করবে
        0, -- IsForceUpdate: ১ দিলে জোরপূর্বক আপডেট বাধ্যতামূলক করবে, ০ দিলে ইউজার স্কিপ করতে পারবে
        'http://217.216.39.94:82/downloads/app-release-v1.3.apk', -- আপনার ডাউনলোড URL
        'Smart Workforce v1.3 Update Available',
        N'• ইউজার ড্যাশবোর্ডে Pull-to-Refresh অপশন যোগ করা হয়েছে।
• শিফট চলাকালীন ১০ মিনিট অফলাইনে থাকলে অ্যাডমিন অটোমেটিক অ্যালার্ট পাবেন।
• লাইভ লোকেশন পিন এবং মার্কারের অন/অফ স্ট্যাটাস উন্নত করা হয়েছে।
• পারফরম্যান্স এবং ব্যাকগ্রাউন্ড ট্র্যাকিংয়ের স্থায়িত্ব বৃদ্ধি করা হয়েছে।',
        1,
        NULL,
        SYSUTCDATETIME()
    );

    PRINT 'Global Version 1.3 (Code 4) inserted successfully.';
END
ELSE
BEGIN
    PRINT 'Version 1.3 (Code 4) already exists in myonline_tbl_AppVersions.';
END
GO

-- ৩. ভেরিফাই করার জন্য সিলেক্ট কুয়েরি
SELECT TOP 5 
    Id, 
    Platform, 
    VersionCode, 
    VersionName, 
    MinVersionCode, 
    IsForceUpdate, 
    IsActive, 
    DownloadUrl, 
    Title, 
    CreatedAt 
FROM dbo.myonline_tbl_AppVersions 
ORDER BY VersionCode DESC, Id DESC;
GO
