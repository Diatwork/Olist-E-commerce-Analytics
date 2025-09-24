SELECT * FROM olist.orders;

#Q6. What’s the breakdown of order statuses?

SELECT order_status,
COUNT(order_id) as total_orders
FROM olist.orders
GROUP BY order_status
ORDER BY total_orders DESC;


#Q7. What is the average delivery time (purchase → delivered)?

SELECT 
	ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)),2) AS average_delivery_time
FROM olist.orders
WHERE order_delivered_customer_date IS NOT NULL;  

##OR
SELECT 
	order_id, customer_id,
    TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS time_to_deliver_order
FROM olist.orders
WHERE order_delivered_customer_date IS NOT NULL
ORDER BY time_to_deliver_order DESC; 


#Number of Orders Grouped by delivery time 
#DAYS TO DELIVER
SELECT 
    TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS days_to_deliver_order,
    COUNT(*) as num_orders
FROM olist.orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY days_to_deliver_order
ORDER BY days_to_deliver_order ASC; 

  
#Q8. How many orders are delivered late vs on time?

SELECT  
    CASE 
		WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'late'
		ELSE 'on time'
    END AS deliver_status,
    COUNT(order_id) AS total_orders
FROM olist.orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY deliver_status;

#Q9. Which days/months see the most orders?

SELECT
	date_format(order_purchase_timestamp, '%m') as Month_name,
	COUNT(order_id) AS total_orders
FROM olist.orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY Month_name
ORDER BY total_orders DESC;
    
#Most Common Day
SELECT
	DAY(order_purchase_timestamp) as day_name,
	COUNT(order_id) AS total_orders
FROM olist.orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY day_name
ORDER BY total_orders DESC;

#Q10. What’s the trend of order volume over time?

SELECT 
	date_format(order_purchase_timestamp, '%Y-%m') as order_month,
    COUNT(order_id) as total_orders
FROM olist.orders
GROUP BY order_month
ORDER BY total_orders DESC;


#Q18. Do payment types affect approval or delivery speed?

WITH order_times AS (
	SELECT
		p.payment_type,
        TIMESTAMPDIFF(DAY, o.order_purchase_timestamp, o.order_approved_at) as approval_time,
		TIMESTAMPDIFF(DAY, o.order_approved_at, o.order_delivered_customer_date) as delivery_time
	FROM olist.payments as p
	JOIN olist.orders as o
		ON p.order_id = o.order_id
	WHERE o.order_delivered_customer_date IS NOT NULL
	)    
SELECT 
		payment_type,
        ROUND(AVG(approval_time),2) as avg_approval_days,
        ROUND(AVG(delivery_time),2) as avg_delivery_days,
        ROUND(AVG(approval_time + delivery_time),2) as avg_total_delivery_days
FROM order_times
GROUP BY payment_type
ORDER BY avg_total_delivery_days ASC;
   
   
#Q19. What is the total revenue trend over time?


SELECT 
	CASE 
		WHEN YEAR(order_purchase_timestamp) = 2016 THEN 'Year 2016'
        WHEN YEAR(order_purchase_timestamp) = 2017 THEN 'Year 2017'
        WHEN YEAR(order_purchase_timestamp) = 2018 THEN 'Year 2018'
    END AS time_stamp,
    ROUND(AVG(p.payment_value), 2) as avg_revenue 
FROM olist.payments as p
	JOIN olist.orders as o
	ON p.order_id = o.order_id  
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY time_stamp
ORDER BY avg_revenue DESC;


#Q20. How much revenue comes from each state/city?

SELECT 
	c.customer_state,
    ROUND(SUM(p.payment_value), 2) as total_revenue 
FROM olist.payments as p
	JOIN olist.orders as o
	ON p.order_id = o.order_id  
    JOIN olist.customers as c
    ON o.customer_id = c.customer_id
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


#Q23. Do faster-approved orders get delivered sooner?
WITH order_times as(
	SELECT 
		order_id,
		TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_approved_at) AS approval_time,
		TIMESTAMPDIFF(DAY, order_approved_at, order_delivered_customer_date) AS delivery_time
	FROM olist.orders
	WHERE order_status = 'delivered'
	AND order_approved_at IS NOT NULL
	AND order_delivered_customer_date IS NOT NULL
    )
SELECT 
	CASE 
        WHEN approval_time = 0 THEN '0 days'
        WHEN approval_time BETWEEN 1 AND 2 THEN '1-2 days'
        WHEN approval_time BETWEEN 3 AND 5 THEN '3-5 days'
        ELSE '6+ days'
    END AS approval_bucket,
    ROUND(AVG(delivery_time),2) as avg_delivery_time,
    COUNT(order_id) as total_orders
FROM order_times
GROUP BY approval_bucket
ORDER BY approval_bucket ASC;
	

#Q24. Which customer segments contribute most to revenue (Pareto 80/20)?
WITH customer_revenue as
(
	 SELECT 
		o.customer_id,
		SUM(p.payment_value) as rev_per_customer
	FROM olist.payments as p
	JOIN olist.orders as o
		ON p.order_id = o.order_id
	WHERE p.payment_value IS NOT NULL  
	GROUP BY o.customer_id
), 
 Ranked_customers as 
 (	SELECT 
		customer_id,
        rev_per_customer,
        SUM(rev_per_customer) OVER () as total_revenue,
        SUM(rev_per_customer) OVER (ORDER BY rev_per_customer DESC) as cumulative_revenue,
        ROW_NUMBER() OVER (ORDER BY rev_per_customer DESC) AS customer_rank,
        COUNT(*) OVER() as total_customers
    FROM customer_revenue    
 )
SELECT
    customer_id,
    rev_per_customer,
    ROUND(cumulative_revenue * 100.0 / total_revenue, 2) AS cumulative_revenue_pct,
    ROUND(customer_rank * 100.0 / total_customers, 2) AS customer_pct
FROM ranked_customers
ORDER BY rev_per_customer DESC;	
 

########### DIFFERENCE BTW GROUP BY AND WINDOW FUNCTION. #############

SELECT customer_id, SUM(payment_value) AS total_spent
FROM olist.payments as p
	JOIN olist.orders as o
		ON p.order_id = o.order_id
	WHERE p.payment_value IS NOT NULL 
GROUP BY customer_id;


SELECT 
    customer_id,
    payment_value,
    SUM(payment_value) OVER (PARTITION BY customer_id) AS total_spent
FROM olist.payments as p
	JOIN olist.orders as o
		ON p.order_id = o.order_id
	WHERE p.payment_value IS NOT NULL ;


#Q25. Can we identify churned customers (ordered once and never returned)?

SELECT
    customer_id,
    COUNT(order_id) AS total_orders,
    CASE 
        WHEN COUNT(order_id) = 1 THEN 'Churned'
        ELSE 'Retained'
    END AS customer_status
FROM olist.orders
WHERE order_status = 'delivered'
GROUP BY customer_id;
