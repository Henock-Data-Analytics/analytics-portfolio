-- =====================================================================
-- Summit Rewards & Resorts -- Week 2 Lab Solutions
-- Run database-schema.sql and sample-data.sql first.
-- =====================================================================


-- =====================================================================
-- 23. Rank customers within each state by total lifetime spend
--     using a window function.
-- =====================================================================
-- Business question: Who are our top-spending loyalty members in each
-- state, so regional marketing teams know who to prioritize for
-- state-level offers and events?

WITH CustomerLifetimeSpend AS (
    SELECT
        c.CustomerID,
        c.FullName,
        c.State,
        SUM(v.AmountSpent) AS LifetimeSpend
    FROM dbo.Customers c
    JOIN dbo.Visits v ON v.CustomerID = c.CustomerID
    GROUP BY c.CustomerID, c.FullName, c.State
)
SELECT
    State,
    FullName,
    LifetimeSpend,
    RANK() OVER (
        PARTITION BY State
        ORDER BY LifetimeSpend DESC
    ) AS StateSpendRank
FROM CustomerLifetimeSpend
ORDER BY State, StateSpendRank;

-- How this derives its answer: the CTE (CustomerLifetimeSpend) first
-- collapses every visit into one lifetime total per customer, alongside
-- their state. The outer query then applies RANK() with
-- PARTITION BY State, which restarts the ranking count at 1 for every
-- new state -- so a customer in FL and a customer in NV can both be
-- rank 1 within their own state, rather than competing against the
-- entire customer base nationally.


-- =====================================================================
-- 24. Build a CTE that finds each customer's most recent visit date.
-- =====================================================================
-- Business question: When did each customer last visit, so we can
-- identify members who haven't been back in a while (churn risk)?

WITH LastVisit AS (
    SELECT
        CustomerID,
        MAX(VisitDate) AS MostRecentVisit
    FROM dbo.Visits
    GROUP BY CustomerID
)
SELECT
    c.CustomerID,
    c.FullName,
    c.Tier,
    lv.MostRecentVisit,
    DATEDIFF(DAY, lv.MostRecentVisit, GETDATE()) AS DaysSinceLastVisit
FROM dbo.Customers c
JOIN LastVisit lv ON lv.CustomerID = c.CustomerID
ORDER BY DaysSinceLastVisit DESC;

-- How this derives its answer: the CTE groups every visit by
-- CustomerID and keeps only the MAX(VisitDate) -- the single latest
-- date -- collapsing potentially dozens of visits per customer down to
-- one row each. Joining that back to Customers attaches the name and
-- tier. DATEDIFF(DAY, ..., GETDATE()) then measures how many days have
-- passed since that last visit -- sorting DESC surfaces your
-- longest-dormant, highest churn-risk members at the top.


-- =====================================================================
-- 25. Create a recursive CTE that lists a date range (e.g., every day
--     in Q1) for a campaign calendar.
-- =====================================================================
-- Business question: We need a full calendar of every day in Q1 to
-- schedule and track daily campaign touchpoints, even on days with no
-- activity yet.

WITH DateRange AS (
    -- Anchor member: the first day of the range
    SELECT CAST('2026-01-01' AS DATE) AS CalendarDate

    UNION ALL

    -- Recursive member: keeps adding one day, referencing itself
    SELECT DATEADD(DAY, 1, CalendarDate)
    FROM DateRange
    WHERE CalendarDate < '2026-03-31'
)
SELECT CalendarDate
FROM DateRange
OPTION (MAXRECURSION 100); -- Q1 is ~90 days; default limit is 100

-- How this derives its answer: the "anchor member" (the first SELECT)
-- produces the starting row: January 1st. The "recursive member" (the
-- SELECT after UNION ALL) then references DateRange -- the CTE's own
-- name -- inside its own definition, taking the most recently produced
-- date and adding one day to it with DATEADD. SQL Server repeats this
-- step automatically, feeding each new row back in as the next
-- iteration's input, until the WHERE clause stops it at March 31st.
-- MAXRECURSION guards against an infinite loop if the stop condition
-- were ever written incorrectly.


