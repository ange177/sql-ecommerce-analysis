-- ============================================================================
-- 04_product_performance.sql
-- Business question: "Which products/categories are carrying the business,
-- and are we dangerously reliant on any one of them?"
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Category revenue share. The scalar subquery recomputes total net revenue
-- so each row can show its % of the whole without a second query round-trip.
-- ----------------------------------------------------------------------------
SELECT
    p.Category,
    ROUND(SUM(oi.Total), 2) AS Net_Revenue,
    ROUND(
        SUM(oi.Total) * 100.0 /
        (SELECT SUM(oi2.Total)
         FROM Order_Items oi2
         JOIN Orders o2 ON oi2.Order_ID = o2.Order_ID
         WHERE o2.Status <> 'Cancelled'),
        1
    ) AS Pct_Of_Revenue
FROM Orders o
JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
JOIN Products p ON oi.Product_ID = p.Product_ID
WHERE o.Status <> 'Cancelled'
GROUP BY p.Category
ORDER BY Net_Revenue DESC;
-- Result: Technology $241,169 (65.6%) | Furniture $83,261 (22.7%) | Office Supplies $42,976 (11.7%)
-- Actionable: two-thirds of revenue rides on one category — a Technology
-- supply-chain disruption or price war would hit the P&L hard. Worth a
-- deliberate push to grow Furniture/Office Supplies share.


-- ----------------------------------------------------------------------------
-- Top 10 products by net revenue: where to focus merchandising and inventory.
-- ----------------------------------------------------------------------------
SELECT
    p.Product_Name,
    p.Category,
    SUM(oi.Quantity)         AS Units_Sold,
    ROUND(SUM(oi.Total), 2)  AS Net_Revenue
FROM Orders o
JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
JOIN Products p ON oi.Product_ID = p.Product_ID
WHERE o.Status <> 'Cancelled'
GROUP BY p.Product_Name, p.Category
ORDER BY Net_Revenue DESC
LIMIT 10;
-- Result: Laptop Pro 15 leads at $83,004 (68 units) — more than double the #2
-- product (Tablet 10", $39,199). 8 of the top 10 are Technology/Furniture.


-- ----------------------------------------------------------------------------
-- Products that have never sold: dead inventory tying up working capital.
-- LEFT JOIN + IS NULL is the standard "find the missing side" pattern.
-- ----------------------------------------------------------------------------
SELECT
    p.Product_Name,
    p.Category,
    p.Unit_Price,
    p.Stock_Quantity
FROM Products p
LEFT JOIN Order_Items oi ON p.Product_ID = oi.Product_ID
WHERE oi.Order_Item_ID IS NULL;
-- Result: 0 rows — every product in the 50-item catalog sold at least once
-- in the year. Catalog is lean with no dead SKUs; if this query ever starts
-- returning rows, that's a new signal worth flagging to merchandising.
