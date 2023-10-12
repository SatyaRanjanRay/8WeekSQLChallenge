CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');

 
DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
 
 select * from runners;
 select * from customer_orders;
 select * from runner_orders_new;
 select * from pizza_names;
 select * from pizza_recipes;
 select * from pizza_toppings;


-- Data Cleaning

--Cleaning Part-1

/* The exclusions and extras columns will need to be cleaned up before using them */

SELECT DISTINCT exclusions, extras
from customer_orders;


SELECT *,
       CASE WHEN exclusions = 'null' THEN '' ELSE exclusions END AS cleaned_exclusions,
       CASE WHEN extras = 'null' OR extras IS NULL THEN '' ELSE extras END AS cleaned_extras
FROM customer_orders;


--Updating customer_orders

UPDATE customer_orders
SET exclusions = CASE WHEN exclusions = 'null' THEN '' ELSE exclusions END,
    extras = CASE WHEN extras = 'null' OR extras IS NULL THEN '' ELSE extras END;

    
   
select * from customer_orders;


--Cleaning Part-2

/*The runner_orders table contains incorrect data types for the columns pickup_time, distance, and duration.
The pickup_time column should be of type TIMESTAMP 
and the distance and duration columns should be of type FLOAT or INTEGER
The missing values in the cancellation column need to be standardized */

select * from runner_orders;

select order_id,
       runner_id,
 	   CASE WHEN pickup_time = 'null' THEN NULL ELSE CAST(pickup_time AS TIMESTAMP) end AS pickup_time_adjusted,
       CAST(REGEXP_SUBSTR(distance, '[0-9]+(\.[0-9]+)?') AS FLOAT) AS dist_adjusted, 
       CAST(REGEXP_SUBSTR(duration, '^[0-9]+') AS INT)  AS dur_adjusted,
       CASE WHEN cancellation IN ('null', '') THEN NULL ELSE cancellation end AS cancellation_adjusted
FROM runner_orders;

/* Instead of updating the runner_orders , I cleaned and transformed the existing table and create a new table
named runner_orders_new with the existing data */

CREATE TABLE runner_orders_new AS
SELECT order_id,
       runner_id,
       CASE WHEN pickup_time = 'null' THEN NULL ELSE CAST(pickup_time AS TIMESTAMP) END AS pickup_time_adjusted,
       CAST(REGEXP_SUBSTR(distance, '[0-9]+(\.[0-9]+)?') AS FLOAT) AS dist_adjusted,
       CAST(REGEXP_SUBSTR(duration, '^[0-9]+') AS INT) AS dur_adjusted,
       CASE WHEN cancellation IN ('null', '') THEN NULL ELSE cancellation END AS cancellation_adjusted
FROM runner_orders;


	
select * from runner_orders;
select * from runner_orders_new;


-- CASE STUDY QUESTIONS

-- A. Pizza Metrics
-- Question 1: How many pizzas were ordered?

SELECT COUNT(*) AS Total_orders
FROM customer_orders;


-- Question 2: How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS Unique_Customerorders
FROM customer_orders;


-- Question 3: How many successful orders were delivered by each runner?

SELECT runner_id,
       COUNT(order_id) AS Successful_orders
FROM runner_orders_new
WHERE cancellation_adjusted IS NULL
GROUP BY runner_id;


-- Question 4: How many of each type of pizza was delivered?

SELECT pn.pizza_name,
       COUNT(co.order_id) AS successful_orders
FROM customer_orders co
JOIN runner_orders_new ro 
ON co.order_id = ro.order_id
JOIN pizza_names pn 
ON co.pizza_id = pn.pizza_id
WHERE cancellation_adjusted IS NULL
GROUP BY pn.pizza_name;


-- Question 5: How many Vegetarian and Meatlovers were ordered by each customer?

SELECT co.customer_id,
       COUNT(CASE WHEN pizza_name = 'Vegetarian' THEN 1 END) AS Vegetarian_count,
       COUNT(CASE WHEN pizza_name = 'Meatlovers' THEN 1 END) AS Meatlovers_count
FROM customer_orders co
JOIN runner_orders_new ro ON co.order_id = ro.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id;


-- Question6: What was the maximum number of pizzas delivered in a single order?

