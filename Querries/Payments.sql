SELECT * FROM olist.payments;

#Q16. What are the most popular payment methods?

SELECT
	payment_type,
	COUNT(order_id) as total_orders
FROM olist.payments
GROUP BY payment_type
ORDER BY total_orders DESC;

#Q17. What is the average order value (AOV)?
SELECT
	ROUND(AVG(total_pay), 2) as aov
FROM (
	SELECT 
		order_id,
		SUM(payment_value) as total_pay
	FROM olist.payments
    WHERE payment_value IS NOT NULL
	GROUP BY order_id) as payment_avg;
    
#OR CAN DO THIS
SELECT 
    ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2) AS aov
FROM olist.payments
WHERE payment_value IS NOT NULL;



