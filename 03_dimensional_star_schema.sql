-- ===============================================================================
-- 03_dimensional_star_schema.sql
-- Project: Sales Performance Data Warehouse & BI (SSMS / SQL Server)
-- Description: Creates the Kimball-style dimensional star schema under schema [dwh].
-- ===============================================================================

USE SalesPerformanceDB;
GO

-- 1. Drop existing tables in reverse dependency order
DROP TABLE IF EXISTS dwh.FactSalesOrders;
DROP TABLE IF EXISTS dwh.FactSalesQuota;
DROP TABLE IF EXISTS dwh.DimCustomer;
DROP TABLE IF EXISTS dwh.DimSalesRep;
DROP TABLE IF EXISTS dwh.DimProduct;
DROP TABLE IF EXISTS dwh.DimTerritory;
DROP TABLE IF EXISTS dwh.DimDate;
GO

-- 2. Dimension: Date (Comprehensive Enterprise Calendar)
CREATE TABLE dwh.DimDate (
    DateKey INT NOT NULL PRIMARY KEY,            -- e.g. 20240115
    FullDate DATE NOT NULL UNIQUE,              -- 2024-01-15
    Year INT NOT NULL,                          -- 2024
    Quarter TINYINT NOT NULL,                   -- 1, 2, 3, 4
    QuarterName NVARCHAR(10) NOT NULL,          -- Q1, Q2, Q3, Q4
    YearQuarter NVARCHAR(20) NOT NULL,          -- 2024 Q1
    MonthNum TINYINT NOT NULL,                  -- 1 to 12
    MonthName NVARCHAR(20) NOT NULL,            -- January
    MonthShortName NVARCHAR(10) NOT NULL,       -- Jan
    YearMonth NVARCHAR(20) NOT NULL,            -- 2024-01
    YearMonthSort INT NOT NULL,                 -- 202401
    DayOfMonth TINYINT NOT NULL,                -- 1 to 31
    DayOfWeek TINYINT NOT NULL,                 -- 1 (Sun) to 7 (Sat)
    DayOfWeekName NVARCHAR(20) NOT NULL,        -- Monday
    WeekOfYear TINYINT NOT NULL,                -- 1 to 53
    IsWeekend BIT NOT NULL,                     -- 1 for weekend, 0 for weekday
    FiscalYear INT NOT NULL,                    -- Fiscal year
    FiscalQuarter NVARCHAR(10) NOT NULL,        -- FQ1, FQ2
    FiscalPeriod INT NOT NULL                   -- Fiscal Period
);
GO

-- 3. Dimension: Territory
CREATE TABLE dwh.DimTerritory (
    TerritoryKey INT IDENTITY(1,1) PRIMARY KEY,
    TerritoryID INT NOT NULL UNIQUE,
    Region NVARCHAR(100) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    SalesGroup NVARCHAR(100) NOT NULL
);
GO

-- 4. Dimension: Sales Representatives
CREATE TABLE dwh.DimSalesRep (
    SalesRepKey INT IDENTITY(1,1) PRIMARY KEY,
    SalesRepID INT NOT NULL UNIQUE,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    FullName NVARCHAR(205) NOT NULL,
    Email NVARCHAR(150) NOT NULL,
    JobTitle NVARCHAR(150) NOT NULL,
    TerritoryKey INT NOT NULL,
    HireDate DATE NOT NULL,
    BaseAnnualQuota DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_DimSalesRep_DimTerritory FOREIGN KEY (TerritoryKey)
        REFERENCES dwh.DimTerritory(TerritoryKey)
);
GO

-- 5. Dimension: Product Catalog
CREATE TABLE dwh.DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL UNIQUE,
    SKU NVARCHAR(50) NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    Category NVARCHAR(100) NOT NULL,
    SubCategory NVARCHAR(100) NOT NULL,
    StandardCost DECIMAL(18,2) NOT NULL,
    ListPrice DECIMAL(18,2) NOT NULL,
    StandardMarginAmount DECIMAL(18,2) NOT NULL,
    StandardMarginPct DECIMAL(9,4) NOT NULL,
    Status NVARCHAR(50) NOT NULL
);
GO

-- 6. Dimension: Customers
CREATE TABLE dwh.DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL UNIQUE,
    CustomerName NVARCHAR(200) NOT NULL,
    CustomerType NVARCHAR(100) NOT NULL,
    Industry NVARCHAR(100) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    StateProvince NVARCHAR(100) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    TerritoryKey INT NOT NULL,
    CONSTRAINT FK_DimCustomer_DimTerritory FOREIGN KEY (TerritoryKey)
        REFERENCES dwh.DimTerritory(TerritoryKey)
);
GO

