-- Real Estate Data Preprocessing and Analysis

-- 1. Initial Data Overview

-- Counting the total number of records
SELECT COUNT(*) AS No_records
FROM realestate;

-- Counting the total number of columns
SELECT COUNT(*) AS No_Columns
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'realestate';

-- Viewing the entire table (sample data)
SELECT TOP 100 *
FROM realestate;

-- 2. Cleaning and Transforming Data

-- Checking unique records of Non_Use_Code
SELECT DISTINCT Non_Use_Code
FROM realestate;

-- Correcting Date_Recorded format and finding NULLs
SELECT Date_Recorded, Format_date_records
FROM (
    SELECT Date_Recorded, CONVERT(VARCHAR, Date_Recorded, 23) AS Format_date_records
    FROM realestate
) AS sub
WHERE Format_date_records IS NULL;

-- Deleting records with NULL Date_Recorded
DELETE FROM realestate
WHERE Date_Recorded IS NULL;

-- Verifying Date_Recorded range
SELECT Date_Recorded
FROM realestate
WHERE Date_Recorded BETWEEN '1999-01-01' AND '2022-12-31'
ORDER BY Date_Recorded ASC;

-- Checking Sale_Amount and Assessed_Value
SELECT *
FROM realestate
ORDER BY Sale_Amount DESC;

-- Counting records with zero values in Assessed_Value and Sale_Amount
SELECT COUNT(*)
FROM realestate
WHERE Assessed_Value = 0 AND Sale_Amount = 0;

-- Transforming Sales_Ratio with NULL values
SELECT COUNT(*)
FROM (
    SELECT CASE 
        WHEN Sale_Amount = 0 THEN NULL
        ELSE (Assessed_Value / Sale_Amount) 
    END AS Sales_cal, Sales_Ratio
    FROM realestate
) AS sub
WHERE Sales_cal IS NULL;

-- Transforming NULL Address to "NO ADDRESS"
UPDATE realestate
SET [Address] = ISNULL([Address], 'NO ADDRESS')
WHERE [Address] IS NULL;

-- Transforming NULL Property_Type to "Other"
UPDATE realestate
SET Property_Type = ISNULL(Property_Type, 'Other')
WHERE Property_Type IS NULL;

-- Checking Town column and correcting unusual names
SELECT DISTINCT Town
FROM realestate
ORDER BY Town ASC;

-- Updating unusual Town name "***Unknown***" to "East Hampton"
UPDATE realestate
SET Town = 'East Hampton'
WHERE Town = '***Unknown***';

-- Transforming NULL Residential_Type to "Non-Residential"
UPDATE realestate
SET Residential_Type = ISNULL(Residential_Type, 'Non-Residential')
WHERE Residential_Type IS NULL;

-- Deleting records marked with incorrect sale values based on remarks
DELETE FROM realestate
WHERE OPM_Remarks LIKE '%INCORRECT Sale%' OR Assessor_Remarks LIKE '%INCORRECT Sale%';

-- Changing NULL values in several columns to more meaningful strings
UPDATE realestate
SET Assessor_Remarks = ISNULL(Assessor_Remarks, 'No Remarks'),
    OPM_Remarks = ISNULL(OPM_Remarks, 'No Management Remarks'),
    Non_Use_Code = ISNULL(Non_Use_Code, 'N/A');

-- Checking distinct Location values (mostly unused)
SELECT COUNT(DISTINCT Location)
FROM realestate;

-- Changing data types for compatibility with ANSI
ALTER TABLE realestate
ALTER COLUMN Assessor_Remarks VARCHAR(MAX) NULL;

ALTER TABLE realestate
ALTER COLUMN OPM_Remarks VARCHAR(MAX) NULL;

-- Adding and updating Sales_Value column
ALTER TABLE realestate
ADD Sales_value FLOAT;

UPDATE realestate
SET Sales_value = (Sale_Amount / Assessed_Value)
WHERE Assessed_Value != 0;

