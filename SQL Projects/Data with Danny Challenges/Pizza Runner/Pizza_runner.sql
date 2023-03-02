Select * from pizza_runner.customer_orders;
Select * from pizza_runner.runner_orders;
Select * from pizza_runner.pizza_names;
Select * from pizza_runner.pizza_recipes;
Select * from pizza_runner.pizza_toppings;
Select * from pizza_runner.runners;

/*Section A: Pizza Metrics
*/
--1: How many pizzas were ordered?
Select count(*)
from pizza_runner.customer_orders;

--2: How many unique customer orders were made?
Select
count(distinct customer_id)
from pizza_runner.customer_orders;

--3:How many successful orders were delivered by each runner?
UPDATE  pizza_runner.runner_orders
SET cancellation = COALESCE(cancellation, 'fulfilled')
where cancellation is null;

Select count(*)
from pizza_runner.runner_orders
where cancellation = 'fulfilled';

--4: How many of each type of pizza was delivered?
Select 
s.pizza_id,
n.pizza_name,
COUNT(s.*) as orders
from pizza_runner.customer_orders as s
left join pizza_runner.pizza_names as n
on s.pizza_id = n.pizza_id
group by 1,2;

--5: How many Vegetarian and Meatlovers were ordered by each customer?
Select 
s.pizza_id,
n.pizza_name,
s.customer_id,
COUNT(s.*) as orders
from pizza_runner.customer_orders as s
left join pizza_runner.pizza_names as n
on s.pizza_id = n.pizza_id
group by 1,2,3
order by 3;

--6: What was the maximum number of pizzas delivered in a single order?
Select 
* from 
(
Select 
order_id,
count(order_id) as orders,
rank() over(order by count(order_id) desc) as ranking
from pizza_runner.customer_orders
where order_id IN (Select order_id from pizza_runner.runner_orders
				  where cancellation is null)
group by 1) as pizza_count
where ranking = 1;

--7:For each customer, how many delivered pizzas had at least 1 
-- change and how many had no changes?
Select 
c.customer_id,
SUM(CASE WHEN (c.exclusions is null and c.exclusions <> '')
	or (c.extras is not null and c.extras <> '') then 1 else 0 end) atleastone_changes,
SUM(CASE WHEN (c.exclusions is null or c.exclusions = '') 
	or (c.extras is null and c.extras = '') then 1 else 0 end) as no_change
from pizza_runner.customer_orders as c
inner join pizza_runner.runner_orders as r
on c.order_id = r.order_id
where r.cancellation is null
group by 1;

--8:How many pizzas were delivered that had both exclusions and extras?
Select * from pizza_runner.customer_orders;
WITH changes as(
Select
order_id,
SUM(case when exclusions is not null and extras is not null then 1 else 0 end) as both_change
from pizza_runner.customer_orders
group by 1)
Select 
SUM(both_change) as pizzas_with_change
from changes
;

--9: What was the total volume of pizzas ordered for each hour of the day?
Select 
EXTRACT(hour from order_time) as hour_of_day,
count(*) as pizza_sold
from pizza_runner.customer_orders
group by 1;

--10:What was the volume of orders for each day of the week?
Select 
to_char(order_time, 'day') as day_of_week,
count(*) as pizza_sold
from pizza_runner.customer_orders
group by 1;

/*Runner and Customer Experience*/
--1: How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
Select
to_char(registration_date,'WW') as week,
count(*)
from pizza_runner.runners
group by 1;

--2: What was the average time in minutes it took for each runner 
--to arrive at the Pizza Runner HQ to pickup the order?
Select * from pizza_runner.runner_orders;

with diff as
(Select
o.order_id,
r.runner_id,
r.pickup_time-o.order_time as time_diff
from pizza_runner.customer_orders as o
inner join pizza_runner.runner_orders as r
on o.order_id = r.order_id
where r.cancellation is null
group by 1,2,3)
Select 
extract(minute from avg(time_diff))
from diff;


--3:Is there any relationship between the number of pizzas and how long the order takes to prepare?
with make_time as
(Select 
o.order_id,
EXTRACT(minute from r.pickup_time - o.order_time) as time_to_make,
count(o.*) as pizzas
from pizza_runner.customer_orders as o
inner join pizza_runner.runner_orders as r
on o.order_id = r.order_id
where r.cancellation is null
group by 1,2)
Select 
CORR(time_to_make,pizzas) * 100 as correlation
from make_time;

--4: What was the average distance travelled for each customer?
Select * from pizza_runner.runner_orders;
Select * from pizza_runner.customer_orders;