-- =====================================================================
-- 26. Create a view, vw_MonthlyRevenue, summarizing revenue by month
--     and venue.
-- =====================================================================
-- Business question: What does our revenue trend look like month over
-- month, broken out by venue, for the monthly executive report?

CREATE OR ALTER VIEW dbo.vw_MonthlyRevenue AS
SELECT
    FORMAT(v.VisitDate, 'yyyy-MM') AS RevenueMonth,
    v.Venue,
    SUM(v.AmountSpent) AS TotalRevenue,
    COUNT(*) AS VisitCount,
    AVG(v.AmountSpent) AS AvgSpendPerVisit
FROM dbo.Visits v
GROUP BY FORMAT(v.VisitDate, 'yyyy-MM'), v.Venue;
GO

-- Query the view exactly like a table:
SELECT *
FROM dbo.vw_MonthlyRevenue
ORDER BY RevenueMonth, Venue;

-- How this derives its answer: CREATE VIEW stores this SELECT
-- statement under the name vw_MonthlyRevenue -- no data is copied or
-- cached. FORMAT(VisitDate, 'yyyy-MM') converts each visit's full date
-- (e.g., 2025-03-17) down to just its year-month (2025-03), which is
-- what GROUP BY uses to bucket every visit into its correct month.
-- Adding Venue to the GROUP BY means each month gets one row per venue
-- rather than one blended total, which is what lets the executive
-- report break revenue out by both dimensions at once. Because it's a
-- view, next month's data appears automatically the next time someone
-- queries it -- no maintenance required.


-- =====================================================================
-- 27. Write a stored procedure, usp_CustomerSegment, that classifies
--     a customer as High/Medium/Low value based on lifetime spend
--     thresholds you define.
-- =====================================================================
-- Business question: Given a customer ID, what value segment do they
-- fall into, so the marketing team can decide which offer tier to send
-- them?
--
-- Thresholds used here (based on this dataset's spend distribution):
--   High   : lifetime spend >= $2,000
--   Medium : lifetime spend >= $500 and < $2,000
--   Low    : lifetime spend < $500

CREATE OR ALTER PROCEDURE dbo.usp_CustomerSegment
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LifetimeSpend DECIMAL(10,2);

    SELECT @LifetimeSpend = SUM(v.AmountSpent)
    FROM dbo.Visits v
    WHERE v.CustomerID = @CustomerID;

    SELECT
        c.CustomerID,
        c.FullName,
        c.Tier,
        ISNULL(@LifetimeSpend, 0) AS LifetimeSpend,
        CASE
            WHEN @LifetimeSpend >= 2000 THEN 'High'
            WHEN @LifetimeSpend >= 500  THEN 'Medium'
            WHEN @LifetimeSpend IS NULL THEN 'No Visits Yet'
            ELSE 'Low'
        END AS ValueSegment
    FROM dbo.Customers c
    WHERE c.CustomerID = @CustomerID;
END;
GO

-- Example calls:
EXEC dbo.usp_CustomerSegment @CustomerID = 1;
EXEC dbo.usp_CustomerSegment @CustomerID = 12;
EXEC dbo.usp_CustomerSegment @CustomerID = 45;

-- How this derives its answer: the procedure first calculates
-- @LifetimeSpend by summing every visit's AmountSpent for the one
-- @CustomerID passed in -- this happens once, stored in a variable,
-- rather than recalculating it inside the CASE statement three times.
-- The CASE WHEN expression then checks that single number against the
-- thresholds top-down: it hits the first TRUE condition and stops, so
-- ordering High before Medium before Low matters -- if Low were
-- checked first with a "< 2000" condition, every Medium customer would
-- incorrectly get labeled Low. ISNULL handles the edge case of a
-- customer with zero visits, where SUM() would otherwise return NULL
-- instead of 0.
