CREATE OR REPLACE SCHEMA dannys_dinner;
USE SCHEMA dannys_dinner;

-- Q1. What is the total amount each customer spent at the restaurant?
SELECT sa.customer_id, CONCAT('$', SUM(me.price)) AS "Total Amount"
FROM sales sa
  JOIN menu me
  ON sa.product_id = me.product_id
GROUP BY 1;

/*
    Explanation:
    This SQL query calculates the total amount spent by each customer at the restaurant. It retrieves the "customer_id" column from the "sales" table and 
    sums up the prices from the "menu" table based on the matching product IDs. The results are grouped by the customer ID. The query provides a result set 
    with two columns: "customer_id" and "Total Amount," showing the total expenses of each customer formatted with a dollar sign. By executing this query, you 
    can obtain the total amount spent by each customer at the restaurant.
    
    Conclusion:
    A spends $76, B spends $74 and C spends $36.
*/

-- Q2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS "Number of days customer visited"
FROM sales
GROUP BY 1;

/*
    Explanation:
    The query aims to determine the number of days each customer has visited the restaurant based on the data in the "sales" table. It selects the 
    "customer_id" column and uses the COUNT(DISTINCT order_date) function to count the distinct order dates for each customer as some cases a customer visited 
    multiple times within day. The results are grouped by the "customer_id" column. The query provides a result set with two columns: "customer_id" and 
    "Number of days customer visited," representing each customer and the count of unique days they have visited the restaurant, respectively.
    
    Conclusion:
    A visited the restaurant for 4 days, B visited 6 days and C visited 2 days.
*/

-- Q3. What was the first item from the menu purchased by each customer?
WITH order_sales_cte AS (
  SELECT s.customer_id, s.order_date, m.product_name, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS row_num
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM order_sales_cte
WHERE row_num = 1
GROUP BY customer_id, product_name;

/*
    Explanation:
    This code uses a common table expression (CTE) to create a temporary result set called "order_sales_cte." It retrieves data from the "sales" and "menu" 
    tables and calculates the row number for each customer's order date using the DENSE_RANK() window function.
    
    The main query then selects the customer ID and product name from the "order_sales_cte" table. It filters the results to only include the rows where the 
    row number is equal to 1, indicating the earliest order for each customer. Finally, the results are grouped by customer ID and product name.
    
    Conclusion:
   - Customer A's first order is sushi and curry.
   - Customer B's first order is curry.
   - Customer C's first order is ramen.
*/

-- Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) AS "# times ordered"
FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

/*
    Explanation:
    This SQL query determines the product that has been ordered the most. It counts the occurrences of each product ID in the "sales" table, joins it with the 
    "menu" table to retrieve the corresponding product names, and groups the results by product name. The query then sorts the results in descending order 
    based on the count of product orders and limits the output to the top row. The final result includes the name of the most frequently ordered product and 
    the count of times it has been ordered.
    
    Conclusion:
    Most purchased item is ramen. It was purchased 8 times by all customers.
*/

-- Q5. Which item was the most popular for each customer?
WITH popular_item AS (
   SELECT s.customer_id, m.product_name, COUNT(s.product_id) AS order_count,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS item_rank
   FROM sales s
   JOIN menu m
   ON s.product_id = m.product_id
   GROUP BY 1,2
)
SELECT customer_id, product_name, order_count
FROM popular_item 
WHERE item_rank = 1;

/*
    Explanation:
    I'm assuming that most popular item means the item which is purchased most number of times. This code determines the most popular item for each customer 
    by counting the occurrences of each product in the "sales" table. It joins the "sales" and "menu" tables, groups the results by customer and product, and 
    assigns a rank to each combination based on the count. 
    
    The final result displays the customer ID, product name, and order count for the item with the highest rank, representing the most popular item for each 
    customer.
    
    Conclusion:
    - Customer with customer id A and C loves ramen.
    - Customer with customer id B enjoys every food in the restaurant.
*/

