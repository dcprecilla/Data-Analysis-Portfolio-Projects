
--Cleaning the pizza_runner.customer_orders
--Removing string 'null'
update pizza_runner.customer_orders
set exclusions = NULLIF(exclusions, 'null'),
extras = NULLIF(extras,'null');

--Updating the customer_orders table again to remove blank spaces
update pizza_runner.customer_orders
set exclusions = CASE exclusions WHEN ''THEN null ELSE exclusions END,
extras = CASE extras WHEN '' THEN null ELSE extras END;

--Cleaning the runner_orders table
--Removing the stringed null from the pickup_time column
update pizza_runner.runner_orders
set pickup_time = NULLIF(pickup_time,'null');

--Alter the pickup_time column from varchar to timestamp without time zone
alter table pizza_runner.runner_orders
alter column pickup_time type timestamp
using pickup_time::timestamp without time zone;

--Cleaning the distance column
UPDATE pizza_runner.runner_orders
set distance = NULLIF(distance, 'null');

--Testing CASE WHEN cleaning for the distance column
Select 
CASE WHEN distance like '%km' THEN REPLACE(distance,'km','') ELSE distance END as distance
from pizza_runner.runner_orders;

--Implementing the CASE WHEN from the previous query
UPDATE pizza_runner.runner_orders
set distance = CASE WHEN distance like '%km' THEN REPLACE(distance,'km','') ELSE distance END

--From varchar, the distnace column should be float
alter table pizza_runner.runner_orders
alter column distance type float
using distance::double precision;

--Cleaning the duration column
update pizza_runner.runner_orders
set duration = LEFT(NULLIF(duration,'null'),2);

--Duration column should be int (using int because the column does not have decimals)
alter table pizza_runner.runner_orders
alter column duration type int
using duration::int;








