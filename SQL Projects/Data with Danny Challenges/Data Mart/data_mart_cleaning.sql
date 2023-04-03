select
*
from data_mart.weekly_sales;
/* 1. Data Cleansing Steps: 
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
Convert the week_date to a DATE format
Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
Add a month_number with the calendar month for each week_date value as the 3rd column
Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
Add a new demographic column using the following mapping for the first letter in the segment values:
Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
*/
CREATE TABLE data_mart.clean_weekly_sales as(
Select
to_date(week_date,'DD/MM/YY'),
EXTRACT(week from to_date(week_date,'DD/MM/YY')) as week_num,
EXTRACT(month from to_date(week_date,'DD/MM/YY')) as month_num,
EXTRACT(year from to_date(week_date,'DD/MM/YY')) as calendar_year,
region,
platform,
CASE WHEN segment = 'null' then 'unknown' else segment end as segment,
CASE WHEN segment like '%1' THEN 'Young Adults'
	WHEN segment like '%2' THEN 'Middle Aged'
	WHEN (segment like '%3' or segment like '%4') THEN 'Retirees'
	ELSE 'unknown' END as age_band,
CASE WHEN LEFT(segment,1) = 'C' THEN 'Couples'
	WHEN LEFT(segment,1) = 'F' THEN 'Families'
	ELSE 'unknown' END as demographic,
transactions,
sales,
ROUND(sales/transactions::numeric,2) as avg_transactions
from data_mart.weekly_sales);