WITH Delivered_pizzas AS (
    SELECT co.order_id,
           COUNT(co.pizza_id) AS pizzas_delivered
    FROM customer_orders co
    JOIN runner_orders_new ro 
    ON co.order_id = ro.order_id
    WHERE cancellation_adjusted IS NULL
    GROUP BY co.order_id
)
SELECT
    order_id,
    pizzas_delivered
FROM
    ( SELECT order_id,
             pizzas_delivered,
             RANK() OVER (ORDER BY pizzas_delivered DESC) AS rnk
      FROM Delivered_pizzas
    ) x
WHERE x.rnk = 1;
 

-- Question 7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT co.customer_id,
       COUNT(CASE WHEN co.exclusions <> '' OR co.extras <> '' THEN 1 END) AS changes,
       COUNT(CASE WHEN co.exclusions = '' AND co.extras = '' THEN 1 END) AS no_changes
FROM customer_orders co
JOIN runner_orders_new ro ON co.order_id = ro.order_id
WHERE cancellation_adjusted IS NULL
GROUP BY co.customer_id;



-- Question 8: How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(*) AS special_pizzas
FROM customer_orders co
JOIN runner_orders_new ro ON co.order_id = ro.order_id
WHERE co.exclusions <> ''
      AND co.extras <> ''
      AND cancellation_adjusted IS NULL;


-- Question 9: What was the total volume of pizzas ordered for each hour of the day?

SELECT EXTRACT(HOUR FROM order_time) AS hour_of_the_day, 
       COUNT(pizza_id) AS pizzas_count
FROM customer_orders
GROUP BY hour_of_the_day
ORDER BY hour_of_the_day ASC;


-- Question 10:  What was the volume of orders for each day of the week?

SELECT TO_CHAR(order_time, 'Day') AS day_of_the_week, 
       COUNT(pizza_id) AS pizzas_count
FROM customer_orders
GROUP BY day_of_the_week
ORDER BY day_of_the_week ASC;


-- B. Runner and Customer Experience

-- Question 1: How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT EXTRACT(WEEK FROM (registration_date + INTERVAL '1 week')) AS week_num,
       COUNT(*) AS signups_per_week
FROM runners
GROUP BY week_num
ORDER BY week_num;


-- Question 2: What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?


WITH avg_time_cte AS (
    SELECT ro.runner_id, 
    	   AVG(ro.pickup_time_adjusted - co.order_time) AS avg_time
    FROM runner_orders_new ro
    JOIN customer_orders co ON ro.order_id = co.order_id
    WHERE ro.cancellation_adjusted IS NULL
    GROUP BY ro.runner_id
)
SELECT runner_id,
       CONCAT(EXTRACT(MINUTE FROM avg_time), ' minutes') AS avg_arrival_time
FROM avg_time_cte;


-- Question 3: Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH relation_cte AS (
    SELECT DISTINCT ro.order_id,
           ro.pickup_time_adjusted - co.order_time AS time_required,
           COUNT(*) OVER (PARTITION BY ro.order_id) AS pizza_count
    FROM runner_orders_new ro
    JOIN customer_orders co ON ro.order_id = co.order_id
    WHERE ro.cancellation_adjusted IS NULL
)
SELECT pizza_count,
       CONCAT(ROUND(AVG(EXTRACT(MINUTE FROM time_required))), ' minutes') AS avg_time_required
FROM relation_cte
GROUP BY pizza_count
ORDER BY pizza_count;


-- Question 4: What was the average distance travelled for each customer?

SELECT co.customer_id,
       CONCAT(ROUND(AVG(ro.dist_adjusted)::NUMERIC,1),' km') AS avg_distance
FROM runner_orders_new ro
JOIN customer_orders co ON ro.order_id = co.order_id
WHERE ro.cancellation_adjusted IS NULL
GROUP BY co.customer_id
ORDER BY co.customer_id;


-- Question 5: What was the difference between the longest and shortest delivery times for all orders?

SELECT CONCAT(MAX(dur_adjusted),' minutes') AS max_deliverytime,
       CONCAT(MIN(dur_adjusted),' minutes') AS min_deliverytime,
       CONCAT(MAX(dur_adjusted)-MIN(dur_adjusted), ' minutes') AS delivery_timediff
FROM runner_orders_new
WHERE cancellation_adjusted IS NULL;


-- Question 6: What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT order_id,
	   runner_id,
	   CONCAT(ROUND(AVG((dist_adjusted*60)/dur_adjusted)::NUMERIC,1),' km') AS avg_speed
