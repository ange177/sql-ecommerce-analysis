-- ============================================================================
-- 05_monthly_trends.sql
-- Business question: "Is revenue growing, and did anything unusual happen
-- during the year that leadership should have caught sooner?"
-- Demonstrates LAG() for period-over-period growth and a running SUM()
-- window for year-to-date tracking — the two window functions a monthly
-- ops review actually needs.
-- ============================================================================

WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.Order_Date) AS Month,
        COUNT(DISTINCT o.Order_ID)      AS Orders,
        SUM(oi.Total)                   AS Net_Revenue
    FROM Orders o
    JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
    WHERE o.Status <> 'Cancelled'
    GROUP BY strftime('%Y-%m', o.Order_Date)
)
SELECT
    Month,
    Orders,
    ROUND(Net_Revenue, 2) AS Net_Revenue,
    -- LAG looks at the previous row (prior month) without a self-join.
    ROUND(Net_Revenue - LAG(Net_Revenue) OVER (ORDER BY Month), 2) AS MoM_Change,
    ROUND(
        (Net_Revenue - LAG(Net_Revenue) OVER (ORDER BY Month)) * 100.0
        / LAG(Net_Revenue) OVER (ORDER BY Month),
        1
    ) AS MoM_Pct_Change,
    -- Running total = year-to-date revenue as of this month.
    ROUND(SUM(Net_Revenue) OVER (ORDER BY Month), 2) AS YTD_Revenue
FROM monthly
ORDER BY Month;
-- Result: Jan $37,106 -> Feb $11,691, a -68.5% month-over-month collapse —
-- the single largest swing in the year, more than 2x any other month's move.
-- Revenue recovers through March-July (peaking at $43,232 in July) then
-- trends down again into Q4.
-- Actionable: this is the finding leadership should see first. A -68.5%
-- MoM drop with no visible recovery trigger warrants an incident review
-- (marketing spend pause? stockout? site issue?) and an early-warning
-- alert for any future month that drops more than ~25% MoM.
