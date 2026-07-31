/*
NovaITInventory - Sample and Synthetic Data
Purpose: Populate the lab inventory database without manual data entry.
The script is designed to be re-runnable without duplicating core records.
*/

USE NovaITInventory;
GO

SET NOCOUNT ON;
GO

/* 1) Departments */
MERGE dbo.Departments AS target
USING
(
    VALUES
        (N'IT',    N'Information Technology'),
        (N'HR',    N'Human Resources'),
        (N'ACC',   N'Accounting'),
        (N'SALES', N'Sales'),
        (N'PURCH', N'Purchasing')
) AS source (DepartmentCode, DepartmentName)
ON target.DepartmentCode = source.DepartmentCode
WHEN MATCHED THEN
    UPDATE SET
        DepartmentName = source.DepartmentName,
        IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (DepartmentCode, DepartmentName)
    VALUES (source.DepartmentCode, source.DepartmentName);
GO

/* 2) The five lab employees */
MERGE dbo.Employees AS target
USING
(
    SELECT
        v.EmployeeNumber,
        v.FirstName,
        v.LastName,
        v.EmailAddress,
        v.JobTitle,
        d.DepartmentID,
        v.HireDate
    FROM
    (
        VALUES
            (N'LAB001', N'Ayse',   N'Yilmaz',  N'ayse.yilmaz@novalab.test',   N'Accounting Specialist',       N'ACC',   CAST('2025-01-06' AS date)),
            (N'LAB002', N'Elif',   N'Demir',   N'elif.demir@novalab.test',    N'HR Specialist',               N'HR',    CAST('2025-02-03' AS date)),
            (N'LAB003', N'Can',    N'Aydin',   N'can.aydin@novalab.test',     N'Sales Specialist',            N'SALES', CAST('2025-03-10' AS date)),
            (N'LAB004', N'Zeynep', N'Arslan',  N'zeynep.arslan@novalab.test', N'Purchasing Specialist',       N'PURCH', CAST('2025-04-07' AS date)),
            (N'LAB005', N'Selin',  N'Yildiz',  N'selin.yildiz@novalab.test',  N'Junior System Specialist',    N'IT',    CAST('2025-05-05' AS date))
    ) AS v (EmployeeNumber, FirstName, LastName, EmailAddress, JobTitle, DepartmentCode, HireDate)
    INNER JOIN dbo.Departments AS d
        ON d.DepartmentCode = v.DepartmentCode
) AS source
ON target.EmployeeNumber = source.EmployeeNumber
WHEN MATCHED THEN
    UPDATE SET
        FirstName = source.FirstName,
        LastName = source.LastName,
        EmailAddress = source.EmailAddress,
        JobTitle = source.JobTitle,
        DepartmentID = source.DepartmentID,
        HireDate = source.HireDate,
        IsActive = 1
WHEN NOT MATCHED THEN
    INSERT
    (
        EmployeeNumber,
        FirstName,
        LastName,
        EmailAddress,
        JobTitle,
        DepartmentID,
        HireDate
    )
    VALUES
    (
        source.EmployeeNumber,
        source.FirstName,
        source.LastName,
        source.EmailAddress,
        source.JobTitle,
        source.DepartmentID,
        source.HireDate
    );
GO

/* 3) Active Directory records for the five lab employees */
MERGE dbo.ActiveDirectoryAccounts AS target
USING
(
    SELECT
        e.EmployeeID,
        LOWER(e.FirstName + N'.' + e.LastName) AS SamAccountName,
        LOWER(e.FirstName + N'.' + e.LastName + N'@novalab.test') AS UserPrincipalName,
        N'CN=' + e.FirstName + N' ' + e.LastName +
        N',OU=' +
        CASE d.DepartmentCode
            WHEN N'IT' THEN N'IT'
            WHEN N'HR' THEN N'HumanResources'
            WHEN N'ACC' THEN N'Accounting'
            WHEN N'SALES' THEN N'Sales'
            WHEN N'PURCH' THEN N'Purchasing'
        END +
        N',OU=Users,OU=NovaLab,DC=novalab,DC=test' AS DistinguishedName
    FROM dbo.Employees AS e
    INNER JOIN dbo.Departments AS d
        ON d.DepartmentID = e.DepartmentID
    WHERE e.EmployeeNumber LIKE N'LAB%'
) AS source
ON target.EmployeeID = source.EmployeeID
WHEN MATCHED THEN
    UPDATE SET
        SamAccountName = source.SamAccountName,
        UserPrincipalName = source.UserPrincipalName,
        DistinguishedName = source.DistinguishedName,
        AccountEnabled = 1
