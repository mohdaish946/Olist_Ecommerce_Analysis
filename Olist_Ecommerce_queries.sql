select * from olist_db


select * from customers
select * from geolocation
select * from order_items
select * from order_payments
select * from order_reviews
select * from orders
select * from products
select * from sellers
select * from product_category_name_translation
select * from rfm



--1. Product categories generating the highest revenue

SELECT 
    p.product_category_name,
    sum(oi.total_item_value) as total_revenue 
FROM order_items oi
JOIN products p 
ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;



-- 2. States generating the most orders

SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c 
ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;



-- 3. Most popular payment method

SELECT 
    payment_type,
    COUNT(order_id) AS total_transactions,
    SUM(payment_value) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_transactions DESC;


-- 4. Customer repeat purchase rate

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count
    FROM orders o
    JOIN customers c 
	ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT 
    CAST(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(*) AS repeat_purchase_rate_pct
FROM customer_orders;




-- 5. Sellers with highest order volume


SELECT 
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders_fulfilled,
    SUM(oi.price) AS total_revenue_generated
FROM order_items oi
JOIN sellers s 
ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_state
ORDER BY total_orders_fulfilled DESC;



-- 6. Percentage of orders delivered late


SELECT 
    ROUND(
        COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) * 100.0 / COUNT(*), 
        2
    ) AS late_delivery_percentage
FROM orders
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date IS NOT NULL 
  AND order_estimated_delivery_date IS NOT NULL;



-- 7. How delivery time affects customer reviews
-- (Yeh query delivery duration days mein calculate karke average review score se map karti hai)

SELECT 
    r.review_score,
    ROUND(AVG(CAST(o.order_delivered_customer_date AS DATE) - CAST(o.order_purchase_timestamp AS DATE)), 1) AS avg_delivery_days
FROM orders o
JOIN order_reviews r 
ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score DESC;



-- 8. Monthly revenue growth rate (MoM)

WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        SUM(oi.total_item_value) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY 1
),
lagged_revenue AS (
    SELECT 
        order_month,
        revenue,
        LAG(revenue) OVER (ORDER BY order_month) AS prev_month_revenue
    FROM monthly_revenue
)
SELECT 
    TO_CHAR(order_month, 'YYYY-MM') AS month_period, revenue, prev_month_revenue,
    ROUND(CAST(((revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0)) * 100 AS NUMERIC), 2) AS mom_growth_rate_pct
FROM lagged_revenue;



-- 9. Categories with highest average order value (AOV)

WITH order_category_value AS (
    SELECT 
        o.order_id,
        p.product_category_name,
        SUM(oi.price + oi.freight_value) AS order_value                                 --(oi.total_item_value)
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY o.order_id, p.product_category_name
)
SELECT 
    product_category_name,
    ROUND(AVG(order_value)::numeric, 2) AS avg_order_value,
    COUNT(order_id) AS total_orders
FROM order_category_value
GROUP BY product_category_name
ORDER BY avg_order_value DESC;


-- 10. Months with the highest sales

SELECT 
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS year_month,
    SUM(oi.total_item_value) AS total_sales,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM')
ORDER BY total_sales DESC;












--Most important questions

--Question:1 Calculate total monthly sales and the revenue difference compared to the previous month.

WITH monthly_sales AS (
    SELECT 
        TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS month,
        ROUND(SUM(oi.price)::numeric, 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change
FROM monthly_sales;






-- Question 2: Category-wise revenue + running total
-- (Python mein missing category already 'unknown' hai, isliye 'Other' hata diya)



WITH category_totals AS (
    SELECT
        COALESCE(p.product_category_name, 'unknown') AS category,
        ROUND(SUM(oi.price)::numeric, 2) AS category_revenue
    FROM order_items oi
    LEFT JOIN products p ON oi.product_id = p.product_id
    GROUP BY 1
)
SELECT category, category_revenue,
    ROUND(SUM(category_revenue) OVER (
              ORDER BY category_revenue DESC, category
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS running_total_revenue,
    ROUND(100.0 * SUM(category_revenue) OVER (
              ORDER BY category_revenue DESC, category
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          / SUM(category_revenue) OVER (), 2) AS running_pct
FROM category_totals
ORDER BY category_revenue DESC;
-- Insight: [Top kitni categories se 80% revenue aata hai? (running_pct dekho)]










-- Question 3: Total orders in sign-up month vs second active month
-- (customer_unique_id use kiya, kyunki customer_id har order par naya hota hai)


WITH cust_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
),
ranked AS (
    SELECT
        customer_unique_id,
        order_id,
        order_month,
        MIN(order_month) OVER (PARTITION BY customer_unique_id) AS signup_month,
        DENSE_RANK() OVER (PARTITION BY customer_unique_id ORDER BY order_month) AS active_month_no
    FROM cust_orders
)
SELECT
    TO_CHAR(signup_month, 'YYYY-MM') AS signup_month,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    COUNT(DISTINCT order_id) FILTER (WHERE active_month_no = 1) AS orders_in_signup_month,
    COUNT(DISTINCT order_id) FILTER (WHERE active_month_no = 2) AS orders_in_second_active_month,
    COUNT(DISTINCT customer_unique_id) FILTER (WHERE active_month_no = 2) AS customers_returned
FROM ranked
GROUP BY signup_month
ORDER BY signup_month;





-- Question 4: On-Time vs Late orders + average review score
-- (pehle review ko order level par dedupe kiya, taaki double count na ho)



WITH order_review AS (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    CASE
        WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date)
            THEN 'On-Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_review_score
FROM orders o
JOIN order_review r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY 1;
-- Insight: [Late orders ka avg review score X vs On-Time ka Y - delivery ka review par kitna asar?]














