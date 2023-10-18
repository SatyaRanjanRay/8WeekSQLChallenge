CREATE SCHEMA foodie_fi;
SET search_path = foodie_fi;

CREATE TABLE plans (
  plan_id INTEGER,
  plan_name VARCHAR(13),
  price DECIMAL(5,2)
);

INSERT INTO plans
  (plan_id, plan_name, price)
VALUES
  ('0', 'trial', '0'),
  ('1', 'basic monthly', '9.90'),
  ('2', 'pro monthly', '19.90'),
  ('3', 'pro annual', '199'),
  ('4', 'churn', null);



CREATE TABLE subscriptions (
  customer_id INTEGER,
  plan_id INTEGER,
  start_date DATE
);

INSERT INTO subscriptions
  (customer_id, plan_id, start_date)
VALUES
  ('1', '0', '2020-08-01'),
  ('1', '1', '2020-08-08'),
  ('2', '0', '2020-09-20'),
  ('2', '3', '2020-09-27'),
  ('3', '0', '2020-01-13'),
 ......... 
 
 
 
 

 select * from plans;
 select * from subscriptions;
 
 
--A. Customer Journey 
 
 /* Based off the 8 sample customers provided in the sample from the subscriptions table, 
 write a brief description about each customer’s onboarding journey. */
 
 
SELECT s.customer_id,
       p.plan_name,
       p.price,
       s.start_date
FROM plans p
INNER JOIN subscriptions s ON p.plan_id = s.plan_id
WHERE s.customer_id IN (1, 2, 11, 13, 15, 16, 18, 19);


-- Description

/* Customer 1 signed up for a free trial of Foodie-Fi on August 1, 2000 
   and later subscribed to the Basic Monthly Plan on August 8, 2020 for a fee of $9.90

   Customer 2 signed up for a free trial of Foodie-Fi on September 20, 2020 
   and later subscribed to the Pro Annual Plan on September 27, 2020 for a fee of $199 
   
   Customer 11 signed up for a free trial of Foodie-Fi on November 19, 2020 
   and cancelled the service on November 26, 2020, right after the end of the 7-day free trial 
   
   Customer 13 started a free trial of Foodie-Fi on December 15, 2020. 
   After the trial period ended, they subscribed to the Basic Monthly Plan on December 22, 2020 for a fee of $9.90
   Later, on March 29, 2021, they upgraded to the Pro Monthly Plan for a price of $19.90 
   
   Customer 15 started a free trial of Foodie-Fi on March 17, 2020. 
   After the trial period ended, they subscribed to the Pro Monthly Plan on March 24, 2020 for a fee of $19.90
   However, they cancelled the service on April 29, 2020, after using it for a month
   
   Customer 16 started a free trial of Foodie-Fi on May 31, 2020. 
   After the trial period ended, they subscribed to the Basic Monthly Plan on June 7, 2020 for a fee of $9.90
   Later, on October 21, 2020, they upgraded to the Pro Annual Plan for a price of $199.00
	   
   Customer 18 started a free trial of Foodie-Fi on July 6, 2020. 
   After the trial period ended, they subscribed to the Pro Monthly Plan on July 13, 2020 for a fee of $19.90

   Customer 19 started a free trial of Foodie-Fi on June 22, 2020. 
   After the trial period ended, they subscribed to the Pro Monthly Plan on June 29, 2020 for a fee of $19.90
   Later, on August 29, 2020, they upgraded to the Pro Annual Plan for a price of $199.00  */


-- B. Data Analysis Questions

-- Question 1: How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM subscriptions;


-- Question 2: What is the monthly distribution of trial plan start_date values for our dataset  
-- use the start of the month as the group by value

SELECT EXTRACT(month from s.start_date) AS month, 
       TO_CHAR(s.start_date, 'Month') AS month_name,
       COUNT(*) AS trial_count
FROM subscriptions s
INNER JOIN plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY month,month_name
ORDER BY month

--Question3: What plan start_date values occur after the year 2020 for our dataset? 
--Show the breakdown by count of events for each plan_name

SELECT p.plan_name,
       COUNT(*) AS count
FROM subscriptions s
INNER JOIN plans p ON s.plan_id = p.plan_id
WHERE extract (year from s.start_date) > '2020'
GROUP BY p.plan_name
ORDER BY COUNT(*) desc;

