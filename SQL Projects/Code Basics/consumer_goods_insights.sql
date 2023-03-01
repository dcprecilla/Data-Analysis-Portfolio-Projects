/* Code basics SQL Challenge for: Provide Insights to Management in Consumer Goods Domain*/

/*Explore the data*/
select
*
from dim_customer;

select 
*
from dim_product;

select 
* 
from fact_gross_price;

select
*
from fact_manufacturing_cost;

select
*
from
fact_pre_invoice_deductions;

select
*
from fact_sales_monthly;

/*Ad-hoc questions:*/

-- 1:  Provide Insights to Management in Consumer Goods Domain
select
distinct market
from dim_customer
where customer = 'Atliq Exclusive'
and region = 'APAC';

-- 2: What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields
/*unique_products_2020
unique_products_2021
percentage_chg */
with prod_2020 as(
select
product_code as products_2020,
SUM(sold_quantity) as total_sold
from fact_sales_monthly
where fiscal_year = 2020
group by 1),
prod_2021 as(
select
product_code as products_2021,
SUM(sold_quantity) as total_sold
from fact_sales_monthly
where fiscal_year = 2021
group by 1)
select
products_2020,
products_2021,
ROUND(cast(f2.total_sold - f1.total_sold as float)/f2.total_sold * 100,2) as percentage_chg
from 
prod_2020 as f1
cross join prod_2021 as f2
on f1.products_2020 = f2.products_2021;

/* 3: Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/
select
segment,
count(product_code) as product_count
from
dim_product
group by 1
order by 2 desc;

/* 4: Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields*/
with prods_2020 as(
select
p.segment as segment1,
COUNT(distinct p.product_code) as product_2020
from dim_product as p
join fact_sales_monthly as s
on p.product_code = s.product_code
where s.fiscal_year = 2020
group by 1),
prods_2021 as(
select
p.segment as segment,
COUNT(distinct p.product_code) as product_2021
from dim_product as p
join fact_sales_monthly as s
on p.product_code = s.product_code
where s.fiscal_year = 2021
group by 1)
select
segment,
product_2021 as product_count_2021,
product_2020 as product_count_2020,
product_2021 - product_2020 as difference
from prods_2021 as t1
left join prods_2020 as t2
on t1.segment = t2.segment1;

/*5: Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/
with costs as(
select
c.product_code,
p.product,
c.manufacturing_cost,
dense_rank() over(order by c.manufacturing_cost) as rankings
from fact_manufacturing_cost as c
join dim_product as p
on c.product_code = p.product_code
group  by 1,2)
select
product_code,
product,
manufacturing_cost
from costs
where rankings in (select
min(rankings) as ranks from costs
union
select max(rankings) as ranks from costs);

/*Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/
with discounts as(
select
d.customer_code,
c.customer,
ROUND(avg(pre_invoice_discount_pct),2) avg_discount_percentage
from fact_pre_invoice_deductions as d
join dim_customer as c
on d.customer_code = d.customer_code
where d.fiscal_year = 2021
and c.market = 'India'
group by 1,2
),
ranks as(
select 
*,
dense_rank() over(order by avg_discount_percentage desc) as ranking
from discounts)
select
d.*
from discounts as d
join ranks as r
on d.customer_code = r.customer_code
where r.ranking <= 5;

/* 7: Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
*/
select
extract(month from s.date) as month,
extract(year from s.date) as year,
SUM(g.gross_price * s.sold_quantity) as gross_sales_amount
from fact_sales_monthly as s
join dim_customer as c
on s.customer_code = c.customer_code
join fact_gross_price as g
on s.product_code = g.product_code
where c.customer = 'Atliq Exclusive'
group by 1,2
order by 2, 1;

/*8: In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/
with quarters as(
select
*,
NTILE(4) OVER(ORDER BY date) as quarter
from fact_sales_monthly
where fiscal_year = 2020)
select
quarter,
SUM(sold_quantity) as total_sold_quantity
from quarters
group by 1
order by 2 desc
LIMIT 1;

/*9:Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/
with channels as(
select
c.channel,
sum(g.gross_price * s.sold_quantity) as gross_sales_mln
from dim_customer as c
join fact_sales_monthly as s
on c.customer_code = s.customer_code
join fact_gross_price as g
on s.product_code = g.product_code
where s.fiscal_year = 2021
group by 1)
select
*,
ROUND(gross_sales_mln/(Select SUM(gross_sales_mln) from channels) * 100,2) as percentage
from channels
order by 3 desc;

/*10: Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order*/
with divisions_rank as(
select
p.division,
p.product_code,
p.product,
SUM(s.sold_quantity) as total_sold_quantity,
dense_rank() over(partition by division 
order by SUM(s.sold_quantity) desc) as rank_order
from fact_sales_monthly as s
join dim_product as p
on s.product_code = p.product_code
group by 1,2,3
)
select
*
from divisions_rank
where rank_order <= 3;