FROM runner_orders_new
WHERE cancellation_adjusted is null
GROUP BY order_id,runner_id;


--Question 7: What is the successful delivery percentage for each runner?

SELECT r.runner_id,
       COUNT(ro.order_id) AS total_orders,
       COUNT(ro.dist_adjusted) AS successful_orders,
       CASE WHEN COUNT(ro.order_id) = 0 THEN NULL
            ELSE CONCAT(ROUND((COUNT(ro.dist_adjusted)::numeric / COUNT(ro.order_id)::numeric) * 100), '%') 
            END AS delivery_percentage
FROM runners r
LEFT JOIN runner_orders_new ro ON r.runner_id = ro.runner_id
GROUP BY r.runner_id
ORDER BY r.runner_id;


-- C. Ingredient Optimization

 select * from pizza_names;
 select * from pizza_recipes;
 select * from pizza_toppings;

-- For the below questions I created virtual table for pizza_recipes by splitting the comma-seprated records of toppings to distinct rows

CREATE VIEW pizza_recipes_new AS
SELECT pizza_id,
       UNNEST(STRING_TO_ARRAY(toppings, ','))::INTEGER AS toppings
FROM pizza_recipes;


-- Question 1: What are the standard ingredients for each pizza?

SELECT pn.pizza_id,
       pn.pizza_name,
       STRING_AGG(pt.topping_name, ',') AS standard_ingredients
FROM pizza_recipes_new pr
INNER JOIN pizza_names pn ON pr.pizza_id = pn.pizza_id
INNER JOIN pizza_toppings pt ON pr.toppings=pt.topping_id
GROUP BY pn.pizza_id,pn.pizza_name;


-- Question 2: What was the most commonly added extra?

WITH extras_cte AS (
  SELECT pizza_id, 
         UNNEST(STRING_TO_ARRAY(extras, ','))::INTEGER AS extras
  FROM customer_orders
)
SELECT topping_name AS most_commonly_added_extra,
       COUNT(*) AS times_added
FROM extras_cte ec
INNER JOIN pizza_toppings pt ON pt.topping_id = ec.extras
GROUP BY topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;


-- Question 3: What was the most common exclusion?

WITH exclusions_cte AS (
  SELECT pizza_id, 
         UNNEST(STRING_TO_ARRAY(exclusions, ','))::INTEGER AS exclusions
  FROM customer_orders
)
SELECT topping_name AS most_commonly_added_exclusion,
       COUNT(*) AS times_added
FROM exclusions_cte ec
INNER JOIN pizza_toppings pt ON pt.topping_id = ec.exclusions
GROUP BY topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;


/* Question 4: Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */
--with exclusions_cte as (
--SELECT  unnest(string_to_array(exclusions, ',')) AS exclusions
--FROM customer_orders 
--),
--extras_cte as (
--SELECT unnest(string_to_array(extras, ',')) AS extras
--FROM customer_orders 
--)



-- Pricing and Ratings

/* Question 1: If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
how much money has Pizza Runner made so far if there are no delivery fees? */

WITH Pizza_runner_sales AS (
  SELECT co.order_id,
         pn.pizza_id,
         pn.pizza_name,
         CASE WHEN pn.pizza_name = 'Meatlovers' THEN 12 ELSE 10 END AS price
  FROM customer_orders co 
  INNER JOIN runner_orders_new ro ON co.order_id = ro.order_id
  INNER JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
  WHERE ro.cancellation_adjusted IS NULL
)

SELECT CONCAT('$ ', SUM(price)) AS Total_sales
FROM Pizza_runner_sales;


-- Question 2: What if there was an additional $1 charge for any pizza extras?

WITH Pizza_runner_sales AS (
  SELECT co.order_id,
         pn.pizza_id,
         pn.pizza_name,
         CASE WHEN pn.pizza_name = 'Meatlovers' THEN 12 ELSE 10 END AS price,
         CASE WHEN LENGTH(extras) = 1 THEN 1
              WHEN LENGTH(extras) > 1 THEN 2
              ELSE 0 END AS extras_price
  FROM customer_orders co
  INNER JOIN runner_orders_new ro ON co.order_id = ro.order_id
  INNER JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
  WHERE ro.cancellation_adjusted IS NULL
)

