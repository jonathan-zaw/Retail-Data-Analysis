# Retail Analysis Scripts

/*
This document provides SQL scripts for analyzing retail data.
 The goal is to extract insights regarding sales, customer behavior,
 and product performance from the `retail_data` table.
*/

CREATE DATABASE retail_db; 
USE retail_db;

-- creating table
CREATE TABLE retail_data (
    Invoice VARCHAR(25),
    StockCode VARCHAR(25),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATETIME,
    Price DOUBLE,
    CustomerID INT,
    Country VARCHAR(60)
);

-- checking DATABASE 
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
SHOW DATABASES;
USE retail_db;
SHOW VARIABLES LIKE 'secure_file_priv';


SELECT * FROM retail_db.retail_data LIMIT 100 ;

-- Seperating columns into two 

/*
ALTER TABLE retail_db.retail_data
ADD COLUMN InvoiceDateOnly DATE,
ADD COLUMN InvoiceTimeOnly TIME;

UPDATE retail_db.retail_data
SET InvoiceDateOnly = DATE(InvoiceDate),
    InvoiceTimeOnly = TIME(InvoiceDate);
*/
    
SELECT InvoiceDate, InvoiceDateOnly, InvoiceTimeOnly
FROM retail_db.retail_data
LIMIT 10;

SELECT DISTINCT Country
FROM retail_data;

-- checking IF THERE IS NULL VALUE
SELECT *
FROM retail_data
WHERE Invoice IS NULL OR StockCode IS NULL OR Description IS NULL OR Quantity IS NULL OR 
		InvoiceDate IS NULL OR Price IS NULL OR CustomerID IS NULL OR Country IS NULL;

-- Total Sales by Country 
SELECT Country, ROUND(SUM(Quantity* Price),2) AS TotalSales
FROM retail_data 
WHERE Quantity > 0 
GROUP BY Country 
ORDER BY TotalSales DESC ;

-- Number of countries 
SELECT COUNT(DISTINCT Country) AS NumberOfCountries
FROM retail_data;

-- top 5 customers with the highest total spending 
SELECT CustomerID,ROUND(SUM(Quantity*Price),2) AS TotalSpent_Cus
FROM retail_data 
GROUP BY CustomerID
ORDER BY TotalSpent_Cus DESC
LIMIT 5 ;

-- Products with Negative Quantities (returns)
SELECT StockCode, Description, SUM(Quantity) AS TotalReturns
FROM retail_data
WHERE Quantity < 0
GROUP BY StockCode, Description
ORDER BY TotalReturns 
LIMIT 20 ;

-- Average order for each country / excluding negative quantities 
SELECT Country , ROUND ( AVG ( Quantity * Price ) , 2 ) AS AverageOrderValue
FROM retail_data 
WHERE Quantity > 0 
GROUP BY COUNTRY 
ORDER BY AverageOrderValue DESC ;


-- Daily Sales with Running Total
SELECT InvoiceDateOnly AS Date, ROUND(SUM(Quantity * Price), 2) AS DailySales,
       ROUND(SUM(SUM(Quantity * Price)) OVER (ORDER BY InvoiceDateOnly), 2) AS RunningTotalSales
FROM retail_data
GROUP BY InvoiceDateOnly
ORDER BY InvoiceDateOnly;


-- Daily Customer Spending by each customer
SELECT InvoiceDateOnly AS Date, CustomerID, ROUND(SUM(Quantity * Price), 2) AS TotalSpent
FROM retail_data
GROUP BY InvoiceDateOnly, CustomerID
ORDER BY Date, TotalSpent DESC;

-- Total Sales Value and Quantity Sold for Each Country Each Day
SELECT InvoiceDateOnly AS Date, Country, ROUND(SUM(Quantity * Price), 2) AS TotalSales, SUM(Quantity) AS TotalQuantity
FROM retail_data
GROUP BY InvoiceDateOnly, Country
ORDER BY Date, TotalSales DESC;

-- Peak Sales Hours
SELECT HOUR(InvoiceTimeOnly) AS Hour,ROUND(SUM(Quantity * Price), 2) AS TotalSales
FROM retail_data
GROUP BY Hour
ORDER BY TotalSales DESC
LIMIT 5; -- Top 5 peak hours





-- For Visualization 

-- the top 5 selling products based on the total quantity sold. (Barchart)   
SELECT StockCode, Description, SUM(Quantity) AS TotalQuantitySold
FROM retail_data
GROUP BY StockCode, Description
ORDER BY TotalQuantitySold DESC
LIMIT 5;


--  Peak Hour for Each Day (time series) 
WITH HourlySales AS (
    SELECT 
        DATE(InvoiceDateOnly) AS Date,
        HOUR(InvoiceTimeOnly) AS Hour,
        ROUND(SUM(Quantity * Price), 2) AS TotalSales
    FROM retail_data
    WHERE Quantity > 0
    GROUP BY Date, Hour
),
RankedSales AS (
    SELECT
        Date,
        Hour,
        TotalSales,
        RANK() OVER (PARTITION BY Date ORDER BY TotalSales DESC) AS SalesRank
    FROM HourlySales
)
SELECT
    Date,
    Hour AS PeakHour,
    TotalSales AS TotalSalesForPeakHour
FROM RankedSales
WHERE SalesRank = 1
ORDER BY Date;

-- Customer Purchase Frequency and Average Spending
SELECT 
    CustomerID,
    COUNT(DISTINCT Invoice) AS PurchaseFrequency,
    ROUND(AVG(TotalSpentPerPurchase), 2) AS AverageSpendingPerPurchase
FROM (
    SELECT 
        CustomerID,
        Invoice,
        ROUND(SUM(Quantity * Price), 2) AS TotalSpentPerPurchase
    FROM retail_data
    GROUP BY CustomerID, Invoice
) AS Purchases
GROUP BY CustomerID
ORDER BY AverageSpendingPerPurchase DESC;

/*
CREATE VIEW Top10CountriesByTotalSpending AS
SELECT Country, ROUND(SUM(TotalSpent), 2) AS TotalSpent_Country
FROM (
    SELECT Country, ROUND(SUM(Quantity * Price), 2) AS TotalSpent
    FROM retail_data
    GROUP BY CustomerID, Country
) customer_spending
GROUP BY Country
ORDER BY TotalSpent_Country DESC
LIMIT 10;
*/

-- the total spending per country and lists the top 10 countries by total spending 
SELECT * FROM Top10CountriesByTotalSpending ;





