$ErrorActionPreference = "Stop"
$baseUrl = "http://104.215.157.203:120"

Write-Host "==========================================================================" -ForegroundColor Yellow
Write-Host " LIVE TRACKING SYSTEM - API DATA INSERTION & LOADING DEMO" -ForegroundColor Yellow
Write-Host "==========================================================================" -ForegroundColor Yellow

# Step 1: Admin & User Login
Write-Host "`n[1] AUTHENTICATION (API LOGINS)" -ForegroundColor Cyan
$adminBody = @{ username = "moxx_admin1"; password = "password123" } | ConvertTo-Json
$adminAuth = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $adminBody
$adminHeaders = @{ Authorization = "Bearer $($adminAuth.token)" }
Write-Host " -> Logged in as Admin: $($adminAuth.name) (Role: $($adminAuth.role))" -ForegroundColor Green

$userBody = @{ username = "moxx_field_319"; password = "password123" } | ConvertTo-Json
$userAuth = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $userBody
$userHeaders = @{ Authorization = "Bearer $($userAuth.token)" }
Write-Host " -> Logged in as User: $($userAuth.name) (Role: $($userAuth.role))" -ForegroundColor Green

# Step 2: User Creation (INSERT) & Fetch Users (LOAD)
Write-Host "`n[2] USER MANAGEMENT (INSERT USER -> LOAD USERS)" -ForegroundColor Cyan
$randDigits = Get-Random -Minimum 1000 -Maximum 9999
$newUsername = "field_officer_$randDigits"
$createReq = @{
    username = $newUsername
    fullName = "Field Officer Test $randDigits"
    password = "password123"
    phoneNumber = "01722$randDigits" + "12"
    role = "User"
    officeLocationId = 1
} | ConvertTo-Json

$createdUser = Invoke-RestMethod -Uri "$baseUrl/api/Users" -Method Post -Headers $adminHeaders -ContentType "application/json" -Body $createReq
Write-Host " -> INSERTED New User via POST /api/Users:" -ForegroundColor Green
Write-Host "    [ID: $($createdUser.userId)] Username: $($createdUser.username), Name: $($createdUser.fullName), Role: $($createdUser.role)"

# Login as the newly created user for subsequent employee operations
$newUserLoginBody = @{ username = $newUsername; password = "password123" } | ConvertTo-Json
$newUserAuth = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $newUserLoginBody
$userHeaders = @{ Authorization = "Bearer $($newUserAuth.token)" }
Write-Host " -> Switched active User session to new user: $($newUserAuth.name) (ID: $($newUserAuth.userId))`n" -ForegroundColor Yellow

$allUsers = Invoke-RestMethod -Uri "$baseUrl/api/Users" -Method Get -Headers $adminHeaders
Write-Host " -> LOADED Users List via GET /api/Users (Total Users: $($allUsers.Count)):" -ForegroundColor Green
$allUsers | Select-Object userId, username, fullName, role, isActive | Format-Table -AutoSize

# Step 3: Customer Registration (INSERT) & Customer List (LOAD)
Write-Host "`n[3] CUSTOMER MANAGEMENT (INSERT CUSTOMER -> LOAD CUSTOMERS)" -ForegroundColor Cyan
$custRand = Get-Random -Minimum 1000 -Maximum 9999
$custName = "Apex Mart $custRand"
$custReq = @{
    name = $custName
    mobile = "01822$custRand" + "1"
    address = "House 12, Road 5, Dhanmondi, Dhaka"
    latitude = 23.7461
    longitude = 90.3742
    remarks = "VIP Wholesale Partner"
} | ConvertTo-Json

$createdCust = Invoke-RestMethod -Uri "$baseUrl/api/Customers" -Method Post -Headers $userHeaders -ContentType "application/json" -Body $custReq
Write-Host " -> INSERTED Customer via POST /api/Customers:" -ForegroundColor Green
Write-Host "    [ID: $($createdCust.customerId)] Name: $($createdCust.name), Mobile: $($createdCust.mobile), Address: $($createdCust.address)"

