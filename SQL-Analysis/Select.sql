-- Used python code for loading csv files into Data base
use olist_db;
-- KPI-1
SELECT 
    CASE 
        WHEN DAYOFWEEK(o.purchase_dt) IN (1,7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS order_day_type,
    
    COUNT(DISTINCT o.order_id) AS total_orders,
    
    concat(round(SUM(p.payment_value) / 1000000, 2),'M') AS total_revenue_million,
    
    ROUND(AVG(p.payment_value), 2) AS avg_payment_value

FROM orders o
JOIN payments p 
    ON o.order_id = p.order_id

WHERE o.order_status = 'delivered'
AND o.purchase_dt IS NOT NULL

GROUP BY order_day_type;
-- KPI-2
SELECT 
   concat(round(COUNT(DISTINCT o.order_id)/1000,2),"K") AS total_5star_creditcard_orders
FROM orders o

JOIN reviews r 
    ON o.order_id = r.order_id

JOIN payments p 
    ON o.order_id = p.order_id

WHERE r.review_score = 5
AND p.payment_type = 'credit_card'
AND o.order_status = 'delivered';

SELECT 
    p.payment_type,
    concat(round(COUNT(DISTINCT o.order_id)/1000,2),"K") AS total_orders

FROM orders o
JOIN reviews r ON o.order_id = r.order_id
JOIN payments p ON o.order_id = p.order_id

WHERE r.review_score = 5
AND o.order_status = 'delivered'

GROUP BY p.payment_type
ORDER BY total_orders DESC;

-- KPI-3
SELECT 
    ct.product_category_name_english AS category,
    ROUND(AVG(od.delivery_days), 3) AS avg_shipping_days

FROM (

    -- STEP 1: Small clean dataset (orders only)
    SELECT 
        order_id,
        DATEDIFF(delivered_dt, purchase_dt) AS delivery_days
    FROM orders
    WHERE order_status = 'delivered'
    AND delivered_dt IS NOT NULL
    AND purchase_dt IS NOT NULL

) od

JOIN (
    -- STEP 2: DISTINCT order → category mapping (reduces explosion)
    SELECT DISTINCT 
        oi.order_id,
        pr.product_category_name
    FROM items oi
    JOIN products pr 
        ON oi.product_id = pr.product_id
) pc 
    ON od.order_id = pc.order_id

JOIN category_translation ct 
    ON pc.product_category_name = ct.product_category_name

GROUP BY ct.product_category_name_english;

-- KPI-4
SELECT 
    CASE 
        WHEN c.customer_city = 'sao paulo' THEN 'Sao Paulo'
        ELSE 'Others'
    END AS city_group,

    AVG(order_price) AS avg_price,
    AVG(order_payment) AS avg_payment_value

FROM (

    SELECT 
        o.order_id,
        o.customer_id,

        SUM(oi.price) AS order_price,
        SUM(p.payment_value) AS order_payment

    FROM orders o

    JOIN items oi 
        ON o.order_id = oi.order_id

    JOIN payments p 
        ON o.order_id = p.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY o.order_id, o.customer_id

) t

JOIN customers c 
    ON t.customer_id = c.customer_id

GROUP BY city_group;

-- KPI-5
SELECT 
    o.order_id,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,

    DATEDIFF(
        STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y'),
        STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y')
    ) AS test_diff

FROM orders o
WHERE o.order_status = 'delivered'
LIMIT 20;

SELECT 
    r.review_score,
    
    round(AVG(
        DATEDIFF(
            STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y'),
            STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y')
        )),0
    ) AS avg_shipping_days

FROM orders o

JOIN reviews r 
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
AND o.order_purchase_timestamp IS NOT NULL

GROUP BY r.review_score
ORDER BY r.review_score;

-- KPI-6
SELECT 
    CONCAT(ROUND(SUM(payment_value) / 1000000, 2), 'M') AS total_revenue
FROM payments;

-- KPI-7
SELECT 
    CONCAT(ROUND(COUNT(DISTINCT order_id) / 1000, 2), 'K') AS total_orders
FROM orders;

-- KPI-8
SELECT 
    ROUND(AVG(DATEDIFF(delivered_dt, purchase_dt)), 0) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
AND delivered_dt IS NOT NULL
AND purchase_dt IS NOT NULL;

-- KPI-9
SELECT 
    ROUND(AVG(payment_value), 2) AS avg_order_value
FROM payments;

-- KPI-10
SELECT 
    CONCAT(
        ROUND(
            (SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) 
            / COUNT(*)) * 100
        , 2),
    '%') AS success_rate_percentage
FROM orders;