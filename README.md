# Olist E-Commerce Performance Analytics

An end-to-end Data Analytics and Business Intelligence project analyzing transactional data from **99K+ orders** across **9 relational tables** (2016–2018) using **Python**, **PostgreSQL**, and **Power BI**.

## Executive Summary & Key Metrics
- **Total Revenue:** $15.84M
- **Total Orders:** 99K+
- **Total Customers:** 96K+
- **Average Order Value (AOV):** $159.33
- **On-Time Delivery Rate:** 91.89%
- **Average Review Score:** 4.09

## Dataset Overview
The project uses the relational Brazilian E-Commerce (Olist) dataset spanning 9 interconnected tables:
- **Core Entities & Transactions:** `orders`, `order_items`, `order_payments`, `order_reviews`
- **Catalog, Users & Geography:** `products`, `customers`, `sellers`, `geolocation` (1M+ rows), and `product_category_name_translation`

## Tech Stack
- **Data Cleaning & ETL:** Python, Pandas, SQLAlchemy
- **Database & Analysis:** PostgreSQL, SQL (`JOIN`s, `CTE`s, Window Functions like `LAG`)
- **Visualization & Reporting:** Power BI, PDF Reporting

## Project Workflow
1. **ETL & Data Cleaning (Python):** Loaded raw tables using Pandas, handled missing values and duplicates, translated product category names to English, and streamed cleaned datasets into PostgreSQL via SQLAlchemy.
2. **Business Analysis (SQL):** Executed structured SQL queries to evaluate top-performing categories (`health_beauty`, `watches_gifts`, `bed_bath_table`, `sports_leisure`, `computers_accessories`), state-wise order volume (`SP`, `RJ`, `MG`), payment methods, repeat purchase behavior, MoM revenue growth, and the impact of delivery delays on review scores.
3. **Interactive Dashboard (Power BI):** Built a dark-themed executive dashboard featuring KPI cards, revenue trends, category and payment breakdowns, state-level demand, review distributions, and delivery SLA performance with dynamic slicers (`Date Range`, `Category`, `Payment Type`, `State`).

## Key Business Recommendations
- **Improve Delivery SLA:** Reduce late deliveries—especially outside São Paulo—to lift customer satisfaction and review scores.
- **Boost Customer Retention:** Drive repeat orders among the 96K customer base through targeted post-purchase engagement and offers.
- **Optimize Regional Fulfillment:** Strengthen logistics coverage in high-volume regions such as `RJ` and `MG`.
- **Scale High-Performing Categories:** Focus campaigns on top revenue categories and flexible payment options to support AOV growth.

## Repository Structure
```text
olist-ecommerce-analytics/
├── README.md
├── .gitignore
├── requirements.txt
├── scripts/
│   ├── etl_pipeline.py
│   └── sql_queries.sql
├── dashboard/
│   ├── olist_ecommerce_dashboard.pbix
│   └── dashboard_preview.png
└── reports/
    └── olist_ecommerce_report.pdf