$allCusts = Invoke-RestMethod -Uri "$baseUrl/api/Customers" -Method Get -Headers $userHeaders
Write-Host " -> LOADED Customer List via GET /api/Customers (Total Customers: $($allCusts.Count)):" -ForegroundColor Green
$allCusts | Select-Object customerId, name, mobile, address, latitude, longitude | Select-Object -First 5 | Format-Table -AutoSize

# Step 4: Customer Visit Recording (INSERT) & Visit History (LOAD)
Write-Host "`n[4] CUSTOMER VISITS (INSERT VISIT -> LOAD VISITS & STATS)" -ForegroundColor Cyan
$visitReq = @{
    customerId = $createdCust.customerId
    latitude = 23.7461
    longitude = 90.3742
    remarks = "Met store manager Mr. Alam. Placed order for 500 units."
    visitStatus = "Completed"
    nextFollowUpDate = (Get-Date).AddDays(5).ToUniversalTime().ToString("o")
} | ConvertTo-Json

$visitRes = Invoke-RestMethod -Uri "$baseUrl/api/visits" -Method Post -Headers $userHeaders -ContentType "application/json" -Body $visitReq
Write-Host " -> INSERTED Visit via POST /api/visits:" -ForegroundColor Green
Write-Host "    [Visit ID: $($visitRes.visitId)] Customer: $($visitRes.customerName), Status: $($visitRes.visitStatus), Next Follow-up: $($visitRes.nextFollowUpDate)"

$myVisits = Invoke-RestMethod -Uri "$baseUrl/api/visits/my-visits" -Method Get -Headers $userHeaders
Write-Host " -> LOADED My Visits via GET /api/visits/my-visits:" -ForegroundColor Green
$myVisits | Select-Object visitId, customerName, visitStatus, visitDate, remarks | Select-Object -First 5 | Format-Table -AutoSize

$dashStats = Invoke-RestMethod -Uri "$baseUrl/api/visits/dashboard-stats" -Method Get -Headers $userHeaders
Write-Host " -> LOADED Dashboard Stats via GET /api/visits/dashboard-stats:" -ForegroundColor Green
Write-Host "    Attendance Status: $($dashStats.attendanceStatus) | Today Visits: $($dashStats.todayVisitsCount) | Pending Follow-ups: $($dashStats.pendingFollowUpsCount)"

