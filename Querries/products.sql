SELECT * FROM olist.products;

#Q11. What are the most frequently ordered products?
SELECT 
	product_category_name,
    COUNT(product_id) as sum_products
FROM olist.products
GROUP BY product_category_name
ORDER BY  sum_products DESC;


#Q12. Which products have the highest cancellation/return rates?
# This is just the canceled/unvailable orders: We've classified as Returns/Cancellations
SELECT 
    p.product_category_name,
    COUNT(oi.order_id) as total_orders,
    SUM(CASE WHEN o.order_status IN ('canceled','unavailable') THEN 1 ELSE 0 END) as failed_orders,
    ROUND(SUM(CASE WHEN o.order_status IN ('canceled','unavailable') THEN 1 ELSE 0 END)*100.00 / COUNT(oi.order_id),2) as Return_Rate
FROM olist.orders as o
JOIN olist.order_items as oi
	ON o.order_id = oi.order_id
JOIN olist.products as p 
	ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY Return_rate DESC;



#Q14. Do certain products sell more in specific states/cities?

SELECT
	p.product_category_name,
    c.customer_state,
    COUNT(oi.order_id) as total_orders
FROM olist.customers as c
LEFT JOIN olist.orders  as o
ON  c.customer_id = o.customer_id
JOIN olist.order_items as oi
ON o.order_id = oi.order_id
JOIN olist.products as p
ON oi.product_id = p.product_id
GROUP BY p.product_category_name, c.customer_state
ORDER BY total_orders DESC;



