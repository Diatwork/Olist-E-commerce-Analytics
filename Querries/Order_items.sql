SELECT * FROM olist.order_items;


#Q13. What’s the average number of items per order?
SELECT 
   ROUND(AVG(items_per_order), 2) as avg_orders
FROM ( 
	SELECT 
		order_id,
		COUNT(product_id) as items_per_order 
	FROM olist.order_items
	GROUP BY order_id 
) as sub;

#Q15. What’s the distribution of product prices?
SELECT 
    COUNT(order_id) as total_orders,
    CASE
		WHEN price < 50 THEN '0-49'
        WHEN price BETWEEN 50 AND 99.99 THEN '50-99'
        WHEN price BETWEEN 99.99 AND 199.99 THEN '100-199'
        WHEN price BETWEEN 199.99 AND 499.99 THEN '200-499'
        ELSE '>500'
	END AS price_range
FROM olist.order_items
GROUP BY price_range
ORDER BY MIN(price);



