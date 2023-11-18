
use AdventureWorksDW2019;

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'stg_dimemp')
BEGIN
    DROP TABLE dbo.stg_dimemp;
END
CREATE TABLE dbo.stg_dimemp (
 EmployeeKey int ,
 FirstName nvarchar(50) not null,
 LastName nvarchar(50) not null,
 Title nvarchar(50),
 PRIMARY KEY(EmployeeKey)
);
INSERT INTO dbo.stg_dimemp (EmployeeKey, FirstName, LastName, Title)
SELECT EmployeeKey, FirstName, LastName, Title
FROM dbo.DimEmployee
WHERE EmployeeKey BETWEEN 270 AND 275;


IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'scd_dimemp')
BEGIN
    DROP TABLE dbo.scd_dimemp;
END
CREATE TABLE dbo.scd_dimemp (
 EmployeeKey int ,
 FirstName nvarchar(50) not null,
 LastName nvarchar(50) not null,
 Title nvarchar(50),
 StartDate datetime,
 EndDate datetime,
);