CREATE SCHEMA portfolio;

CREATE TABLE portfolio.ca_hospitals(
incident_year int,
COUNTY varchar,
HOSPITAL varchar,
OSHPDID varchar,
Procedure_Condition varchar,
Adjusted_mortality_rate float,
Death_Count int,
Cases int,
Hospital_Ratings varchar,
LONGITUDE varchar,
LATITUDE varchar
);


--Had to add an additional clause because it is a UTF-8 
COPY portfolio.ca_hospitals FROM 'C:\Users\Public\Datasets\ca_hosp.csv' DELIMITER ',' CSV HEADER encoding 'windows-1251';

-- Check the ca_hospitals table
select
*
from portfolio.ca_hospitals;

/*Upon checking the table we have wrong data types. I will be making a copy of the table so we don't lose any original detail from the table*/
create temp table hospitals as(
select
*
from portfolio.ca_hospitals);

/*Upon seeing the initial data, there are 'None' values in the longitude, latitude, and oshpdid columns. These columns should be floats and int repectfully
I will saving this again in a temp table so I don't have to house it in a CTE*/
DROP TABLE hospitals_update
CREATE TEMP TABLE hospitals_update as(
select
incident_year,
COUNTY,
HOSPITAL,
CASE WHEN oshpdid = 'None' THEN null ELSE oshpdid END::int as hospital_id,
Procedure_Condition,
Adjusted_mortality_rate,
Death_Count,
Cases,
Hospital_Ratings,
CASE WHEN longitude = 'None' THEN null ELSE longitude END as longitude,
CASE WHEN latitude = 'None' THEN null ELSE latitude END as latitude
from hospitals
where county != 'AAAA');

select
*
from hospitals_update;

/*Analysis Start*/
/*Problem: Exploratory data analysis of California Hospital Inpatient Mortality Rates and Quality Ratings for the years 2016 - 2020*/

Select
count(*)
from hospitals_update
;
--24,368 rows in the dataset

-- How many hospitals are in the dataset?
Select
count(distinct hospital)
from hospitals_update;
/* 389 hospitals*/

-- Descriptive statistics
Select
incident_year,
SUM(Death_Count) as yearly_death,
SUM(Cases) as yearly_cases,
FLOOR(AVG(Death_Count)) as avg_death,
MIN(Death_Count) as minimum_death_yearly,
MAX(Death_Count) as max_death_yearly
from hospitals_update
where Cases is not null
and Death_Count is not null
group by 1
order by 1;

--Checking if descriptive statistics is correct
Select
*
from hospitals_update
where incident_year = 2016
and Death_Count = 153;

Select
*
from hospitals_update
where incident_year = 2017
and Death_Count = 167;

Select
*
from hospitals_update
where incident_year = 2020
and Death_Count = 130;


-- First I wanted to know what year had the highest in patient deaths, regardless of conditions
Select
incident_year,
sum(death_count) as total_deaths
from hospitals_update
group by 1
order by 2 desc;

/*2020 is the year with the highest death toll, we can expect this because 2020 was the year of COVID-19*/

--What is the condition/procedure with the highest deaths and what is percent share of the total deaths to total cases?
select
Procedure_Condition,
sum(Death_Count) as death_total,
sum(cases) as cases,
ROUND(sum(Death_Count)/sum(Cases)::numeric * 100.0,2) as pct_share_to_cases
from hospitals_update
group by 1
order by 2 desc;

/*The highest death cause is Acute Stroke at 54,292 deaths in a span of 4 years. While Acute Stroke Hemorrhagic has a 20.54% share of deaths from 
the total number of cases and 8.83% share of death for Acurte Stroke from its total cases */

-- Which hospital and county has the highest death count?
Select
HOSPITAL,
COUNTY,
sum(Death_count) as total
from hospitals_update
group by 1,2
order by 3 desc; 

/*Fresno county's Community Regional Medical Center – Fresno has the highest deaths in 4 years having 1,989 patients dead*/

--What was the leading cause of death per year?
with ranking_causes as(
Select
incident_year,
Procedure_Condition,
sum(Death_Count) as totals,
rank() over(partition by incident_year
		   order by sum(Death_Count) desc) as num_rank
from hospitals_update
group by 1,2
)
select
incident_year,
Procedure_Condition
from ranking_causes
where num_rank = 1;

/*From 2016 to 2019 Acute Stroke was the number 1 cause of death for inpatinet mortality, 2020 was pneumonia because one of COVID-19's 
developmental sickness in pneumonia*/


--What was the yearly difference of death toll per condition?
with year_total as(
Select
incident_year,
Procedure_Condition,
sum(Death_Count) as totals
from hospitals_update
group by 1,2),
prevs as(
Select
*,
COALESCE(LAG(incident_year) over(partition by procedure_condition
					   order by incident_year)::varchar, 'first year') as previous_year,
LAG(totals) over(partition by procedure_condition
				order by incident_year) as previous_death_count
					   from year_total)
select
*,
totals - previous_death_count as diff --negative values indicate that from the previous year they had less deaths
from prevs
;

/*Survived conditions: To calculate survivors Cases - Death_Count,
I wanted to see which condition has the lowest survivors */
with survivors as(
Select
incident_year,
Procedure_Condition,
sum(Cases) as total_cases,
sum(Cases - Death_Count) as survivors
from hospitals_update
where county != 'AAAA'
group by 1,2
order by 4 desc
)
select
*,
ROUND(survivors/total_cases::numeric *100,2) as pct_survivors
from survivors
order by 5 asc;





























