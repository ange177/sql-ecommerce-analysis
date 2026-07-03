-- ============================================================================
-- 01_revenue_kpis.sql
-- Business question: "What's the top-line health of the business right now?"
-- A stakeholder opening this dashboard cares about recognized revenue (money
-- actually earned), not gross bookings that include cancelled orders — so
-- every KPI below is split to make that distinction explicit rather than
-- silently inflating the headline number.
-- ============================================================================

SELECT
    COUNT(DISTINCT o.Order_ID)                                              AS Total_Orders,
    COUNT(DISTINCT o.Customer_ID)                                           AS Active_Customers,
    ROUND(SUM(oi.Subtotal), 2)                                              AS Gross_Revenue,
    ROUND(SUM(oi.Discount_Amount), 2)                                       AS Total_Discounts_Given,
    -- Recognized revenue excludes Cancelled orders: they were never fulfilled,
    -- so counting them would overstate what the business actually earned.
    ROUND(SUM(CASE WHEN o.Status <> 'Cancelled' THEN oi.Total ELSE 0 END), 2)  AS Recognized_Revenue,
    ROUND(SUM(CASE WHEN o.Status = 'Cancelled' THEN oi.Total ELSE 0 END), 2)   AS Revenue_Lost_To_Cancellations
FROM Orders o
JOIN Order_Items oi ON o.Order_ID = oi.Order_ID;
-- Result: 500 orders | 145 customers | Gross $409,464 | Discounts $26,357
--         Recognized revenue $367,406 | $15,701 lost to cancelled orders (3% of orders)


-- ----------------------------------------------------------------------------
-- Order fulfillment funnel: how much of gross revenue never converts to cash?
-- Useful for an ops manager tracking cancellation rate as a leading indicator.
-- ----------------------------------------------------------------------------
SELECT
    Status,
    COUNT(*)                                              AS Orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Orders), 1) AS Pct_Of_Orders
FROM Orders
GROUP BY Status
ORDER BY Orders DESC;
-- Result: Delivered 80.0% | Shipped 11.4% | Processing 5.6% | Cancelled 3.0%
