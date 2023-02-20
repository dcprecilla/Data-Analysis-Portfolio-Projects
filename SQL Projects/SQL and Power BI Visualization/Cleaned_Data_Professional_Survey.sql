--table creation to house our survey data
CREATE TABLE project.data_survey(
Unique_ID varchar,
current_job varchar,
data_career_switch varchar,	
current_salary_USD varchar,
industry varchar,
programming_language varchar,
satisfaction_salary int ,
satisfaction_work_life_balance int,
satisfaction_coworkers int,
satisfaction_Management int,
satisfaction_upward_mobility int,
satisfaction_learning int ,
difficulty_getting_to_data varchar,	
new_job_requirements varchar,	
gender varchar,
age int,
country varchar,
educational_attainment varchar,
ethnicity varchar
)
-- Upload the file into the table
COPY project.data_survey
FROM 'C:\filepath'
DELIMITER ','
CSV HEADER;

--Check if the table has been properly loaded
select
* 
from project.data_survey;

--educational_attainment column: Only 5 people gave feedback so I am just going to exclude the column from EDA and cleaning
select
count(distinct educational_attainment)
from project.data_survey;

--creating a temp table without the educational_attainment column: The reason for temp table is I don't want to lose any important information
--that's why we need to keep the orginal source just in case we need it in future references
create temp table data_survey as(
select
Unique_ID,
current_job,
data_career_switch,
current_salary_USD,
industry,
programming_language,
satisfaction_salary,
satisfaction_work_life_balance,
satisfaction_coworkers,
satisfaction_Management,
satisfaction_upward_mobility,
satisfaction_learning,
difficulty_getting_to_data,	
new_job_requirements,	
gender,
age,
country,
ethnicity
from project.data_survey
);

select
*
from data_survey;

/*data cleaning current salary USD: From estimate I will just make it into a minimum and maximum type*/
with data_salary as(
select
*,
TRIM(REGEXP_REPLACE(split_part(current_salary_usd,'-',1),'[+,k]+','')) as min_salary,
TRIM(REGEXP_REPLACE(split_part(current_salary_usd,'-',2),'[+,k]+','')) as max_salary_dirty
from data_survey)

/*select
distinct min_salary
from data_salary;*/
-- There is a blank row in the max_salary, so we cannot yet convert to int
/*select
distinct max_salary
from data_salary*/

Select
programming_language,
count(*)
from data_survey_1
where lower(programming_language) like '%other%'
group by 1;

--filling up the values
with data_salary as(
select
*,
TRIM(REGEXP_REPLACE(split_part(current_salary_usd,'-',1),'[+,k]+','')) as min_salary,
TRIM(REGEXP_REPLACE(split_part(current_salary_usd,'-',2),'[+,k]+','')) as max_salary_dirty
from data_survey),
data_survey_1 as(
select
Unique_ID,
current_job,
data_career_switch,
current_salary_USD,
industry,
programming_language,
-- I cleaned the languages to include SQL because there is a significant share from the survey takers
CASE WHEN LOWER(programming_language) like '%sql%' THEN 'SQL' ELSE programming_language END as programming_language_clean,
COALESCE(satisfaction_salary,0),
COALESCE(satisfaction_work_life_balance,0),
COALESCE(satisfaction_coworkers,0),
COALESCE(satisfaction_Management,0),
COALESCE(satisfaction_upward_mobility,0),
COALESCE(satisfaction_learning,0),
difficulty_getting_to_data,	
new_job_requirements,	
gender,
age,
country,
ethnicity,
min_salary:: int, -- cast as int 
CAST(CASE max_salary_dirty when '' THEN '0' ELSE max_salary_dirty END as int) as max_salary -- cast as int
from data_salary)
-- check if the values are now valid
/*select
distinct min_salary
from data_survey_1;*/

/*select
distinct max_salary
from data_survey_1;*/

/*select 
industry,
count(*)
from data_survey_1
where lower(industry) like '%other%'
group by 1
;*/
CREATE TEMP TABLE data_cleaning as(
with data_salary as(
select
*,
TRIM(REGEXP_REPLACE(split_part(current_salary_usd,'-',1),'[+,k]+','')) as min_salary,
TRIM(REGEXP_REPLACE(split_part(current_salary_usd,'-',2),'[+,k]+','')) as max_salary_dirty
from data_survey)
select
Unique_ID,
current_job,
data_career_switch,
current_salary_USD,
industry,
CASE WHEN lower(industry) like '%reta%' THEN 'Retail'
	WHEN lower(industry) like '%auto%' THEN 'Automotive'
	WHEN lower(industry) like '%manu%' THEN 'Manufacturing'
	ELSE industry END as industry_1,
programming_language,
-- I cleaned the languages to include SQL because there is a significant share from the survey takers
CASE WHEN LOWER(programming_language) like '%sql%' THEN 'SQL' ELSE programming_language END as programming_language_clean,
COALESCE(satisfaction_salary,0) as satisfaction_salary,
COALESCE(satisfaction_work_life_balance,0) as satisfaction_work_life_balance,
COALESCE(satisfaction_coworkers,0) as satisfaction_coworkers,
COALESCE(satisfaction_Management,0) as satisfaction_Management,
COALESCE(satisfaction_upward_mobility,0) as satisfaction_upward_mobility,
COALESCE(satisfaction_learning,0) as satisfaction_learning,
difficulty_getting_to_data,	
new_job_requirements,	
gender,
age,
country,
ethnicity,
min_salary:: int, -- cast as int 
CAST(CASE max_salary_dirty when '' THEN '0' ELSE max_salary_dirty END as int) as max_salary -- cast as int
from data_salary)
;
	
/*select 
industry,
CASE WHEN lower(industry) like '%reta%' THEN 'Retail'
	WHEN lower(industry) like '%auto%' THEN 'Automotive'
	WHEN lower(industry) like '%manu%' THEN 'Manufacturing'
	ELSE industry END as industry_1
from data_cleaning_1*/

select
*,
min_salary + max_salary/2 as avg_salary
from data_cleaning;

select

from data_cleaning
group by 1;

--avg salary by ethnicity in the US
-- This is just my own curiosity, we can derive different conclusions from this result but for me this is saying that
-- majority of the survey takers who happened to be Caucasian has a high salary 
with cte as(
select
*,
CASE WHEN lower(ethnicity) like '%other%' THEN 'Other' ELSE ethnicity END as ethnicity_1,
min_salary + max_salary/2 as avg_salary
from data_cleaning)
Select
country, 
ethnicity_1,
ROUND(avg(avg_salary),2) as over_all_avg
from cte
where country = 'United States'
group by 1,2
order by 3 desc;

-- This will now be exported to CSV and be visualized in Power BI:
CREATE TABLE project.survey_data_cleaned as(
select
*,
min_salary + max_salary/2 as avg_salary
from data_cleaning)

-- Check the data and export to csv file
select
*
from project.survey_data_cleaned;












