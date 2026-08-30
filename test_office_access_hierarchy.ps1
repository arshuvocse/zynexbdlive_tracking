$baseUrl = "http://104.215.157.203:120"

function Login-Admin($username, $password) {
    try {
        $body = @{ username = $username; password = $password } | ConvertTo-Json
        $res = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $body -ContentType "application/json"
        return $res.token
    } catch {
        Write-Host "[-] Login failed for ${username}: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Testing Office Location & Admin Access Management (Live)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Login with SuperAdmin
$superToken = Login-Admin "moxx_admin1" "Admin@123"
if (-not $superToken) {
    Write-Host "Could not login as admin." -ForegroundColor Yellow
    exit 0
}

$headers = @{ Authorization = "Bearer $superToken" }

# 2. Test Get Office Locations
Write-Host "`n[1] Fetching Office Locations..." -ForegroundColor Green
$offices = Invoke-RestMethod -Uri "$baseUrl/api/admin/office-locations?all=true" -Method Get -Headers $headers
Write-Host "Found $($offices.Count) office location(s)." -ForegroundColor Yellow
foreach ($o in $offices) {
    Write-Host "  -> Office ID: $($o.officeLocationId), Name: $($o.name), Lat: $($o.latitude), Lng: $($o.longitude)"
}

Write-Host "`n[2] Testing Users retrieval..." -ForegroundColor Green
$users = Invoke-RestMethod -Uri "$baseUrl/api/users" -Method Get -Headers $headers
Write-Host "Total accessible users for Admin: $($users.Count)" -ForegroundColor Yellow

Write-Host "`n[3] Testing Executive Summary..." -ForegroundColor Green
$summary = Invoke-RestMethod -Uri "$baseUrl/api/admin/summary" -Method Get -Headers $headers
Write-Host "Summary -> Total: $($summary.totalUsers), Active: $($summary.activeUsers), Online: $($summary.onlineTrackingUsers)" -ForegroundColor Yellow

Write-Host "`n[+] Verification script complete." -ForegroundColor Cyan