-- 7. Fact: Sales Quota & Targets (Periodic Snapshot Fact Table)
CREATE TABLE dwh.FactSalesQuota (
    QuotaKey INT IDENTITY(1,1) PRIMARY KEY,
    TargetID INT NOT NULL,
    DateKey INT NOT NULL,
    SalesRepKey INT NOT NULL,
    TerritoryKey INT NOT NULL,
    TargetYear INT NOT NULL,
    TargetMonth TINYINT NOT NULL,
    TargetAmount DECIMAL(18,2) NOT NULL,
    TargetUnits INT NOT NULL,
    CONSTRAINT FK_FactSalesQuota_DimDate FOREIGN KEY (DateKey)
        REFERENCES dwh.DimDate(DateKey),
    CONSTRAINT FK_FactSalesQuota_DimSalesRep FOREIGN KEY (SalesRepKey)
        REFERENCES dwh.DimSalesRep(SalesRepKey),
    CONSTRAINT FK_FactSalesQuota_DimTerritory FOREIGN KEY (TerritoryKey)
        REFERENCES dwh.DimTerritory(TerritoryKey)
);
GO

-- 8. Fact: Sales Orders & Line Items (Transactional Fact Table)
CREATE TABLE dwh.FactSalesOrders (
    OrderLineKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    OrderLineNumber INT NOT NULL,
    OrderDateKey INT NOT NULL,
    ShipDateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    SalesRepKey INT NOT NULL,
    TerritoryKey INT NOT NULL,
    Channel NVARCHAR(50) NOT NULL,
    OrderQuantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    ExtendedPrice DECIMAL(18,2) NOT NULL,   -- OrderQuantity * UnitPrice
    TotalCost DECIMAL(18,2) NOT NULL,       -- OrderQuantity * UnitCost
    DiscountAmount DECIMAL(18,2) NOT NULL,  -- Discount applied
    NetSales DECIMAL(18,2) NOT NULL,        -- ExtendedPrice - DiscountAmount
    TaxAmount DECIMAL(18,2) NOT NULL,
    ShippingAmount DECIMAL(18,2) NOT NULL,
    TotalDue DECIMAL(18,2) NOT NULL,        -- NetSales + TaxAmount + ShippingAmount
    GrossProfit DECIMAL(18,2) NOT NULL,     -- NetSales - TotalCost
    ProfitMarginPct DECIMAL(9,4) NOT NULL,  -- GrossProfit / NetSales
    OrderStatus NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_FactSalesOrders_OrderDate FOREIGN KEY (OrderDateKey)
        REFERENCES dwh.DimDate(DateKey),
    CONSTRAINT FK_FactSalesOrders_ShipDate FOREIGN KEY (ShipDateKey)
        REFERENCES dwh.DimDate(DateKey),
    CONSTRAINT FK_FactSalesOrders_DimCustomer FOREIGN KEY (CustomerKey)
        REFERENCES dwh.DimCustomer(CustomerKey),
    CONSTRAINT FK_FactSalesOrders_DimProduct FOREIGN KEY (ProductKey)
        REFERENCES dwh.DimProduct(ProductKey),
    CONSTRAINT FK_FactSalesOrders_DimSalesRep FOREIGN KEY (SalesRepKey)
        REFERENCES dwh.DimSalesRep(SalesRepKey),
    CONSTRAINT FK_FactSalesOrders_DimTerritory FOREIGN KEY (TerritoryKey)
        REFERENCES dwh.DimTerritory(TerritoryKey)
);
GO

-- 9. Performance Indexes for Power BI Analytical Slicing & Joins
CREATE NONCLUSTERED INDEX IX_FactSalesOrders_OrderDateKey 
    ON dwh.FactSalesOrders (OrderDateKey) 
    INCLUDE (NetSales, GrossProfit, OrderQuantity, DiscountAmount);

CREATE NONCLUSTERED INDEX IX_FactSalesOrders_SalesRepKey 
    ON dwh.FactSalesOrders (SalesRepKey) 
    INCLUDE (OrderDateKey, NetSales, GrossProfit);

CREATE NONCLUSTERED INDEX IX_FactSalesOrders_ProductKey 
    ON dwh.FactSalesOrders (ProductKey) 
    INCLUDE (OrderQuantity, NetSales, GrossProfit);

CREATE NONCLUSTERED INDEX IX_FactSalesOrders_CustomerKey 
    ON dwh.FactSalesOrders (CustomerKey) 
    INCLUDE (NetSales, GrossProfit);

CREATE NONCLUSTERED INDEX IX_FactSalesOrders_TerritoryKey 
    ON dwh.FactSalesOrders (TerritoryKey);

CREATE NONCLUSTERED INDEX IX_FactSalesQuota_Lookup 
    ON dwh.FactSalesQuota (DateKey, SalesRepKey) 
    INCLUDE (TargetAmount, TargetUnits);
GO

PRINT 'Dimensional Star Schema [dwh] tables and performance indexes created successfully.';
GO
