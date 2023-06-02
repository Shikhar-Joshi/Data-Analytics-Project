USE DATABASE dannyc
;

CREATE OR REPLACE SCHEMA pizza_runner
;

USE schema pizza_runner
;
DROP TABLE IF EXISTS runners
;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
)
;
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15')
;


DROP TABLE IF EXISTS customer_orders
;
CREATE OR REPLACE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(20),
  extras VARCHAR(20),
  order_time TIMESTAMP
)
;

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
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
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49')
;

DROP TABLE IF EXISTS runner_orders
;
CREATE OR REPLACE TABLE runner_orders (
  order_id VARCHAR(5),
  runner_id VARCHAR(5),
  pickup_time VARCHAR(50),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
)
;

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
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
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null')
;

DROP TABLE IF EXISTS pizza_names
;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
)
;
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian')
;

DROP TABLE IF EXISTS pizza_recipes
;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
)
;
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12')
;

DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
)
;
INSERT INTO pizza_toppings
  (topping_id, topping_name)
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
  (12, 'Tomato Sauce')
;
  
// Data Cleaning for customer_orders table
// Creating new table to perform operations and to prevent loss of original data
CREATE OR REPLACE TABLE customer_orders_placeholder AS
SELECT * FROM customer_orders;

UPDATE customer_orders_placeholder
SET exclusions = CASE exclusions
                    WHEN 'null' THEN NULL
                    ELSE exclusions
                 END,
    extras = CASE extras
                    WHEN 'null' THEN NULL
                    ELSE extras
                 END
    ;
    
ALTER TABLE customer_orders_placeholder
RENAME TO customer_orders_clean;

// Data Cleaning for runner_orders table
// creating new table for data cleaning
CREATE OR REPLACE TEMPORARY TABLE runner_orders_placeholder AS
SELECT * FROM runner_orders;

// Changing datatype of runner_id. Since direct modification of VARCHAR to NUMBER is not allowed in Snowflake, we have to create a new column and then perform our operations
ALTER TABLE runner_orders_placeholder 
ADD COLUMN runner_id_placeholder NUMBER(38,0);
UPDATE runner_orders_placeholder 
SET runner_id_placeholder = CAST(runner_id AS NUMBER(38,0));

ALTER TABLE runner_orders_placeholder 
DROP COLUMN runner_id;

ALTER TABLE runner_orders_placeholder 
RENAME COLUMN runner_id_placeholder TO runner_id;

//changing datatype of order_id
ALTER TABLE runner_orders_placeholder 
ADD COLUMN order_id_placeholder NUMBER(38,0);
UPDATE runner_orders_placeholder 
SET order_id_placeholder = CAST(order_id AS NUMBER(38,0));

ALTER TABLE runner_orders_placeholder 
DROP COLUMN order_id;

ALTER TABLE runner_orders_placeholder 
RENAME COLUMN order_id_placeholder TO order_id;

// Creating new column to change null values of distance column
ALTER TABLE runner_orders_placeholder
ADD distance_km_placeholder NUMBER(4,2);

// removing 'km' from the table
UPDATE runner_orders_placeholder
SET distance = REPLACE(distance, 'km', '');

UPDATE runner_orders_placeholder
SET distance_km_placeholder = CASE distance
                        WHEN 'null' THEN NULL
                        ELSE distance
                      END;
                      
ALTER TABLE runner_orders_placeholder 
DROP COLUMN distance;
ALTER TABLE runner_orders_placeholder 
RENAME COLUMN distance_km_placeholder TO distance_km;

// Creating new column to change null values of pickup_time column
ALTER TABLE runner_orders_placeholder
ADD pickup_time_placeholder DATETIME;

UPDATE runner_orders_placeholder
SET pickup_time_placeholder = CASE pickup_time
                        WHEN 'null' THEN NULL
                        ELSE pickup_time
                      END;
                      
ALTER TABLE runner_orders_placeholder 
DROP COLUMN pickup_time;
ALTER TABLE runner_orders_placeholder 
RENAME COLUMN pickup_time_placeholder TO pickup_time;

UPDATE runner_orders_placeholder
SET cancellation = CASE cancellation
                    WHEN 'null' THEN NULL
                    ELSE cancellation
                   END;

ALTER TABLE runner_orders_placeholder
ADD duration_placeholder NUMBER(4,0);

// replacing 'null' string to actual NULL
UPDATE runner_orders_placeholder
SET duration = NULL
WHERE duration = 'null';

// removing minutes, mins, minute from duration column from the table
UPDATE runner_orders_placeholder
SET duration_placeholder = CASE
                            WHEN duration IS NOT NULL THEN REGEXP_REPLACE(duration, '[^0-9]', '')
                            ELSE NULL
                           END;
ALTER TABLE runner_orders_placeholder
DROP COLUMN duration;
ALTER TABLE runner_orders_placeholder
RENAME COLUMN duration_placeholder TO duration;

//Creating new table to hold clean data
CREATE OR REPLACE TABLE runner_orders_clean AS
SELECT order_id, runner_id, pickup_time, distance_km AS distance_km, duration, cancellation 
FROM runner_orders_placeholder;

DROP TABLE runner_orders_placeholder;

//****************************************< Start of Pizza Metrics>****************************************
//Q1. How many pizzas were ordered?
SELECT COUNT(*) AS num_of_pizzas_ordered
FROM customer_orders_clean;
/*
    Explanation:
    This code calculates the total number of pizzas ordered from the "customer_orders_clean" table. It uses the COUNT function to count the number of rows in the table, which corresponds to the number
    of pizzas ordered.
    
    Conclusion:
    Total 14 pizzas were ordered.
*/