-- Question 4: What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

WITH churned_cte AS (
  SELECT COUNT(DISTINCT s.customer_id) AS churn_count
  FROM subscriptions s
  INNER JOIN plans p ON s.plan_id = p.plan_id
  WHERE p.plan_name = 'churn'
)
SELECT COUNT(DISTINCT s.customer_id) AS total_customers,
       churn_count,
       CONCAT(ROUND(churn_count/COUNT(DISTINCT s.customer_id)::NUMERIC * 100, 1),'%') AS churn_rate
FROM subscriptions s
CROSS JOIN churned_cte 
GROUP BY churn_count;

-- Question 5: How many customers have churned straight after their initial free trial 
--             What percentage is this rounded to the nearest whole number?  
 
WITH post_plan_cte AS (
  SELECT s.customer_id,
         p.plan_name,
         LEAD(p.plan_name) OVER (PARTITION BY customer_id ORDER BY p.plan_id) AS post_trial_plan
  FROM plans p
  INNER JOIN subscriptions s
  ON p.plan_id = s.plan_id
)

SELECT COUNT(DISTINCT s.customer_id) AS total_customers,
       COUNT(DISTINCT pc.customer_id) AS posttrial_churned_customers,
       CONCAT(ROUND(COUNT(DISTINCT pc.customer_id) / COUNT(DISTINCT s.customer_id)::numeric * 100),'%') AS post_trial_churnrate
FROM post_plan_cte pc
CROSS JOIN subscriptions s
WHERE pc.plan_name = 'trial' AND pc.post_trial_plan = 'churn';



-- Question 6: What is the number and percentage of customer plans after their initial free trial?

WITH post_plan_cte AS (
  SELECT s.customer_id,
         p.plan_name,
         LEAD(p.plan_name) OVER (PARTITION BY customer_id ORDER BY p.plan_id) AS post_trial_plan
  FROM plans p
  INNER JOIN subscriptions s
  ON p.plan_id = s.plan_id
),
total_customers_cte AS (
  SELECT COUNT(DISTINCT customer_id) AS Total_customers
  FROM subscriptions
)
SELECT post_trial_plan,
       Total_customers,
       COUNT(post_trial_plan) AS plan_counts,
       CONCAT(ROUND(COUNT(post_trial_plan) / Total_customers::numeric * 100),'%' ) AS planwise_percentage
FROM post_plan_cte pc
CROSS JOIN total_customers_cte t
WHERE plan_name = 'trial'
GROUP BY post_trial_plan, Total_customers
ORDER BY COUNT(post_trial_plan) DESC ;

       

-- Question 7: What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH latest_plans_cte AS (
  SELECT s.customer_id, 
         s.plan_id, 
         p.plan_name, 
         s.start_date, 
         DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.start_date DESC) AS rnk
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE s.start_date <= '2020-12-31'
),
total_customers_cte AS (
  SELECT COUNT(DISTINCT customer_id) AS total_customers
  FROM subscriptions
)

SELECT plan_name,
       COUNT(plan_name) AS count,
       CONCAT(ROUND(COUNT(plan_name) / total_customers::numeric * 100, 1), ' %') AS percentage
FROM latest_plans_cte
CROSS JOIN total_customers_cte
WHERE rnk = 1
GROUP BY plan_name, total_customers
ORDER BY COUNT(plan_name) DESC;


-- Question 8: How many customers have upgraded to an annual plan in 2020?

select p.plan_name,
	   count(*) as count
from plans p
inner join subscriptions s on p.plan_id=s.plan_id 
where extract(year from s.start_date)='2020' and p.plan_name='pro annual'
group by p.plan_name;


