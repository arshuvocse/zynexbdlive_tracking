/* ============================================================
   Seed an initial Admin user.
   NOTE: PasswordHash below is a BCrypt hash for password "Admin@123".
   Generated with BCrypt.Net-Next (work factor 11).
   Replace via the API's user-creation endpoint in production.
   ============================================================ */
USE LiveTrackingDB;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.myonline_tbl_Users WHERE Username = N'admin')
BEGIN
    INSERT INTO dbo.myonline_tbl_Users (Name, Username, PasswordHash, Role, IsActive)
    VALUES
    (
        N'System Administrator',
        N'admin',
        N'$2a$11$3euPcmQFCiblsZeEu5s7p.9wVsZeS/AoEg1UZ9YEfKgOK5Xy8oXpu', -- Admin@123
        N'Admin',
        1
    );
END
GO