//Q2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS uniq_customer_order
FROM customer_orders_clean;
/*
    Explanation:
    This code calculates the count of unique customer orders from the "customer_orders_clean" table. It uses the COUNT function along with the DISTINCT keyword to count the number of distinct (unique)
    values in the "order_id" column.
    
    Conclusion:
    Total 10 unique customer orders were made.
*/

//Q3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT_IF(distance_km IS NOT NULL) AS successful_order
FROM runner_orders_clean
GROUP BY 1;

/*
    Explanation:
    This code retrieves the count of successful orders for each runner from the "runner_orders_clean" table. It uses the COUNT_IF function to count the number of times the "distance_km" column is not
    NULL, indicating a successful order. The results are then grouped by the "runner_id" column, providing the count of successful orders for each individual runner.
    
    Conclusion:
    - Runner_id 1 delivered 4 orders successfully
    - Runner_id 2 delivered 3 orders successfully
    - Runner_id 3 delivered 1 orders successfully
*/

//Q4. How many of each type of pizza was delivered?
SELECT pizza_name, COUNT(*) AS pizza_ordered
FROM customer_orders_clean co
  JOIN runner_orders_clean ro ON ro.order_id = co.order_id
  JOIN pizza_names pn ON pn.pizza_id = co.pizza_id
WHERE ro.distance_km IS NOT NULL
GROUP BY 1;

/*
    Explanation:
    This code retrieves the count of how many times each pizza name appears in the "customer_orders_clean" table. It achieves this by joining the "customer_orders_clean" table with the 
    "runner_orders_clean" table and the "pizza_names" table based on the respective IDs. The condition "ro.distance_km IS NOT NULL" ensures that we include only those orders which are successfully
    delivered. The results are then grouped by the pizza name, and the count of orders for each pizza is calculated and displayed.
    
    Conclusion:
    - Vegetarian pizza was ordered 3 times
    - Meatlovers pizza was ordered 9 times.
*/

//Q5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT co.customer_id, pn.pizza_name, COUNT(*) AS Total_pizzas_ordered
FROM customer_orders co
  JOIN pizza_names pn ON pn.pizza_id = co.pizza_id
GROUP BY 1,2
ORDER BY co.customer_id;

/*
  Explanation:
  This query retrieves the customer ID, pizza name, and the total count of pizzas ordered for each combination of customer and pizza from the "customer_orders" and "pizza_names" tables. It uses a 
  JOIN operation to match the pizza ID between the two tables. The result is grouped by customer ID and pizza name, and then ordered by customer ID. This provides a summary of the total number of 
  pizzas ordered by each customer for each pizza type.
  
  Conclusion:
  - Customer_ID 101 ordered 1 Vegetarian and 2 Meatlovers pizza.
  - Customer_ID 102 ordered 1 Vegetarian and 2 Meatlovers pizza.
  - Customer_ID 103 ordered 1 Vegetarian and 3 Meatlovers pizza.
  - Customer_ID 104 ordered 3 Meatlovers pizza.
  - Customer_ID 105 ordered 1 Vegetarian.
*/

//Q6. What was the maximum number of pizzas delivered in a single order?
SELECT co.order_id AS order_id, COUNT(pizza_id) AS max_pizzas
FROM customer_orders co
  JOIN runner_orders_clean ro ON ro.order_id = co.order_id
WHERE ro.distance_km IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

/*
    Explanation:
    This query returns the order_id with the maximum number of pizza_id from the customer_orders table joined with the runner_orders_clean table on the order_id column. The query filters out rows where the
    distance_km column in the runner_orders table is NULL which means pizza is successfully delivered. The result is grouped by the first column (order_id) and ordered in descending order by the 
    second column (max_pizzas). Finally, only the first row of the result is returned to get the max number of pizzas delivered.
    
    Conclusion:
    Maximum number of pizzas delivered in a single order(in this case order id 4) are 3.
*/

//Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id, 
  COUNT_IF(
            (exclusions IS NOT NULL AND LENGTH(exclusions) > 0) 
              OR 
            (extras IS NOT NULL AND LENGTH(extras) > 0)
           ) AS pizzas_with_one_change,
  COUNT_IF(
            (exclusions IS NULL OR LENGTH(exclusions) = 0) 
              AND
            (extras IS  NULL OR LENGTH(extras) = 0)
           ) AS pizzas_with_no_change
FROM customer_orders_clean co
  JOIN runner_orders_clean ro ON ro.order_id = co.order_id
WHERE ro.distance_km IS NOT NULL
GROUP BY 1;
/*
    Explanation:
    This query calculates the number of pizzas with at least one change (either an exclusion or an extra) and the number of pizzas with no changes for each customer. It does this by joining the 
    customer_orders_clean and runner_orders_clean tables on the order_id column and filtering out any rows where the distance_km column in the runner_orders table is NULL(which means pizza is not successfully 
    delivered). The results are then grouped by customer_id, and the COUNT_IF function is used to count the number of rows that meet the specified conditions for pizzas with at least one change and 
    pizzas with no changes. The final result is a table with one row for each customer, showing their customer_id, the number of pizzas they ordered with at least one change, and the number of 
    pizzas they ordered with no changes.
    
    Conclusion:
    - Customer id 101 has 2 pizzas with no change.
    - Customer id 102 has 3 pizzas with no change.
    - Customer id 103 has 3 pizzas with atleast one change.
    - Customer id 104 has 2 pizzas with atleast one change and 1 pizza with no change.
    - Customer id 105 has 1 pizza with atleast one change.
*/

