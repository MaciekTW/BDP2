WITH RankedProducts AS (
    SELECT 
        CAST(OrderDate AS DATE) AS OrderDay,
        ProductKey,
        UnitPrice,
        ROW_NUMBER() OVER (PARTITION BY CAST(OrderDate AS DATE) ORDER BY UnitPrice DESC) AS PriceRank
    FROM 
        AdventureWorksDW2019.dbo.FactInternetSales
)
SELECT 
    OrderDay,
    ProductKey,
    UnitPrice
FROM 
    RankedProducts
WHERE 
    PriceRank <= 3
ORDER BY 
    OrderDay, 
    PriceRank;