WHEN NOT MATCHED THEN
    INSERT
    (
        EmployeeID,
        SamAccountName,
        UserPrincipalName,
        DistinguishedName,
        AccountEnabled
    )
    VALUES
    (
        source.EmployeeID,
        source.SamAccountName,
        source.UserPrincipalName,
        source.DistinguishedName,
        1
    );
GO

/* 4) Lab devices */
MERGE dbo.Devices AS target
USING
(
    VALUES
        (N'DC01',     N'Server',      N'Windows Server 2025', N'192.168.100.10', N'NOVALAB-DC01',     N'NL-SRV-001', N'Active', CAST('2026-07-27' AS date)),
        (N'CLIENT01', N'Workstation', N'Windows 11 Enterprise', N'192.168.100.20', N'NOVALAB-CLIENT01', N'NL-CLI-001', N'Active', CAST('2026-07-30' AS date)),
        (N'SQL01',    N'Server',      N'Windows Server 2025', N'192.168.100.30', N'NOVALAB-SQL01',    N'NL-SRV-002', N'Active', CAST('2026-07-31' AS date))
) AS source
(
    DeviceName,
    DeviceType,
    OperatingSystem,
    IPAddress,
    SerialNumber,
    AssetTag,
    DeviceStatus,
    PurchaseDate
)
ON target.DeviceName = source.DeviceName
WHEN MATCHED THEN
    UPDATE SET
        DeviceType = source.DeviceType,
        OperatingSystem = source.OperatingSystem,
        IPAddress = source.IPAddress,
        SerialNumber = source.SerialNumber,
        AssetTag = source.AssetTag,
        DeviceStatus = source.DeviceStatus,
        PurchaseDate = source.PurchaseDate
WHEN NOT MATCHED THEN
    INSERT
    (
        DeviceName,
        DeviceType,
        OperatingSystem,
        IPAddress,
        SerialNumber,
        AssetTag,
        DeviceStatus,
        PurchaseDate
    )
    VALUES
    (
        source.DeviceName,
        source.DeviceType,
        source.OperatingSystem,
        source.IPAddress,
        source.SerialNumber,
        source.AssetTag,
        source.DeviceStatus,
        source.PurchaseDate
    );
GO

/* 5) Selin Yildiz -> CLIENT01 assignment */
IF NOT EXISTS
(
    SELECT 1
    FROM dbo.DeviceAssignments AS da
    INNER JOIN dbo.Devices AS d
        ON d.DeviceID = da.DeviceID
    WHERE d.DeviceName = N'CLIENT01'
      AND da.ReturnedDate IS NULL
)
BEGIN
    INSERT dbo.DeviceAssignments
    (
        DeviceID,
        EmployeeID,
        AssignedDate,
        Notes
    )
    SELECT
        d.DeviceID,
        e.EmployeeID,
        CAST('2026-07-30' AS date),
        N'Domain client assigned during the NovaLab project.'
    FROM dbo.Devices AS d
    CROSS JOIN dbo.Employees AS e
    WHERE d.DeviceName = N'CLIENT01'
      AND e.EmployeeNumber = N'LAB005';
END;
GO

/* 6) Generate 100 synthetic employees */
DECLARE @i INT = 1;

DECLARE @FirstNames TABLE
(
    RowID INT PRIMARY KEY,
    FirstName NVARCHAR(60) NOT NULL
);

INSERT @FirstNames (RowID, FirstName)
VALUES
    (1, N'Deniz'),
    (2, N'Ece'),
    (3, N'Kerem'),
    (4, N'Merve'),
    (5, N'Berk'),
    (6, N'Derya'),
    (7, N'Emre'),
    (8, N'Gizem'),
    (9, N'Ozan'),
    (10, N'Naz');

