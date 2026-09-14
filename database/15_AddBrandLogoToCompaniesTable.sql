-- Migration: 15_AddBrandLogoToCompaniesTable.sql
-- Description: Adds BrandLogo column to myonline_tbl_Companies table if it doesn't already exist.

USE [WorkForce_DB];
GO

IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'myonline_tbl_Companies' 
      AND COLUMN_NAME = 'BrandLogo'
)
BEGIN
    ALTER TABLE [dbo].[myonline_tbl_Companies]
    ADD [BrandLogo] NVARCHAR(500) NULL;
    PRINT 'Added BrandLogo column to myonline_tbl_Companies.';
END
ELSE
BEGIN
    PRINT 'BrandLogo column already exists in myonline_tbl_Companies.';
END
GO
