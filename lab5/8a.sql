SELECT 
    CAST(OrderDate AS DATE) AS OrderDay, 
    COUNT(*) AS OrdersCount
FROM 
    AdventureWorksDW2019.dbo.FactInternetSales
GROUP BY 
    CAST(OrderDate AS DATE)
HAVING 
    COUNT(*) < 100
ORDER BY 
    OrdersCount DESC;
