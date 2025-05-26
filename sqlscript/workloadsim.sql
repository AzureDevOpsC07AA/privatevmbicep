-- Drop indexes to force missing index recommendations
DROP INDEX IF EXISTS IX_Customer_LastName_FirstName ON SalesLT.Customer;
DROP INDEX IF EXISTS IX_SalesOrderDetail_ProductID ON SalesLT.SalesOrderDetail;

-- Query 1: Search customers by last name
SELECT CustomerID, FirstName, LastName, EmailAddress
FROM SalesLT.Customer
WHERE LastName LIKE 'S%';

-- Query 2: Join orders with customers
SELECT soh.SalesOrderID, soh.OrderDate, c.FirstName, c.LastName
FROM SalesLT.SalesOrderHeader soh
JOIN SalesLT.Customer c ON soh.CustomerID = c.CustomerID
WHERE soh.OrderDate >= '2014-01-01';

-- Query 3: Search products by name pattern
SELECT ProductID, Name, ProductNumber, ListPrice
FROM SalesLT.Product
WHERE Name LIKE 'M%';

-- Query 4: Aggregate line totals
SELECT ProductID, SUM(LineTotal) AS TotalSales
FROM SalesLT.SalesOrderDetail
GROUP BY ProductID;

-- Query 5: Force plan issues by alternating selective and broad queries
SELECT * 
FROM SalesLT.SalesOrderDetail
WHERE SalesOrderID = 71774;

SELECT * 
FROM SalesLT.SalesOrderDetail
WHERE SalesOrderID > 0;

--  Non-sargable search: function on column
SELECT CustomerID, FirstName, LastName
FROM SalesLT.Customer
WHERE LEFT(LastName, 1) = 'S';  -- Forces scan, can't use index


-- demo




-- OPTION (RECOMPILE) to mess with plan cache
SELECT * 
FROM SalesLT.SalesOrderDetail
WHERE SalesOrderID = 71774
OPTION (RECOMPILE);

--  Non-sargable search: function on column
SELECT CustomerID, FirstName, LastName
FROM SalesLT.Customer
WHERE LEFT(LastName, 1) = 'S';  -- Forces scan, can't use index

--  Wildcard at start of LIKE: prevents index usage
SELECT ProductID, Name, ProductNumber
FROM SalesLT.Product
WHERE Name LIKE '%Mountain';  -- Slow LIKE pattern

-- ISNULL on search column: kills index usage
SELECT CustomerID, FirstName, LastName
FROM SalesLT.Customer
WHERE ISNULL(EmailAddress, '') = 'someone@example.com';


-- Subquery in SELECT: runs multiple times
SELECT c.CustomerID, 
       (SELECT COUNT(*) 
        FROM SalesLT.SalesOrderHeader soh 
        WHERE soh.CustomerID = c.CustomerID)
FROM SalesLT.Customer c;

-- Unnecessary ORDER BY without covering index
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ListPrice DESC;

-- JOIN on non-indexed columns + broad WHERE
SELECT soh.SalesOrderID, c.FirstName, c.LastName
FROM SalesLT.SalesOrderHeader soh
JOIN SalesLT.Customer c ON soh.CustomerID = c.CustomerID
WHERE soh.SalesOrderID > 0;  -- Forces broad scan