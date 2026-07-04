# SQL E-Commerce Analysis — Revenue, Customer & Operations Intelligence

A SQL-only business intelligence analysis of a year of e-commerce trading, turning five raw transaction tables into revenue KPIs, customer segmentation, and an early-warning finding on a 68.5% month-over-month revenue collapse.

## Business Context

A retail stakeholder doesn't want a query — they want to know three things: *is revenue healthy, which customers/products matter most, and where is money leaking?* This project answers all three from raw order-level data:

- **Revenue & growth** — what did we actually earn (net of cancellations and discounts), and did anything unusual happen month to month that leadership should have caught sooner?
- **Customer value** — which segments and individual accounts drive the business, and how exposed are we if a handful of them churn?
- **Operational efficiency** — is premium shipping actually faster, and how much revenue is lost to returns and cancelled orders?

Every finding below is written as something a manager can act on this week, not just a query result.

## Dataset

A synthetic, portfolio-safe online retail dataset: 150 customers, 50 products, 500 orders, 1,539 order line items, and 30 returns, covering Jan–Dec 2023. Full schema in [`docs/data_dictionary.md`](docs/data_dictionary.md).

```
Orders (500, fact table)
 ├─→ Customers (150) — Segment: Consumer / Corporate / Home Office
 ├─→ Order_Items (1,539) — Quantity, Unit_Price, Discount, Total
 │     └─→ Products (50) — Category: Technology / Furniture / Office Supplies
 └─→ Returns (30) — Reason, Status, Refund_Amount
```

## Key Findings

1. **Revenue collapsed 68.5% in one month.** January ($37,106) fell to February ($11,691) — the single largest swing of the year. No comparable recovery trigger is visible in the data, which means this needs an incident review (marketing pause? stockout? site issue?), plus an early-warning alert for any future month that drops more than ~25% MoM.
2. **Two-thirds of revenue rides on one category.** Technology is 65.6% of net revenue ($241K of $367K). A supply issue or price war in that category would hit the P&L hard — worth a deliberate push to grow Furniture and Office Supplies share.
3. **Revenue is concentrated in a small customer base.** The top 25% of customers (37 people) drive 55.5% of revenue; 31 "High Value" customers alone account for 49.4%. A retention program for this group protects roughly half the business.
4. **Retention is a real strength, not a weakness.** 86.9% of customers are repeat buyers. Growth efforts should lean toward increasing basket size/order frequency rather than just acquisition spend.
5. **Premium shipping isn't actually faster.** "Next Day" orders dispatch in 3.4 days on average — statistically the same as Standard (3.6 days) and Express (3.5 days). Customers paying for expedited shipping aren't getting it; this is a trust and SLA-compliance risk worth fixing before it shows up in reviews.
6. **Returns are healthy overall (2.17% of revenue) but have an unresolved tail.** "Changed Mind" is the largest and most preventable refund category ($2,401); $1,080 in Defective refunds are still sitting Pending and should be escalated to vendor/QA management.
7. **3% of orders (worth $15,701) never convert to revenue** because they're cancelled — small, but a useful leading indicator to watch alongside the monthly trend.

## Repository Structure

```
sql-ecommerce-analysis/
├── data/           # source CSVs + data README
├── sql/            # numbered, commented analysis queries (run in order)
│   ├── 00_schema.sql
│   ├── 01_revenue_kpis.sql
│   ├── 02_customer_segmentation.sql
│   ├── 03_customer_value_ranking.sql
│   ├── 04_product_performance.sql
│   ├── 05_monthly_trends.sql
│   ├── 06_shipping_operations.sql
│   └── 07_returns_and_refunds.sql
├── outputs/        # exported CSV results for the headline queries
├── docs/           # data dictionary
└── README.md
```

## Project Impact & Skills Demonstrated

- Business-first framing: translating raw transactional data into decisions a manager can act on
- Relational data modeling and star-schema reasoning
- SQL joins, CTEs, subqueries, `CASE` logic, and window functions (`RANK`, `NTILE`, `LAG`, running `SUM`)
- KPI design (recognized vs. gross revenue, cancellation rate, repeat purchase rate)
- Data-quality judgment: recognizing and documenting a schema limitation (Returns → category attribution) instead of forcing a misleading metric
- Clear technical writing: every query commented with the business question it answers, not just what it does
