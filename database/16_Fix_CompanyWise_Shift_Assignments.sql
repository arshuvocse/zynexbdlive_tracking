-- ==========================================================
-- Migration 16: Fix Company-Wise Shift Assignments for Existing Users
-- ==========================================================

-- 1. Ensure all active companies have their active default shift assigned to employees if ShiftId is NULL
UPDATE u
SET u.ShiftId = s.ShiftId
FROM [dbo].[myonline_tbl_Users] u
INNER JOIN [dbo].[myonline_tbl_Shifts] s ON s.CompanyId = u.CompanyId AND s.IsDefault = 1 AND s.IsActive = 1
WHERE u.ShiftId IS NULL AND u.CompanyId IS NOT NULL;

-- 2. Fallback: if no default shift marked, assign any active shift for that company
UPDATE u
SET u.ShiftId = s.ShiftId
FROM [dbo].[myonline_tbl_Users] u
CROSS APPLY (
    SELECT TOP 1 ShiftId 
    FROM [dbo].[myonline_tbl_Shifts] 
    WHERE CompanyId = u.CompanyId AND IsActive = 1
    ORDER BY IsDefault DESC, ShiftId ASC
) s
WHERE u.ShiftId IS NULL AND u.CompanyId IS NOT NULL;

PRINT '✅ Successfully updated ShiftId for existing users based on company shifts.';
