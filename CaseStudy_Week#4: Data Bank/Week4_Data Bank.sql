CREATE SCHEMA data_bank;
SET search_path = data_bank;

CREATE TABLE regions (
  region_id INTEGER,
  region_name VARCHAR(9)
);

INSERT INTO regions
  (region_id, region_name)
VALUES
  ('1', 'Australia'),
  ('2', 'America'),
  ('3', 'Africa'),
  ('4', 'Asia'),
  ('5', 'Europe');
  
 select * from regions;
 
 CREATE TABLE customer_nodes (
  customer_id INTEGER,
  region_id INTEGER,
  node_id INTEGER,
  start_date DATE,
  end_date DATE
);

 CREATE TABLE customer_transactions (
  customer_id INTEGER,
  txn_date DATE,
  txn_type VARCHAR(10),
  txn_amount INTEGER
);

-- Refer to 8weeksqlchallenge.com for insert statement for both customer_nodes and customer_transactions table

select * from regions;
select * from customer_nodes;
select * from customer_transactions;



-- A. Customer Nodes Exploration

-- Question 1: How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS node_count
FROM customer_nodes;


-- Question 2: What is the number of nodes per region?

SELECT r.region_name,
       COUNT(DISTINCT cn.node_id) AS regionwise_node_count
FROM regions r
INNER JOIN customer_nodes cn ON r.region_id = cn.region_id
GROUP BY r.region_name;


--Question 3: How many customers are allocated to each region?

SELECT r.region_name,
       COUNT(DISTINCT cn.customer_id) AS regionwise_customer_count
FROM regions r
INNER JOIN customer_nodes cn ON r.region_id = cn.region_id
GROUP BY r.region_name
ORDER BY regionwise_customer_count DESC;


-- Question 4: How many days on average are customers reallocated to a different node?

SELECT ROUND(AVG(end_date - start_date)) AS average_reallocation_days
FROM customer_nodes
WHERE end_date <>'9999-12-31';


-- Question 5: What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH reallocation_cte AS (
  SELECT region_name,
         ROUND(end_date - start_date) AS reallocation_days
  FROM regions r 
  INNER JOIN customer_nodes cn ON r.region_id = cn.region_id
  WHERE end_date <> '9999-12-31'
)

SELECT region_name, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reallocation_days) AS median,
       PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY reallocation_days) AS percentile_80th,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY reallocation_days) AS percentile_95th
FROM reallocation_cte
GROUP BY region_name;


-- B. Customer Transactions

-- Question 1:  What is the unique count and total amount for each transaction type?

SELECT txn_type AS transaction_type,
       COUNT(txn_type) AS count,
       TO_CHAR(SUM(txn_amount), 'FM$ 999,999,999') AS total_amount
FROM customer_transactions
GROUP BY txn_type
ORDER BY count DESC;


-- Question 2: What is the average total historical deposit counts and amounts for all customers?

WITH transaction_details AS (
  SELECT customer_id,
         COUNT(txn_type) AS deposit_count,
         AVG(txn_amount) AS avg_amount
  FROM customer_transactions
  WHERE txn_type = 'deposit'
  GROUP BY customer_id
)

SELECT ROUND(AVG(deposit_count)) AS deposit_count,
       CONCAT('$ ', ROUND(AVG(avg_amount), 2)) AS avg_deposit_amount
FROM transaction_details;


-- Question 3: For each month - how many Data Bank customers make more than 1 deposit 
-- and either 1 purchase or 1 withdrawal in a single month?

WITH transaction_details AS (
  SELECT customer_id,
         EXTRACT(MONTH FROM txn_date) AS month,
         UPPER(TO_CHAR(txn_date, 'month')) AS month_name,
         COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit,
         COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase,
         COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal
  FROM customer_transactions 
  GROUP BY customer_id, month, month_name
)

SELECT month,
       month_name,
       COUNT(DISTINCT customer_id) AS customer_counts
FROM transaction_details
WHERE deposit > 1 AND (purchase > 0 OR withdrawal > 0)
GROUP BY month, month_name
ORDER BY month;

-- Question 4: What is the closing balance for each customer at the end of the month?

SELECT customer_id,
       EXTRACT(MONTH FROM txn_date) AS month,
       UPPER(TO_CHAR(txn_date, 'month')) AS month_name,
       SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS closing_balance
FROM customer_transactions 
GROUP BY customer_id, month, month_name
ORDER BY customer_id, month;


-- Question 5: What is the percentage of customers who increase their closing balance by more than 5%?

WITH monthly_balance_cte as (
  SELECT customer_id,
         EXTRACT(MONTH FROM txn_date) AS month,
         SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS closing_balance
  FROM customer_transactions
  GROUP BY customer_id, month
),
closingbalance_gt5_cte AS (
  SELECT COUNT(DISTINCT customer_id) AS customer_count
  FROM (SELECT customer_id, 
              (LEAD(closing_balance) OVER(PARTITION BY customer_id ORDER BY month) - closing_balance) / closing_balance::numeric * 100 AS percent_change
        FROM monthly_balance_cte
       ) sb
    WHERE percent_change > 5
)
SELECT COUNT(DISTINCT ct.customer_id) AS total_customers,
       MAX(customer_count) AS customer_count, 
       CONCAT(ROUND(MAX(customer_count) / COUNT(DISTINCT ct.customer_id)::numeric * 100, 2), ' %') AS customer_percentage
FROM closingbalance_gt5_cte cb 
CROSS JOIN customer_transactions ct;


-- C. Data Allocation Challenge

/* To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

Option 1: data is allocated based off the amount of money at the end of the previous month 
Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
Option 3: data is updated real-time
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

running customer balance column that includes the impact each transaction
customer balance at the end of each month
minimum, average and maximum values of the running balance for each customer
Using all of the data available - how much data would have been required for each option on a monthly basis? */


-- Running balance

SELECT *, 
       SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) 
       OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM customer_transactions;

-- Monthly balance

SELECT customer_id,
       EXTRACT(MONTH FROM txn_date) AS month,
       UPPER(TO_CHAR(txn_date, 'month')) AS month_name,
       SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS closing_balance
FROM customer_transactions 
GROUP BY customer_id, month, month_name
ORDER BY customer_id, month;

-- Min,Max & Average Transaction

WITH running_bal_cte AS (
  SELECT *,
         SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) 
         OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
  FROM customer_transactions
)

SELECT customer_id,
       MIN(running_balance) AS min_transaction,
       MAX(running_balance) AS max_transaction,
       ROUND(AVG(running_balance), 2) AS avg_transaction
FROM running_bal_cte
GROUP BY customer_id
ORDER BY customer_id;
