-- ===============================================================================
-- 04_etl_transform_and_load.sql
-- Project: Sales Performance Data Warehouse & BI (SSMS / SQL Server)
-- Description: Transforms staging data into Kimball star schema dimensions and facts.
-- ===============================================================================

USE SalesPerformanceDB;
GO

-- 1. Stored Procedure: Populate DimDate
CREATE OR ALTER PROCEDURE etl.sp_PopulateDimDate
    @StartDate DATE = '2024-01-01',
    @EndDate DATE = '2027-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TotalDays INT = DATEDIFF(DAY, @StartDate, @EndDate);

    ;WITH DateTally AS (
        SELECT TOP (@TotalDays + 1)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS DayOffset
        FROM sys.all_columns a
        CROSS JOIN sys.all_columns b
    ),
    Dates AS (
        SELECT DATEADD(DAY, DayOffset, @StartDate) AS d
        FROM DateTally
    )
    INSERT INTO dwh.DimDate (
        DateKey,
        FullDate,
        Year,
        Quarter,
        QuarterName,
        YearQuarter,
        MonthNum,
        MonthName,
        MonthShortName,
        YearMonth,
        YearMonthSort,
        DayOfMonth,
        DayOfWeek,
        DayOfWeekName,
        WeekOfYear,
        IsWeekend,
        FiscalYear,
        FiscalQuarter,
        FiscalPeriod
    )
    SELECT
        CAST(YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d) AS INT) AS DateKey,
        d AS FullDate,
        YEAR(d) AS Year,
        DATEPART(QUARTER, d) AS Quarter,
        N'Q' + CAST(DATEPART(QUARTER, d) AS NVARCHAR(2)) AS QuarterName,
        CAST(YEAR(d) AS NVARCHAR(4)) + N' Q' + CAST(DATEPART(QUARTER, d) AS NVARCHAR(2)) AS YearQuarter,
        MONTH(d) AS MonthNum,
        DATENAME(MONTH, d) AS MonthName,
        LEFT(DATENAME(MONTH, d), 3) AS MonthShortName,
        FORMAT(d, 'yyyy-MM') AS YearMonth,
        YEAR(d) * 100 + MONTH(d) AS YearMonthSort,
        DAY(d) AS DayOfMonth,
        DATEPART(WEEKDAY, d) AS DayOfWeek,
        DATENAME(WEEKDAY, d) AS DayOfWeekName,
        DATEPART(ISO_WEEK, d) AS WeekOfYear,
        CASE WHEN DATEPART(WEEKDAY, d) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
        CASE WHEN MONTH(d) >= 7 THEN YEAR(d) + 1 ELSE YEAR(d) END AS FiscalYear,
        CASE 
            WHEN MONTH(d) BETWEEN 7 AND 9 THEN N'FQ1'
            WHEN MONTH(d) BETWEEN 10 AND 12 THEN N'FQ2'
            WHEN MONTH(d) BETWEEN 1 AND 3 THEN N'FQ3'
            ELSE N'FQ4'
        END AS FiscalQuarter,
        CASE WHEN MONTH(d) >= 7 THEN MONTH(d) - 6 ELSE MONTH(d) + 6 END AS FiscalPeriod
    FROM Dates
    WHERE NOT EXISTS (
        SELECT 1 FROM dwh.DimDate dd 
        WHERE dd.DateKey = CAST(YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d) AS INT)
    );

    PRINT 'DimDate populated with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' days.';
END;
GO

