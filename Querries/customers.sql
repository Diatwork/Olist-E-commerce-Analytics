SELECT * FROM olist.customers;

##Q1. How many unique customers are there?
SELECT COUNT(DISTINCT customer_id) as unique_customers FROM olist.customers;


##Q2. Which cities/states have the most customers?
SELECT customer_city,
	COUNT(*) as Total_customers
FROM olist.customers
GROUP BY customer_city
ORDER BY Total_customers DESC;

##Q3. What is the distribution of customers by ZIP code?
SELECT customer_zip_code_prefix,
	COUNT(*) as Total_customers
FROM olist.customers
GROUP BY customer_zip_code_prefix
ORDER BY Total_customers DESC;

##Q4. What is the average number of orders placed per customer?
SELECT 
	AVG(count_order) as average_orders
FROM (
	SELECT customer_id, COUNT(order_id) as count_order
	FROM olist.orders
	GROUP BY customer_id) as customer_orders;    

##Q5. How many repeat vs. one-time customers are there?
SELECT customer_type,
COUNT(*) num_customers
FROM
	(SELECT 
		c.customer_id, 
		COUNT(o.order_id) as total_orders,
		CASE 
			WHEN COUNT(o.order_id)= 1 THEN 'one-time customer'
			WHEN COUNT(o.order_id) >1 THEN 'repeat customer'
			ELSE 'No Orders'
		END AS customer_type    
	FROM olist.customers as c
	LEFT JOIN olist.orders as o
		on c.customer_id = o.customer_id
		GROUP BY c.customer_id 
		) as sub 
GROUP BY customer_type;        
        
#Q. which city has the most orders?

SELECT 
	c.customer_city, 
    o.order_status,
    COUNT(o.order_id) as total_orders
FROM olist.customers as c
LEFT JOIN olist.orders as o    
ON c.customer_id = o.customer_id
GROUP BY c.customer_city, o.order_status
ORDER BY total_orders DESC;
        
#Q21. What factors contribute most to late deliveries?

######### BY CUSTOMER STATE ###########
SELECT 
	c.customer_state,
	ROUND(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)*100 / COUNT(o.order_id),2) AS late_rate
FROM olist.orders as o
JOIN olist.customers as c
	ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY late_rate DESC;
   
   
######### BY PRODUCT CATEGORY ###########
SELECT 
	p.product_category_name,
	ROUND(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)*100 / COUNT(o.order_id),2) AS late_rate
FROM olist.orders as o
JOIN olist.customers as c
	ON o.customer_id = c.customer_id
JOIN olist.order_items as oi
	ON o.order_id = oi.order_id    
JOIN olist.products as p
	ON oi.product_id = p.product_id	
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY late_rate DESC;   


################ Number of items in ORDER ###################
WITH items_per_order AS (
    SELECT 
        o.order_id,
        COUNT(oi.product_id) AS num_items,
        CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END AS is_late
    FROM olist.orders AS o
    JOIN olist.order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, o.order_delivered_customer_date, o.order_estimated_delivery_date
)
SELECT 
    num_items,
    COUNT(order_id) AS total_orders,
    SUM(is_late) AS late_orders,
    ROUND(SUM(is_late) * 100.0 / COUNT(order_id), 2) AS late_rate
FROM items_per_order
GROUP BY num_items
ORDER BY num_items;

#Q22. Are certain states/cities more prone to late deliveries?
SELECT 
	c.customer_state,
	ROUND(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)*100 / COUNT(o.order_id),2) AS late_rate
FROM olist.orders as o
JOIN olist.customers as c
	ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY late_rate DESC;    


    

        
