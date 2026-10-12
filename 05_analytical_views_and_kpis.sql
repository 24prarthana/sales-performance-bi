-- ===============================================================================
-- 05_analytical_views_and_kpis.sql
-- Project: Sales Performance Data Warehouse & BI (SSMS / SQL Server)
-- Description: Curated semantic and analytical views for Power BI reporting and SSMS queries.
-- ===============================================================================

USE SalesPerformanceDB;
GO

-- 1. View: Executive Monthly Rollup & Time Intelligence
CREATE OR ALTER VIEW dwh.vw_MonthlyExecutiveKPIs AS
WITH MonthlySales AS (
    SELECT 
        d.Year,
        d.MonthNum,
        d.YearMonth,
        d.YearMonthSort,
        d.QuarterName,
        COUNT(DISTINCT f.OrderID) AS TotalOrders,
        SUM(f.OrderQuantity) AS TotalUnitsSold,
        SUM(f.ExtendedPrice) AS GrossSales,
        SUM(f.DiscountAmount) AS TotalDiscounts,
        SUM(f.NetSales) AS NetRevenue,
        SUM(f.TotalCost) AS TotalCOGS,
        SUM(f.GrossProfit) AS GrossProfit,
        CASE WHEN SUM(f.NetSales) > 0 
             THEN ROUND(SUM(f.GrossProfit) / SUM(f.NetSales) * 100, 2) 
             ELSE 0.0 
        END AS ProfitMarginPct,
        ROUND(AVG(f.NetSales), 2) AS AvgLineValue
    FROM dwh.FactSalesOrders f
    INNER JOIN dwh.DimDate d ON f.OrderDateKey = d.DateKey
    WHERE f.OrderStatus IN (N'Completed', N'Shipped', N'Processing')
    GROUP BY d.Year, d.MonthNum, d.YearMonth, d.YearMonthSort, d.QuarterName
),
MonthlyTargets AS (
    SELECT 
        TargetYear AS Year,
        TargetMonth AS MonthNum,
        SUM(TargetAmount) AS TargetRevenue,
        SUM(TargetUnits) AS TargetUnits
    FROM dwh.FactSalesQuota
    GROUP BY TargetYear, TargetMonth
)
SELECT 
    s.Year,
    s.MonthNum,
    s.YearMonth,
    s.YearMonthSort,
    s.QuarterName,
    s.TotalOrders,
    s.TotalUnitsSold,
    s.GrossSales,
    s.TotalDiscounts,
    s.NetRevenue,
    t.TargetRevenue,
    s.NetRevenue - ISNULL(t.TargetRevenue, 0) AS TargetVarianceDollar,
    CASE WHEN ISNULL(t.TargetRevenue, 0) > 0 
         THEN ROUND(s.NetRevenue / t.TargetRevenue * 100, 2) 
         ELSE 0.0 
    END AS QuotaAttainmentPct,
    s.TotalCOGS,
    s.GrossProfit,
    s.ProfitMarginPct,
    -- Prior Year Revenue using LAG across 12 periods
    LAG(s.NetRevenue, 12) OVER (ORDER BY s.YearMonthSort) AS PriorYearNetRevenue,
    -- YoY Growth in Dollar
    s.NetRevenue - LAG(s.NetRevenue, 12) OVER (ORDER BY s.YearMonthSort) AS YoYGrowthDollar,
    -- YoY Growth Percentage
    CASE WHEN LAG(s.NetRevenue, 12) OVER (ORDER BY s.YearMonthSort) > 0
         THEN ROUND((s.NetRevenue - LAG(s.NetRevenue, 12) OVER (ORDER BY s.YearMonthSort)) 
              / LAG(s.NetRevenue, 12) OVER (ORDER BY s.YearMonthSort) * 100, 2)
         ELSE NULL
    END AS YoYGrowthPct
FROM MonthlySales s
LEFT JOIN MonthlyTargets t 
    ON s.Year = t.Year AND s.MonthNum = t.MonthNum;
GO