-- Q6. Which item was purchased first by the customer after they became a member?
WITH order_after_join AS (
  SELECT sales.customer_id, sales.product_id,sales.order_date, members.join_date,
  DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS item_rank
  FROM sales
    JOIN members ON sales.customer_id = members.customer_id
  WHERE sales.order_date >= members.join_date
  GROUP BY 1,2,3,4
  ORDER BY sales.order_date
)
SELECT customer_id, menu.product_name
FROM order_after_join orj
  JOIN menu ON orj.product_id = menu.product_id
WHERE item_rank = 1;

/*
    Explanation:
    This code retrieves the first item ordered by each customer after they join the membership program. It joins the "sales" and "members" tables based on 
    the customer ID, filters the orders to include only those made after the join date, and assigns a rank to each combination of customer and order date.
    
    The code then selects the customer ID and corresponding product name from the "menu" table for the items with the lowest rank, indicating the first 
    ordered item after joining.
    
    Conclusion:
    - Customer with customer id A and B ordered curry and sushi ,respectively, after becoming member.
*/

-- Q7. Which item was purchased just before the customer became a member?
WITH order_after_join AS (
  SELECT sales.customer_id, sales.product_id,sales.order_date, members.join_date,
  DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS item_rank
  FROM sales
    JOIN members ON sales.customer_id = members.customer_id
  WHERE sales.order_date <= members.join_date
  GROUP BY 1,2,3,4
  ORDER BY sales.order_date DESC
)
SELECT customer_id, menu.product_name, order_date, join_date
FROM order_after_join orj
  JOIN menu ON orj.product_id = menu.product_id
WHERE item_rank = 1;

/*
    Explanation:
    This code retrieves the last item ordered by each customer before they join the membership program. It joins the "sales" and "members" tables based 
    on the customer ID, filters the orders to include only those made before or on the join date, and assigns a rank to each combination of customer and 
    order date. 
    
    The code then selects the customer ID, corresponding product name, order date, and join date from the "menu" table for the items with the lowest rank, 
    indicating the last ordered item before joining. By executing this code, you can identify the final item purchased by each customer before becoming a 
    member. Since purchase time is not given so I'm considering that last order by day.
    
    Conclusion:
    - Customer with customer id A ordered sushi and curry before becoming member.
    - Customer with customer id B ordered curry before becoming member.
*/

-- Q8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) AS "Total Items", SUM(m.price) AS "Total amount spent"
FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY 1;

/*
    Explanation:
    This code calculates the total number of items purchased and the total amount spent by each customer before they join the membership program. It joins 
    the "sales," "menu," and "members" tables based on the customer ID and product ID. The WHERE clause filters the orders to include only those made
    before the customer's join date. The results are then grouped by the customer ID, and the COUNT function is used to count the number of products and
    the SUM function is used to calculate the total amount spent.
    
    Conclusion:
    - So 2 items were purchased by A which costs $25.
    - So 3 items were purchased by A which costs $40.
*/

-- Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH eval_points_menu AS (
  SELECT *, 
    CASE
      WHEN product_id = 1 THEN price * 20
      ELSE price * 10
    END AS points
  FROM menu
)
SELECT s.customer_id AS "Customer Id", SUM(epm.points) AS "Total Points"
FROM sales s
  JOIN eval_points_menu epm ON s.product_id = epm.product_id
GROUP BY 1;

/*
    Explanation:
    This code calculates the total points earned by each customer based on their purchases. It creates a Common Table Expression (CTE) named "eval_points_menu" 
    that includes all columns from the "menu" table and adds a new column called "points." The "points" column is calculated based on the product ID: if the 
    product ID is 1, the points are calculated by multiplying the price by 20, otherwise, the points are calculated by multiplying the price by 10. 
    
    The main query then joins the "sales" table with the "eval_points_menu" CTE on the product ID. It groups the results by the customer ID and calculates the 
    sum of the "points" column for each customer. By executing this code, you can obtain the customer ID and their corresponding total points earned based on 
    their purchases, taking into account the different point multipliers for different products.
    
    Conclusion:
    - Total points acquired by A,B, and C are 860, 940, 360 respectively.
*/

-- Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many 
-- points do customer A and B have at the end of January?
WITH add_date_member AS (
  SELECT *,
    DATEADD(DAY, 6, join_date) AS offer_week_end,
    DATE('2021-01-31') AS last_date_jan
  FROM members
)
SELECT s.customer_id AS "Customer Id",
  SUM(CASE
    WHEN s.order_date BETWEEN adm.join_date AND adm.offer_week_end THEN m.price * 20
    WHEN m.product_name = 'sushi' THEN m.price * 20
    ELSE m.price * 10
  END) AS Points
FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  JOIN add_date_member adm ON s.customer_id = adm.customer_id
WHERE s.order_date <= adm.last_date_jan
GROUP BY 1;

/*
    Explanation:
    This code calculates the total points earned by each customer based on their purchases during a specific time period. It starts by creating a Common Table 
    Expression (CTE) named "add_date_member" that holds details of members and two additional columns to the "members" table: "offer_week_end" and 
    "last_date_jan". The "offer_week_end" column calculates the end date of a special offer week for each member by adding 6 days to their join date as we are
     including the date they joined the membership. The "last_date_jan" column is set to a specific date ('2021-01-31') representing the end of January.
    
    The main query then joins the "sales" table with the "menu" table and the "add_date_member" CTE on the respective columns. It calculates the points for 
    each purchase based on specific conditions: if the order date is within the offer week period or if the product name is 'sushi', the points are calculated 
    by multiplying the price by 20; otherwise, the points are calculated by multiplying the price by 10. The results are then grouped by the customer ID, and 
    the sum of the points is calculated for each customer.
    
    Conclusion:
    A has 1370 points and B has 820 points.
*/

--------------------------------------BONUS QUESTIONS---------------------------------------
--Join All things

CREATE OR REPLACE VIEW Quick_Detail AS (
  SELECT s.customer_id, s.order_date, menu.product_name, menu.price,
      CASE
          WHEN s.order_date >= mem.join_date THEN 'Y'
          ELSE 'N'
      END AS member
  FROM SALES s
    JOIN MENU menu ON s.product_id = menu.product_id
    LEFT JOIN MEMBERS mem ON mem.customer_id = s.customer_id
);

SELECT * FROM Quick_Detail;
/*
    Explanation:
    This code creates a view called "Quick_Detail" that combines information from the "SALES," "MENU," and "MEMBERS" tables. It includes the customer ID, 
    order date, product name, price, and a column indicating whether the customer is a member or not. The "member" column is determined based on whether the 
    order date is greater than or equal to the customer's join date. 

    The second part of the code simply selects all columns from the "Quick_Detail" view, effectively displaying the consolidated information from the joined 
    tables.
*/

-- Rank All the things
CREATE OR REPLACE VIEW Quick_Detail_Rank AS (
  SELECT s.customer_id, s.order_date, menu.product_name, menu.price,
      CASE
          WHEN s.order_date >= mem.join_date THEN 'Y'
          ELSE 'N'
      END AS member,
      CASE
          WHEN member = 'N' THEN null
          ELSE DENSE_RANK() OVER(PARTITION BY s.customer_id,member ORDER BY s.order_date)
      END AS ranking
  FROM SALES s
    JOIN MENU menu ON s.product_id = menu.product_id
    LEFT JOIN MEMBERS mem ON mem.customer_id = s.customer_id
);

SELECT * FROM Quick_Detail_Rank;
/*
    Explanation:
    This code creates a view called "Quick_Detail_Rank" that combines information from the "SALES," "MENU," and "MEMBERS" tables, similar to the previous view. 
    In addition to the columns from the previous view, it includes a new column called "ranking." The "ranking" column is calculated using the DENSE_RANK() 
    window function and assigns a rank to each customer's order based on their order date, within the scope of their membership status. 

    The second part of the code simply selects all columns from the "Quick_Detail_Rank" view, allowing you to view the detailed information along with the
    ranking of each order. By executing this code, you can see the sales details, product information, membership status, and the ranking of orders for each 
    customer.
*/
