/* ============================================================
   File: database/01_CreateDatabase.sql
   LiveTrackingDB - Database Creation Script
   Server: NASA-PC\MSSQLSERVER2019
   ============================================================ */
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'LiveTrackingDB')
BEGIN
    CREATE DATABASE LiveTrackingDB;
END
GO

ALTER DATABASE LiveTrackingDB SET RECOVERY SIMPLE;
GO

ALTER DATABASE LiveTrackingDB SET READ_COMMITTED_SNAPSHOT ON;
GO