//Q8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT_IF(
                (exclusions IS NOT NULL AND LENGTH(exclusions) > 0)
                    AND
                (extras IS NOT NULL AND LENGTH(extras) > 0) 
             ) AS pizzas_with_exclusions_extras
FROM customer_orders_clean co
JOIN runner_orders_clean ro
  ON ro.order_id = co.order_id
WHERE ro.distance_km IS NOT NULL;

/*
    Explanation:
    This code calculates the count of pizzas that have both exclusions and extras specified in the customer orders. It uses the COUNT_IF function to evaluate the conditions where exclusions and extras
    are not null and have a length greater than zero. The query joins the customer_orders_clean and runner_orders_clean tables based on the order_id and applies a filter to include only those orders 
    which are delivered successfully.
    
    Conclusion:
    There is only one pizza which was delivered successfully.
*/
             
// Q9. What was the total volume of pizzas ordered for each hour of the day?
SELECT HOUR(order_time) AS hourly_order, COUNT(*) AS pizza_ordered
FROM customer_orders_clean
GROUP BY 1
ORDER BY 1;

/*
    Explanation:
    This code retrieves the hour component from the "order_time" column in the "customer_orders_clean" table. It then counts the number of orders for each hour and groups the results by the hour. The 
    result is a summary of the number of pizzas ordered for each hour, sorted in ascending order by the hour.
    
    Conclusion:
    Total volume of pizzas ordered for each hour of the day(starting from 11 AM as it was the time when first pizza was ordered):
    - No of pizzas ordered between 11 AM(inclusive) and 12PM(exclusive)=> 1.
    - No information is available between 12PM to 1PM.
    - No of pizzas ordered between 1 PM(inclusive) and 2 PM(exclusive)=> 3.
    - No of pizzas ordered between 6 PM(inclusive) and 7 PM(exclusive)=> 3
    - No of pizzas ordered between 7 PM(inclusive) and 8 PM(exclusive)=> 1.
    - No of pizzas ordered between 9 PM(inclusive) and 10 PM(exclusive)=> 3.
    - No of pizzas ordered between 11 PM(inclusive) and 12 AM(exclusive)=> 3.
*/

// Q10. What was the volume of orders for each day of the week?
SELECT DAYNAME(order_time) AS weekly_order, COUNT(*) AS num_of_order
FROM customer_orders_clean
GROUP BY 1
ORDER BY 2 DESC;

/*
    Explanation:
    This code calculates the dayname from the "order_time" column in the "customer_orders_clean" table. It then counts the number of orders for each dayname and groups the results by the dayname. The
    result is a summary of the number of orders for each dayname, sorted in descending order by the number of orders.
    
    Conclusion:
    - Num. of pizzas ordered on FRIDAY => 1
    - Num. of pizzas ordered on SATURDAY => 5
    - Num. of pizzas ordered on THURSDAY => 3
    - Num. of pizzas ordered on WEDNESDAY => 5
*/

//****************************************<End of Pizza Metrics>****************************************

//****************************************<Start of Runner and Customer Experience>****************************************
// Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT DATE_TRUNC('week',registration_date) + 4 AS start_of_week, COUNT(runner_id) AS runner_signed_up
FROM runners
GROUP BY 1;
/*
    Explanation:
    This query calculates the number of runners who signed up for each week. It does this by truncating the registration_date column in the runners table to the week using the DATE_TRUNC
    function and adding 4 days because for some reasons '2021-01-01' shows last year date when we truncate it without adding 4 days.  The results are then grouped by this value and the COUNT 
    function is used to count the number of rows in each group, representing the total number of runners who signed up during that week. The result is a summary of the number of runners signed up for
    each week, based on their registration date.
    
    Conclusion:
    - Week start at '2021-01-01' has 2 runner signed up.
    - Week start at '2021-01-08' has 1 runner signed up.
    - Week start at '2021-01-15' has 1 runner signed up.
*/

// Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT runner_id AS "Runner ID", 
       ROUND(AVG(TIMEDIFF(minute ,co.order_time, ro.pickup_time)),1) AS "Average Time Taken(in minutes)"
FROM customer_orders_clean co
  JOIN runner_orders_clean ro
  ON ro.order_id = co.order_id
GROUP BY 1;

/*
    Explanation:
    This query calculates the average time taken for each runner to pick up an order. It does this by joining the customer_orders_clean and runner_orders_clean tables on the order_id column and using
    the TIMEDIFF function to calculate the difference in minutes between the order_time and pickup_time columns. The results are then grouped by runner_id and the AVG function is used to calculate 
    the average time taken for each runner. 
    
    Conclusion:
    Average time taken by
    - Runner ID 1 is 15.7 minutes
    - Runner ID 2 is 24.2 minutes
    - Runner ID 3 is 10.0 minutes
*/

// Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH order_prepare AS (
    SELECT co.order_id, COUNT(pizza_id) AS num_pizzas_ordered, 
            MAX(TIMEDIFF(minute ,co.order_time, ro.pickup_time)) AS time_required
  FROM customer_orders_clean co
      JOIN runner_orders_clean ro ON ro.order_id = co.order_id
  WHERE ro.pickup_time IS NOT NULL
  GROUP BY 1
  ORDER BY 3 DESC
)
SELECT num_pizzas_ordered, ROUND(AVG(time_required), 1) AS "AVG time required"
FROM order_prepare
GROUP BY 1;