# Step 5: Location Tracking Ping (INSERT) & Admin Live Map (LOAD)
Write-Host "`n[5] GPS LOCATION TRACKING (INSERT PING -> LOAD LATEST LOCATIONS)" -ForegroundColor Cyan
$pingReq = @{
    latitude = 23.8103
    longitude = 90.4125
    accuracy = 3.5
    speed = 12.4
    bearing = 180.0
    recordedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json

$null = Invoke-RestMethod -Uri "$baseUrl/api/Locations/ping" -Method Post -Headers $userHeaders -ContentType "application/json" -Body $pingReq
Write-Host " -> INSERTED Location Ping via POST /api/Locations/ping (Lat: 23.8103, Lng: 90.4125)" -ForegroundColor Green

$liveLocs = Invoke-RestMethod -Uri "$baseUrl/api/Locations/latest" -Method Get -Headers $adminHeaders
Write-Host " -> LOADED Live Tracking Locations via GET /api/Locations/latest:" -ForegroundColor Green
$liveLocs | Select-Object userId, username, fullName, latitude, longitude, speed, recordedAtUtc | Format-Table -AutoSize

# Step 6: Attendance Punch In/Out (INSERT) & Attendance Records (LOAD)
Write-Host "`n[6] ATTENDANCE SYSTEM (INSERT PUNCH IN/OUT -> LOAD HISTORY)" -ForegroundColor Cyan
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"
$bodyLines = (
    "--$boundary",
    'Content-Disposition: form-data; name="Latitude"', '', '23.8103',
    "--$boundary",
    'Content-Disposition: form-data; name="Longitude"', '', '90.4125',
    "--$boundary",
    'Content-Disposition: form-data; name="Selfie"; filename="selfie.jpg"',
    'Content-Type: image/jpeg', '', 'SELFIE_IMAGE_RAW_BYTES',
    "--$boundary--"
) -join $LF

$punchIn = Invoke-RestMethod -Uri "$baseUrl/api/Attendance/punch-in" -Method Post -Headers $userHeaders -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines
Write-Host " -> INSERTED Punch In via POST /api/Attendance/punch-in:" -ForegroundColor Green
Write-Host "    [Attendance ID: $($punchIn.id)] User: $($punchIn.userName), Type: $($punchIn.type), Status: $($punchIn.status)"

$punchOut = Invoke-RestMethod -Uri "$baseUrl/api/Attendance/punch-out" -Method Post -Headers $userHeaders -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines
Write-Host " -> INSERTED Punch Out via POST /api/Attendance/punch-out:" -ForegroundColor Green
Write-Host "    [Attendance ID: $($punchOut.id)] User: $($punchOut.userName), Type: $($punchOut.type), Status: $($punchOut.status)"

$attHistory = Invoke-RestMethod -Uri "$baseUrl/api/Attendance/history" -Method Get -Headers $userHeaders
Write-Host " -> LOADED Attendance History via GET /api/Attendance/history:" -ForegroundColor Green
$attHistory | Select-Object id, userName, type, timestampUtc, latitude, longitude, isWithinGeofence | Select-Object -First 4 | Format-Table -AutoSize

# Step 7: Leave Application (INSERT) & Approval (UPDATE -> LOAD)
Write-Host "`n[7] LEAVE MANAGEMENT (INSERT LEAVE -> APPROVE -> LOAD HISTORY)" -ForegroundColor Cyan
$randOffset = Get-Random -Minimum 40 -Maximum 300
$targetDate = (Get-Date).AddDays($randOffset).ToString("yyyy-MM-dd")
$leaveReq = @{
    leaveTypeId = 2
    startDate = $targetDate
    endDate = $targetDate
    reason = "Medical checkup and personal leave"
} | ConvertTo-Json

$leaveApp = Invoke-RestMethod -Uri "$baseUrl/api/Leave/apply" -Method Post -Headers $userHeaders -ContentType "application/json" -Body $leaveReq
Write-Host " -> INSERTED Leave Application via POST /api/Leave/apply:" -ForegroundColor Green
Write-Host "    [Leave App ID: $($leaveApp.id)] Type: $($leaveApp.leaveTypeName), Days: $($leaveApp.totalDays), Status: $($leaveApp.status)"

$approveReq = @{ comment = "Approved by Manager" } | ConvertTo-Json
$approvedLeave = Invoke-RestMethod -Uri "$baseUrl/api/Leave/admin/$($leaveApp.id)/approve" -Method Put -Headers $adminHeaders -ContentType "application/json" -Body $approveReq
Write-Host " -> UPDATED Leave Status via PUT /api/Leave/admin/$($leaveApp.id)/approve:" -ForegroundColor Green
Write-Host "    [Leave App ID: $($approvedLeave.id)] Status: $($approvedLeave.status), Comment: $($approvedLeave.reviewComment)"

$myLeaves = Invoke-RestMethod -Uri "$baseUrl/api/Leave/my-history" -Method Get -Headers $userHeaders
Write-Host " -> LOADED My Leave Applications via GET /api/Leave/my-history:" -ForegroundColor Green
$myLeaves | Select-Object id, leaveTypeName, startDate, endDate, totalDays, status, reviewComment | Select-Object -First 5 | Format-Table -AutoSize

Write-Host "`n==========================================================================" -ForegroundColor Yellow
Write-Host " ALL API DATA INSERTION & FETCH TESTS COMPLETED SUCCESSFULLY (100% PASS)" -ForegroundColor Yellow
Write-Host "==========================================================================" -ForegroundColor Yellow
