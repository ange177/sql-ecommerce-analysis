-- ============================================================================
-- 00_schema.sql
-- Database: Online Retail 2023 (SQLite dialect, portable to T-SQL/BigQuery
-- with minor type changes, see docs/data_dictionary.md)
--
-- Star-schema layout: Orders is the fact table, Customers/Products are
-- dimensions, Order_Items is the line-item grain, Returns tracks post-sale
-- refunds against an Order (not an individual line item; see docs/notes.md
-- for why category-level return analysis isn't attempted in sql/07).
-- ============================================================================

CREATE TABLE Customers (
    Customer_ID         TEXT PRIMARY KEY,          -- e.g. 'C0001'
    Customer_Name       TEXT NOT NULL,
    Email               TEXT,
    Phone               TEXT,
    City                TEXT,
    State               TEXT,
    Country             TEXT,
    Segment             TEXT CHECK (Segment IN ('Consumer','Corporate','Home Office')),
    Registration_Date   DATE
);

CREATE TABLE Products (
    Product_ID       TEXT PRIMARY KEY,             -- e.g. 'P0001'
    Product_Name     TEXT NOT NULL,
    Category         TEXT CHECK (Category IN ('Technology','Furniture','Office Supplies')),
    Unit_Price       NUMERIC NOT NULL,              -- current list price
    Stock_Quantity   INTEGER,
    Supplier         TEXT
);

CREATE TABLE Orders (
    Order_ID     TEXT PRIMARY KEY,                 -- e.g. 'ORD00001'
    Customer_ID  TEXT REFERENCES Customers(Customer_ID),
    Order_Date   DATE NOT NULL,
    Ship_Date    DATE,
    Ship_Mode    TEXT CHECK (Ship_Mode IN ('Standard','Express','Next Day','Ground')),
    -- Status carries revenue meaning: Cancelled orders should NOT count as
    -- recognized revenue even though their line items exist in Order_Items.
    Status       TEXT CHECK (Status IN ('Delivered','Shipped','Processing','Cancelled'))
);

CREATE TABLE Order_Items (
    Order_Item_ID     INTEGER PRIMARY KEY,
    Order_ID          TEXT REFERENCES Orders(Order_ID),
    Product_ID        TEXT REFERENCES Products(Product_ID),
    Quantity          INTEGER NOT NULL,
    Unit_Price        NUMERIC NOT NULL,             -- price at time of sale
    Discount          NUMERIC,                      -- discount rate applied (0.00-1.00)
    Subtotal          NUMERIC,                       -- Quantity * Unit_Price
    Discount_Amount   NUMERIC,                       -- Subtotal * Discount
    Total             NUMERIC                        -- Subtotal - Discount_Amount (net revenue line)
);

CREATE TABLE Returns (
    Return_ID       TEXT PRIMARY KEY,               -- e.g. 'RET0001'
    -- NOTE: Returns links to Order_ID only, not Order_Item_ID/Product_ID.
    -- A returned order can contain several line items across categories,
    -- so a refund cannot be safely attributed to one product or category
    -- without guessing. Return analysis in this project is therefore kept
    -- at the order / reason / status grain, not the category grain.
    Order_ID        TEXT REFERENCES Orders(Order_ID),
    Return_Date     DATE,
    Reason          TEXT,   -- 'Defective','Changed Mind','Wrong Item','Damaged','Not Satisfied'
    Refund_Amount   NUMERIC,
    Status          TEXT    -- 'Approved','Pending','Rejected'
);
