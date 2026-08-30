$baseUrl = "http://104.215.157.203:120"

function Login-User($username, $password) {
    try {
        $body = @{ username = $username; password = $password } | ConvertTo-Json
        $res = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $body -ContentType "application/json"
        return $res
    } catch {
        Write-Host "Login failed for $username : $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Write-Host "Starting Office Location & Admin Access Flow Test on Live Server..." -ForegroundColor Cyan
$admin = Login-User "moxx_admin1" "Admin@123"
if ($admin) {
    Write-Host "Admin Login OK: $($admin.name)" -ForegroundColor Green
    $headers = @{ Authorization = "Bearer $($admin.token)" }
    $offices = Invoke-RestMethod -Uri "$baseUrl/api/admin/office-locations?all=true" -Method Get -Headers $headers
    Write-Host "Offices: $($offices.Count)" -ForegroundColor Green
}