DECLARE @LastNames TABLE
(
    RowID INT PRIMARY KEY,
    LastName NVARCHAR(60) NOT NULL
);

INSERT @LastNames (RowID, LastName)
VALUES
    (1, N'Kaya'),
    (2, N'Sahin'),
    (3, N'Koc'),
    (4, N'Yildirim'),
    (5, N'Aksoy'),
    (6, N'Polat'),
    (7, N'Gunes'),
    (8, N'Cetinkaya'),
    (9, N'Eren'),
    (10, N'Tekin');

WHILE @i <= 100
BEGIN
    DECLARE @EmployeeNumber NVARCHAR(20) =
        N'EMP' + RIGHT(N'000' + CONVERT(NVARCHAR(3), @i), 3);

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Employees
        WHERE EmployeeNumber = @EmployeeNumber
    )
    BEGIN
        DECLARE @FirstName NVARCHAR(60);
        DECLARE @LastName NVARCHAR(60);
        DECLARE @DepartmentCode NVARCHAR(20);
        DECLARE @DepartmentID INT;
        DECLARE @JobTitle NVARCHAR(100);
        DECLARE @SamAccountName NVARCHAR(100);

        SELECT @FirstName = FirstName
        FROM @FirstNames
        WHERE RowID = ((@i - 1) % 10) + 1;

        SELECT @LastName = LastName
        FROM @LastNames
        WHERE RowID = (((@i - 1) / 10) % 10) + 1;

        SET @DepartmentCode =
            CASE (@i - 1) % 5
                WHEN 0 THEN N'IT'
                WHEN 1 THEN N'HR'
                WHEN 2 THEN N'ACC'
                WHEN 3 THEN N'SALES'
                ELSE N'PURCH'
            END;

        SET @JobTitle =
            CASE @DepartmentCode
                WHEN N'IT' THEN N'IT Support Specialist'
                WHEN N'HR' THEN N'Human Resources Specialist'
                WHEN N'ACC' THEN N'Accounting Specialist'
                WHEN N'SALES' THEN N'Sales Specialist'
                WHEN N'PURCH' THEN N'Purchasing Specialist'
            END;

        SELECT @DepartmentID = DepartmentID
        FROM dbo.Departments
        WHERE DepartmentCode = @DepartmentCode;

        SET @SamAccountName =
            N'user' + RIGHT(N'000' + CONVERT(NVARCHAR(3), @i), 3);

        INSERT dbo.Employees
        (
            EmployeeNumber,
            FirstName,
            LastName,
            EmailAddress,
            JobTitle,
            DepartmentID,
            HireDate
        )
        VALUES
        (
            @EmployeeNumber,
            @FirstName,
            @LastName,
            @SamAccountName + N'@novalab.test',
            @JobTitle,
            @DepartmentID,
            DATEADD(day, -(@i * 7), CAST(GETDATE() AS date))
        );

        DECLARE @EmployeeID INT = SCOPE_IDENTITY();

        INSERT dbo.ActiveDirectoryAccounts
        (
            EmployeeID,
            SamAccountName,
            UserPrincipalName,
            DistinguishedName,
            AccountEnabled
        )
        VALUES
        (
            @EmployeeID,
            @SamAccountName,
            @SamAccountName + N'@novalab.test',
            N'CN=' + @FirstName + N' ' + @LastName +
            N',OU=' +
            CASE @DepartmentCode
                WHEN N'IT' THEN N'IT'
                WHEN N'HR' THEN N'HumanResources'
                WHEN N'ACC' THEN N'Accounting'
                WHEN N'SALES' THEN N'Sales'
                ELSE N'Purchasing'
            END +
            N',OU=Users,OU=NovaLab,DC=novalab,DC=test',
            1
        );

        INSERT dbo.OperationLogs
        (
            EntityType,
            EntityID,
            OperationType,
            PerformedBy,
            Description
        )
        VALUES
        (
            N'Employee',
            @EmployeeID,
            N'CREATE',
            N'NOVALAB\Administrator',
            N'Synthetic employee record generated for lab testing.'
        );
    END;

    SET @i += 1;
END;
GO

/* 7) Generate 50 synthetic laptop devices */
DECLARE @DeviceNo INT = 1;

