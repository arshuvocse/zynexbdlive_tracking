param(
    [string]$connStr = "Server=localhost,1433;Database=LiveTrackingDB;User Id=sa;Password=sa1234;TrustServerCertificate=True;",
    [string]$sqlFile = "LiveTrackingSystem/Database/CreateShiftsTable.sql"
)

try {
    $rawSql = Get-Content -Path $sqlFile -Raw
    $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
    $conn.Open()
    Write-Output "Connected to Database."

    $batches = $rawSql -split "(?m)^\s*GO\s*$"
    foreach ($b in $batches) {
        $trimmed = $b.Trim()
        if (![string]::IsNullOrWhiteSpace($trimmed)) {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = $trimmed
            $cmd.ExecuteNonQuery() | Out-Null
        }
    }
    $conn.Close()
    Write-Output "SUCCESS: Shifts migration executed successfully!"
} catch {
    Write-Error "Migration error: $_"
}
