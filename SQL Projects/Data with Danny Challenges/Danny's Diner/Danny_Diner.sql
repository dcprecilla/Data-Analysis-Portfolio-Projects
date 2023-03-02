-- Question 1: What is the total amount each customer spent at the restaurant?
WITH sales_cust as (
Select
s.customer_id as customer_id,
s.product_id,
m.price as price
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id = m.product_id)
Select 
customer_id,
SUM(price) as total_spent
from sales_cust
group by customer_id
order by customer_id;

-- Question 2: How many days has each customer visited the restaurant?
Select * from dannys_diner.sales;
Select 
customer_id,
count(distinct(order_date)) as num_visits_date
from dannys_diner.sales
group by 1;

-- What was the first item from the menu purchased by each customer?
WITH ranking as (Select
s.customer_id as cust_id,
s.order_date,
m.product_name as name,
dense_rank() over(partition by customer_id
				 order by order_date asc) as rank_num
from 
 dannys_diner.sales as s
 inner join dannys_diner.menu as m
 on s.product_id = m.product_id)
Select 
cust_id,
name
from ranking
where rank_num = 1
group by 1,2;

--What is the most purchased item on the menu and 
--how many times was it purchased by all customers?
Select 
m.product_name,
count(s.*) as sales_per_dish
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id = m.product_id
group by 1
order by 2 desc;

--Which item was the most popular for each customer?
WITH orders as(
Select 
s.customer_id as id,
m.product_name as name,
COUNT(*) as sales
from dannys_diner.sales as s
left join dannys_diner.menu as m 
on s.product_id = m.product_id
group by 1, 2)
Select
id,
name
from
(Select
*,
rank() over(
	partition by id order by sales desc) as ranking
from orders) as sub
where ranking = 1;

--Which item was purchased first by the customer 
--after they became a member?
WITH mem_ord as(
Select
s.customer_id as id,
m.product_name as name,
s.order_date as date,
rank() over(partition by s.customer_id
		   order by s.order_date) as ranking
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id = m.product_id
inner join dannys_diner.members as r
on s.customer_id = r.customer_id
where 
s.customer_id IN (Select customer_id from dannys_diner.members)
and s.order_date > r.join_date)
Select 
id,
name
from mem_ord
where ranking = 1

--Which item was purchased just before the customer became a member?
WITH mem_ord as(
Select
s.customer_id as id,
m.product_name as name,
s.order_date as date,
rank() over(partition by s.customer_id
		   order by s.order_date desc) as ranking
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id = m.product_id
inner join dannys_diner.members as r
on s.customer_id = r.customer_id
where 
s.customer_id IN (Select customer_id from dannys_diner.members)
and s.order_date < r.join_date)
Select 
id,
name
from mem_ord
where ranking = 1

--What is the total items and amount spent for each member 
--before they became a member?
with mem_total as(
Select
s.customer_id as id,
m.product_name as name,
s.order_date as date,
m.price as amount
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id = m.product_id
inner join dannys_diner.members as r
on s.customer_id = r.customer_id
where 
s.customer_id IN (Select customer_id from dannys_diner.members)
and s.order_date < r.join_date)
Select
id, 
count(distinct name) as total_orders,
SUM(amount) as total_spent
from mem_total
group by 1
order by 3 desc;

--if each $1 spent equates to 10 points and sushi has 
--a 2x points multiplier - how many points would each customer have?
Select
s.customer_id,
SUM(CASE WHEN m.product_name = 'sushi' THEN m.price*20
   else price*10 END) as total_pts
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id = m.product_id
group by 1
order by 2 desc
;

--In the first week after a customer joins the program 
--(including their join date) they earn 2x points on 
--all items, not just sushi - how many points do 
--customerA and B have at the end of January?
Select
s.customer_id,
SUM(CASE WHEN s.order_date BETWEEN r.join_date AND (r.join_date + 
												   interval '6 days')::date
   THEN m.price*10*2
   WHEN m.product_name = 'sushi' THEN m.price*20
   ELSE m.price*10 END) as total_pts
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id = m.product_id
join dannys_diner.members as r
on s.customer_id = r.customer_id
where s.customer_id in (Select customer_id from dannys_diner.members)
and EXTRACT(month from s.order_date) = 1
group by 1
order by 2 desc
;

--BONUS QUESTIONS
Select
s.customer_id as id,
s.order_date as date,
m.product_name as dish,
m.price as price,
CASE WHEN s.order_date >= r.join_date THEN 'Y'
	ELSE 'N' END as member
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id = m.product_id
left join dannys_diner.members as r
on s.customer_id = r.customer_id
order by 1, 2;

--Ranking All things
WITH base as(
Select
s.customer_id as id,
s.order_date as date,
m.product_name as dish,
m.price as price,
CASE WHEN s.order_date >= r.join_date THEN 'Y'
	ELSE 'N' END as member
from dannys_diner.sales as s
left join dannys_diner.menu as m
on s.product_id = m.product_id
left join dannys_diner.members as r
on s.customer_id = r.customer_id
order by 1, 2)
Select 
*,
CASE WHEN member = 'Y' THEN RANK()
OVER(partition by id, member
	 order by date) END as ranking
from base
order by 1,2;









