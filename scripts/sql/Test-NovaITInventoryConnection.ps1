$ErrorActionPreference = "Stop"

$connectionString = @"
Server=tcp:SQL01,1433;
Database=NovaITInventory;
Integrated Security=True;
Encrypt=True;
TrustServerCertificate=True;
"@

$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString

try {
    $connection.Open()

    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT
    SYSTEM_USER AS SqlLogin,
    COUNT(*) AS EmployeeCount
FROM dbo.Employees;
"@

    $reader = $command.ExecuteReader()

    if ($reader.Read()) {
        Write-Host ""
        Write-Host "SQL bağlantısı başarılı."
        Write-Host "Kullanılan hesap: $($reader['SqlLogin'])"
        Write-Host "NovaITInventory personel sayısı: $($reader['EmployeeCount'])"
        Write-Host ""
    }

    $reader.Close()
}
catch {
    Write-Host ""
    Write-Host "SQL bağlantısı başarısız:"
    Write-Host $_.Exception.Message
    Write-Host ""
    exit 1
}
finally {
    if ($connection.State -ne [System.Data.ConnectionState]::Closed) {
        $connection.Close()
    }
}
