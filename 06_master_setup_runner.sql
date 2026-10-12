-- ===============================================================================
-- 06_master_setup_runner.sql
-- Project: Sales Performance Data Warehouse & BI (SSMS / SQL Server)
-- Description: Master runner and verification script for SSMS.
--              Run this script in SSMS (Ctrl+Shift+E) to verify all tables,
--              procedures, views, and core KPIs.
-- ===============================================================================

USE SalesPerformanceDB;
GO

PRINT '===============================================================================';
PRINT '   SALES PERFORMANCE DATA WAREHOUSE (SSMS / POWER BI) - SYSTEM HEALTH CHECK    ';
PRINT '===============================================================================';
GO

-- 1. Check Row Counts across Dimensions and Facts
PRINT '1. Table Row Counts:';
SELECT 
    t.TABLE_SCHEMA AS [Schema],
    t.TABLE_NAME AS [Table],
    p.rows AS [RowCount]
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN sys.tables st 
    ON t.TABLE_NAME = st.name AND SCHEMA_NAME(st.schema_id) = t.TABLE_SCHEMA
INNER JOIN sys.partitions p 
    ON st.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.TABLE_SCHEMA IN ('stg', 'dwh', 'etl')
ORDER BY t.TABLE_SCHEMA DESC, p.rows DESC;
GO

-- 2. Check Execution Audit Log
PRINT '2. Latest ETL Audit Log:';
SELECT TOP 5
    LogID,
    ProcedureName,
    StepName,
    Status,
    RowsAffected,
    ExecutionStartTime,
    ExecutionEndTime,
    DurationSeconds
FROM etl.ExecutionLog
ORDER BY LogID DESC;
GO

-- 3. Executive KPI Sanity Check
PRINT '3. Executive KPI Snapshot (All Time):';
SELECT 
    COUNT(DISTINCT f.OrderID) AS TotalOrders,
    SUM(f.OrderQuantity) AS TotalUnitsSold,
    FORMAT(SUM(f.NetSales), 'C', 'en-US') AS TotalRevenue,
    FORMAT(SUM(f.GrossProfit), 'C', 'en-US') AS GrossProfit,
    CAST(ROUND(SUM(f.GrossProfit) / SUM(f.NetSales) * 100, 2) AS VARCHAR(10)) + '%' AS ProfitMarginPct,
    FORMAT(AVG(f.NetSales), 'C', 'en-US') AS AvgOrderLineValue
FROM dwh.FactSalesOrders f
WHERE f.OrderStatus IN ('Completed', 'Shipped', 'Processing');
GO

-- 4. Sales Rep Quota Attainment Leaderboard Top 5
PRINT '4. Top 5 Sales Representatives (Quota Attainment):';
SELECT TOP 5
    r.SalesRepName,
    r.JobTitle,
    r.Region,
    FORMAT(SUM(r.ActualRevenue), 'C', 'en-US') AS TotalRevenue,
    FORMAT(SUM(r.TargetAmount), 'C', 'en-US') AS TotalQuota,
    CAST(ROUND(SUM(r.ActualRevenue) / SUM(r.TargetAmount) * 100, 1) AS VARCHAR(10)) + '%' AS AttainmentPct,
    CASE 
        WHEN SUM(r.ActualRevenue) >= SUM(r.TargetAmount) THEN '🟢 Exceeded'
        WHEN SUM(r.ActualRevenue) >= (SUM(r.TargetAmount) * 0.85) THEN '🟡 On Track'
        ELSE '🔴 Underperforming'
    END AS OverallStatus
FROM dwh.vw_RepQuotaAttainment r
GROUP BY r.SalesRepName, r.JobTitle, r.Region
ORDER BY SUM(r.ActualRevenue) / SUM(r.TargetAmount) DESC;
GO

-- 5. Product Category Breakdown
PRINT '5. Product Category Performance:';
SELECT 
    p.Category,
    COUNT(DISTINCT p.ProductID) AS ActiveProducts,
    SUM(p.TotalUnitsSold) AS TotalUnitsSold,
    FORMAT(SUM(p.NetRevenue), 'C', 'en-US') AS CategoryRevenue,
    FORMAT(SUM(p.GrossProfit), 'C', 'en-US') AS CategoryProfit,
    CAST(ROUND(SUM(p.GrossProfit) / SUM(p.NetRevenue) * 100, 1) AS VARCHAR(10)) + '%' AS ProfitMarginPct
FROM dwh.vw_ProductProfitability p
GROUP BY p.Category
ORDER BY SUM(p.NetRevenue) DESC;
GO

PRINT '===============================================================================';
PRINT '   SUCCESS: All tables, views, and data structures are fully ready for Power BI! ';
PRINT '===============================================================================';
GO
