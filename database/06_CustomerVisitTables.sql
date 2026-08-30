/* ============================================================
   File: database/06_CustomerVisitTables.sql
   LiveTrackingDB - Customer & Customer Visits Management
   ============================================================ */
USE LiveTrackingDB;
GO

/* ------------------------------------------------------------
   1. dbo.Customers
   ------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.Customers', N'U') IS NOT NULL
    DROP TABLE dbo.Customers;
GO

CREATE TABLE dbo.Customers
(
    CustomerId      INT IDENTITY(1,1)   NOT NULL PRIMARY KEY,
    Name            NVARCHAR(150)       NOT NULL,
    Mobile          NVARCHAR(30)        NOT NULL,
    Address         NVARCHAR(300)       NOT NULL,
    Latitude        FLOAT               NOT NULL,
    Longitude       FLOAT               NOT NULL,
    Remarks         NVARCHAR(500)       NULL,
    CreatedDate     DATETIME2           NOT NULL CONSTRAINT DF_Customers_CreatedDate DEFAULT (SYSUTCDATETIME()),
    IsActive        BIT                 NOT NULL CONSTRAINT DF_Customers_IsActive DEFAULT (1),
    CreatedByUserId INT                 NULL
);
GO

CREATE NONCLUSTERED INDEX IX_Customers_Name_Mobile ON dbo.Customers (Name, Mobile);
GO

/* ------------------------------------------------------------
   2. dbo.CustomerVisits
   ------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.CustomerVisits', N'U') IS NOT NULL
    DROP TABLE dbo.CustomerVisits;
GO

CREATE TABLE dbo.CustomerVisits
(
    VisitId              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerId           INT                  NOT NULL CONSTRAINT FK_CustomerVisits_Customers REFERENCES dbo.Customers(CustomerId) ON DELETE CASCADE,
    UserId               INT                  NOT NULL,
    VisitDate            DATETIME2            NOT NULL CONSTRAINT DF_CustomerVisits_VisitDate DEFAULT (SYSUTCDATETIME()),
    Latitude             FLOAT                NOT NULL,
    Longitude            FLOAT                NOT NULL,
    Remarks              NVARCHAR(500)        NULL,
    VisitStatus          NVARCHAR(50)         NOT NULL CONSTRAINT DF_CustomerVisits_VisitStatus DEFAULT (N'Completed'),
    NextFollowUpDate     DATETIME2            NULL,
    ShopPhotoPath        NVARCHAR(400)        NULL,
    IsFollowUpCompleted  BIT                  NOT NULL CONSTRAINT DF_CustomerVisits_IsFollowUpCompleted DEFAULT (0)
);
GO

CREATE NONCLUSTERED INDEX IX_CustomerVisits_UserId_VisitDate ON dbo.CustomerVisits (UserId, VisitDate DESC);
CREATE NONCLUSTERED INDEX IX_CustomerVisits_NextFollowUpDate ON dbo.CustomerVisits (NextFollowUpDate);
GO
