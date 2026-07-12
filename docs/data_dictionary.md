# Data Dictionary

Generated online-retail dataset covering 2023-01-01 to 2023-12-31: 150 customers, 50 products, 500 orders, 1,539 order line items, 30 returns. All customer names/emails are generated placeholders, no real personal data.

## Customers (`SQL_Customers.csv`)
| Column | Type | Notes |
|---|---|---|
| Customer_ID | text | PK, e.g. `C0001` |
| Customer_Name | text | |
| Email | text | generated placeholder |
| Phone | text | generated placeholder |
| City / State / Country | text | |
| Segment | text | `Consumer`, `Corporate`, `Home Office` |
| Registration_Date | date | |

## Products (`SQL_Products.csv`)
| Column | Type | Notes |
|---|---|---|
| Product_ID | text | PK, e.g. `P0001` |
| Product_Name | text | |
| Category | text | `Technology`, `Furniture`, `Office Supplies` |
| Unit_Price | numeric | current list price |
| Stock_Quantity | integer | |
| Supplier | text | |

## Orders (`SQL_Orders.csv`)
| Column | Type | Notes |
|---|---|---|
| Order_ID | text | PK, e.g. `ORD00001` |
| Customer_ID | text | FK -> Customers |
| Order_Date | date | |
| Ship_Date | date | |
| Ship_Mode | text | `Standard`, `Express`, `Next Day`, `Ground` |
| Status | text | `Delivered`, `Shipped`, `Processing`, `Cancelled`. **Cancelled orders are excluded from recognized-revenue KPIs throughout this project** |

## Order_Items (`SQL_Order_Items.csv`)
| Column | Type | Notes |
|---|---|---|
| Order_Item_ID | integer | PK |
| Order_ID | text | FK -> Orders |
| Product_ID | text | FK -> Products |
| Quantity | integer | |
| Unit_Price | numeric | price at time of sale |
| Discount | numeric | discount rate (0.00-1.00) |
| Subtotal | numeric | `Quantity * Unit_Price` |
| Discount_Amount | numeric | `Subtotal * Discount` |
| Total | numeric | `Subtotal - Discount_Amount`, the net-revenue figure used in every query |

## Returns (`SQL_Returns.csv`)
| Column | Type | Notes |
|---|---|---|
| Return_ID | text | PK, e.g. `RET0001` |
| Order_ID | text | FK -> Orders. **Not** linked to Order_Item_ID or Product_ID |
| Return_Date | date | |
| Reason | text | `Defective`, `Changed Mind`, `Wrong Item`, `Damaged`, `Not Satisfied` |
| Refund_Amount | numeric | |
| Status | text | `Approved`, `Pending`, `Rejected` |

### Known limitation
Because `Returns` only carries `Order_ID`, and most returned orders contain 3-5 line items spanning multiple categories, a refund cannot be reliably attributed to one product or category. `sql/07_returns_and_refunds.sql` deliberately analyzes returns at the order/reason/status grain rather than fabricating a category-level return rate the schema can't actually support.
