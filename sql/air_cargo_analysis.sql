/* CANDIDATE: DAVID MARIA OLANDESE
Air Cargo Analysis
Course-end Project 2
Description
Air Cargo is an aviation company that provides air transportation services for passengers and freight. Air Cargo uses its aircraft to provide different services with the help of partnerships or alliances with other airlines. The company wants to prepare reports on regular passengers, busiest routes, ticket sales details, and other scenarios to improve the ease of travel and booking for customers.
 
Project Objective:
You, as a DBA expert, need to focus on identifying the regular customers to provide offers, analyze the busiest route which helps to increase the number of aircraft required and prepare an analysis to determine the ticket sales details. This will ensure that the company improves its operability and becomes more customer-centric and a favorable choice for air travel.
Note: You must download the dataset from the course resource section in the LMS and create the tables to perform the above objective.
 

*/

select * from customer;
select * from passengers_on_flights;
select * from routes;
select * from ticket_details;

-- 1.	Create an ER diagram for the given airlines database.
-- Use Database -> Reverse Engineer to visualize relationships.

-- 2.	Write a query to create route_details table using suitable data types for the fields, 
-- such as route_id, flight_num, origin_airport, destination_airport, aircraft_id, and distance_miles.
-- Implement the check constraint for the flight number and unique constraint for the route_id fields. 
-- Also, make sure that the distance miles field is greater than 0.


CREATE TABLE route_details (
  route_id            INT PRIMARY KEY,   -- unique by PK
  flight_num          VARCHAR(10) NOT NULL,
  origin_airport      VARCHAR(100) NOT NULL,
  destination_airport VARCHAR(100) NOT NULL,
  aircraft_id         INT,
  distance_miles      INT NOT NULL,
  CONSTRAINT chk_rd_flightnum CHECK (flight_num REGEXP '^[A-Z]{1,2}[0-9]{1,4}$'),  -- CHECK on flight_num for pattern: 1-2 letters + 1-4 digits (e.g., EK123, LH99)
  CONSTRAINT chk_rd_distance CHECK (distance_miles > 0)  -- UNIQUE on route_id, and distance_miles > 0
) ENGINE=InnoDB;

select * from route_details;

-- 3.	Write a query to display all the passengers (customers) who have travelled in routes 01 to 25. 
-- Take data  from the passengers_on_flights table.
-- If your route_id is INT, the range 1..25:

SELECT c.*
FROM customer c
JOIN passengers_on_flights p ON p.customer_id = c.customer_id
WHERE p.route_id BETWEEN 1 AND 25
GROUP BY c.customer_id, c.first_name, c.last_name, c.date_of_birth, c.gender;

-- 4.	Write a query to identify the number of passengers and total revenue in business class from the ticket_details table.
SELECT
  SUM(no_of_tickets) AS business_passengers,
  SUM(no_of_tickets * price_per_ticket) AS business_revenue
FROM ticket_details
WHERE class_id = 'Bussiness';  -- note: business is spelled wrong in the original table


-- 5.	Write a query to display the full name of the customer by extracting the first name and last name from the customer table.
SELECT
  customer_id,
  CONCAT(first_name, ' ', last_name) AS full_name
FROM customer;

-- 6.	Write a query to extract the customers who have registered and booked a ticket.
-- Use data from the customer and ticket_details tables.
SELECT DISTINCT
  c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN ticket_details t ON t.customer_id = c.customer_id;

-- 7.	Write a query to identify the customer’s first name and last name based on their customer ID and brand (Emirates)
-- from the ticket_details table.
SELECT DISTINCT
  c.customer_id, c.first_name, c.last_name
FROM ticket_details t
JOIN customer c ON c.customer_id = t.customer_id
WHERE t.brand = 'Emirates';

-- 8.	Write a query to identify the customers who have travelled by Economy Plus class using Group By and Having clause
-- on the passengers_on_flights table.
SELECT
  p.customer_id,
  COUNT(*) AS trips_econ_plus
FROM passengers_on_flights p
GROUP BY p.customer_id
HAVING SUM(p.class_id = 'Economy Plus') > 0;

-- 9.	Write a query to identify whether the revenue has crossed 10000 using the IF clause on the ticket_details table.
SELECT IF(sum(no_of_tickets * price_per_ticket) > 10000, 'Yes', 'No') AS revenue_over_10000
FROM ticket_details;

-- 10.	Write a query to create and grant access to a new user to perform operations on a database.
-- Adjust host and password to your environment.
-- Requires CREATE USER / GRANT privileges.
-- CREATE USER 'air_user'@'%' IDENTIFIED BY 'ChangeMe!Strong1';
-- GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON airlines.* TO 'air_user'@'%';
-- FLUSH PRIVILEGES;

-- 11.	Write a query to find the maximum ticket price for each class using window functions on the ticket_details table.
SELECT
  class_id,
  price_per_ticket,
  MAX(price_per_ticket) OVER (PARTITION BY class_id) AS max_price_in_class
FROM ticket_details
ORDER BY class_id, price_per_ticket DESC;

-- 12.	Write a query to extract the passengers whose route ID is 4 
-- by improving the speed and performance of the passengers_on_flights table.
-- Index already created above: KEY idx_pof_route (route_id)
SELECT *
FROM passengers_on_flights
WHERE route_id = 4;

-- 13.	 For the route ID 4, write a query to view the execution plan of the passengers_on_flights table.
EXPLAIN FORMAT=TRADITIONAL
SELECT *
FROM passengers_on_flights
WHERE route_id = 4;