/*
    Explanation:
    This query calculates the average time required to prepare an order for each number of pizzas ordered. It uses a common table expression (CTE) to calculate the number of pizzas ordered and the
    maximum time required to prepare each order. The main query then selects from the CTE and calculates the average time required for each number of pizzas ordered. The final result is a table 
    showing the number of pizzas ordered and the average time required to prepare an order for that number of pizzas.
    
    Conclusion:
    On average
    - 3 pizzas take 30 minutes.
    - 2 pizzas take 18 minutes(approx).
    - 1 pizza take 12 minutes(approx).
    
    So we can clearly see there is a relationship between the number of pizzas and how long the order takes to prepare. As the number of pizzas increase, the time it requried to prepare also increase.
*/

// Q4. What was the average distance travelled for each customer?
SELECT co.customer_id, ROUND(AVG(ro.distance_km), 1) AS "Average distance travelled(in KM)"
FROM customer_orders_clean co
    JOIN runner_orders_clean ro ON ro.order_id = co.order_id
WHERE distance_km IS NOT NULL
GROUP BY 1;

/*
    Explanation:
    This query calculates the average distance traveled by runners for each customer. It does this by joining the customer_orders_clean and runner_orders_clean tables on the order_id column and 
    filtering out any rows where the distance_km column is NULL. The results are then grouped by customer_id and the AVG function is used to calculate the average distance traveled for each customer.
    The final result is a table with one row for each customer, showing their customer_id and the average distance traveled by runners for their orders, rounded to one decimal place.
    
    Conclusion:
    On an average
    - For Customer id 101, average distance travelled by runner is 20 km.
    - For Customer id 102, average distance travelled by runner is 16 km(approx).
    - For Customer id 103, average distance travelled by runner is 23 km(approx).
    - For Customer id 104, average distance travelled by runner is 10 km.
    - For Customer id 105, average distance travelled by runner is 25 km.
*/

//Q5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration) - MIN(duration) AS max_min_diff
FROM runner_orders_clean;

/*
    Explanation:
    This code subtracts the minimum duration from the maximum duration to determine the difference between the longest and shortest delivery times for all orders.
    
    Conclusion:
    The difference between the longest and shortest delivery times for all orders is 30 minute.
*/

// Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, ro.order_id, COUNT(pizza_id) AS "#Pizzas delivered",
    ROUND(AVG(60*distance_km/duration), 1) AS "AVG speed(in km/hr)"
FROM customer_orders_clean co
    JOIN runner_orders_clean ro ON ro.order_id = co.order_id
WHERE distance_km IS NOT NULL
GROUP BY 1,2, distance_km, duration
ORDER BY 1;

/*
    Explanation:
    This code calculate the average speed of each runner for each order. It selects the runner_id, order_id, counts the number of pizzas delivered (pizza_id), and calculates the average speed in 
    km/hr. The results are grouped by runner_id, order_id, distance_km, and duration and ordered by runner_id.
    
    Conclusion:
    - Although the order with the highest speed had only one pizza and the order with the lowest speed had three pizzas, there isn’t a distinct pattern indicating that having more 
      pizzas in an order results in slower delivery times.
*/

// Q7. What is the successful delivery percentage for each runner?
SELECT
  runner_id,
  ROUND(100 * COUNT(pickup_time) / COUNT(order_id)) AS delivery_percentage
FROM runner_orders_clean
GROUP BY 1
ORDER BY 1;

/*
    Explanation:
    This code calculate the delivery success rate for each runner. It selects the runner_id, counts the number of successful deliveries (pickup_time), counts the total number of deliveries (order_id),
    and calculates the delivery success percentage. The results are grouped by runner_id and ordered by runner_id.
    
    Conclusion:
    - Runner ID 1 has 100% success delivery rate.
    - Runner ID 2 has 75% success delivery rate.
    - Runner ID 3 has 50% success delivery rate.
*/
//****************************************<End of Runner and Customer Experience>****************************************

//****************************************<Start of Ingredient Optimisation>****************************************
// Q1. What are the standard ingredients for each pizza?
SELECT pt.topping_name AS "Topping Name" 
FROM pizza_recipes pr
LEFT JOIN LATERAL SPLIT_TO_TABLE(pr.toppings, ',') AS split_top
JOIN pizza_toppings pt ON pt.topping_id = split_top.value
GROUP BY 1
HAVING COUNT(DISTINCT pr.pizza_id) = 2;

/*
    Explanation:
    This is a SQL query that selects the name of toppings from the pizza_toppings table that are standard ingredients for each pizza. The pizza_recipes table has a column toppings that contains 
    a comma-separated list of topping IDs. The SPLIT_TO_TABLE function is used to split this list into rows. LATERAL is used to indicate that the result of the SPLIT_TO_TABLE function depends on the 
    values from the preceding table (pizza_recipes).The resulting rows are then joined with the pizza_toppings table to get the name of the toppings. The GROUP BY and HAVING clauses are used 
    to filter the results to only include toppings that are are standard ingredients for each pizza.
    
    Conclusion:
    - Cheese and Mushrooms are the standard ingredients for each pizzas.
*/