Select
o.customer_id,
avg(r.distance) as avg_distance
from pizza_runner.customer_orders as o
left join pizza_runner.runner_orders as r
on o.order_id = r.order_id
where r.cancellation is null
group by 1
;

--5: What was the difference between the longest 
--and shortest delivery times for all orders?
Select
MAX(duration) - MIN(duration) as diff
from pizza_runner.runner_orders
where cancellation is null;

--6. What was the average speed for each runner for each 
--delivery and do you notice any trend for these values?
Select * from pizza_runner.runner_orders;
Select 
c.order_id,
count(c.*) as pizza_count,
r.runner_id,
r.distance,
ROUND((r.distance/r.duration * 60)::numeric, 2) as avg_speed
from pizza_runner.runner_orders as r
left join pizza_runner.customer_orders as c
on r.order_id = c.order_id
where duration is not null
group by 1,3,4,5
order by 2 desc, 5;

--7: What is the successful delivery percentage for each runner?
Select
runner_id,
ROUND(100 * SUM(CASE WHEN duration <> 0 then 1 else 0 end)/COUNT(*),0) as percent_delivery
from pizza_runner.runner_orders
group by 1;

/* Ingredient Optimisation */
Select * from pizza_runner.pizza_names;
Select * from pizza_runner.pizza_recipes;
Select * from pizza_runner.pizza_toppings;

--1: What are the standard ingredients for each pizza?
WITH recipes as(
Select 
pizza_id,
regexp_split_to_table(toppings,'[,\s]+')::integer as topping
from pizza_runner.pizza_recipes)
,
ingredients as(
Select 
n.pizza_name as name,
t.topping_name as toppings,
r.pizza_id
from recipes as r
join pizza_runner.pizza_toppings as t on t.topping_id = r.topping
join pizza_runner.pizza_names as n on r.pizza_id = n.pizza_id)
Select 
name,
toppings
from ingredients
order by name;

--2: What was the most commonly added extra?
Select * from pizza_runner.customer_orders;
Select * from pizza_runner.pizza_toppings;

WITH extras as(
Select order_id,
REGEXP_SPLIT_TO_TABLE(extras,'[,\s]+')::integer as extra_order
from pizza_runner.customer_orders
where extras is not null),
counting as(
Select 
e.order_id,
e.extra_order,
t.topping_name
from extras as e
join pizza_runner.pizza_toppings as t on e.extra_order = t.topping_id
)
Select 
c.topping_name,
count(c.*) as tally
from counting as c
group by 1
order by 2 desc;

--3: What was the most common exclusion?
Select * from pizza_runner.customer_orders;
Select * from pizza_runner.pizza_toppings;

with exclusions as(
Select 
order_id,
regexp_split_to_table(exclusions, '[,\s]+')::integer as exclusion_order
from pizza_runner.customer_orders
where exclusions is not null)
Select 
t.topping_name,
count(e.exclusion_order) as count_exclusion
from exclusions as e
join pizza_runner.pizza_toppings as t on e.exclusion_order = t.topping_id
group by 1
order by 2 desc;

/*4: 4. Generate an order item for each record in the customers_orders table in the format of one of the following:a. Meat Lovers
b. Meat Lovers - Exclude Beef
c. Meat Lovers - Extra Bacon
d. Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/
Select * from pizza_runner.customer_orders
where exclusions is not null
or extras is not null;


Select order_id,
pizza_id,
exclusions,
extras,
CASE 
WHEN pizza_id = 1 AND (exclusions like '2%' AND extras like '1%4') THEN 'Meat Lovers - Exclude BBQ Sauce, Mushroom - Extra Bacon, Cheese'
WHEN pizza_id = 1 AND (exclusions = '4' AND extras like '1%5') THEN 'Meat Lovers - Exclude Cheese - Extra Bacon, Chicken'
WHEN pizza_id = 1 AND exclusions is null AND extras is null THEN 'Meat Lovers'
WHEN pizza_id = 2 AND exclusions is null AND extras is null THEN 'Vegetarian'
WHEN pizza_id = 1 AND exclusions = '4' AND extras is null THEN 'Meat Lovers - Exclude Cheese'
WHEN pizza_id = 2 AND exclusions = '4' AND extras is null THEN 'Vegetarian - Exclude Cheese'
WHEN pizza_id = 1 AND exclusions is null AND extras = '1' THEN 'Meat Lovers - Extra Bacon'
WHEN pizza_id = 2 AND exclusions is null AND extras = '1' THEN 'Vegetarian - Extra Bacon'
END as pizza_type
from pizza_runner.customer_orders
order by pizza_id;

--Pricing and Rating
/*Question 1: If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were 
no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?*/
Select * from pizza_runner.customer_orders;
WITH pizza_total as(
Select 
order_id,
customer_id,
pizza_id,
CASE WHEN pizza_id = 1 THEN 12
	WHEN pizza_id = 2 THEN 10 END as pizza_price
from pizza_runner.customer_orders
where order_id in (Select order_id
				  from pizza_runner.runner_orders where duration is not null))
