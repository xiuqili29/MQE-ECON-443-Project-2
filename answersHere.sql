##################################################
### Put your queries in this file and resubmit ###
##################################################

### PART 1 Cleaning Data ###
USE hw2;
# 1.) Run messydata.sql. Check if there are any duplicate columns with the same name. 
# Remove any duplicate columns using Alter Table.


# From obeservation, these three columns are the same.


SELECT concode, code, countrycode FROM dataset;

ALTER TABLE dataset
DROP COLUMN concode;
ALTER TABLE dataset
DROP COLUMN Code;
# 2.) Convert the single table into Relational Tables.
CREATE TABLE IF NOT EXISTS city AS
(SELECT DISTINCT `ID`, `name_city`, 
`CountryCode`, `language`, `IsOfficial`, 
`percentage`  FROM dataset);
CREATE TABLE IF NOT EXISTS country AS
(SELECT DISTINCT `CountryCode`, `name_country`, 
`SurfaceArea`, `IndepYear`, `population_country`,
 `LifeExpectancy`, `GNP`, `GNPOld`, `LocalName`,
 `GovernmentForm`, `HeadOfState`, `Capital`,
 `Code2` FROM dataset);
 CREATE TABLE IF NOT EXISTS area AS
(SELECT DISTINCT `Region`, `Continent` FROM dataset);

# 3.) Add unique primary keys in each table.
DROP TABLE IF exists area;
SET @rownumber = 0;
CREATE TABLE IF NOT EXISTS area AS
SELECT (@rownumber:= @rownumber + 1) AS ContinentCode, t. *
FROM
(SELECT DISTINCT `Region`, `Continent` FROM dataset) t;

DROP TABLE IF exists city;
CREATE TABLE IF NOT EXISTS city AS 
(SELECT DISTINCT d.ID AS cityID, d.name_city, d.District, d.CountryCode, 
a.ContinentCode, d.Population, d.Language, d.IsOfficial, d.Percentage
FROM 
(SELECT `ID`, `name_city`, `District`, `CountryCode`, `Population`, 
`Language`, `IsOfficial`, `Percentage`, `Continent`, `Region`
FROM dataset) d
JOIN area a
ON a.Continent = d.Continent
AND a.Region = d.Region);

DROP TABLE IF exists country;
CREATE TABLE IF NOT EXISTS country AS
(SELECT DISTINCT `CountryCode`, `name_country`, 
`SurfaceArea`, `IndepYear`, `population_country`,
 `LifeExpectancy`, `GNP`, `GNPOld`, `LocalName`,
 `GovernmentForm`, `HeadOfState`, `Capital`,
 `Code2` FROM dataset);




# 4.) Add foreign keys to each table.

# 5.) Reverse engineer a schema and create relations in the editor. Export and upload
#Foreign keys and primary keys are showed in the pdf file


### Part 2 Procedures, Views and Functions ###

# 1.) Create a procedure that, given a three didgit country code, returns the percent 
# change in GDPin the string format "3.14%". If there is a NULL value return "Not Enough Data".
# Call the function with an example.
USE `hw2`;
DROP procedure IF EXISTS `GNPcal`;

USE `hw2`;
DROP procedure IF EXISTS `hw2`.`GNPcal`;
;

DELIMITER $$
USE `hw2`$$
CREATE DEFINER=`root`@`localhost` 
PROCEDURE `GNPcal`(in Code_input Varchar(3),out result VARCHAR(250))
BEGIN

select concat(round(((t.GNP-t.GNPOld)/t.GNPOld)*100,2),'%') into result
from (select GNP, GNPOld, CountryCode FROM country) t
where t.CountryCode = Code_input;
SELECT IF(ISNULL(result) = 1, "Not Enough Data", result);
END$$

DELIMITER ;
;

DELIMITER $$
USE `hw2`$$
CREATE DEFINER=`root`@`localhost` 
PROCEDURE `GNPcaln`(in Code_input Varchar(3),out result VARCHAR(250))
BEGIN