-- Viewing the entire table (sample data)
SELECT TOP 100 *
FROM realestate;

/*

-- 3. Data Analysis

*/
-- Creating a view for better optimization
CREATE VIEW sales AS
SELECT List_Year, Date_Recorded, Assessed_Value, Sale_Amount, Sales_Ratio, Town, Property_Type, Residential_Type
FROM realestate;

-- Viewing top 100 records from the sales view
SELECT TOP 100 *
FROM sales;

-- Property Valuations

-- 1. Average assessed value and sale amount for each town
-- 2. Highest sales ratio by town
-- (Sales_Ratio > 1 indicates profit)
SELECT Town, 
    AVG(Assessed_Value) AS avg_assessed_value, 
    AVG(Sale_Amount) AS avg_sale_amount, 
    MIN(Sales_Ratio) AS highest_Sales
FROM sales
GROUP BY Town
ORDER BY MIN(Sales_Ratio) ASC;

-- Distribution of property types
SELECT Town, Property_Type, COUNT(Property_Type) AS Propertytype_count
FROM sales
WHERE Property_Type IN ('Residential', 'Commercial')
GROUP BY Town, Property_Type
ORDER BY COUNT(Property_Type) DESC;

-- Residential Properties Analysis

-- 1. Average assessed value and sale amount for single-family homes in each town
-- 2. Highest average sale amount for two-family houses
-- 3. Average sales_ratio of condos in each town

WITH ce AS (
    SELECT Town, 
        AVG(Assessed_Value) AS avg_assessed_value, 
        AVG(Sale_Amount) AS avg_sale_amount, 
        AVG(Sales_Ratio) AS avg_salesratio, 
        Residential_Type
    FROM sales
    WHERE Residential_Type IN ('Single Family', 'Condo', 'Two Family')
    GROUP BY Town, Residential_Type
)
SELECT Town, avg_assessed_value, avg_sale_amount, Residential_Type 
FROM ce
ORDER BY avg_sale_amount DESC;

-- Additional Analysis

-- Average Sale Amount for Each Residential Type Over the Years
SELECT List_Year, Residential_Type, AVG(Sale_Amount) AS avg_sale_amount
FROM realestate
GROUP BY List_Year, Residential_Type
ORDER BY List_Year, Residential_Type;

-- Distribution of Residential Properties by Year and Town
SELECT List_Year, Town, Residential_Type, COUNT(*) AS property_count
FROM realestate
WHERE Residential_Type IS NOT NULL
GROUP BY List_Year, Town, Residential_Type
ORDER BY List_Year, Town, Residential_Type;

-- Top 5 Residential Properties with Highest Sale Amounts
SELECT TOP 5 Town, Address, Residential_Type, Sale_Amount
FROM realestate
WHERE Residential_Type IS NOT NULL
ORDER BY Sale_Amount DESC;

-- Profits Analysis Over the Years
SELECT List_Year, 
       MAX(Sale_Amount - Assessed_Value) AS max_profit, 
       AVG(Sale_Amount - Assessed_Value) AS avg_profit, 
       MIN(Sale_Amount - Assessed_Value) AS min_profit
FROM realestate
GROUP BY List_Year
ORDER BY List_Year;

-- Year with the Highest Profit
SELECT TOP 1 List_Year, 
       MAX(Sale_Amount - Assessed_Value) AS highest_profit
FROM realestate
GROUP BY List_Year
ORDER BY highest_profit DESC;

-- Sale Value vs Assessed Value
SELECT List_Year, 
       AVG(Sale_Amount) AS avg_sale_value, 
       AVG(Assessed_Value) AS avg_assessed_value
FROM realestate
GROUP BY List_Year
ORDER BY List_Year;

-- Comparing Sale Value and Assessed Value for each Property Type
SELECT Property_Type, 
       AVG(Sale_Amount) AS avg_sale_value, 
       AVG(Assessed_Value) AS avg_assessed_value
FROM realestate
GROUP BY Property_Type
ORDER BY Property_Type;