// Q2. What was the most commonly added extra?
SELECT 
    pt.topping_name
FROM customer_orders_clean co
    LEFT JOIN LATERAL SPLIT_TO_TABLE(co.extras, ',') AS split_extra
    JOIN pizza_toppings pt ON pt.topping_id = split_extra.value
WHERE split_extra.value<>''
GROUP BY 1
ORDER BY COUNT(split_extra.value) DESC
LIMIT 1;

/*
    Explanation:
    This is a SQL query that selects the name of the most commonly ordered extra topping from the customer_orders_clean table. The extras column contains a comma-separated list of topping IDs. 
    The SPLIT_TO_TABLE function is used to split this list into rows. LATERAL is used to indicate that the result of the SPLIT_TO_TABLE function depends on the values from the preceding 
    table (customer_orders_clean). The resulting rows are then joined with the pizza_toppings table to get the name of the toppings. The GROUP BY, ORDER BY, and LIMIT clauses are used to find the 
    most frequently ordered topping.
    
    Conclusion:
    - The most commonly added extra is Bacon.
*/

// Q3. What was the most common exclusion?
SELECT 
    pt.topping_name, COUNT(split_exclusion.value) AS num_times_excluded
FROM customer_orders_clean co
    LEFT JOIN LATERAL SPLIT_TO_TABLE(co.exclusions, ',') AS split_exclusion
    JOIN pizza_toppings pt ON pt.topping_id = split_exclusion.value
WHERE split_exclusion.value<>''
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

/*
    Explanation:
    This code retrieves the most frequently excluded toppings from customer orders. It uses the SPLIT_TO_TABLE function to split the exclusions column into separate values, and then joins it with 
    the pizza_toppings table to get the corresponding topping names.  LATERAL is used to indicate that the result of the SPLIT_TO_TABLE function depends on the values from the preceding 
    table (customer_orders_clean). The result is grouped by topping name and ordered by the count of occurrences in descending order. The query returns the topping with the highest count, indicating
    the most commonly excluded topping in customer orders.
    
    Conclusion:
    - The most common exclusion is cheese.
*/

/* Q4. Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */

WITH extra_topping_details AS(
    SELECT 
        co.order_id, co.pizza_id, co.extras,
        LISTAGG(DISTINCT pt.topping_name, ', ') AS extra_topping
    FROM customer_orders_clean co
        LEFT JOIN LATERAL SPLIT_TO_TABLE(co.extras, ',') AS split_extras
        JOIN pizza_toppings pt ON pt.topping_id = split_extras.value
    WHERE split_extras.value<>''
    GROUP BY 1,2,3
), 
    exclude_topping_details AS (
      SELECT 
        co.order_id, co.pizza_id, co.exclusions,
        LISTAGG(DISTINCT pt.topping_name, ', ') AS exclude_topping
      FROM customer_orders_clean co
        LEFT JOIN LATERAL SPLIT_TO_TABLE(co.exclusions, ',') AS split_exclude
        JOIN pizza_toppings pt ON pt.topping_id = split_exclude.value
      WHERE split_exclude.value<>''
      GROUP BY 1,2,3
)
SELECT co.order_id,
       CONCAT(
           CASE
                WHEN pn.pizza_name = 'Meatlovers' THEN 'Meat Lovers'
                ELSE pn.pizza_name
            END,
           COALESCE(' - Extra ' || extra_topping,''), 
           COALESCE(' - Exclude ' || exclude_topping, '') 
       ) AS order_item
FROM customer_orders_clean co
LEFT JOIN extra_topping_details AS extra ON extra.order_id = co.order_id 
            AND extra.pizza_id = co.pizza_id 
            AND extra.extras = co.extras
LEFT JOIN exclude_topping_details AS exclude ON exclude.order_id = co.order_id 
            AND exclude.pizza_id = co.pizza_id 
            AND exclude.exclusions = co.exclusions
JOIN pizza_names AS pn ON pn.pizza_id = co.pizza_id
ORDER BY co.order_id;

/*
    Explanation:
    This code combines and formats information from different tables to generate detailed order items for customer orders. It first creates two CTEs (extra_topping_details and exclude_topping_details)
    to retrieve the extra and excluded toppings for each order as comma-separate values. It then joins these CTEs with the customer_orders_clean table and the pizza_names table to gather names of
    all pizzas. The CONCAT function is used to create the final order item string, including the pizza name, extra toppings, and excluded toppings. I've used COALESCE function becuase there are
    some null values so it will replace null values with ''.The result is ordered by the order ID.
    
    Conclusion:
    Created additional column "order_item" to show result in the format specified in the question.
*/

// Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
//For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

//Note: Don't get scared after watching the length of query. I'll help you to understand it. Stick to the last