-- Question 9: How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH annual_plan_cte AS (
  SELECT s.customer_id
  FROM plans p
  INNER JOIN subscriptions s ON p.plan_id = s.plan_id
  WHERE p.plan_name = 'pro annual'
),
upgrade_date_cte AS (
  SELECT ap.customer_id,
         p.plan_name,
         s.start_date AS joining_date,
         LEAD(start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS updated_date
  FROM annual_plan_cte ap
  INNER JOIN subscriptions s ON ap.customer_id = s.customer_id
  INNER JOIN plans p ON s.plan_id = p.plan_id
  WHERE p.plan_name IN ('trial', 'pro annual')
)

SELECT CONCAT(ROUND(AVG(updated_date - joining_date), 1), ' days') AS avg_days
FROM upgrade_date_cte;


-- Question 10: How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH plans_cte AS (
  SELECT s.customer_id,
         s.start_date,
         p.plan_name,
         LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS latest_plan
  FROM subscriptions s 
  INNER JOIN plans p ON s.plan_id = p.plan_id 
  WHERE EXTRACT(YEAR FROM s.start_date) = '2020'
)

SELECT COUNT(*) AS downgraded_count
FROM plans_cte
WHERE plan_name = 'pro monthly' AND latest_plan = 'basic monthly';




-- C. Challenge Payment Question

/* The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments */

/*  To solve this challenge, we would do some steps​

STEP 1:  I filtered the subscriptions to only include those made in the year 2020.                  
I used the lead window function to calculate the end date for the next plan whenever it was available. 
I also excluded any plans labeled as 'trial' or 'churn' since no payments were made for these. */

SELECT s.customer_id,
       s.plan_id,
       p.plan_name,
       s.start_date,
       LEAD(s.start_date) OVER (PARTITION BY customer_id ORDER BY s.start_date, s.plan_id) AS end_date,
       p.price AS amount
FROM subscriptions s 
INNER JOIN plans p ON p.plan_id = s.plan_id
WHERE EXTRACT(YEAR FROM s.start_date) = '2020' AND p.plan_name NOT IN ('churn', 'trial');


-- STEP-2:  I replaced the null values in the 'end date' column with the last day of the year 2020 
-- indicating  that it was the last plan the user had for that year.

WITH cte AS (
  SELECT s.customer_id,
         s.plan_id,
         p.plan_name,
         s.start_date,
         LEAD(s.start_date) OVER (PARTITION BY customer_id ORDER BY s.start_date, s.plan_id) AS end_date,
         p.price AS amount
  FROM subscriptions s 
  INNER JOIN plans p ON p.plan_id = s.plan_id
  WHERE EXTRACT(YEAR FROM s.start_date) = '2020'
    AND p.plan_name NOT IN ('churn', 'trial')
)
SELECT customer_id,
       plan_id,
       plan_name,
       start_date,
       COALESCE(end_date, '2020-12-31'),
       amount
FROM cte;


-- STEP-3: 

WITH RECURSIVE cte AS (
  SELECT
    s.customer_id,
    s.plan_id,
    p.plan_name,
    s.start_date,
    LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date, s.plan_id) AS end_date,
    p.price AS amount
  FROM subscriptions s
  INNER JOIN plans p ON p.plan_id = s.plan_id
  WHERE EXTRACT(YEAR FROM s.start_date) = 2020
    AND p.plan_name NOT IN ('churn', 'trial')
),
cte1 AS (
  SELECT
    customer_id,
    plan_id,
    plan_name,
    start_date,
    COALESCE(end_date, '2020-12-31') AS end_date,
    amount
  FROM cte
),
cte2 AS (
  SELECT
    customer_id,
    plan_id,
    plan_name,
    start_date::date, -- Cast to date
    COALESCE(end_date, '2020-12-31')::date AS end_date, -- Cast to date
    amount
  FROM cte1
  UNION ALL
  SELECT
    customer_id,
    plan_id,
    plan_name,
    (start_date + INTERVAL '1 month')::date AS start_date, -- Cast to date
    end_date::date, -- Cast to date
    amount
  FROM cte2
  WHERE plan_name = 'pro annual' AND end_date > (start_date + INTERVAL '1 month')
),
cte3 AS (
  SELECT *,
    LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS last_plan,
    LAG(amount) OVER (PARTITION BY customer_id ORDER BY start_date) AS last_amount_paid,
    RANK() OVER (PARTITION BY customer_id ORDER BY start_date) AS payment_order
  FROM cte2
)
SELECT
  customer_id,
  plan_id,
  plan_name,
  start_date,
  (CASE
    WHEN plan_id IN (2, 3) AND last_plan = 1 THEN amount - last_amount_paid
    ELSE amount
  END) AS amount,
  payment_order
FROM cte3;



 
 
 
 
 
 
 
 
 
 
 
 