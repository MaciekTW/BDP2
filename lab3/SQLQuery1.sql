USE AdventureWorksDW2019;
GO

CREATE PROCEDURE Lab3
    @YearsAgo INT
AS
BEGIN
    SELECT FactCurrencyRate.*
    FROM dbo.FactCurrencyRate AS FactCurrencyRate
    INNER JOIN dbo.DimCurrency AS DimCurrency
        ON DimCurrency.CurrencyKey = DimCurrency.CurrencyKey
    WHERE
        CAST(CONVERT(VARCHAR(8), FactCurrencyRate.DateKey) AS DATE) <= DATEADD(YEAR, -@YearsAgo, GETDATE())
        AND (DimCurrency.CurrencyAlternateKey = 'GBP' OR DimCurrency.CurrencyAlternateKey = 'EUR');
END;
GO

DECLARE @YearsAgo INT
SET @YearsAgo = 6
EXEC Lab3 @YearsAgo;