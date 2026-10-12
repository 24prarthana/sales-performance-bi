-- ===============================================================================
-- 01_create_database_and_schemas.sql
-- Project: Sales Performance Data Warehouse & BI (SSMS / SQL Server)
-- Description: Creates SalesPerformanceDB database, isolated schemas, and ETL audit log.
-- ===============================================================================

-- 1. Create Database if not exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'SalesPerformanceDB')
BEGIN
    CREATE DATABASE SalesPerformanceDB;
    PRINT 'Database [SalesPerformanceDB] created successfully.';
END
ELSE
BEGIN
    PRINT 'Database [SalesPerformanceDB] already exists.';
END
GO

USE SalesPerformanceDB;
GO

-- 2. Configure Database Options for Performance and Consistency
ALTER DATABASE SalesPerformanceDB SET RECOVERY SIMPLE;
ALTER DATABASE SalesPerformanceDB SET READ_COMMITTED_SNAPSHOT ON;
GO

-- 3. Create Schemas
-- stg: Raw staging tables for bulk file ingestion
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'stg')
    EXEC('CREATE SCHEMA stg AUTHORIZATION dbo;');
GO

-- dwh: Enterprise Dimensional Star Schema (Dimension & Fact tables)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dwh')
    EXEC('CREATE SCHEMA dwh AUTHORIZATION dbo;');
GO

-- etl: Pipeline logging, control procedures, and data loading routines
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'etl')
    EXEC('CREATE SCHEMA etl AUTHORIZATION dbo;');
GO

PRINT 'Schemas [stg], [dwh], and [etl] verified.';
GO

-- 4. Create Execution Audit Logging Table
IF OBJECT_ID('etl.ExecutionLog', 'U') IS NULL
BEGIN
    CREATE TABLE etl.ExecutionLog (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        ProcedureName NVARCHAR(100) NOT NULL,
        StepName NVARCHAR(100) NOT NULL,
        Status NVARCHAR(20) NOT NULL, -- 'STARTED', 'SUCCESS', 'FAILED'
        RowsAffected INT NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        ExecutionStartTime DATETIME2 DEFAULT SYSDATETIME(),
        ExecutionEndTime DATETIME2 NULL,
        DurationSeconds AS DATEDIFF(SECOND, ExecutionStartTime, ExecutionEndTime)
    );

    PRINT 'Table [etl.ExecutionLog] created successfully.';
END
GO
