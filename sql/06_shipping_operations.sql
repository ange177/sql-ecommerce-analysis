-- ============================================================================
-- 06_shipping_operations.sql
-- Business question: "Are customers getting what they pay for on shipping
-- speed, and which ship mode is most/least used?"
-- ============================================================================

SELECT
    o.Ship_Mode,
    COUNT(DISTINCT o.Order_ID)                                              AS Orders,
    ROUND(COUNT(DISTINCT o.Order_ID) * 100.0 / (SELECT COUNT(*) FROM Orders), 1) AS Pct_Of_Orders,
    -- Julianday subtraction gives fractional days between order and ship date.
    ROUND(AVG(julianday(o.Ship_Date) - julianday(o.Order_Date)), 1)         AS Avg_Days_To_Ship,
    ROUND(SUM(oi.Total) / COUNT(DISTINCT o.Order_ID), 2)                    AS Avg_Order_Value
FROM Orders o
JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
WHERE o.Status <> 'Cancelled'
GROUP BY o.Ship_Mode
ORDER BY Orders DESC;
-- Result:
--   Standard  47.0% of orders | 3.6 days to ship | $824.79 AOV
--   Express   27.2% of orders | 3.5 days to ship | $666.17 AOV
--   Next Day  15.8% of orders | 3.4 days to ship | $763.89 AOV
--   Ground     7.0% of orders | 3.1 days to ship | $646.68 AOV
--
-- Actionable — this is a real operational red flag, not a technicality:
-- "Next Day" dispatches in 3.4 days on average, statistically indistinguishable
-- from Standard (3.6 days) and Express (3.5 days). Customers paying a premium
-- for expedited shipping are not receiving a materially faster dispatch.
-- Either the fulfillment process for premium tiers needs fixing, or the
-- premium pricing needs to be re-justified/relabeled — as-is it's a customer
-- trust and SLA-compliance risk.