-- 14.	Write a query to calculate the total price of all tickets booked by a customer across different aircraft IDs 
-- using rollup function.
SELECT
  customer_id,
  aircraft_id,
  SUM(no_of_tickets * price_per_ticket) AS total_amount,
  GROUPING(customer_id) AS is_customer_total,
  GROUPING(aircraft_id) AS is_aircraft_total
FROM ticket_details
GROUP BY customer_id, aircraft_id WITH ROLLUP;

-- 15.	Write a query to create a view with only business class customers along with the brand of airlines.
CREATE OR REPLACE VIEW vw_business_customers AS
SELECT DISTINCT
  t.customer_id,
  c.first_name,
  c.last_name,
  t.brand
FROM ticket_details t
JOIN customer c ON c.customer_id = t.customer_id
WHERE t.class_id = 'Bussiness'; -- typo mistake Business with double s

select * from vw_business_customers;

-- 16.	Write a query to create a stored procedure to get the details of all passengers flying between a range of routes defined in run time.
-- Also, return an error message if the table doesn't exist.
DELIMITER $$
CREATE PROCEDURE sp_passengers_between_routes(IN p_min INT, IN p_max INT)
BEGIN
  DECLARE t_exists INT DEFAULT 0;
  SELECT COUNT(*) INTO t_exists
  FROM information_schema.tables
  WHERE table_schema = DATABASE()
    AND table_name = 'passengers_on_flights';
  IF t_exists = 0 THEN
    SIGNAL SQLSTATE '42S02'
      SET MESSAGE_TEXT = 'Table passengers_on_flights does not exist in current schema.';
  ELSE
    SELECT p.*
    FROM passengers_on_flights p
    WHERE p.route_id BETWEEN p_min AND p_max
    ORDER BY p.route_id, p.customer_id;
  END IF;
END$$
DELIMITER ;

-- Example:
 CALL sp_passengers_between_routes(1, 25);

-- 17.	Write a query to create a stored procedure that extracts all the details
-- from the routes table where the travelled distance is more than 2000 miles.
DELIMITER $$
CREATE PROCEDURE sp_routes_over_2000()
BEGIN
  SELECT *
  FROM routes
  WHERE distance_miles > 2000
  ORDER BY distance_miles DESC;
END$$
DELIMITER ;

-- Example:
CALL sp_routes_over_2000();

-- 18.	Write a query to extract ticket purchase date, customer ID, 
-- class ID and specify if the complimentary services are provided for the specific class using a stored function in stored procedure on the ticket_details table.
DELIMITER $$
CREATE PROCEDURE sp_distance_buckets()
BEGIN
  SELECT
    flight_num,
    route_id,
    distance_miles,
    CASE
      WHEN distance_miles >= 0 AND distance_miles <= 2000 THEN 'SDT' -- Short Distance Travel
      WHEN distance_miles > 2000 AND distance_miles <= 6500 THEN 'IDT' -- Intermediate
      WHEN distance_miles > 6500 THEN 'LDT' -- Long Distance
      ELSE 'UNKNOWN'
    END AS distance_bucket
  FROM routes
  ORDER BY distance_miles;
END$$
DELIMITER ;

-- Example:
 CALL sp_distance_buckets();

-- 19.	If the class is Business and Economy Plus, then complimentary services are given as Yes, else it is No
DELIMITER $$
CREATE FUNCTION fn_compl_services(p_class VARCHAR(30))
RETURNS VARCHAR(3)
DETERMINISTIC
BEGIN
  RETURN (CASE
    WHEN p_class IN ('Business','Economy Plus') THEN 'Yes'
    ELSE 'No'
  END);
END$$
DELIMITER ;

-- Procedure that extracts p_date, customer_id, class_id and complimentary flag
DELIMITER $$
CREATE PROCEDURE sp_ticket_complimentary()
BEGIN
  SELECT
    p_date,
    customer_id,
    class_id,
    fn_compl_services(class_id) AS complimentary_services
  FROM ticket_details
  ORDER BY p_date, customer_id;
END$$
DELIMITER ;

-- Example:
CALL sp_ticket_complimentary();

--     20. Write a query to extract the first record of the customer whose last name ends with Scott using a cursor from the customer table.
DELIMITER $$
CREATE PROCEDURE sp_first_scott()
BEGIN
  DECLARE v_customer_id INT;
  DECLARE v_first_name  VARCHAR(50);
  DECLARE v_last_name   VARCHAR(50);
  DECLARE v_dob         DATE;
  DECLARE v_gender      VARCHAR(10);
  DECLARE done INT DEFAULT 0;

  DECLARE cur CURSOR FOR
    SELECT customer_id, first_name, last_name, date_of_birth, gender
    FROM customer
    WHERE last_name LIKE '%Scott'
    ORDER BY customer_id;  -- "first" by smallest id; change as needed

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  FETCH cur INTO v_customer_id, v_first_name, v_last_name, v_dob, v_gender;
  IF done = 0 THEN
    SELECT v_customer_id AS customer_id,
           v_first_name  AS first_name,
           v_last_name   AS last_name,
           v_dob         AS date_of_birth,
           v_gender      AS gender;
  ELSE
    SELECT NULL AS customer_id, NULL AS first_name, NULL AS last_name, NULL AS date_of_birth, NULL AS gender;
  END IF;
  CLOSE cur;
END$$
DELIMITER ;

-- Example:
CALL sp_first_scott();

