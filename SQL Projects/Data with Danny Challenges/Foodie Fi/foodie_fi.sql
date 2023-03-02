/*Part A: Based off the 8 sample customers provided in the sample
from the subscriptions table, write a brief description 
about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to
run some sort of join to make your explanations a bit easier!*/

Select 
* 
from foodie_fi.subscriptions;

Select
* 
from foodie_fi.plans;

WITH sample as(
Select 
s.customer_id,
s.plan_id,
s.start_date,
p.plan_name
from foodie_fi.subscriptions as s
inner join foodie_fi.plans as p
on s.plan_id = p.plan_id
where s.customer_id in (1,2,11,13,15,16,18,19))
Select
*,
RANK() OVER(Partition by customer_id
		   Order by start_date asc) as rank_start
from sample;

--B. Data Analysis Questions
--1: How many customers has Foodie-Fi ever had?
Select
COUNT(DISTINCT customer_id)
from foodie_fi.subscriptions;

--2: What is the monthly distribution of trial plan start_date
--values for our dataset - use the start of the month as the 
--group by value
WITH master as(
Select 
s.customer_id,
s.plan_id,
s.start_date,
p.plan_name
from foodie_fi.subscriptions as s
inner join foodie_fi.plans as p
on s.plan_id = p.plan_id)
Select 
DATE_TRUNC('month', m.start_date)::date as month_start,
COUNT(*) as sub_count
from master as m
where m.plan_name = 'trial'
group by DATE_TRUNC('month', m.start_date)
order by 1;

--3: What plan start_date values occur after the year 2020 for 
--our dataset? Show the breakdown by count of events for each 
--plan_name
Select 
EXTRACT(year from start_date),
count(*)
from foodie_fi.subscriptions 
group by 1;

WITH master as(
Select 
s.customer_id,
s.plan_id,
s.start_date,
p.plan_name
from foodie_fi.subscriptions as s
inner join foodie_fi.plans as p
on s.plan_id = p.plan_id)
Select 
m.plan_name,
COUNT(*) as count_sub
from master as m
where extract(year from start_date) > 2020
group by 1;

--4: What is the customer count and percentage of customers
--who have churned rounded to 1 decimal place?
WITH churn_total as(
Select 
(Select COUNT(DISTINCT customer_id) from foodie_fi.subscriptions where plan_id = 4) as churn,
COUNT(DISTINCT customer_id) as total
from foodie_fi.subscriptions
)
Select
ROUND(churn/total::numeric * 100.0,1) as churn_rate
from churn_total;

--5:How many customers have churned straight after their initial 
--free trial - what percentage is this rounded to the nearest 
--whole number?
WITH sample as(
Select 
s.customer_id,
s.plan_id,
s.start_date,
p.plan_name
from foodie_fi.subscriptions as s
inner join foodie_fi.plans as p
on s.plan_id = p.plan_id),
churned as (
Select
*,
row_number() over(partition by customer_id
				 order by plan_id) as plan_row
from sample)
Select
ROUND(COUNT(DISTINCT customer_id)::numeric/(Select count(distinct customer_id) from foodie_fi.subscriptions) * 100.0,1) as churn_rate_from_free
from churned
where plan_id = 4
and plan_row = 2;

--6 : What is the number and percentage of customer plans 
--after their initial free trial?
with plan as(
Select
customer_id,
plan_id,
lead(plan_id) over(partition by customer_id
				  order by plan_id) as next_plan
from foodie_fi.subscriptions
)
Select
next_plan,
count(*) as conversions,
ROUND(100.0 * count(*)::numeric/(select count(distinct customer_id)
						  from foodie_fi.subscriptions),2) as conversion_rate
from plan
where next_plan is not null
and plan_id = 0
group by 1
order by 1;

/*
Select
plan_id,
next_plan
from plan
where plan_id = 0;*/

--7: What is the customer count and percentage breakdown of 
--all 5 plan_name values at 2020-12-31?
--Get the next start date
WITH dates as(
Select
*,
LEAD(start_date) over(partition by customer_id
					 order by start_date) as next_date
from foodie_fi.subscriptions
where start_date <= '2020-12-31'),
customer_count as(
Select 
plan_id,
COUNT(DISTINCT customer_id) as customers
from dates
where 
(next_date is not null and (start_date < '2020-12-31'
						   and next_date > '2020-12-31'))
or (next_date is null and start_date < '2020-12-31')
group by 1)
Select
*,
ROUND(customers/(Select COUNT(DISTINCT customer_id) from foodie_fi.subscriptions)::numeric*100.0, 2) as percentage
from customer_count;

--8:How many customers have upgraded to an annual plan in 2020?
Select 
count(distinct customer_id) as customers
from foodie_fi.subscriptions
where plan_id = 3
and EXTRACT(year from start_date) = 2020;

--9: How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH free_trial as(
Select
customer_id,
plan_id, 
start_date as initial
from foodie_fi.subscriptions
where plan_id = 0),
annual as(
Select 
customer_id, 
plan_id,
start_date as annual_up
from foodie_fi.subscriptions
where plan_id = 3)
Select
CEILING(AVG(annual_up - initial)) as avg_days
from free_trial as ft, annual as a
where ft.customer_id = a.customer_id;



--10: Can you further breakdown this average value into 30 day periods (i.e. 0–30 days, 31–60 days etc)
WITH free_trial as(
Select
customer_id,
plan_id, 
start_date as initial
from foodie_fi.subscriptions
where plan_id = 0),
annual as(
Select 
customer_id, 
plan_id,
start_date as annual_up
from foodie_fi.subscriptions
where plan_id = 3),
with bins as(
Select
a.customer_id,
WIDTH_BUCKET(annual_up - initial, 0, 360, 12) as bin
from free_trial as ft, annual as a
where ft.customer_id = a.customer_id
group by 1,2)


--11: How many customers downgraded from a pro monthly(2) to a basic monthly plan(1) in 2020?
--The answer for 11 is 0. No customer has downgraded.

WITH plan as(
Select 
*,
LEAD(plan_id) OVER(Partition by customer_id 
					 Order by start_date, plan_id) as next_plan
from foodie_fi.subscriptions
where extract(year from start_date) = 2020)

Select 
COUNT(DISTINCT customer_id) as customers_downgrade
from plan 
where plan_id = 2
and next_plan = 1;


