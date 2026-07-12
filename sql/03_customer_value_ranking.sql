-- ============================================================================
-- 03_customer_value_ranking.sql
-- Business question: "Who is our #1 account in each segment, and how
-- concentrated is our revenue among a handful of customers?"
-- Demonstrates window functions (RANK, NTILE, running SUM), the kind of
-- ranking/concentration analysis a spreadsheet VLOOKUP can't do cleanly.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Top account per segment: RANK() partitions the ranking so each segment gets
-- its own #1, instead of one global top-10 list dominated by big segments.
-- ----------------------------------------------------------------------------
WITH customer_spend AS (
    SELECT
        c.Segment,
        c.Customer_Name,
        SUM(oi.Total) AS Total_Spend
    FROM Customers c
    JOIN Orders o ON c.Customer_ID = o.Customer_ID
    JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
    WHERE o.Status <> 'Cancelled'
    GROUP BY c.Segment, c.Customer_Name
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY Segment ORDER BY Total_Spend DESC) AS Rank_In_Segment
    FROM customer_spend
)
SELECT Segment, Customer_Name, ROUND(Total_Spend, 2) AS Total_Spend
FROM ranked
WHERE Rank_In_Segment = 1
ORDER BY Total_Spend DESC;
-- Result: Consumer -> Customer_42 ($14,321) | Home Office -> Customer_90 ($8,503)
--         Corporate -> Customer_93 ($8,337)
-- Actionable: these three accounts are natural candidates for a named account
-- manager / key-account program rather than generic email marketing.


-- ----------------------------------------------------------------------------
-- Revenue concentration via NTILE: split customers into 4 equal-sized groups
-- by spend to see how much of the business rides on the top quartile.
-- ----------------------------------------------------------------------------
WITH customer_spend AS (
    SELECT
        c.Customer_ID,
        SUM(oi.Total) AS Total_Spend
    FROM Customers c
    JOIN Orders o ON c.Customer_ID = o.Customer_ID
    JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
    WHERE o.Status <> 'Cancelled'
    GROUP BY c.Customer_ID
),
quartiled AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY Total_Spend DESC) AS Spend_Quartile
    FROM customer_spend
)
SELECT
    Spend_Quartile,
    COUNT(*)                                                        AS Customers,
    ROUND(SUM(Total_Spend), 2)                                      AS Quartile_Revenue,
    ROUND(SUM(Total_Spend) * 100.0 / (SELECT SUM(Total_Spend) FROM customer_spend), 1) AS Pct_Of_Revenue,
    -- Running total lets a stakeholder read straight off the row where
    -- cumulative revenue crosses a threshold (e.g. "top 2 quartiles = X%").
    ROUND(SUM(SUM(Total_Spend)) OVER (ORDER BY Spend_Quartile), 2)  AS Cumulative_Revenue
FROM quartiled
GROUP BY Spend_Quartile
ORDER BY Spend_Quartile;
-- Result: Quartile 1 (top 25%, 37 customers) drives 55.5% of net revenue
-- ($204,072 of $367,406), confirming the concentration flagged in
-- 02_customer_segmentation.sql and quantifying the downside risk if a
-- handful of top accounts churn.