-- 2. View: Sales Representative Quota Attainment & Leaderboard
CREATE OR ALTER VIEW dwh.vw_RepQuotaAttainment AS
WITH RepActuals AS (
    SELECT 
        d.Year,
        d.MonthNum,
        d.YearMonth,
        f.SalesRepKey,
        COUNT(DISTINCT f.OrderID) AS OrdersCount,
        SUM(f.OrderQuantity) AS ActualUnits,
        SUM(f.NetSales) AS ActualRevenue,
        SUM(f.GrossProfit) AS ActualProfit
    FROM dwh.FactSalesOrders f
    INNER JOIN dwh.DimDate d ON f.OrderDateKey = d.DateKey
    WHERE f.OrderStatus IN (N'Completed', N'Shipped', N'Processing')
    GROUP BY d.Year, d.MonthNum, d.YearMonth, f.SalesRepKey
),
RepTargets AS (
    SELECT 
        TargetYear AS Year,
        TargetMonth AS MonthNum,
        SalesRepKey,
        SUM(TargetAmount) AS TargetAmount,
        SUM(TargetUnits) AS TargetUnits
    FROM dwh.FactSalesQuota
    GROUP BY TargetYear, TargetMonth, SalesRepKey
)
SELECT 
    t.Year,
    t.MonthNum,
    r.SalesRepID,
    r.FullName AS SalesRepName,
    r.JobTitle,
    r.Email,
    ter.Region,
    ter.Country,
    ter.SalesGroup,
    ISNULL(a.OrdersCount, 0) AS OrdersCount,
    ISNULL(a.ActualUnits, 0) AS ActualUnits,
    ISNULL(a.ActualRevenue, 0) AS ActualRevenue,
    t.TargetAmount,
    ISNULL(a.ActualRevenue, 0) - t.TargetAmount AS QuotaVarianceDollar,
    CASE WHEN t.TargetAmount > 0 
         THEN ROUND(ISNULL(a.ActualRevenue, 0) / t.TargetAmount * 100, 2) 
         ELSE 0.0 
    END AS QuotaAttainmentPct,
    ISNULL(a.ActualProfit, 0) AS ActualProfit,
    CASE WHEN ISNULL(a.ActualRevenue, 0) > 0 
         THEN ROUND(ISNULL(a.ActualProfit, 0) / a.ActualRevenue * 100, 2) 
         ELSE 0.0 
    END AS ProfitMarginPct,
    CASE 
        WHEN ISNULL(a.ActualRevenue, 0) >= t.TargetAmount THEN N'🟢 Exceeded'
        WHEN ISNULL(a.ActualRevenue, 0) >= (t.TargetAmount * 0.85) THEN N'🟡 On Track'
        ELSE N'🔴 Underperforming'
    END AS PerformanceTier
FROM RepTargets t
INNER JOIN dwh.DimSalesRep r ON t.SalesRepKey = r.SalesRepKey
INNER JOIN dwh.DimTerritory ter ON r.TerritoryKey = ter.TerritoryKey
LEFT JOIN RepActuals a 
    ON t.Year = a.Year AND t.MonthNum = a.MonthNum AND t.SalesRepKey = a.SalesRepKey;
GO

-- 3. View: Product Profitability & Catalog Analysis
CREATE OR ALTER VIEW dwh.vw_ProductProfitability AS
SELECT 
    p.ProductID,
    p.SKU,
    p.ProductName,
    p.Category,
    p.SubCategory,
    p.StandardCost,
    p.ListPrice,
    p.StandardMarginPct * 100 AS StandardMarginPct,
    COUNT(DISTINCT f.OrderID) AS TotalOrdersCount,
    SUM(f.OrderQuantity) AS TotalUnitsSold,
    SUM(f.ExtendedPrice) AS GrossRevenue,
    SUM(f.DiscountAmount) AS TotalDiscountsGiven,
    SUM(f.NetSales) AS NetRevenue,
    SUM(f.TotalCost) AS TotalCOGS,
    SUM(f.GrossProfit) AS GrossProfit,
    CASE WHEN SUM(f.NetSales) > 0 
         THEN ROUND(SUM(f.GrossProfit) / SUM(f.NetSales) * 100, 2) 
         ELSE 0.0 
    END AS RealizedProfitMarginPct,
    DENSE_RANK() OVER (ORDER BY SUM(f.NetSales) DESC) AS SalesRank,
    DENSE_RANK() OVER (ORDER BY SUM(f.GrossProfit) DESC) AS ProfitRank
FROM dwh.DimProduct p
LEFT JOIN dwh.FactSalesOrders f 
    ON p.ProductKey = f.ProductKey AND f.OrderStatus IN (N'Completed', N'Shipped', N'Processing')
GROUP BY 
    p.ProductID, p.SKU, p.ProductName, p.Category, p.SubCategory, 
    p.StandardCost, p.ListPrice, p.StandardMarginPct;
GO

-- 4. View: Territory & Regional Performance Summary
CREATE OR ALTER VIEW dwh.vw_TerritoryPerformance AS
SELECT 
    ter.TerritoryID,
    ter.Region,
    ter.Country,
    ter.SalesGroup,
    COUNT(DISTINCT r.SalesRepKey) AS AssignedSalesReps,
    COUNT(DISTINCT c.CustomerKey) AS ActiveCustomers,
    COUNT(DISTINCT f.OrderID) AS TotalOrders,
    SUM(f.OrderQuantity) AS TotalUnitsSold,
    SUM(f.NetSales) AS NetRevenue,
    SUM(f.GrossProfit) AS GrossProfit,
    CASE WHEN SUM(f.NetSales) > 0 
         THEN ROUND(SUM(f.GrossProfit) / SUM(f.NetSales) * 100, 2) 
         ELSE 0.0 
    END AS ProfitMarginPct,
    CASE WHEN COUNT(DISTINCT f.OrderID) > 0 
         THEN ROUND(SUM(f.NetSales) / COUNT(DISTINCT f.OrderID), 2) 
         ELSE 0.0 
    END AS AverageOrderValue