Select
SUM(pizza_price) as profit
from pizza_total;


/* Question2: What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 extra*/
Select * from pizza_runner.customer_orders;
WITH extra_charge as(
Select 
order_id,
customer_id,
extras,
pizza_id,
CASE
	WHEN pizza_id = 1 and extras like '%,%' THEN 14
	WHEN pizza_id = 2 and extras like '%,%' THEN 12
	WHEN pizza_id = 1 and extras is not null THEN 12 + 1
	WHEN pizza_id = 2 and extras is not null THEN 10 + 1
	WHEN pizza_id = 1 and extras is null THEN 12
	ELSE 10 END as pizza_price
from pizza_runner.customer_orders)
Select SUM(pizza_price)
from extra_charge;

/*Question 3: The Pizza Runner team now wants to add an additional 
ratings system that allows customers to rate their runner, 
how would you design an additional table for this new dataset 
- generate a schema for this new table and insert your
own data for ratings for each successful customer order between 1 to 5.*/
CREATE SCHEMA ratings;
CREATE TYPE star AS ENUM ('1', '2', '3', '4', '5');

CREATE TABLE ratings.rating as
Select 
c.order_id,
r.runner_id,
c.customer_id
from pizza_runner.customer_orders as c
inner join pizza_runner.runner_orders as r
on c.order_id = r.order_id
where r.cancellation is null;

--Adding the rating column with star datatype
ALTER TABLE ratings.rating
ADD COLUMN rating star;


UPDATE ratings.rating
SET rating = CASE WHEN order_id = 1 THEN '3'::star
			WHEN order_id = 3 THEN '4'::star
			WHEN order_id = 10 THEN '5'::star
			WHEN order_id = 4 THEN '2'::star
			ELSE '3'::star END;

CREATE TABLE pizza_runner.runner_rating as
Select * from ratings.rating;
Select * from pizza_runner.runner_rating;

/* Question 4: Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas*/
Select 
c.order_id,
r.runner_id,
rr.rating,
c.order_time,
r.pickup_time,
r.duration,
ROUND((r.distance/r.duration * 60)::numeric, 2) as avg_speed,
count(c.*) as total_pizza
from pizza_runner.runner_orders as r
left join pizza_runner.customer_orders as c
on r.order_id = c.order_id
left join pizza_runner.runner_rating as rr
on c.order_id = rr.order_id and r.runner_id = rr.runner_id
where duration is not null
group by 1,2,3,4,5,6,7
;

/*Question 5: If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each 
runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?*/
WITH pizza_totals as(
Select 
c.order_id,
c.customer_id,
c.pizza_id,
r.runner_id,
r.distance,
CASE WHEN pizza_id = 1 THEN 12
	WHEN pizza_id = 2 THEN 10 END as pizza_price
from pizza_runner.customer_orders as c
left join pizza_runner.runner_orders r 
on c.order_id = r.order_id
where r.distance is not null),

runner_payment as(
Select 
p.runner_id,
p.distance,
(p.distance * 0.30)::numeric as payment
from pizza_totals as p)

Select 
SUM(pizza_price) - (select sum(payment) from runner_payment) as profit
from pizza_totals;

--BONUS QUESTION:
/*If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an 
INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?*/

--Identify the tables needed to be modified:
Select * from pizza_runner.pizza_names;
Select * from pizza_runner.pizza_recipes;

--Starting with pizza_names, insert a new pizza_id and pizza_name:
INSERT INTO pizza_runner.pizza_names (pizza_id, pizza_name)
VALUES
    (3, 'Supreme Pizza');
	
--Check if the new record has been added:
Select * from pizza_runner.pizza_names;

--The second table to be altered is the recipes table:
INSERT INTO pizza_runner.pizza_recipes (pizza_id, toppings)
VALUES
    (3, '1,2,3,4,5,6,7,8,9,10,11,12');

--check your table:
Select * from pizza_runner.pizza_recipes;

--Updated to have a space in between commas
update pizza_runner.pizza_recipes
set toppings = '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12'
where pizza_id = 3;












