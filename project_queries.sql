-- QUESTION 1
-- What are the top 5 most popular film categories for rentals?

SELECT cat.name category,
	COUNT(*)
FROM category cat
JOIN film_category fc
ON cat.category_id = fc.category_id
JOIN film f
ON fc.film_id = f.film_id
JOIN inventory i
ON f.film_id = i.film_id
JOIN rental r
ON i.inventory_id = r.inventory_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


-- QUESTION 2
-- Does the length of films effect how often a movie is rented out?

WITH count_rentals AS (
		SELECT f.film_id count_id,
			COUNT(r.*) film_count
		FROM film f
		JOIN inventory i
		ON f.film_id = i.film_id
		JOIN rental r
		ON i.inventory_id = r.inventory_id
		GROUP BY 1
	),
	film_length AS (
		SELECT f.film_id length_id,
			NTILE(100) OVER(ORDER BY f.length) AS length_percentile
		FROM film f
	)
SELECT length_percentile,
	SUM(film_count)
FROM count_rentals
JOIN film_length
ON count_rentals.count_id = film_length.length_id
GROUP BY 1
ORDER BY 1;


-- QUESTION 3
-- Do any customers have a favorite actor, based on their rental history?

SELECT (c.first_name || ' ' || c.last_name || ' - ' || a.first_name || ' ' || a.last_name) customer_actor_pair,
	COUNT(*) time_rented
FROM actor a
JOIN film_actor fa
ON a.actor_id = fa.film_id
JOIN film f
ON fa.film_id = f.film_id
JOIN inventory i
ON f.film_id = i.film_id
JOIN rental r
ON i.inventory_id = r.inventory_id
JOIN customer c
ON r.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 8;


-- QUESTION 4
-- Who are the top 5 paying customers, and how do their payments differ monthly during 2007?

WITH top_ten_customers AS (
		SELECT cust.customer_id top_ten_id,
			SUM(pay.amount)
		FROM customer cust
		JOIN payment pay
		ON cust.customer_id = pay.customer_id
		GROUP BY 1
		ORDER BY 2 DESC
		LIMIT 5
	),
	sum_table AS (
		SELECT cust.customer_id cust_id,
			DATE_TRUNC('month', pay.payment_date) AS payment_month,
			CONCAT(cust.first_name, ' ', cust.last_name) full_name,
			SUM(pay.amount) monthly_pay_amount
		FROM customer cust
		JOIN payment pay
		ON cust.customer_id = pay.customer_id
		WHERE pay.payment_date BETWEEN '2007-01-01' AND '2008-01-01'
		GROUP BY 1, 2, 3
	),
	difference_table AS (
		SELECT sum_table.payment_month,
			sum_table.full_name,
			sum_table.monthly_pay_amount,
			sum_table.monthly_pay_amount - LAG(sum_table.monthly_pay_amount) OVER (PARTITION BY sum_table.full_name ORDER BY sum_table.payment_month) AS monthly_difference
		FROM sum_table
		JOIN top_ten_customers
		ON sum_table.cust_id = top_ten_customers.top_ten_id
		ORDER BY 2, 1
	)
SELECT *
FROM difference_table;