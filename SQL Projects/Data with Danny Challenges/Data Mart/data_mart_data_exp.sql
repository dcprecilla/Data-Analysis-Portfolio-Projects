/* Data Exploration */
--1: What day of the week is used for each week_date value?
Select
distinct(to_char(to_date,'day')) as week_day
from data_mart.clean_weekly_sales;

--2: What range of week numbers are missing from the dataset?
-- 1 to 52 because there are 52 weeks in a calendar year
with week_nums as(
select 
generate_series(1,52) as weeks)
Select
weeks
from week_nums
where weeks not in (select distinct week_num
				   from data_mart.clean_weekly_sales);
--3: How many total transactions were there for each year in the dataset?
select
calendar_year,
sum(transactions) as total_transactions
from data_mart.clean_weekly_sales
group by 1;

--4: What is the total sales for each region for each month?
Select
region,
month_num,
sum(sales) as total_sales
from data_mart.clean_weekly_sales
group by 1,2;

--5: What is the total count of transactions for each platform
select
platform,
sum(transactions) as total_transactions
from data_mart.clean_weekly_sales
group by 1;

--6: What is the percentage of sales for Retail vs Shopify for each month?
with monthly as(
select
calendar_year,
month_num,
sum(sales) as monthly_sales
from data_mart.clean_weekly_sales
group by 1,2),
platform as(
select
calendar_year,
month_num,
SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) as retail,
SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) as shopify
from data_mart.clean_weekly_sales
group by 1,2)
select
p.calendar_year,
p.month_num,
ROUND(p.retail/m.monthly_sales::numeric * 100,2) as pct_retail,
ROUND(p.shopify/m.monthly_sales::numeric * 100,2) as pct_shopify
from platform as p
join monthly as m 
on p.calendar_year = m.calendar_year
and p.month_num = m.month_num
order by 1,2 asc;

--7: What is the percentage of sales by demographic for each year in the dataset?
with yearly as(
select
calendar_year,
sum(sales) as yearly_sales
from data_mart.clean_weekly_sales
group by 1),
demographics as(
select
calendar_year,
SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END) as family_sum,
SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END) as couples_sum,
SUM(CASE WHEN demographic = 'unknown' THEN sales ELSE 0 END) as unknown_sum
from data_mart.clean_weekly_sales
group by 1)
select
d.calendar_year,
family_sum/yearly_sales::numeric * 100 as pct_sales_family,
couples_sum/yearly_sales::numeric * 100 as pct_sales_couples,
unknown_sum/yearly_sales::numeric * 100 as pct_sales_unknown
from demographics as d
join yearly as y
on d.calendar_year = y.calendar_year
order by 1;

-- 8: Which age_band and demographic values contribute the most to Retail sales?
select
age_band,
demographic,
sum(sales) as total_sales
from data_mart.clean_weekly_sales
where platform = 'Retail'
group by 1,2
order by 3 desc
;

--9: Can we use the avg_transaction column to find the average transaction size 
--for each year for Retail vs Shopify? If not 
-- how would you calculate it instead?
select
*
from
data_mart.clean_weekly_sales;

with trans as(
select
calendar_year,
sum(CASE WHEN platform = 'Retail' then transactions else 0 end) as Retail_Trans,
sum(CASE WHEN platform = 'Shopify' then transactions else 0 end) as Shopify_Trans
from data_mart.clean_weekly_sales
group by 1),
sales as(
select
calendar_year,
sum(case when platform = 'Retail' then sales else 0 end) as Retail,
sum(case when platform = 'Shopify' then sales else 0 end) as Shopify
from data_mart.clean_weekly_sales
group by 1)
select 
s.calendar_year,
CEILING(Retail/Retail_Trans:: numeric) as atv_retail,
CEILING(Shopify/Shopify_Trans:: numeric) as atv_shopify
from sales as s
join trans as t
on s.calendar_year = t.calendar_year;

--Section 3: Before and Aftetr Analysis

-- 1: What is the total sales for the 4 weeks before and after 2020-06-15?
--What is the growth or reduction rate in actual values
--and percentage of sales?

-- get first the week number for filtering 4 weeks before and after
select
distinct week_num
from data_mart.clean_weekly_sales
where to_date = '2020-06-15'; -- 25

with weeks as(
select 
to_date,
week_num,
sum(sales) as t_sales
from data_mart.clean_weekly_sales
where week_num between 21 and 29
	and calendar_year = 2020
group by 1,2),
change as(
select
SUM(CASE WHEN week_num BETWEEN 21 AND 24 THEN t_sales ELSE 0 END) as before_change,
SUM(CASE WHEN week_num BETWEEN 25 AND 28 THEN t_sales ELSE 0 END) as after_change	
from weeks
)
select
before_change,
after_change,
after_change - before_change as diff,
100 * (after_change - before_change)/before_change as pct
from change

--2. What about the entire 12 weeks before and after?
with weeks as(
select 
to_date,
week_num,
sum(sales) as t_sales
from data_mart.clean_weekly_sales
where week_num between 13 and 37
	and calendar_year = 2020
group by 1,2),
change as(
select
SUM(CASE WHEN week_num BETWEEN 13 AND 24 THEN t_sales ELSE 0 END) as before_change,
SUM(CASE WHEN week_num BETWEEN 25 AND 37 THEN t_sales ELSE 0 END) as after_change	
from weeks
)
select
before_change,
after_change,
after_change - before_change as diff,
100 * (after_change - before_change)/before_change as pct
from change

--3:How do the sale metrics for these 2 periods before and after compare 
--with the previous years in 2018 and 2019?
with weeks as(
select 
to_date,
week_num,
sum(sales) as t_sales
from data_mart.clean_weekly_sales
where week_num between 13 and 37
	and calendar_year in (2018,2019,2020)
group by 1,2),
change as(
select
extract(year from to_date) as year,
SUM(CASE WHEN week_num BETWEEN 13 AND 24 THEN t_sales ELSE 0 END) as before_change,
SUM(CASE WHEN week_num BETWEEN 25 AND 37 THEN t_sales ELSE 0 END) as after_change	
from weeks
group by 1)
select
year,
before_change,
after_change,
after_change - before_change as diff,
ROUND(100 * (after_change - before_change)/before_change,2) as pct
from change

