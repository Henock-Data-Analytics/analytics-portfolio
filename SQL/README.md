# Basics
Some Sql for customer segmentation and exploratory data analysis.

# CRM Analytics SQL Project — Summit Rewards & Resorts

A SQL portfolio project built against a simulated CRM database for a fictional
hospitality and casino loyalty program, Summit Rewards & Resorts. Covers core
SQL refreshers, window functions, CTEs (including recursive CTEs), views, and
stored procedures.

## Files in This Folder

| File | Purpose |
|---|---|
| `database-schema.sql` | `CREATE TABLE` scripts for `Customers`, `Visits`, `Campaigns`, and `CampaignResponses`, plus supporting indexes |
| `sample-data.sql` | Realistic sample rows — 60 customers, ~450 visits, 6 campaigns, and 200+ campaign responses |
| `lab-solutions.sql` | Commented answers to all five lab questions below |
| `README.md` | This write-up |

**Setup order:** run `database-schema.sql` first, then `sample-data.sql`, then `lab-solutions.sql`.

## Business Questions Each Query Answers

**1. State-level customer ranking (window function)**
*"Who are our top-spending loyalty members in each state?"*
Uses `RANK() OVER (PARTITION BY State ORDER BY LifetimeSpend DESC)` on top of a
CTE that totals each customer's lifetime spend, so regional marketing teams can
identify who to prioritize for state-specific offers and events.

**2. Most recent visit per customer (CTE)**
*"When did each customer last visit, so we can flag churn risk?"*
A CTE collapses every visit down to a single `MAX(VisitDate)` per customer,
then joins back to `Customers` and calculates days since that last visit —
surfacing the most dormant, highest-risk members first.

**3. Q1 campaign calendar (recursive CTE)**
*"We need a full calendar of every day in Q1 to schedule daily campaign
touchpoints."*
A recursive CTE starts at January 1st and repeatedly adds one day to itself
until it reaches March 31st, generating a complete date list even for days
with no campaign activity yet — useful for building a calendar table or
scheduling grid.

**4. Monthly revenue by venue (view)**
*"What does revenue look like month over month, broken out by venue, for the
executive report?"*
`vw_MonthlyRevenue` groups every visit by year-month and venue, so it always
reflects current data with no manual refresh — querying it is as simple as
querying a table.

**5. Customer value segmentation (stored procedure)**
*"Given a customer ID, what value segment do they fall into, so marketing
knows which offer tier to send them?"*
`usp_CustomerSegment` takes a `@CustomerID` parameter, totals their lifetime
spend, and classifies them as **High** (≥ $2,000), **Medium** ($500–$2,000),
or **Low** (< $500) using a `CASE` expression — reusable for any customer
without rewriting the query.

## Schema Overview

```
Customers ----1:N----> Visits
Customers ----1:N----> CampaignResponses <----N:1---- Campaigns
```

| Table | Key Columns |
|---|---|
| `Customers` | CustomerID (PK), FullName, Tier, JoinDate, State |
| `Visits` | VisitID (PK), CustomerID (FK), VisitDate, Venue, AmountSpent |
| `Campaigns` | CampaignID (PK), CampaignName, Channel, StartDate |
| `CampaignResponses` | ResponseID (PK), CampaignID (FK), CustomerID (FK), Responded, Redeemed |