-- 2. Stored Procedure: Full ETL Transform & Load
CREATE OR ALTER PROCEDURE etl.sp_LoadDataWarehouse
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LogID INT;
    DECLARE @RowsLoaded INT = 0;

    INSERT INTO etl.ExecutionLog (ProcedureName, StepName, Status, ExecutionStartTime)
    VALUES ('etl.sp_LoadDataWarehouse', 'ETL Full Pipeline', 'STARTED', SYSDATETIME());
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- Step 1: Ensure DimDate is populated
        IF NOT EXISTS (SELECT 1 FROM dwh.DimDate)
        BEGIN
            EXEC etl.sp_PopulateDimDate '2024-01-01', '2027-12-31';
        END

        -- Step 2: Clear target tables in reverse foreign-key order
        DELETE FROM dwh.FactSalesOrders;
        DELETE FROM dwh.FactSalesQuota;
        DELETE FROM dwh.DimCustomer;
        DELETE FROM dwh.DimSalesRep;
        DELETE FROM dwh.DimProduct;
        DELETE FROM dwh.DimTerritory;

        -- Step 3: Load DimTerritory
        INSERT INTO dwh.DimTerritory (TerritoryID, Region, Country, SalesGroup)
        SELECT 
            CAST(TRIM(TerritoryID) AS INT),
            TRIM(Region),
            TRIM(Country),
            TRIM(SalesGroup)
        FROM stg.Territories;

        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' rows into dwh.DimTerritory.';

        -- Step 4: Load DimSalesRep
        INSERT INTO dwh.DimSalesRep (SalesRepID, FirstName, LastName, FullName, Email, JobTitle, TerritoryKey, HireDate, BaseAnnualQuota)
        SELECT 
            CAST(TRIM(s.SalesRepID) AS INT),
            TRIM(s.FirstName),
            TRIM(s.LastName),
            TRIM(s.FirstName) + N' ' + TRIM(s.LastName),
            TRIM(s.Email),
            TRIM(s.Title),
            t.TerritoryKey,
            CAST(TRIM(s.HireDate) AS DATE),
            CAST(TRIM(s.QuotaTargetBase) AS DECIMAL(18,2))
        FROM stg.SalesReps s
        INNER JOIN dwh.DimTerritory t 
            ON CAST(TRIM(s.TerritoryID) AS INT) = t.TerritoryID;

        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' rows into dwh.DimSalesRep.';

        -- Step 5: Load DimProduct
        INSERT INTO dwh.DimProduct (ProductID, SKU, ProductName, Category, SubCategory, StandardCost, ListPrice, StandardMarginAmount, StandardMarginPct, Status)
        SELECT 
            CAST(TRIM(ProductID) AS INT),
            TRIM(SKU),
            TRIM(ProductName),
            TRIM(Category),
            TRIM(SubCategory),
            CAST(TRIM(StandardCost) AS DECIMAL(18,2)),
            CAST(TRIM(ListPrice) AS DECIMAL(18,2)),
            CAST(TRIM(ListPrice) AS DECIMAL(18,2)) - CAST(TRIM(StandardCost) AS DECIMAL(18,2)),
            CASE 
                WHEN CAST(TRIM(ListPrice) AS DECIMAL(18,2)) > 0 
                THEN (CAST(TRIM(ListPrice) AS DECIMAL(18,2)) - CAST(TRIM(StandardCost) AS DECIMAL(18,2))) / CAST(TRIM(ListPrice) AS DECIMAL(18,2))
                ELSE 0.0 
            END,
            TRIM(Status)
        FROM stg.Products;

        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' rows into dwh.DimProduct.';

        -- Step 6: Load DimCustomer
        INSERT INTO dwh.DimCustomer (CustomerID, CustomerName, CustomerType, Industry, City, StateProvince, Country, TerritoryKey)
        SELECT 
            CAST(TRIM(c.CustomerID) AS INT),
            TRIM(c.CustomerName),
            TRIM(c.CustomerType),
            TRIM(c.Industry),
            TRIM(c.City),
            TRIM(c.StateProvince),
            TRIM(c.Country),
            t.TerritoryKey
        FROM stg.Customers c
        INNER JOIN dwh.DimTerritory t 
            ON CAST(TRIM(c.TerritoryID) AS INT) = t.TerritoryID;

        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' rows into dwh.DimCustomer.';

        -- Step 7: Load FactSalesQuota
        INSERT INTO dwh.FactSalesQuota (TargetID, DateKey, SalesRepKey, TerritoryKey, TargetYear, TargetMonth, TargetAmount, TargetUnits)
        SELECT 
            CAST(TRIM(q.TargetID) AS INT),
            CAST(TRIM(q.DateKey) AS INT),
            r.SalesRepKey,
            t.TerritoryKey,
            CAST(TRIM(q.[Year]) AS INT),
            CAST(TRIM(q.[Month]) AS TINYINT),
            CAST(TRIM(q.TargetAmount) AS DECIMAL(18,2)),
            CAST(TRIM(q.TargetUnits) AS INT)
        FROM stg.SalesTargets q
        INNER JOIN dwh.DimSalesRep r 
            ON CAST(TRIM(q.SalesRepID) AS INT) = r.SalesRepID
        INNER JOIN dwh.DimTerritory t 
            ON CAST(TRIM(q.TerritoryID) AS INT) = t.TerritoryID;

        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' rows into dwh.FactSalesQuota.';

        -- Step 8: Load FactSalesOrders
        INSERT INTO dwh.FactSalesOrders (
            OrderID,
            OrderLineNumber,
            OrderDateKey,
            ShipDateKey,
            CustomerKey,
            ProductKey,
            SalesRepKey,
            TerritoryKey,
            Channel,
            OrderQuantity,
            UnitPrice,
            UnitCost,
            ExtendedPrice,
            TotalCost,
            DiscountAmount,
            NetSales,
            TaxAmount,
            ShippingAmount,
            TotalDue,
            GrossProfit,
            ProfitMarginPct,
            OrderStatus
        )
        SELECT 
            CAST(TRIM(o.OrderID) AS INT),
            CAST(TRIM(o.OrderLineNumber) AS INT),
            CONVERT(INT, CONVERT(VARCHAR(8), CAST(TRIM(o.OrderDate) AS DATE), 112)),
            CONVERT(INT, CONVERT(VARCHAR(8), CAST(TRIM(o.ShipDate) AS DATE), 112)),
            c.CustomerKey,
            p.ProductKey,
            r.SalesRepKey,
            t.TerritoryKey,
            TRIM(o.Channel),
            CAST(TRIM(o.OrderQuantity) AS INT),
            CAST(TRIM(o.UnitPrice) AS DECIMAL(18,2)),
            CAST(TRIM(o.UnitCost) AS DECIMAL(18,2)),
            -- ExtendedPrice = Qty * UnitPrice
            CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitPrice) AS DECIMAL(18,2)),
            -- TotalCost = Qty * UnitCost
            CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitCost) AS DECIMAL(18,2)),
            -- DiscountAmount
            CAST(TRIM(o.DiscountAmount) AS DECIMAL(18,2)),
            -- NetSales = ExtendedPrice - DiscountAmount
            (CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitPrice) AS DECIMAL(18,2))) - CAST(TRIM(o.DiscountAmount) AS DECIMAL(18,2)),
            CAST(TRIM(o.TaxAmount) AS DECIMAL(18,2)),
            CAST(TRIM(o.ShippingAmount) AS DECIMAL(18,2)),
            -- TotalDue = NetSales + Tax + Shipping
            ((CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitPrice) AS DECIMAL(18,2))) - CAST(TRIM(o.DiscountAmount) AS DECIMAL(18,2)))
                + CAST(TRIM(o.TaxAmount) AS DECIMAL(18,2)) + CAST(TRIM(o.ShippingAmount) AS DECIMAL(18,2)),
            -- GrossProfit = NetSales - TotalCost
            ((CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitPrice) AS DECIMAL(18,2))) - CAST(TRIM(o.DiscountAmount) AS DECIMAL(18,2)))
                - (CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitCost) AS DECIMAL(18,2))),
            -- ProfitMarginPct
            CASE 
                WHEN ((CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitPrice) AS DECIMAL(18,2))) - CAST(TRIM(o.DiscountAmount) AS DECIMAL(18,2))) > 0
                THEN (((CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitPrice) AS DECIMAL(18,2))) - CAST(TRIM(o.DiscountAmount) AS DECIMAL(18,2)))
                      - (CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitCost) AS DECIMAL(18,2))))
                     / ((CAST(TRIM(o.OrderQuantity) AS INT) * CAST(TRIM(o.UnitPrice) AS DECIMAL(18,2))) - CAST(TRIM(o.DiscountAmount) AS DECIMAL(18,2)))
                ELSE 0.0
            END,
            TRIM(o.OrderStatus)
        FROM stg.SalesOrders o
        INNER JOIN dwh.DimCustomer c 
            ON CAST(TRIM(o.CustomerID) AS INT) = c.CustomerID
        INNER JOIN dwh.DimProduct p 
            ON CAST(TRIM(o.ProductID) AS INT) = p.ProductID
        INNER JOIN dwh.DimSalesRep r 
            ON CAST(TRIM(o.SalesRepID) AS INT) = r.SalesRepID
        INNER JOIN dwh.DimTerritory t 
            ON CAST(TRIM(o.TerritoryID) AS INT) = t.TerritoryID;

        SET @RowsLoaded = @@ROWCOUNT;
        PRINT 'Loaded ' + CAST(@RowsLoaded AS NVARCHAR(10)) + ' rows into dwh.FactSalesOrders.';

        UPDATE etl.ExecutionLog
        SET Status = 'SUCCESS',
            RowsAffected = @RowsLoaded,
            ExecutionEndTime = SYSDATETIME()
        WHERE LogID = @LogID;

        PRINT '==================================================';
        PRINT 'Data Warehouse Load Completed Successfully!';
        PRINT '==================================================';
    END TRY
    BEGIN CATCH
        UPDATE etl.ExecutionLog
        SET Status = 'FAILED',
            ErrorMessage = ERROR_MESSAGE(),
            ExecutionEndTime = SYSDATETIME()
        WHERE LogID = @LogID;

        PRINT 'Error during ETL pipeline execution: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO
