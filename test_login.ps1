$baseUrl = "http://104.215.157.203:120"

$adminLogin = @{ username = "admin"; password = "User@123" } | ConvertTo-Json
$adminRes = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $adminLogin
Write-Host "Admin Login Token:" $adminRes.token
Write-Host "Admin Name:" $adminRes.name
Write-Host "Admin Role:" $adminRes.role

$userLogin = @{ username = "user2"; password = "User@123" } | ConvertTo-Json
$userRes = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $userLogin
Write-Host "User Login Token:" $userRes.token
Write-Host "User Name:" $userRes.name
Write-Host "User Role:" $userRes.role
