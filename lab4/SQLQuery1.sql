use AdventureWorksDW2019

/*Postgres*/
SELECT *
FROM information_schema.columns
WHERE table_schema = 'dbo'
AND table_name = 'FactInternetSales'; 

/*Oracle and MySql
DESCRIBE AdventureWorksDW2019.dbo.FactInternetSales; 
*/