WITH extra_topping_details AS(
    SELECT 
        co.order_id, co.pizza_id, co.extras, pt.topping_id,
        pt.topping_name
    FROM customer_orders_clean co
        LEFT JOIN LATERAL SPLIT_TO_TABLE(co.extras, ',') AS split_extras
        JOIN pizza_toppings pt ON pt.topping_id = split_extras.value
    WHERE split_extras.value<>''
),
    exclude_topping_details AS (
      SELECT 
        co.order_id, co.pizza_id, co.exclusions, pt.topping_id,
        pt.topping_name AS excluded_topping
      FROM customer_orders_clean co
        LEFT JOIN LATERAL SPLIT_TO_TABLE(co.exclusions, ',') AS split_exclude
        JOIN pizza_toppings pt ON pt.topping_id = split_exclude.value
      WHERE split_exclude.value<>''
),
    order_details AS (
    SELECT co.order_id, co.pizza_id,
            pt.topping_id, pt.topping_name
    FROM customer_orders_clean co
        JOIN pizza_recipes pr ON pr.pizza_id = co.pizza_id
        LEFT JOIN LATERAL SPLIT_TO_TABLE(toppings, ',') AS split_exclude
        JOIN pizza_toppings pt ON pt.topping_id = split_exclude.value
),
    orders_with_extras_and_exclusions AS (
    SELECT od.order_id, od.pizza_id, od.topping_id, od.topping_name
    FROM order_details od
        LEFT JOIN exclude_topping_details excl 
            ON excl.order_id = od.order_id AND excl.pizza_id = od.pizza_id 
            AND excl.topping_id = od.topping_id
    WHERE excl.order_id IS NULL

    UNION ALL

    SELECT order_id, pizza_id, topping_id, topping_name
    FROM extra_topping_details
),
    INGREDIENT_TOTALS AS (
      SELECT order_id, pizza_name, topping_name, COUNT(topping_name) AS n
      FROM orders_with_extras_and_exclusions AS o
          JOIN pizza_names pn ON pn.pizza_id = o.pizza_id
      GROUP BY 1,2,3
      ORDER BY 1,2,3
),
    SUMMARY AS(
      SELECT order_id, pizza_name,
          LISTAGG( DISTINCT CASE
              WHEN n > 1 THEN n || 'x' || topping_name
              ELSE topping_name
          END, ', ') AS ingred
      FROM INGREDIENT_TOTALS
      GROUP BY 1,2
)
SELECT order_id, 
    CONCAT(
      (
        CASE
            WHEN pizza_name = 'Meatlovers' THEN 'Meat Lovers'
            ELSE pizza_name
        END
       ),
            ': ',
            ingred
    ) AS ingredient_list
FROM SUMMARY;

/*
    Explanation:
    This code is used to generate ingredient lists for customer orders. It involves several steps and CTEs to gather information from different tables and combine them in a desired format. Here's a 
    breakdown of the code:
    
    The first two CTEs, extra_topping_details and exclude_topping_details, retrieve the details of extra and excluded toppings for each order from the customer_orders_clean table by joining with
     the pizza_toppings table.
    
    The order_details CTE retrieves the details of standard toppings of pizzas(i.e. those toppings without adding extras and removing exclusions) from the pizza_recipes table for each order.
    
    The orders_with_extras_and_exclusions CTE combines the order details with the extra and excluded topping details, filtering out any toppings that are excluded. Basically you can imagine
     (standard toppings + extras - excludings)
    
    The INGREDIENT_TOTALS CTE calculates the count of each topping for each order, along with the pizza name. It uses a join with the pizza_names table to retrieve the pizza name based on the
    pizza ID.
    
    The SUMMARY CTE aggregates the ingredient totals, grouping them by the order ID and pizza name. It uses the LISTAGG function to concatenate the topping names into a comma-separated list, 
    handling the case when there are multiple occurrences of the same topping by adding "nX" where n is the number of times that topping is ordered.
    
    The final SELECT statement retrieves the order ID and the concatenated ingredient list, formatting it with the pizza name and the ingredient list.
    
    Conclusion:
    Created additional column "order_item" to show result in the format specified in the question.
*/

// Q6.  What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH extra_topping_details AS (
    SELECT 
        co.order_id, co.pizza_id, co.extras, pt.topping_id,
        pt.topping_name
    FROM customer_orders_clean co
        LEFT JOIN LATERAL SPLIT_TO_TABLE(co.extras, ',') AS split_extras
        JOIN pizza_toppings pt ON pt.topping_id = split_extras.value
    WHERE split_extras.value<>''
),
    exclude_topping_details AS (
      SELECT 
        co.order_id, co.pizza_id, co.exclusions, pt.topping_id,
        pt.topping_name AS excluded_topping
      FROM customer_orders_clean co
        LEFT JOIN LATERAL SPLIT_TO_TABLE(co.exclusions, ',') AS split_exclude
        JOIN pizza_toppings pt ON pt.topping_id = split_exclude.value
      WHERE split_exclude.value<>''
),
order_details AS (
    SELECT co.order_id, co.pizza_id,
            pt.topping_id, pt.topping_name
    FROM customer_orders_clean co
        JOIN pizza_recipes pr ON pr.pizza_id = co.pizza_id
        LEFT JOIN LATERAL SPLIT_TO_TABLE(toppings, ',') AS split_exclude
        JOIN pizza_toppings pt ON pt.topping_id = split_exclude.value
),
orders_with_extras_and_exclusions AS (
    SELECT od.order_id, od.pizza_id, od.topping_id, od.topping_name
    FROM order_details od
        LEFT JOIN exclude_topping_details excl 
            ON excl.order_id = od.order_id AND excl.pizza_id = od.pizza_id 
            AND excl.topping_id = od.topping_id
    WHERE excl.order_id IS NULL

    UNION ALL

    SELECT order_id, pizza_id, topping_id, topping_name
    FROM extra_topping_details
)
SELECT topping_name, COUNT(topping_id) AS num_time_ingred_added
FROM orders_with_extras_and_exclusions ow
    JOIN runner_orders_clean ro ON ro.order_id = ow.pizza_id
WHERE distance_km IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

