-- Danny's Dinner Case study--
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);
INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  -- Creating Product Table --
  CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);
-- Inserting Values in Product Table ---
INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  -- Creating Members Table --
  CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);
  -- Inserting Values In Member Table --
  INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
 
 SHOW DATABASES;
  -- Case Study -- 
-- What is the total amount each customer spent at the restaurant?
SELECT customer_id,
SUM(price) as total_spend
FROM SALES AS S
INNER JOIN menu AS M ON S.product_id=M.product_id
GROUP BY customer_id;
-- How many days has each customer visited the restaurant?
SELECT 
customer_id,
COUNT(DISTINCT order_date) as days
FROM sales
GROUP BY customer_id;
-- What was the first item from the menu purchased by each customer?
WITH CTE AS(
SELECT 
customer_id,
order_date,
product_name,
RANK()OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS rnk,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) as rn
FROM SALES AS S
INNER JOIN menu AS M ON S.product_id=M.product_id
)
SELECT customer_id, product_name
FROM CTE
WHERE rnk=1;
-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
product_name,
COUNT(order_date) as orders
FROM SALES AS S
INNER JOIN menu AS M ON S.product_id=M.product_id
GROUP BY product_name
ORDER BY COUNT(order_date)DESC
LIMIT 1;
-- Which item was the most popular for each customer?
WITH CTE AS(
SELECT 
product_name,
customer_id,
COUNT(order_date) as orders,
RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(order_date)DESC) AS rnk,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(order_date) DESC)AS rn
FROM SALES AS S
INNER JOIN menu AS M ON S.product_id=M.product_id
GROUP BY product_name,
customer_id
)
SELECT 
customer_id,
product_name
 FROM CTE 
WHERE rn= 1;
-- Which item was purchased first by the customer after they became a member?
WITH CTE AS(
SELECT
S.customer_id,
order_date,
join_date,
product_name,
RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rnk,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS rn
FROM sales AS S
INNER JOIN members AS MEM on MEM.customer_id=S.customer_id
INNER JOIN menu AS M ON S.product_id=M.product_id
WHERE order_date >= join_date
)
SELECT customer_id,
product_name
 FROM CTE
  WHERE rnk =1;
  -- Which item was purchased just before the customer became a member?
  WITH CTE AS(
SELECT
S.customer_id,
order_date,
join_date,
product_name,
RANK() OVER (PARTITION BY S.customer_id ORDER BY order_date DESC ) AS rnk,
ROW_NUMBER() OVER(PARTITION BY S.customer_id ORDER BY order_date DESC) AS rn
FROM sales AS S
INNER JOIN members AS MEM on MEM.customer_id=S.customer_id
INNER JOIN menu AS M ON S.product_id=M.product_id
WHERE order_date < join_date
)
SELECT customer_id,
product_name
 FROM CTE
 WHERE rnk =1;
 -- What is the total items and amount spent for each member before they became a member?
 SELECT
S.customer_id,
COUNT(product_name) AS total_items,
SUM(price) AS amount_spent
FROM sales AS S
INNER JOIN members AS MEM on MEM.customer_id=S.customer_id
INNER JOIN menu AS M ON S.product_id=M.product_id
WHERE order_date < join_date
GROUP BY S.customer_id;
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have
SELECT customer_id,
SUM(CASE
WHEN product_name='sushi' THEN price * 10 *2
ELSE price * 10
END) AS points
FROM MENU AS M
INNER JOIN SALES AS S ON S.product_id = M.product_id
GROUP BY customer_id;
-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?
SELECT 
  S.customer_id, 
  SUM(
    CASE 
      WHEN S.order_date BETWEEN MEM.join_date AND DATE_ADD(MEM.join_date, INTERVAL 6 DAY) THEN price * 10 * 2 
      ELSE price * 10 
    END
  ) AS points 
FROM 
  MENU AS M 
  INNER JOIN SALES AS S ON S.product_id = M.product_id
  INNER JOIN MEMBERS AS MEM ON MEM.customer_id = S.customer_id 
WHERE 
  DATE_FORMAT(S.order_date, '%Y-%m') = '2021-01'
GROUP BY 
  S.customer_id;
-- Bonus Questions 
-- Join All the Things 
SELECT 
  S.customer_id, 
  order_date, 
  product_name, 
  price, 
  CASE 
    WHEN join_date IS NULL THEN 'N'
    WHEN order_date < join_date THEN 'N' 
    ELSE 'Y' 
  END as member 
FROM 
  SALES as S
  INNER JOIN MENU AS M ON S.product_id = M.product_id 
  LEFT JOIN MEMBERS AS MEM ON MEM.customer_id = S.customer_id 
ORDER BY 
  S.customer_id, 
  order_date, 
  price DESC;
  -- Rank All The Things
WITH CTE AS (
  SELECT 
    S.customer_id, 
    S.order_date, 
    product_name, 
    price, 
    CASE 
      WHEN join_date IS NULL THEN 'N'
      WHEN order_date < join_date THEN 'N'
      ELSE 'Y' 
    END as member 
  FROM 
    SALES as S 
    INNER JOIN MENU AS M ON S.product_id = M.product_id
    LEFT JOIN MEMBERS AS MEM ON MEM.customer_id = S.customer_id
  ORDER BY 
    customer_id, 
    order_date, 
    price DESC
)
SELECT 
  *
  ,CASE 
    WHEN member = 'N'  THEN NULL
    ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)  
  END as rnk
FROM CTE;


  