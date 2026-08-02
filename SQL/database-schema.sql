-- =====================================================================
-- Summit Rewards & Resorts -- CRM Analytics Sample Database
-- Generated for the Modern Analytics Engineering & CRM Analytics Bootcamp
-- Compatible with: SQL Server / Azure SQL (T-SQL)
-- =====================================================================

-- Uncomment to create and use a dedicated database:
-- CREATE DATABASE SummitRewards;
-- GO
-- USE SummitRewards;
-- GO

-- =====================================================================
-- 1. SCHEMA
-- =====================================================================

IF OBJECT_ID('dbo.CampaignResponses', 'U') IS NOT NULL DROP TABLE dbo.CampaignResponses;
IF OBJECT_ID('dbo.Visits', 'U') IS NOT NULL DROP TABLE dbo.Visits;
IF OBJECT_ID('dbo.Campaigns', 'U') IS NOT NULL DROP TABLE dbo.Campaigns;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
GO

CREATE TABLE dbo.Customers (
    CustomerID   INT             NOT NULL PRIMARY KEY,
    FullName     NVARCHAR(100)   NOT NULL,
    Tier         VARCHAR(20)     NOT NULL,
    JoinDate     DATE            NOT NULL,
    State        CHAR(2)         NOT NULL
);
GO

CREATE TABLE dbo.Visits (
    VisitID      INT             NOT NULL PRIMARY KEY,
    CustomerID   INT             NOT NULL,
    VisitDate    DATE            NOT NULL,
    Venue        VARCHAR(50)     NOT NULL,
    AmountSpent  DECIMAL(10,2)   NOT NULL,
    CONSTRAINT FK_Visits_Customers FOREIGN KEY (CustomerID)
        REFERENCES dbo.Customers (CustomerID)
);
GO

CREATE TABLE dbo.Campaigns (
    CampaignID    INT            NOT NULL PRIMARY KEY,
    CampaignName  VARCHAR(100)   NOT NULL,
    Channel       VARCHAR(30)    NOT NULL,
    StartDate     DATE           NOT NULL
);
GO

CREATE TABLE dbo.CampaignResponses (
    ResponseID   INT             NOT NULL PRIMARY KEY,
    CampaignID   INT             NOT NULL,
    CustomerID   INT             NOT NULL,
    Responded    BIT             NOT NULL,
    Redeemed     BIT             NOT NULL,
    CONSTRAINT FK_Responses_Campaigns FOREIGN KEY (CampaignID)
        REFERENCES dbo.Campaigns (CampaignID),
    CONSTRAINT FK_Responses_Customers FOREIGN KEY (CustomerID)
        REFERENCES dbo.Customers (CustomerID)
);
GO

CREATE INDEX IX_Visits_CustomerID ON dbo.Visits (CustomerID);
CREATE INDEX IX_Responses_CampaignID ON dbo.CampaignResponses (CampaignID);
CREATE INDEX IX_Responses_CustomerID ON dbo.CampaignResponses (CustomerID);
GO

-- =====================================================================
