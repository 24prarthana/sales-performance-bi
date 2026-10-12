-- ===============================================================================
-- 02_staging_tables.sql
-- Project: Sales Performance Data Warehouse & BI (SSMS / SQL Server)
-- Description: Creates raw staging tables and stored procedure for bulk CSV ingestion.
-- ===============================================================================

USE SalesPerformanceDB;
GO

-- 1. Drop existing staging tables if recreating
DROP TABLE IF EXISTS stg.SalesOrders;
DROP TABLE IF EXISTS stg.SalesTargets;
DROP TABLE IF EXISTS stg.Customers;
DROP TABLE IF EXISTS stg.Products;
DROP TABLE IF EXISTS stg.SalesReps;
DROP TABLE IF EXISTS stg.Territories;
GO

-- 2. Staging: Territories
CREATE TABLE stg.Territories (
    TerritoryID NVARCHAR(50),
    Region NVARCHAR(100),
    Country NVARCHAR(100),
    SalesGroup NVARCHAR(100)
);

-- 3. Staging: Sales Reps
CREATE TABLE stg.SalesReps (
    SalesRepID NVARCHAR(50),
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    Email NVARCHAR(150),
    Title NVARCHAR(150),
    TerritoryID NVARCHAR(50),
    HireDate NVARCHAR(50),
    QuotaTargetBase NVARCHAR(50)
);

-- 4. Staging: Products
CREATE TABLE stg.Products (
    ProductID NVARCHAR(50),
    SKU NVARCHAR(50),
    ProductName NVARCHAR(200),
    Category NVARCHAR(100),
    SubCategory NVARCHAR(100),
    StandardCost NVARCHAR(50),
    ListPrice NVARCHAR(50),
    Status NVARCHAR(50)
);

-- 5. Staging: Customers
CREATE TABLE stg.Customers (
    CustomerID NVARCHAR(50),
    CustomerName NVARCHAR(200),
    CustomerType NVARCHAR(100),
    Industry NVARCHAR(100),
    City NVARCHAR(100),
    StateProvince NVARCHAR(100),
    Country NVARCHAR(100),
    TerritoryID NVARCHAR(50)
);

-- 6. Staging: Sales Targets
CREATE TABLE stg.SalesTargets (
    TargetID NVARCHAR(50),
    Year NVARCHAR(50),
    Month NVARCHAR(50),
    DateKey NVARCHAR(50),
    SalesRepID NVARCHAR(50),
    TerritoryID NVARCHAR(50),
    TargetAmount NVARCHAR(50),
    TargetUnits NVARCHAR(50)
);

-- 7. Staging: Sales Orders
CREATE TABLE stg.SalesOrders (
    OrderID NVARCHAR(50),
    OrderLineNumber NVARCHAR(50),
    OrderDate NVARCHAR(50),
    ShipDate NVARCHAR(50),
    CustomerID NVARCHAR(50),
    ProductID NVARCHAR(50),
    SalesRepID NVARCHAR(50),
    TerritoryID NVARCHAR(50),
    Channel NVARCHAR(50),
    OrderQuantity NVARCHAR(50),
    UnitPrice NVARCHAR(50),
    UnitCost NVARCHAR(50),
    DiscountAmount NVARCHAR(50),
    TaxAmount NVARCHAR(50),
    ShippingAmount NVARCHAR(50),
    OrderStatus NVARCHAR(50)
);
GO

PRINT 'Staging tables created successfully.';
GO

-- ===============================================================================
-- 8. Stored Procedure: Ingest CSV files into Staging Layer
-- ===============================================================================
CREATE OR ALTER PROCEDURE etl.sp_BulkLoadStaging
    @DataDirectory NVARCHAR(500) = N'C:\Users\HP\.gemini\antigravity\scratch\sales-performance-bi\data'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LogID INT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Rows INT;
    
    -- Ensure trailing backslash
    IF RIGHT(@DataDirectory, 1) <> '\'
        SET @DataDirectory = @DataDirectory + '\';

    INSERT INTO etl.ExecutionLog (ProcedureName, StepName, Status, ExecutionStartTime)
    VALUES ('etl.sp_BulkLoadStaging', 'Bulk Load Ingestion', 'STARTED', SYSDATETIME());
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- Truncate Staging Tables
        TRUNCATE TABLE stg.Territories;
        TRUNCATE TABLE stg.SalesReps;
        TRUNCATE TABLE stg.Products;
        TRUNCATE TABLE stg.Customers;
        TRUNCATE TABLE stg.SalesTargets;
        TRUNCATE TABLE stg.SalesOrders;

        -- 1. Territories
        SET @SQL = N'BULK INSERT stg.Territories FROM ''' + @DataDirectory + N'territories.csv'' ' +
                   N'WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @SQL;

        -- 2. Sales Reps
        SET @SQL = N'BULK INSERT stg.SalesReps FROM ''' + @DataDirectory + N'sales_reps.csv'' ' +
                   N'WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @SQL;

        -- 3. Products
        SET @SQL = N'BULK INSERT stg.Products FROM ''' + @DataDirectory + N'products.csv'' ' +
                   N'WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @SQL;

        -- 4. Customers
        SET @SQL = N'BULK INSERT stg.Customers FROM ''' + @DataDirectory + N'customers.csv'' ' +
                   N'WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @SQL;

        -- 5. Sales Targets
        SET @SQL = N'BULK INSERT stg.SalesTargets FROM ''' + @DataDirectory + N'sales_targets.csv'' ' +
                   N'WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @SQL;

        -- 6. Sales Orders
        SET @SQL = N'BULK INSERT stg.SalesOrders FROM ''' + @DataDirectory + N'sales_orders.csv'' ' +
                   N'WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0d0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @SQL;

        SELECT @Rows = COUNT(*) FROM stg.SalesOrders;

        UPDATE etl.ExecutionLog
        SET Status = 'SUCCESS',
            RowsAffected = @Rows,
            ExecutionEndTime = SYSDATETIME()
        WHERE LogID = @LogID;

        PRINT 'Bulk load complete. Staged ' + CAST(@Rows AS NVARCHAR(20)) + ' order rows.';
    END TRY
    BEGIN CATCH
        UPDATE etl.ExecutionLog
        SET Status = 'FAILED',
            ErrorMessage = ERROR_MESSAGE(),
            ExecutionEndTime = SYSDATETIME()
        WHERE LogID = @LogID;

        THROW;
    END CATCH
END;
GO
