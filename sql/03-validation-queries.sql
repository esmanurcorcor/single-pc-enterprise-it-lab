/*
NovaITInventory - Validation Queries
Purpose: Verify that the database, relationships, and sample data are working.
*/

USE NovaITInventory;
GO

SET NOCOUNT ON;
GO

/* 1) Record counts */
SELECT N'Departments' AS RecordType, COUNT(*) AS RecordCount
FROM dbo.Departments
UNION ALL
SELECT N'Employees', COUNT(*) FROM dbo.Employees
UNION ALL
SELECT N'ActiveDirectoryAccounts', COUNT(*) FROM dbo.ActiveDirectoryAccounts
UNION ALL
SELECT N'Devices', COUNT(*) FROM dbo.Devices
UNION ALL
SELECT N'DeviceAssignments', COUNT(*) FROM dbo.DeviceAssignments
UNION ALL
SELECT N'OperationLogs', COUNT(*) FROM dbo.OperationLogs;
GO

/* 2) Employee distribution by department */
SELECT
    d.DepartmentName,
    COUNT(*) AS EmployeeCount
FROM dbo.Employees AS e
INNER JOIN dbo.Departments AS d
    ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName
ORDER BY EmployeeCount DESC, d.DepartmentName;
GO

/* 3) Active Directory account mapping */
SELECT TOP (15)
    e.EmployeeNumber,
    e.FirstName,
    e.LastName,
    d.DepartmentName,
    ad.SamAccountName,
    ad.UserPrincipalName,
    ad.AccountEnabled
FROM dbo.Employees AS e
INNER JOIN dbo.Departments AS d
    ON d.DepartmentID = e.DepartmentID
INNER JOIN dbo.ActiveDirectoryAccounts AS ad
    ON ad.EmployeeID = e.EmployeeID
ORDER BY e.EmployeeNumber;
GO

/* 4) Current device assignments */
SELECT TOP (20)
    dv.DeviceName,
    dv.DeviceType,
    dv.OperatingSystem,
    e.EmployeeNumber,
    e.FirstName + N' ' + e.LastName AS AssignedEmployee,
    d.DepartmentName,
    da.AssignedDate
FROM dbo.DeviceAssignments AS da
INNER JOIN dbo.Devices AS dv
    ON dv.DeviceID = da.DeviceID
INNER JOIN dbo.Employees AS e
    ON e.EmployeeID = da.EmployeeID
INNER JOIN dbo.Departments AS d
    ON d.DepartmentID = e.DepartmentID
WHERE da.ReturnedDate IS NULL
ORDER BY dv.DeviceName;
GO

/* 5) Verify Selin Yildiz -> CLIENT01 */
SELECT
    e.FirstName + N' ' + e.LastName AS EmployeeName,
    ad.SamAccountName,
    dv.DeviceName,
    dv.IPAddress,
    da.AssignedDate
FROM dbo.DeviceAssignments AS da
INNER JOIN dbo.Devices AS dv
    ON dv.DeviceID = da.DeviceID
INNER JOIN dbo.Employees AS e
    ON e.EmployeeID = da.EmployeeID
INNER JOIN dbo.ActiveDirectoryAccounts AS ad
    ON ad.EmployeeID = e.EmployeeID
WHERE e.EmployeeNumber = N'LAB005'
  AND dv.DeviceName = N'CLIENT01'
  AND da.ReturnedDate IS NULL;
GO

/* 6) Devices that are not currently assigned */
SELECT
    dv.DeviceName,
    dv.DeviceType,
    dv.DeviceStatus,
    dv.IPAddress
FROM dbo.Devices AS dv
LEFT JOIN dbo.DeviceAssignments AS da
    ON da.DeviceID = dv.DeviceID
   AND da.ReturnedDate IS NULL
WHERE da.AssignmentID IS NULL
ORDER BY dv.DeviceName;
GO

/* 7) Recent operation logs */
SELECT TOP (20)
    OperationDate,
    EntityType,
    EntityID,
    OperationType,
    PerformedBy,
    Description
FROM dbo.OperationLogs
ORDER BY OperationDate DESC, LogID DESC;
GO
