/*
NovaITInventory - Database Schema
Purpose: Single-PC enterprise IT lab inventory database
Compatible with: SQL Server Express
*/

IF DB_ID(N'NovaITInventory') IS NULL
BEGIN
    CREATE DATABASE NovaITInventory;
END;
GO

USE NovaITInventory;
GO

IF OBJECT_ID(N'dbo.Departments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Departments
    (
        DepartmentID   INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Departments PRIMARY KEY,
        DepartmentCode NVARCHAR(20) NOT NULL
            CONSTRAINT UQ_Departments_DepartmentCode UNIQUE,
        DepartmentName NVARCHAR(100) NOT NULL
            CONSTRAINT UQ_Departments_DepartmentName UNIQUE,
        IsActive       BIT NOT NULL
            CONSTRAINT DF_Departments_IsActive DEFAULT (1),
        CreatedAt      DATETIME2(0) NOT NULL
            CONSTRAINT DF_Departments_CreatedAt DEFAULT (SYSDATETIME())
    );
END;
GO

IF OBJECT_ID(N'dbo.Employees', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Employees
    (
        EmployeeID     INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Employees PRIMARY KEY,
        EmployeeNumber NVARCHAR(20) NOT NULL
            CONSTRAINT UQ_Employees_EmployeeNumber UNIQUE,
        FirstName      NVARCHAR(60) NOT NULL,
        LastName       NVARCHAR(60) NOT NULL,
        EmailAddress   NVARCHAR(150) NULL,
        JobTitle       NVARCHAR(100) NULL,
        DepartmentID   INT NOT NULL,
        HireDate       DATE NULL,
        IsActive       BIT NOT NULL
            CONSTRAINT DF_Employees_IsActive DEFAULT (1),
        CreatedAt      DATETIME2(0) NOT NULL
            CONSTRAINT DF_Employees_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Employees_Departments
            FOREIGN KEY (DepartmentID)
            REFERENCES dbo.Departments(DepartmentID)
    );

    CREATE INDEX IX_Employees_DepartmentID
        ON dbo.Employees(DepartmentID);
END;
GO

IF OBJECT_ID(N'dbo.ActiveDirectoryAccounts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ActiveDirectoryAccounts
    (
        ADAccountID      INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_ActiveDirectoryAccounts PRIMARY KEY,
        EmployeeID       INT NOT NULL
            CONSTRAINT UQ_ActiveDirectoryAccounts_EmployeeID UNIQUE,
        SamAccountName   NVARCHAR(100) NOT NULL
            CONSTRAINT UQ_ActiveDirectoryAccounts_SamAccountName UNIQUE,
        UserPrincipalName NVARCHAR(180) NOT NULL
            CONSTRAINT UQ_ActiveDirectoryAccounts_UserPrincipalName UNIQUE,
        DistinguishedName NVARCHAR(500) NULL,
        AccountEnabled   BIT NOT NULL
            CONSTRAINT DF_ADAccounts_AccountEnabled DEFAULT (1),
        LastPasswordReset DATETIME2(0) NULL,
        CreatedAt        DATETIME2(0) NOT NULL
            CONSTRAINT DF_ADAccounts_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_ADAccounts_Employees
            FOREIGN KEY (EmployeeID)
            REFERENCES dbo.Employees(EmployeeID)
    );
END;
GO

IF OBJECT_ID(N'dbo.Devices', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Devices
    (
        DeviceID       INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Devices PRIMARY KEY,
        DeviceName     NVARCHAR(100) NOT NULL
            CONSTRAINT UQ_Devices_DeviceName UNIQUE,
        DeviceType     NVARCHAR(40) NOT NULL,
        OperatingSystem NVARCHAR(150) NULL,
        IPAddress      VARCHAR(45) NULL,
        SerialNumber   NVARCHAR(100) NULL
            CONSTRAINT UQ_Devices_SerialNumber UNIQUE,
        AssetTag       NVARCHAR(50) NULL
            CONSTRAINT UQ_Devices_AssetTag UNIQUE,
        DeviceStatus   NVARCHAR(30) NOT NULL
            CONSTRAINT DF_Devices_DeviceStatus DEFAULT (N'Active'),
        PurchaseDate   DATE NULL,
        CreatedAt      DATETIME2(0) NOT NULL
            CONSTRAINT DF_Devices_CreatedAt DEFAULT (SYSDATETIME())
    );
END;
GO

IF OBJECT_ID(N'dbo.DeviceAssignments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DeviceAssignments
    (
        AssignmentID INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_DeviceAssignments PRIMARY KEY,
        DeviceID     INT NOT NULL,
        EmployeeID   INT NOT NULL,
        AssignedDate DATE NOT NULL
            CONSTRAINT DF_DeviceAssignments_AssignedDate DEFAULT (CONVERT(date, GETDATE())),
        ReturnedDate DATE NULL,
        Notes        NVARCHAR(500) NULL,
        CreatedAt    DATETIME2(0) NOT NULL
            CONSTRAINT DF_DeviceAssignments_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_DeviceAssignments_Devices
            FOREIGN KEY (DeviceID)
            REFERENCES dbo.Devices(DeviceID),
        CONSTRAINT FK_DeviceAssignments_Employees
            FOREIGN KEY (EmployeeID)
            REFERENCES dbo.Employees(EmployeeID),
        CONSTRAINT CK_DeviceAssignments_Dates
            CHECK (ReturnedDate IS NULL OR ReturnedDate >= AssignedDate)
    );

    CREATE INDEX IX_DeviceAssignments_EmployeeID
        ON dbo.DeviceAssignments(EmployeeID);

    CREATE UNIQUE INDEX UX_DeviceAssignments_CurrentDevice
        ON dbo.DeviceAssignments(DeviceID)
        WHERE ReturnedDate IS NULL;
END;
GO

IF OBJECT_ID(N'dbo.OperationLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OperationLogs
    (
        LogID         BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_OperationLogs PRIMARY KEY,
        EntityType    NVARCHAR(50) NOT NULL,
        EntityID      INT NULL,
        OperationType NVARCHAR(50) NOT NULL,
        PerformedBy   NVARCHAR(150) NOT NULL,
        Description   NVARCHAR(1000) NULL,
        OperationDate DATETIME2(0) NOT NULL
            CONSTRAINT DF_OperationLogs_OperationDate DEFAULT (SYSDATETIME())
    );

    CREATE INDEX IX_OperationLogs_OperationDate
        ON dbo.OperationLogs(OperationDate DESC);
END;
GO

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
ORDER BY t.name;
GO
