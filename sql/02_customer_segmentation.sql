-- ============================================================================
-- 02_customer_segmentation.sql
-- Business question: "Which customer segments and which individual customers
-- should marketing and account management prioritize?"
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Segment-level revenue: are we over-indexed on one customer type?
-- ----------------------------------------------------------------------------
SELECT
    c.Segment,
    COUNT(DISTINCT c.Customer_ID)                              AS Customers,
    ROUND(SUM(oi.Total), 2)                                    AS Net_Revenue,
    ROUND(SUM(oi.Total) / COUNT(DISTINCT c.Customer_ID), 2)    AS Revenue_Per_Customer
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
WHERE o.Status <> 'Cancelled'   -- exclude unfulfilled orders from earned revenue
GROUP BY c.Segment
ORDER BY Net_Revenue DESC;
-- Result: Consumer 67 cust / $172,254 ($2,571/ea) | Corporate 53 cust / $126,721 ($2,391/ea)
--         Home Office 25 cust / $68,431 ($2,737/ea) — smallest base, highest revenue/customer


-- ----------------------------------------------------------------------------
-- Customer value tiers via a CTE + CASE: turns a continuous spend number into
-- an actionable tier a CRM/loyalty program can key off of. Thresholds are
-- picked from the actual spend distribution (roughly quartile-sized groups),
-- not arbitrary round numbers.
-- ----------------------------------------------------------------------------
WITH customer_spend AS (
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        c.Segment,
        SUM(oi.Total) AS Total_Spend
    FROM Customers c
    JOIN Orders o ON c.Customer_ID = o.Customer_ID
    JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
    WHERE o.Status <> 'Cancelled'
    GROUP BY c.Customer_ID, c.Customer_Name, c.Segment
)
SELECT
    CASE
        WHEN Total_Spend >= 4000 THEN '1 - High Value ($4K+)'
        WHEN Total_Spend >= 2000 THEN '2 - Mid Value ($2-4K)'
        WHEN Total_Spend >= 800  THEN '3 - Low Value ($800-2K)'
        ELSE '4 - At Risk (<$800)'
    END AS Customer_Tier,
    COUNT(*)                                                            AS Customers,
    ROUND(SUM(Total_Spend), 2)                                          AS Tier_Revenue,
    ROUND(SUM(Total_Spend) * 100.0 / (SELECT SUM(Total_Spend) FROM customer_spend), 1) AS Pct_Of_Revenue
FROM customer_spend
GROUP BY Customer_Tier
ORDER BY Customer_Tier;
-- Result: High Value (31 cust) = 49.4% of revenue | At Risk (27 cust) = only 3.0%
-- Actionable: a VIP retention program for the 31 High Value customers protects
-- essentially half the business; the 27 At-Risk customers are cheap to win back
-- (small basket) but numerous enough to matter for a re-engagement campaign.


-- ----------------------------------------------------------------------------
-- Repeat purchase rate: are we building a loyal base or living order-to-order?
-- ----------------------------------------------------------------------------
WITH order_counts AS (
    SELECT Customer_ID, COUNT(DISTINCT Order_ID) AS Order_Count
    FROM Orders
    GROUP BY Customer_ID
)
SELECT
    SUM(CASE WHEN Order_Count = 1 THEN 1 ELSE 0 END)                          AS One_Time_Customers,
    SUM(CASE WHEN Order_Count > 1 THEN 1 ELSE 0 END)                          AS Repeat_Customers,
    ROUND(SUM(CASE WHEN Order_Count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Repeat_Purchase_Rate_Pct
FROM order_counts;
-- Result: 126 of 145 customers (86.9%) are repeat buyers — retention is a
-- genuine strength; the acquisition funnel isn't the bottleneck, so growth
-- initiatives should lean toward increasing basket size/frequency, not just
-- customer acquisition spend.
