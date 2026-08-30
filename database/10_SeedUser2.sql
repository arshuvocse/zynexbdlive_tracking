/* ============================================================
   File: database/10_SeedUser2.sql
   Seed a regular field-user account for testing.
   NOTE: PasswordHash below is a real BCrypt hash for password
   "User@123" (work factor 11), generated with BCrypt.Net-Next
   and verified to round-trip against PasswordHasherService.Verify().
   Change the username/password/office assignment as needed.
   ============================================================ */
USE LiveTrackingDB;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.myonline_tbl_Users WHERE Username = N'user2')
BEGIN
    INSERT INTO dbo.myonline_tbl_Users (Name, Username, PasswordHash, Role, IsActive, OfficeLocationId)
    VALUES
    (
        N'Field User Two',
        N'user2',
        N'$2a$11$t4vWAEB8CiNFETroTXiVPOLjeQg4O.ieqe1cDWxHU1Z2FQ/cNj.li', -- User@123
        N'User',
        1,
        NULL
    );
END
GO