/*
    Explanation:
    This SQL query uses several common table expressions (CTEs) to get the details of the extra toppings and excluded toppings for each order, as well as the default toppings for each pizza. The 
    extra_topping_details CTE retrieves the extra toppings for each order by joining the customer_orders_clean table with the pizza_toppings table using a LATERAL JOIN with the 
    SPLIT_TO_TABLE function to split the comma-separated list of extra toppings. The exclude_topping_details CTE does the same for excluded toppings.
    
    The order_details CTE retrieves the default toppings for each pizza by joining the customer_orders_clean table with the pizza_recipes and pizza_toppings tables. The 
    orders_with_extras_and_exclusions CTE combines the information from the order_details, extra_topping_details, and exclude_topping_details CTEs to create a result that includes all of 
    the toppings for each pizza. Again you can imagine (standard toppings + extras - excludings).
    
    The final SELECT statement joins the orders_with_extras_and_exclusions CTE with the runner_orders_clean table to filter out orders that have a null distance_km value(which means pizzas is 
    successfully delivered). It then groups by topping name and counts the number of times each topping was added. The result is ordered by this count in descending order.
    
    Conclusion:
    Created additional column "num_time_ingred_added" to show result in the format specified in the question.
*/

//****************************************<End of Ingredient Optimisation>****************************************

//****************************************<Start of Pricing and Ratings>****************************************
// Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT CONCAT('$', SUM(DECODE(co.pizza_id, 1, 12, 10))) AS total_revenue
FROM customer_orders_clean co
    JOIN runner_orders_clean ro ON ro.order_id = co.order_id
WHERE ro.distance_km IS NOT NULL;

/*
    Explanation:
    This query calculates the total revenue from pizza sales. The query selects data from the customer_orders_clean and runner_orders_clean tables and joins them on the order_id column. It then 
    filters the rows to include only those where the distance_km column in the runner_orders_clean table is not NULL.

    The query uses the DECODE function to assign a price of $12 to pizzas with a pizza_id of 1(i.e. Meat Lovers pizza) and a price of $10 to all other pizzas. It then calculates the total revenue 
    by summing up the prices for all rows in the resulting table.
    
    Conclusion:
    Total revenue collected after selling Meatlovers Pizza(at $12 each) and Vegetarian Pizza(at $10 each) is $138.
*/

// Q2. What if there was an additional $1 charge for any pizza extras?
//  -Add cheese is $1 extra
WITH TOTAL_EXTRAS_ADDED AS (
    SELECT co.pizza_id, COUNT(se.value) AS extra_revenue
    FROM customer_orders_clean co
    LEFT JOIN LATERAL SPLIT_TO_TABLE(extras, ',') AS se
    JOIN runner_orders_clean ro ON ro.order_id = co.order_id
    WHERE se.value<>'' AND ro.distance_km IS NOT NULL
    GROUP BY 1
),
TOTAL_WOUT_EXTRA AS (
    SELECT co.pizza_id, SUM(DECODE(co.pizza_id, 1, 12, 10)) AS pizza_revenue
    FROM customer_orders_clean co
        JOIN runner_orders_clean ro ON ro.order_id = co.order_id
        JOIN TOTAL_EXTRAS_ADDED tea ON tea.pizza_id = co.pizza_id
    WHERE ro.distance_km IS NOT NULL
    GROUP BY 1
)
SELECT CONCAT('$', SUM(DISTINCT extra_revenue + pizza_revenue)) AS TOTAL_REVENUE
FROM customer_orders co
        JOIN TOTAL_EXTRAS_ADDED tea ON tea.pizza_id = co.pizza_id
        JOIN TOTAL_WOUT_EXTRA twe ON twe.pizza_id = co.pizza_id
;

/*
    Explanation:
    This query calculates the total revenue from pizza sales and extra toppings. The query uses two Common Table Expressions (CTEs) to calculate the revenue from pizzas and extra toppings 
    separately.
    
    The first CTE, TOTAL_EXTRAS_ADDED, calculates the revenue from extra toppings for each type of pizza. It selects data from the customer_orders_clean and runner_orders_clean tables and joins 
    them on the order_id column. It then uses a lateral join with the SPLIT_TO_TABLE function to split the extras column into separate rows for each extra topping. The CTE filters the rows to 
    include only those where the extras column is not empty and the distance_km column in the runner_orders_clean table is not NULL(means pizza delivered successfully). Finally, it calculates the 
    revenue from extra toppings by counting the number of rows for each type of pizza.
    
    The second CTE, TOTAL_WOUT_EXTRA, calculates the revenue from pizza sales for each type of pizza. It selects data from the customer_orders_clean and runner_orders_clean tables and joins them 
    on the order_id column. It then filters the rows to include only those where the distance_km column in the runner_orders_clean table is not NULL. The CTE uses the DECODE function to assign a 
    price of $12 to pizzas with a pizza_id of 1 and a price of $10 to all other pizzas. It then calculates the revenue from pizza sales by summing up the prices for each type of pizza.

    The main query joins these two CTEs with the customer_orders table on the pizza_id column and calculates the total revenue by summing up the revenue from pizzas and extra toppings for all rows
    in the resulting table. Finally, it uses the CONCAT function to concatenate a ‘$’ character with the total revenue to generate a final result that shows the total revenue formatted as a currency 
    value.
    
    Conclusion:
    After including extras(for $1 each), the total revenue generated by Meatlovers pizzas($12 each) and Vegetarian pizzas($10 each) is $142.
*/

/* Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a 
    schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5. 
*/

// Creating new table `runner_ratings` 
CREATE OR REPLACE TABLE runner_ratings AS
  SELECT runner_id, order_id
  FROM runner_orders_clean ro
  WHERE ro.distance_km IS NOT NULL;

// Creating rating column and adding random values
ALTER TABLE runner_ratings
ADD COLUMN rating INT;

UPDATE runner_ratings
SET rating = uniform(1, 5, random());

/*
    Explanation:
    This code creates a new table called `runner_ratings` with columns `runner_id` and `order_id` from the `runner_orders_clean` table where the `distance_km` column is not null. Then it adds a new
    column called `rating` of type `INT` to the `runner_ratings` table. Finally, it updates the `rating` column with random values between 1 and 5 using the `uniform()` function.
    
    Conclusion:
    Required table created.
*/

/* Q4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? 
  * customer_id
  * order_id
  * runner_id
  * rating
  * order_time
  * pickup_time
  * Time between order and pickup
  * Delivery duration
  * Average speed
  * Total number of pizzas
*/

SELECT 
    co.customer_id, rr.order_id, rr.runner_id, rr.rating, co.order_time, ro.pickup_time,
    ROUND(AVG(TIMEDIFF(minute ,co.order_time, ro.pickup_time)),1) AS "Average Time Taken(in minutes)",
    ro.duration,
    ROUND(AVG(60*distance_km/duration), 1) AS "AVG speed(in km/hr)",
    COUNT(co.pizza_id) AS num_of_pizzas_ordered
FROM customer_orders_clean co
    JOIN runner_orders_clean ro ON ro.order_id = co.order_id
    JOIN runner_ratings rr ON rr.order_id = co.order_id
WHERE ro.distance_km IS NOT NULL
GROUP BY 1,2,3,4,5,6,ro.duration
ORDER BY 1;

/*
    Explanation:
    The query retrieves information and calculates aggregated metrics related to customer orders, runner orders, and runner ratings. It begins with the `SELECT` clause, which specifies the required
    columns to be included in the query result.

    The `FROM` clause specifies the tables involved in the query. The `customer_orders_clean` table represents the table containing customer order information. The `runner_orders_clean` table
    represents the table containing runner order information. Lastly, the `runner_ratings` table represents the table containing runner ratings.

    The `JOIN` statements establish relationships between these tables. The `runner_orders_clean` and `customer_orders_clean` tables are joined based on the order ID, connecting runner orders with 
    their corresponding customer orders. Similarly, the `runner_ratings` table is joined with the `customer_orders_clean` table based on the order ID, linking runner ratings with the respective 
    customer orders.

    The `WHERE` clause filters the results by checking that the `distance_km` column in the `runner_orders_clean` table is not NULL. This condition ensures that only orders with a valid distance value
    are included in the calculations.

    Lastly, the `GROUP BY` clause groups the results by several columns, including customer ID, order ID, runner ID, rating, order time, pickup time, and duration. This grouping enables the 
    calculation of aggregated metrics for each distinct group, such as the average time taken, average speed, and the count of pizzas ordered within each group.
    
    Conclusion:
    Result contains required fields
*/

/* Q5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over 
       after these deliveries?
*/
WITH AMT_AFTER_OVERHEAD AS (
  SELECT ro.runner_id, SUM(DECODE(co.pizza_id, 1, 12, 10)) - SUM(distance_km)*0.30 AS amt_left
  FROM customer_orders_clean co
      JOIN runner_orders_clean ro ON ro.order_id = co.order_id
  WHERE ro.distance_km IS NOT NULL
  GROUP BY 1
)
SELECT '$' || ROUND(SUM(amt_left), 2) AS "REMAINING AMOUNT"
FROM AMT_AFTER_OVERHEAD
;

/*
    Explanation:
    This query uses a common table expression (CTE) called `REVENUE_AFTER_OVERHEAD` to calculate the amount left after overhead for each runner. The CTE selects data from two tables: 
    `customer_orders_clean` and `runner_orders_clean`, which are joined on the `order_id` column. The `DECODE()` function is used to assign a value of 12 if the `pizza_id` is 1 and 10 otherwise. 
    
    The sum of these values(means total revenue before paying runners) is then subtracted by the product of the sum of `distance_km` and 0.30(means amount runners will get). Only rows where the 
    `distance_km` column is not null are included in the calculation. The results are grouped by the first column (`runner_id`). The main query then calculates the sum of the `amt_left` column from
    the CTE and formats it as a currency value.
    
    Conclusion:
    $73.38 is amount left after paying each runner for the distance they travelled($0.30 per km).
*/

//****************************************<End of Pricing and Ratings>****************************************

//****************************************<Bonus DML Challenges (DML = Data Manipulation Language)>****************************************
/* If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the 
    toppings was added to the Pizza Runner menu?
*/
select * from pizza_names;
INSERT INTO pizza_names
VALUES
(3, 'Supreme');

select * from pizza_recipes;
INSERT INTO pizza_recipes
VALUES
(3, '4, 6, 8, 10');

/*
    If a new Supreme pizza with all the toppings was added to the Pizza Runner menu, then we need to add the pizza name 'Supreme 'to `pizza_names` table. After that we need to add the toppings using
    pizza_id inside `pizza_recipes` table.
*/
//****************************************</Bonus DML Challenges (DML = Data Manipulation Language)>****************************************
