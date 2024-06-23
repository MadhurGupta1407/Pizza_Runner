use pizza_runner;

-- A. Pizza Metrics
-- 1 How many pizzas were ordered?
Select count(*) AS Pizzas_Ordered from customer_orders;

-- 2 How many unique customer orders were made?
Select Count(Distinct(order_id)) as Order_Count from Customer_orders;

-- 3 How many successful orders were delivered by each runner?
Select runner_id , Count(Distinct order_id) AS Order_Delivered from
runner_orders ro 
where pickup_time<>'null'
group by runner_id;

-- 4 How many of each type of pizza was delivered?
Select pizza_name AS Pizza_Type, count(co.order_id) AS Delivered_Count from 
customer_orders co 
JOIN
runner_orders ro
ON co.order_id = ro.order_id JOIN
pizza_names pn
ON pn.pizza_id = co.pizza_id
where pickup_time<>'null'
group by pizza_name;

-- 5 How many Vegetarian and Meatlovers were ordered by each customer?
Select customer_id , pizza_name,  Count(co.pizza_id) AS pizzas_ordered from
customer_orders co 
JOIN
pizza_names pn 
ON pn.pizza_id = co.pizza_id
Group by customer_id , pizza_name
order by customer_id;

-- 6 What was the maximum number of pizzas delivered in a single order?
select co.order_id, count(co.order_id) AS Pizzas_Ordered from
customer_orders co 
JOIN
runner_orders ro
ON co.order_id = ro.order_id
where pickup_time <> 'null'
group by co.order_id 
order by count(co.order_id) desc 
LIMIT 1;

-- 7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  customer_id, 
  SUM(CASE 
    WHEN 
        (
          (exclusions IS NOT NULL AND exclusions<>'null' AND LENGTH(exclusions)>0) 
        OR (extras IS NOT NULL AND extras<>'null' AND LENGTH(extras)>0)
        )=TRUE
    THEN 1 
    ELSE 0
  END) as changes, 
  SUM(CASE 
    WHEN 
        (
          (exclusions IS NOT NULL AND exclusions<>'null' AND LENGTH(exclusions)>0) 
        OR (extras IS NOT NULL AND extras<>'null' AND LENGTH(extras)>0)
        )=TRUE
    THEN 0 
    ELSE 1
  END) as no_changes 
FROM 
  customer_orders as co 
  INNER JOIN runner_orders as ro on ro.order_id = co.order_id 
WHERE 
  pickup_time<>'null'
GROUP BY 
  customer_id;

-- 8 How many pizzas were delivered that had both exclusions and extras?
Select count(co.order_id) AS Pizzas_With_Exclusion_AND_Extras from
customer_orders co 
JOIN
runner_orders ro
ON co.order_id = ro.order_id 
where 
pickup_time <> 'null' 
AND
(exclusions <> 'null' AND LENGTH(exclusions)>0)
AND
(extras <> 'null' AND LENGTH(extras)>0);

-- 9 What was the total volume of pizzas ordered for each hour of the day? 
Select Hour(order_time) AS Hour, count(order_id) AS Orders from customer_orders group by Hour(order_time);

-- 10. What was the volume of orders for each day of the week?
Select dayofweek(order_time) AS Day_Of_Week, count(order_id) AS Orders from customer_orders group by dayofweek(order_time);

-- B. Runner and Customer Experience
-- 1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
Select 
DATE_ADD('2021-01-01', INTERVAL FLOOR(DATEDIFF(registration_date, '2021-01-01') / 7) * 7 DAY) AS week_start,
Count(runner_id) 
from Runners
Group BY Week_Start;

-- 2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?	
SELECT 
runner_id,
AVG(TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time)) AS avg_pickup_time_minutes
FROM runner_orders ro
JOIN customer_orders co ON ro.order_id = co.order_id
WHERE
ro.pickup_time <> 'null'
GROUP BY ro.runner_id
ORDER BY ro.runner_id;

-- 3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
With CTE AS (SELECT 
co.order_id,
Count(pizza_id) as No_of_pizzas,
MAX(TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time)) AS prep_time
FROM runner_orders ro
JOIN customer_orders co ON ro.order_id = co.order_id
WHERE
ro.pickup_time <> 'null'
Group by co.order_id)
Select No_of_pizzas , AVG(prep_time) AS Avg_Prep_Time from CTE group by No_of_pizzas;

-- 4 What was the average distance travelled for each customer?
select 
customer_id, Round(AVG(distance),2) 
from runner_orders ro
JOIN customer_orders co ON ro.order_id = co.order_id
where distance<>'null'
group by customer_id;

-- 5 What was the difference between the longest and shortest delivery times for all orders?
SELECT
    MAX(REGEXP_REPLACE(duration, '[^0-9]', '')) -
    MIN((REGEXP_REPLACE(duration, '[^0-9]', '') )) AS delivery_time_difference
FROM
    runner_orders
WHERE
    duration IS NOT NULL
    AND duration <> 'null';

-- 6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
    ro.runner_id,
    co.order_id,
    ROUND((SUM(CAST(REGEXP_REPLACE(distance, '[^0-9.]', '') AS DECIMAL)) / 
     (SUM(CAST(REGEXP_REPLACE(duration, '[^0-9]', '') AS DECIMAL))/60)),2) AS `Avg_Speed(kmph)`
FROM
    runner_orders ro
JOIN
    customer_orders co ON ro.order_id = co.order_id
WHERE
    pickup_time <> 'null'
GROUP BY
    ro.runner_id,
    co.order_id;

-- 7 What is the successful delivery percentage for each runner?
With CTE AS (SELECT
    runner_id,
    COUNT(CASE WHEN pickup_time <> 'null' THEN 1 END) AS successful_deliveries,
    COUNT(CASE WHEN pickup_time = 'null' THEN 1 END) AS unsuccessful_deliveries
FROM
    runner_orders 
GROUP BY
    runner_id)
 Select *, (Successful_deliveries / (successful_deliveries + unsuccessful_deliveries))*100 AS Succeful_Delivery_Percentage from CTE ;
 
 
--  C. Ingredient Optimisation
-- 1 What are the standard ingredients for each pizza?
-- 2 What was the most commonly added extra?
-- 3 What was the most common exclusion?
-- 4 Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- 5 Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- 6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
 
 
 
 -- D. Pricing and Ratings
-- 1 If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
--   how much money has Pizza Runner made so far if there are no delivery fees?



-- 2 What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra


-- 3 The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table 
-- for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.


-- 4 Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas



-- 5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled ,
--  how much money does Pizza Runner have left over after these deliveries?