WHILE @DeviceNo <= 50
BEGIN
    DECLARE @DeviceName NVARCHAR(100) =
        N'NB-' + RIGHT(N'000' + CONVERT(NVARCHAR(3), @DeviceNo), 3);

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Devices
        WHERE DeviceName = @DeviceName
    )
    BEGIN
        INSERT dbo.Devices
        (
            DeviceName,
            DeviceType,
            OperatingSystem,
            SerialNumber,
            AssetTag,
            DeviceStatus,
            PurchaseDate
        )
        VALUES
        (
            @DeviceName,
            N'Laptop',
            N'Windows 11 Enterprise',
            N'NOVALAB-' + @DeviceName,
            N'NL-NB-' + RIGHT(N'000' + CONVERT(NVARCHAR(3), @DeviceNo), 3),
            N'Active',
            DATEADD(day, -(@DeviceNo * 12), CAST(GETDATE() AS date))
        );

        DECLARE @NewDeviceID INT = SCOPE_IDENTITY();

        INSERT dbo.OperationLogs
        (
            EntityType,
            EntityID,
            OperationType,
            PerformedBy,
            Description
        )
        VALUES
        (
            N'Device',
            @NewDeviceID,
            N'CREATE',
            N'NOVALAB\Administrator',
            N'Synthetic laptop record generated for lab testing.'
        );
    END;

    SET @DeviceNo += 1;
END;
GO

/* 8) Assign the 50 laptops to the first 50 synthetic employees */
DECLARE @AssignmentNo INT = 1;

WHILE @AssignmentNo <= 50
BEGIN
    DECLARE @AssignmentDeviceName NVARCHAR(100) =
        N'NB-' + RIGHT(N'000' + CONVERT(NVARCHAR(3), @AssignmentNo), 3);

    DECLARE @AssignmentEmployeeNumber NVARCHAR(20) =
        N'EMP' + RIGHT(N'000' + CONVERT(NVARCHAR(3), @AssignmentNo), 3);

    DECLARE @AssignmentDeviceID INT;
    DECLARE @AssignmentEmployeeID INT;

    SELECT @AssignmentDeviceID = DeviceID
    FROM dbo.Devices
    WHERE DeviceName = @AssignmentDeviceName;

    SELECT @AssignmentEmployeeID = EmployeeID
    FROM dbo.Employees
    WHERE EmployeeNumber = @AssignmentEmployeeNumber;

    IF @AssignmentDeviceID IS NOT NULL
       AND @AssignmentEmployeeID IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM dbo.DeviceAssignments
           WHERE DeviceID = @AssignmentDeviceID
             AND ReturnedDate IS NULL
       )
    BEGIN
        INSERT dbo.DeviceAssignments
        (
            DeviceID,
            EmployeeID,
            AssignedDate,
            Notes
        )
        VALUES
        (
            @AssignmentDeviceID,
            @AssignmentEmployeeID,
            DATEADD(day, -@AssignmentNo, CAST(GETDATE() AS date)),
            N'Automatically generated assignment for lab testing.'
        );

        INSERT dbo.OperationLogs
        (
            EntityType,
            EntityID,
            OperationType,
            PerformedBy,
            Description
        )
        VALUES
        (
            N'DeviceAssignment',
            SCOPE_IDENTITY(),
            N'ASSIGN',
            N'NOVALAB\Administrator',
            @AssignmentDeviceName + N' assigned to ' + @AssignmentEmployeeNumber + N'.'
        );
    END;

    SET @AssignmentNo += 1;
END;
GO

/* 9) Summary */
SELECT N'Departments' AS RecordType, COUNT(*) AS RecordCount
FROM dbo.Departments
UNION ALL
SELECT N'Employees', COUNT(*)
FROM dbo.Employees
UNION ALL
SELECT N'ActiveDirectoryAccounts', COUNT(*)
FROM dbo.ActiveDirectoryAccounts
UNION ALL
SELECT N'Devices', COUNT(*)
FROM dbo.Devices
UNION ALL
SELECT N'DeviceAssignments', COUNT(*)
FROM dbo.DeviceAssignments
UNION ALL
SELECT N'OperationLogs', COUNT(*)
FROM dbo.OperationLogs;
GO