SELECT CONCAT('$ ', SUM(price) + SUM(extras_price)) AS Total_sales
FROM Pizza_runner_sales;



/* Question 3: The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
how would you design an additional table for this new dataset - generate a schema for this new table and 
insert your own data for ratings for each successful customer order between 1 to 5. */
DROP TABLE IF EXISTS rating_system;

CREATE TABLE rating_system (
    order_id INT DEFAULT NULL,
    customer_id INT DEFAULT NULL,
    runner_id INT DEFAULT NULL,
    rating INT DEFAULT NULL
);

INSERT INTO rating_system
(order_id, customer_id, runner_id, rating)
VALUES
(1, 101, 1, 4),
(2, 101, 1, 5),
(3, 102, 1, 4),
(4, 103, 2, 2),
(5, 104, 3, 3),
(7, 105, 2, 1),
(8, 102, 2, 4),
(10, 104, 1, 5);


SELECT * FROM rating_system;

/* Question 4: Using your newly generated table - can you join all of the information together 
   to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed  
Total number of pizzas */


WITH order_details AS (
  SELECT co.customer_id,
         co.order_id,
         ro.runner_id,
         co.order_time,
         ro.pickup_time_adjusted AS pickup_time,
         ro.pickup_time_adjusted - co.order_time AS order_pickup_duration,
         ro.dur_adjusted AS delivery_duration,
         ROUND((ro.dist_adjusted / (ro.dur_adjusted / 60.0))::NUMERIC, 1) AS avg_speed,
         COUNT(*) OVER (PARTITION BY ro.order_id) AS total_orders,
         ROW_NUMBER() OVER (PARTITION BY ro.order_id) AS rn
  FROM customer_orders co
  RIGHT JOIN runner_orders_new ro ON co.order_id = ro.order_id
  WHERE ro.cancellation_adjusted IS NULL
)

SELECT o.customer_id,
       o.order_id,
       o.runner_id,
       rs.rating,
       o.order_time,
       o.pickup_time,
       o.order_pickup_duration,
       o.delivery_duration,
       o.avg_speed,
       o.total_orders
FROM order_details o
INNER JOIN rating_system rs ON o.order_id = rs.order_id
WHERE o.rn = 1;

-- # Using Sub Query
  
select sq.customer_id,
	   sq.order_id,
	   sq.runner_id,
	   rs.rating,
	   sq.order_time,
	   sq.pickup_time,
	   sq.order_pickup_duration,
	   sq.delivery_duration,
	   sq.avg_speed,
	   sq.total_orders
from rating_system rs 
join (
select co.customer_id,
	   co.order_id,
	   ro.runner_id,
	   co.order_time,
	   ro.pickup_time_adjusted as pickup_time,
	   ro.pickup_time_adjusted - co.order_time AS order_pickup_duration,
	   ro.dur_adjusted as delivery_duration,
	   ROUND((ro.dist_adjusted / (ro.dur_adjusted / 60.0))::NUMERIC, 1) AS avg_speed,
	   COUNT(*) OVER (PARTITION BY ro.order_id) AS total_orders,
	   ROW_NUMBER() OVER (PARTITION BY ro.order_id) AS rn
from customer_orders co 
right join runner_orders_new ro on co.order_id=ro.order_id
where ro.cancellation_adjusted is null
) sq
on sq.order_id=rs.order_id
where sq.rn=1

/* Question 5: If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
and each runner is paid $0.30 per kilometre traveled 
how much money does Pizza Runner have left over after these deliveries? */

WITH pizza_income_cte AS (
  SELECT co.order_id, 
         ro.runner_id, 
         ro.dist_adjusted, 
         pn.pizza_name, 
         CASE WHEN pn.pizza_name = 'Meatlovers' THEN 12 ELSE 10 END AS pizza_price
  FROM customer_orders co
  INNER JOIN runner_orders_new ro ON co.order_id = ro.order_id
  INNER JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
  WHERE ro.cancellation_adjusted IS NULL
),
pizza_income_per_order_cte AS 
(
  SELECT SUM(pizza_price) AS sales_per_order, 
         AVG(dist_adjusted)*0.30 AS runner_payment
  FROM pizza_income_cte
  GROUP BY order_id
)
SELECT CONCAT('$ ',SUM(sales_per_order) - SUM(runner_payment)) AS Profit
FROM pizza_income_per_order_cte;