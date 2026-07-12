-- ============================================================================
-- 07_returns_and_refunds.sql
-- Business question: "How much revenue are we giving back, and is it
-- preventable (customer changed their mind) or a quality problem (defective/
-- damaged) that points back to sourcing or QA?"
--
-- Design note: Returns links to Order_ID only, not Order_Item_ID or
-- Product_ID, and most returned orders contain 3-5 line items across
-- multiple categories (see sql/00_schema.sql). Attributing a refund to a
-- single product/category would require guessing which line item was
-- returned, so this analysis is deliberately kept at the order/reason/status
-- grain rather than manufacturing a category breakdown the data can't support.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Refund impact by reason and status: separates preventable returns (Changed
-- Mind, Not Satisfied) from quality issues (Defective, Damaged, Wrong Item),
-- and surfaces anything still unresolved (Pending).
-- ----------------------------------------------------------------------------
SELECT
    Reason,
    Status,
    COUNT(*)                        AS Return_Count,
    ROUND(SUM(Refund_Amount), 2)    AS Total_Refund
FROM Returns
GROUP BY Reason, Status
ORDER BY Total_Refund DESC;
-- Result (top lines): Changed Mind/Approved $2,401 (7) | Not Satisfied/Approved
-- $1,450 (4) | Defective/Pending $1,080 (3) | Wrong Item/Approved $1,013 (5)
-- Actionable: "Changed Mind" is the single largest refund category and is the
-- most preventable. Better product photography/sizing info on the product
-- page typically cuts this bucket. The $1,080 in still-Pending Defective
-- refunds should be escalated; an open quality claim sitting unresolved is
-- a customer-trust risk, not just a bookkeeping line.


-- ----------------------------------------------------------------------------
-- Refunds as a share of recognized revenue: the number a CFO wants on one line.
-- ----------------------------------------------------------------------------
SELECT
    (SELECT ROUND(SUM(Refund_Amount), 2) FROM Returns) AS Total_Refunds,
    (SELECT ROUND(COUNT(DISTINCT Order_ID) * 100.0 / (SELECT COUNT(*) FROM Orders), 1)
     FROM Returns)                                       AS Pct_Of_Orders_With_A_Return,
    ROUND(
        (SELECT SUM(Refund_Amount) FROM Returns) * 100.0 /
        (SELECT SUM(oi.Total) FROM Order_Items oi
         JOIN Orders o ON oi.Order_ID = o.Order_ID
         WHERE o.Status <> 'Cancelled'),
        2
    ) AS Refunds_As_Pct_Of_Recognized_Revenue;
-- Result: $7,965 total refunds | 6.0% of orders had a return | 2.17% of
-- recognized revenue: a healthy, not alarming, return rate, but the
-- Pending/Defective backlog above still merits action.