select concat(round(((t.GNP-t.GNPOld)/t.GNPOld)*100,2),'%') into result
from (select GNP, GNPOld, CountryCode FROM country) t
where t.CountryCode = Code_input;
#SELECT IF(ISNULL(result) = 1, "Not Enough Data", result);
END$$

DELIMITER ;
;
DELIMITER $$
USE `hw2`$$
CREATE DEFINER=`root`@`localhost` 
PROCEDURE `percentGDP`(
IN code3 VARCHAR(5), OUT changeGDP VARCHAR(30))
BEGIN 
SELECT IFNULL(t.GDP0, "Not Enough Data") AS GDP1 INTO changeGDP 
FROM 
(SELECT CountryCode, CONCAT(ROUND((GNP - GNPOld)/GNPOld*100,2),"%")
AS GDP0 FROM country) t
WHERE CountryCode = code3;
END$$

DELIMITER ;
;

set @result = '0';
call hw2.GNPcal('esp', @result);
select @result;

set @changeGDP = '0';
call hw2.percentGDP('esp', @changeGDP);
select @changeGDP;

/* 2.) Create a function that uses the above procedure. 
Select a table with the associated percent change in GDP as a new column for each country code*/
USE `hw2`;
DROP function IF EXISTS `new_function`;

USE `hw2`;
DROP function IF EXISTS `hw2`.`new_function`;
;

DELIMITER $$
USE `hw2`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `new_function`(CodeInput VARCHAR(3)) RETURNS varchar(250) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
	DECLARE GDPCHANGE varchar(250);
    CALL GNPcal (CodeInput, GDPCHANGE);
    RETURN GDPCHANGE;
END$$

DELIMITER ;
;

DELIMITER $$
USE `hw2`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `new_function1`(CodeInput VARCHAR(3)) RETURNS varchar(250) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
	DECLARE GDPCHANGE varchar(250);
    CALL GNPcaln (CodeInput, GDPCHANGE);
    RETURN GDPCHANGE;
END$$

DELIMITER ;
;



SELECT CountryCode, new_function1(CountryCode) FROM country;


DELIMITER $$
USE `hw2`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `new_function2`(CodeInput VARCHAR(3)) RETURNS varchar(250) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
	DECLARE GDPCHANGE varchar(250);
    CALL percentGDP (CodeInput, GDPCHANGE);
    RETURN GDPCHANGE;
END$$

DELIMITER ;
;
SELECT CountryCode, new_function2(CountryCode) FROM country;

# 3.) Save the table from Question 2 as a view.
CREATE OR REPLACE VIEW V1 
AS
SELECT CountryCode, new_function1(CountryCode) FROM country
ORDER BY CountryCode;
SELECT * FROM V1;

CREATE OR REPLACE VIEW V2 
AS
SELECT CountryCode, new_function2(CountryCode) FROM country
ORDER BY CountryCode;
SELECT * FROM V2;
/*4.) Expanding on the view from 3, 
add another column that is the average population of the cities within a country
*/
ALTER VIEW V1
AS
SELECT 
c.CountryCode, new_function1(c.CountryCode), co.population_country/count(c.cityID)
FROM country co, city c
GROUP BY c.CountryCode
ORDER BY c.CountryCode;
SELECT * FROM V1;

ALTER VIEW V2
AS
SELECT 
c.CountryCode, new_function2(c.CountryCode), co.population_country/count(c.cityID)
FROM country co, city c
GROUP BY c.CountryCode
ORDER BY c.CountryCode;
SELECT * FROM V2;


# 5.) Full join all of your tables and return cities that that start with the first 
# letter of your first name and end with the last letter of your last name.
SELECT * FROM 
area a
RIGHT JOIN city c
ON a.continentCode = c.continentCode
	RIGHT JOIN country co
    ON c.CountryCode = co.CountryCode
WHERE name_city like 'X%I';

SELECT * FROM 
area a
RIGHT JOIN city c
ON a.continentCode = c.continentCode
	RIGHT JOIN country co
    ON c.CountryCode = co.CountryCode
		RIGHT JOIN v2
        ON c.CountryCode = v2.CountryCode
WHERE name_city like 'X%I';