FROM dwh.DimTerritory ter
LEFT JOIN dwh.DimSalesRep r ON ter.TerritoryKey = r.TerritoryKey
LEFT JOIN dwh.DimCustomer c ON ter.TerritoryKey = c.TerritoryKey
LEFT JOIN dwh.FactSalesOrders f 
    ON ter.TerritoryKey = f.TerritoryKey AND f.OrderStatus IN (N'Completed', N'Shipped', N'Processing')
GROUP BY ter.TerritoryID, ter.Region, ter.Country, ter.SalesGroup;
GO

-- 5. View: Customer Portfolio & Lifetime Value
CREATE OR ALTER VIEW dwh.vw_CustomerLifetimeMetrics AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.CustomerType,
    c.Industry,
    c.City,
    c.Country,
    ter.Region,
    COUNT(DISTINCT f.OrderID) AS LifetimeOrders,
    MIN(d.FullDate) AS FirstOrderDate,
    MAX(d.FullDate) AS MostRecentOrderDate,
    DATEDIFF(DAY, MAX(d.FullDate), CAST(SYSDATETIME() AS DATE)) AS DaysSinceLastOrder,
    SUM(f.NetSales) AS LifetimeSpend,
    SUM(f.GrossProfit) AS LifetimeProfitGenerated,
    CASE WHEN COUNT(DISTINCT f.OrderID) > 0 
         THEN ROUND(SUM(f.NetSales) / COUNT(DISTINCT f.OrderID), 2) 
         ELSE 0.0 
    END AS AverageOrderSpend,
    DENSE_RANK() OVER (ORDER BY SUM(f.NetSales) DESC) AS CustomerValueRank
FROM dwh.DimCustomer c
INNER JOIN dwh.DimTerritory ter ON c.TerritoryKey = ter.TerritoryKey
LEFT JOIN dwh.FactSalesOrders f 
    ON c.CustomerKey = f.CustomerKey AND f.OrderStatus IN (N'Completed', N'Shipped', N'Processing')
LEFT JOIN dwh.DimDate d ON f.OrderDateKey = d.DateKey
GROUP BY 
    c.CustomerID, c.CustomerName, c.CustomerType, c.Industry, 
    c.City, c.Country, ter.Region;
GO

-- 6. Unified Flat Semantic View (Ready for DirectQuery or Simple SSMS Queries)
CREATE OR ALTER VIEW dwh.vw_SalesPerformanceSummary AS
SELECT 
    f.OrderLineKey,
    f.OrderID,
    f.OrderLineNumber,
    -- Date Attributes
    dOrder.FullDate AS OrderDate,
    dOrder.Year AS OrderYear,
    dOrder.QuarterName AS OrderQuarter,
    dOrder.MonthNum AS OrderMonthNum,
    dOrder.MonthName AS OrderMonthName,
    dOrder.YearMonth AS OrderYearMonth,
    dOrder.YearMonthSort AS OrderYearMonthSort,
    dShip.FullDate AS ShipDate,
    -- Customer Attributes
    c.CustomerID,
    c.CustomerName,
    c.CustomerType,
    c.Industry,
    c.City AS CustomerCity,
    c.Country AS CustomerCountry,
    -- Product Attributes
    p.ProductID,
    p.SKU,
    p.ProductName,
    p.Category AS ProductCategory,
    p.SubCategory AS ProductSubCategory,
    -- Sales Rep Attributes
    r.SalesRepID,
    r.FullName AS SalesRepName,
    r.JobTitle AS SalesRepTitle,
    -- Territory Attributes
    ter.Region,
    ter.Country AS TerritoryCountry,
    ter.SalesGroup,
    -- Order Attributes & Measures
    f.Channel,
    f.OrderStatus,
    f.OrderQuantity,
    f.UnitPrice,
    f.UnitCost,
    f.ExtendedPrice,
    f.DiscountAmount,
    f.NetSales,
    f.TotalCost,
    f.GrossProfit,
    f.ProfitMarginPct,
    f.TaxAmount,
    f.ShippingAmount,
    f.TotalDue
FROM dwh.FactSalesOrders f
INNER JOIN dwh.DimDate dOrder ON f.OrderDateKey = dOrder.DateKey
INNER JOIN dwh.DimDate dShip ON f.ShipDateKey = dShip.DateKey
INNER JOIN dwh.DimCustomer c ON f.CustomerKey = c.CustomerKey
INNER JOIN dwh.DimProduct p ON f.ProductKey = p.ProductKey
INNER JOIN dwh.DimSalesRep r ON f.SalesRepKey = r.SalesRepKey
INNER JOIN dwh.DimTerritory ter ON f.TerritoryKey = ter.TerritoryKey;
GO

PRINT 'Analytical and semantic views created in [dwh] schema successfully.';
GO
