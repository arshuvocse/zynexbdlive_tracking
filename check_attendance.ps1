$adminLogin = @{ username = "admin"; password = "User@123" } | ConvertTo-Json
try {
    $auth = Invoke-RestMethod -Uri "http://104.215.157.203:120/api/Auth/login" -Method Post -Body $adminLogin -ContentType "application/json"
    $headers = @{ Authorization = "Bearer $($auth.token)" }
    $history = Invoke-RestMethod -Uri "http://104.215.157.203:120/api/Attendance/admin" -Method Get -Headers $headers
    Write-Host "Total attendance records: $($history.Count)"
    foreach ($h in ($history | Select-Object -First 10)) {
        Write-Host "ID: $($h.id) | User: $($h.userName) | Type: $($h.type) | Time: $($h.timestamp) | SelfieUrl: '$($h.selfieUrl)'"
        if ($h.selfieUrl) {
            $testUrl = if ($h.selfieUrl.StartsWith("http")) { $h.selfieUrl } else { "http://104.215.157.203:120" + $h.selfieUrl }
            try {
                $head = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 3
                Write-Host "   -> URL HTTP Status: $($head.StatusCode)" -ForegroundColor Green
            } catch {
                Write-Host "   -> URL HTTP Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "   -> SelfieUrl is NULL or EMPTY in database!" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
