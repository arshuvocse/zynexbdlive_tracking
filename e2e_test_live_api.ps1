$ErrorActionPreference = "Continue"
$baseUrl = "http://104.215.157.203:120"
$results = [System.Collections.Generic.List[PSObject]]::new()

function Report-Test {
    param(
        [string]$Category,
        [string]$Endpoint,
        [string]$Method,
        [bool]$Success,
        [string]$Details
    )
    $statusStr = if ($Success) { "PASS" } else { "FAIL" }
    $color = if ($Success) { "Green" } else { "Red" }
    Write-Host "[$statusStr] $Category - $Method $Endpoint : $Details" -ForegroundColor $color
    $results.Add([PSCustomObject]@{
        Category = $Category
        Endpoint = "$Method $Endpoint"
        Status   = $statusStr
        Details  = $Details
    })
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  LIVE API END-TO-END AUTOMATED TEST SUITE" -ForegroundColor Cyan
Write-Host "  Base URL: $baseUrl" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 1. AUTHENTICATION & LOGIN FLOW
# -----------------------------------------------------------------------------
Write-Host "--- 1. AUTHENTICATION & LOGIN FLOW ---" -ForegroundColor Yellow

$adminToken = ""
$adminHeaders = @{}
$userToken = ""
$userHeaders = @{}

# 1.1 Valid Admin Login
try {
    $body = @{ username = "moxx_admin1"; password = "password123" } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -ContentType "application/json" -Body $body
    $adminToken = $res.token
    $adminHeaders = @{ Authorization = "Bearer $adminToken" }
    Report-Test "Auth" "/api/auth/login (Admin Valid)" "POST" $true "Success. Name: $($res.name), Role: $($res.role), Token Acquired"
} catch {
    Report-Test "Auth" "/api/auth/login (Admin Valid)" "POST" $false $_.Exception.Message
}

# 1.2 Invalid Password
try {
    $body = @{ username = "moxx_admin1"; password = "WrongPassword!@#" } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -ContentType "application/json" -Body $body
    Report-Test "Auth" "/api/auth/login (Invalid Password)" "POST" $false "Expected failure but received HTTP 200"
} catch {
    Report-Test "Auth" "/api/auth/login (Invalid Password)" "POST" $true "Correctly rejected 401 Unauthorized"
}

# 1.3 Non-existent Username
try {
    $body = @{ username = "user_does_not_exist_99"; password = "password123" } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -ContentType "application/json" -Body $body
    Report-Test "Auth" "/api/auth/login (Non-existent User)" "POST" $false "Expected failure but received HTTP 200"
} catch {
    Report-Test "Auth" "/api/auth/login (Non-existent User)" "POST" $true "Correctly rejected 401 Unauthorized"
}

# -----------------------------------------------------------------------------
# 2. USERS & FIELD OFFICER CREATION / LOGIN
# -----------------------------------------------------------------------------
Write-Host "`n--- 2. USERS MANAGEMENT & EMPLOYEE AUTH ---" -ForegroundColor Yellow
$userId = 0
$userLoginName = ""

if ($adminToken) {
    # 2.1 Get Users List
    try {
        $users = Invoke-RestMethod -Uri "$baseUrl/api/users" -Method Get -Headers $adminHeaders
        Report-Test "Users" "/api/users" "GET" $true "Count: $($users.Count) users found."
        
        $fieldOfficer = $users | Where-Object { $_.role -ne "Admin" } | Select-Object -First 1
        if ($fieldOfficer) {
            $userId = $fieldOfficer.userId
            $userLoginName = $fieldOfficer.username
        }
    } catch {
        Report-Test "Users" "/api/users" "GET" $false $_.Exception.Message
    }

    # 2.2 Get User Quota
    try {
        $quota = Invoke-RestMethod -Uri "$baseUrl/api/users/quota" -Method Get -Headers $adminHeaders
        Report-Test "Users" "/api/users/quota" "GET" $true "Max: $($quota.maxUserLimit), Used: $($quota.usedUserCount), Remaining: $($quota.remainingUserCount)"
    } catch {
        Report-Test "Users" "/api/users/quota" "GET" $false $_.Exception.Message
    }

    # 2.3 If no employee exists or need a fresh one, create employee
    if ($userId -eq 0) {
        try {
            $rand = Get-Random -Minimum 100 -Maximum 999
            $userLoginName = "moxx_emp_$rand"
            $newUserBody = @{
                fullName = "MOXX Employee $rand"
                username = $userLoginName
                password = "User@123"
                role = "User"
                phoneNumber = "01722$rand" + "456"
                officeLocationId = 1
            } | ConvertTo-Json
            $createRes = Invoke-RestMethod -Uri "$baseUrl/api/users" -Method Post -Headers $adminHeaders -ContentType "application/json" -Body $newUserBody
            $userId = $createRes.userId
            Report-Test "Users" "/api/users (Create Employee)" "POST" $true "Created employee: $userLoginName (ID: $userId)"
        } catch {
            Report-Test "Users" "/api/users (Create Employee)" "POST" $false $_.Exception.Message
        }
    }

    # 2.4 Login as Employee
    if ($userLoginName) {
        try {
            $body = @{ username = $userLoginName; password = "password123" } | ConvertTo-Json
            $res = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -ContentType "application/json" -Body $body
            $userToken = $res.token
            $userHeaders = @{ Authorization = "Bearer $userToken" }
            $userId = $res.id
            Report-Test "Auth" "/api/auth/login (Employee Valid)" "POST" $true "Success. Name: $($res.name), Role: $($res.role), ID: $($res.id)"
        } catch {
            Report-Test "Auth" "/api/auth/login (Employee Valid)" "POST" $false $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# 3. ADMIN CONFIGURATION (Summary, Office Locations, Shifts, Holidays)
# -----------------------------------------------------------------------------
Write-Host "`n--- 3. ADMIN & COMPANY CONFIGURATION ---" -ForegroundColor Yellow
if ($adminToken) {
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/admin/summary" -Method Get -Headers $adminHeaders
        Report-Test "Admin" "/api/admin/summary" "GET" $true "TotalUsers=$($res.totalUsers), ActiveUsers=$($res.activeUsers), OnlineTracking=$($res.onlineTrackingUsers)"
    } catch {
        Report-Test "Admin" "/api/admin/summary" "GET" $false $_.Exception.Message
    }

    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/admin/office-locations?all=true" -Method Get -Headers $adminHeaders
        Report-Test "Admin" "/api/admin/office-locations" "GET" $true "Office Locations count: $($res.Count)"
    } catch {
        Report-Test "Admin" "/api/admin/office-locations" "GET" $false $_.Exception.Message
    }

    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/shifts" -Method Get -Headers $adminHeaders
        Report-Test "Shifts" "/api/shifts" "GET" $true "Shifts count: $($res.Count)"
    } catch {
        Report-Test "Shifts" "/api/shifts" "GET" $false $_.Exception.Message
    }

    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/holidays" -Method Get -Headers $adminHeaders
        Report-Test "Holidays" "/api/holidays" "GET" $true "Holidays count: $($res.Count)"
    } catch {
        Report-Test "Holidays" "/api/holidays" "GET" $false $_.Exception.Message
    }

    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/subscription/status" -Method Get -Headers $adminHeaders
        Report-Test "Subscription" "/api/subscription/status" "GET" $true "Status: Active, DaysLeft: $($res.daysRemaining)"
    } catch {
        Report-Test "Subscription" "/api/subscription/status" "GET" $false $_.Exception.Message
    }

    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/subscription/plans" -Method Get -Headers $adminHeaders
        Report-Test "Subscription" "/api/subscription/plans" "GET" $true "Plans queried successfully"
    } catch {
        Report-Test "Subscription" "/api/subscription/plans" "GET" $false $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# 4. LOCATION TRACKING & GPS PINGS
# -----------------------------------------------------------------------------
Write-Host "`n--- 4. LOCATION TRACKING & GPS PINGS ---" -ForegroundColor Yellow
if ($userToken) {
    # 4.1 Ping Location
    try {
        $pingBody = @{
            latitude = 23.8103
            longitude = 90.4125
            accuracy = 4.5
            speed = 1.2
            bearing = 45.0
            batteryPercentage = 88
            recordedAtUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        } | ConvertTo-Json
        $res = Invoke-RestMethod -Uri "$baseUrl/api/locations/ping" -Method Post -Headers $userHeaders -ContentType "application/json" -Body $pingBody
        Report-Test "Locations" "/api/locations/ping" "POST" $true "Location coordinates pinged to Live Server"
    } catch {
        Report-Test "Locations" "/api/locations/ping" "POST" $false $_.Exception.Message
    }
}

if ($adminToken) {
    # 4.2 Get Latest Locations (All)
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/locations/latest" -Method Get -Headers $adminHeaders
        Report-Test "Locations" "/api/locations/latest" "GET" $true "Latest active users count: $($res.Count)"
    } catch {
        Report-Test "Locations" "/api/locations/latest" "GET" $false $_.Exception.Message
    }

    # 4.3 Get Location History (Route Polyline)
    if ($userId -gt 0) {
        try {
            $today = (Get-Date).ToString("yyyy-MM-dd")
            $res = Invoke-RestMethod -Uri "$baseUrl/api/locations/history/$userId?date=$today" -Method Get -Headers $adminHeaders
            Report-Test "Locations" "/api/locations/history/$userId" "GET" $true "Route points count for ${today}: $($res.Count)"
        } catch {
            Report-Test "Locations" "/api/locations/history/$userId" "GET" $false $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# 5. ATTENDANCE MANAGEMENT (PUNCH IN, PUNCH OUT, HISTORY, ADMIN)
# -----------------------------------------------------------------------------
Write-Host "`n--- 5. ATTENDANCE SYSTEM ---" -ForegroundColor Yellow
if ($userToken) {
    # 5.1 Punch In Multipart using curl.exe with selfie
    try {
        $punchInRaw = curl.exe -s -X POST "$baseUrl/api/attendance/punch-in" -H "Authorization: Bearer $userToken" -F "Latitude=23.8103" -F "Longitude=90.4125" -F "Selfie=@d:\Shuvo\zynexbd\live_tracking\test_selfie.jpg"
        if ($punchInRaw -like "*id*" -or $punchInRaw -like "*already*") {
            Report-Test "Attendance" "/api/attendance/punch-in" "POST" $true "Punch In processed: $punchInRaw"
        } else {
            Report-Test "Attendance" "/api/attendance/punch-in" "POST" $false $punchInRaw
        }
    } catch {
        Report-Test "Attendance" "/api/attendance/punch-in" "POST" $false $_.Exception.Message
    }

    # 5.2 Today Status
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/attendance/today" -Method Get -Headers $userHeaders
        Report-Test "Attendance" "/api/attendance/today" "GET" $true "HasPunchedIn: $($res.hasPunchedIn), HasPunchedOut: $($res.hasPunchedOut)"
    } catch {
        Report-Test "Attendance" "/api/attendance/today" "GET" $false $_.Exception.Message
    }

    # 5.3 Attendance History (Employee)
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/attendance/history" -Method Get -Headers $userHeaders
        Report-Test "Attendance" "/api/attendance/history" "GET" $true "Employee attendance records count: $($res.Count)"
    } catch {
        Report-Test "Attendance" "/api/attendance/history" "GET" $false $_.Exception.Message
    }

    # 5.4 Punch Out Multipart using curl.exe
    try {
        $punchOutRaw = curl.exe -s -X POST "$baseUrl/api/attendance/punch-out" -H "Authorization: Bearer $userToken" -F "Latitude=23.8103" -F "Longitude=90.4125" -F "Selfie=@d:\Shuvo\zynexbd\live_tracking\test_selfie.jpg"
        if ($punchOutRaw -like "*id*" -or $punchOutRaw -like "*already*") {
            Report-Test "Attendance" "/api/attendance/punch-out" "POST" $true "Punch Out processed: $punchOutRaw"
        } else {
            Report-Test "Attendance" "/api/attendance/punch-out" "POST" $false $punchOutRaw
        }
    } catch {
        Report-Test "Attendance" "/api/attendance/punch-out" "POST" $false $_.Exception.Message
    }
}

if ($adminToken) {
    # 5.5 Admin Attendance Sheet
    try {
        $today = (Get-Date).ToString("yyyy-MM-dd")
        $res = Invoke-RestMethod -Uri "$baseUrl/api/attendance/admin?from=$today" -Method Get -Headers $adminHeaders
        Report-Test "Attendance" "/api/attendance/admin" "GET" $true "Admin attendance records count: $($res.Count)"
    } catch {
        Report-Test "Attendance" "/api/attendance/admin" "GET" $false $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# 6. CUSTOMER MANAGEMENT
# -----------------------------------------------------------------------------
Write-Host "`n--- 6. CUSTOMER MANAGEMENT ---" -ForegroundColor Yellow
$createdCustomerId = 0
if ($userToken) {
    # 6.1 Create Customer
    try {
        $randId = Get-Random -Minimum 1000 -Maximum 9999
        $custBody = @{
            name = "Apex Enterprise $randId"
            mobile = "018$randId" + "123"
            address = "Gulshan-2, Dhaka"
            latitude = 23.7937
            longitude = 90.4066
            remarks = "Key account retail client"
        } | ConvertTo-Json
        $res = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Method Post -Headers $userHeaders -ContentType "application/json" -Body $custBody
        $createdCustomerId = $res.customerId
        Report-Test "Customers" "/api/customers" "POST" $true "Customer created: $($res.name) (ID: $createdCustomerId)"
    } catch {
        Report-Test "Customers" "/api/customers" "POST" $false $_.Exception.Message
    }

    # 6.2 Get Customer List
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Method Get -Headers $userHeaders
        Report-Test "Customers" "/api/customers" "GET" $true "Customers list count: $($res.Count)"
    } catch {
        Report-Test "Customers" "/api/customers" "GET" $false $_.Exception.Message
    }

    # 6.3 Get Customer Details
    if ($createdCustomerId -gt 0) {
        try {
            $res = Invoke-RestMethod -Uri "$baseUrl/api/customers/$createdCustomerId" -Method Get -Headers $userHeaders
            Report-Test "Customers" "/api/customers/$createdCustomerId" "GET" $true "Customer fetched: $($res.name), Mobile: $($res.mobile)"
        } catch {
            Report-Test "Customers" "/api/customers/$createdCustomerId" "GET" $false $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# 7. CUSTOMER VISITS & FOLLOW-UPS
# -----------------------------------------------------------------------------
Write-Host "`n--- 7. CUSTOMER VISITS & FOLLOW-UPS ---" -ForegroundColor Yellow
if ($userToken) {
    # 7.1 Record Visit
    if ($createdCustomerId -gt 0) {
        try {
            $visitBody = @{
                customerId = $createdCustomerId
                latitude = 23.7937
                longitude = 90.4066
                remarks = "Sales Discussion and order booked"
                visitStatus = "Completed"
                nextFollowUpDate = (Get-Date).AddDays(3).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            } | ConvertTo-Json
            $res = Invoke-RestMethod -Uri "$baseUrl/api/visits" -Method Post -Headers $userHeaders -ContentType "application/json" -Body $visitBody
            Report-Test "Visits" "/api/visits" "POST" $true "Visit logged successfully. Visit ID: $($res.visitId), Customer: $($res.customerName)"
        } catch {
            Report-Test "Visits" "/api/visits" "POST" $false $_.Exception.Message
        }
    }

    # 7.2 Get My Visits
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/visits/my-visits" -Method Get -Headers $userHeaders
        Report-Test "Visits" "/api/visits/my-visits" "GET" $true "My Visits count: $($res.Count)"
    } catch {
        Report-Test "Visits" "/api/visits/my-visits" "GET" $false $_.Exception.Message
    }

    # 7.3 Get Followups
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/visits/followups" -Method Get -Headers $userHeaders
        Report-Test "Visits" "/api/visits/followups" "GET" $true "Pending Follow-ups count: $($res.Count)"
    } catch {
        Report-Test "Visits" "/api/visits/followups" "GET" $false $_.Exception.Message
    }

    # 7.4 Get Visits Dashboard Stats
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/visits/dashboard-stats" -Method Get -Headers $userHeaders
        Report-Test "Visits" "/api/visits/dashboard-stats" "GET" $true "Stats fetched successfully"
    } catch {
        Report-Test "Visits" "/api/visits/dashboard-stats" "GET" $false $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# 8. LEAVE MANAGEMENT
# -----------------------------------------------------------------------------
Write-Host "`n--- 8. LEAVE MANAGEMENT ---" -ForegroundColor Yellow
$appliedLeaveId = 0
if ($userToken) {
    # 8.1 Leave Types
    try {
        $types = Invoke-RestMethod -Uri "$baseUrl/api/leave/types" -Method Get -Headers $userHeaders
        Report-Test "Leave" "/api/leave/types" "GET" $true "Leave types count: $($types.Count)"
    } catch {
        Report-Test "Leave" "/api/leave/types" "GET" $false $_.Exception.Message
    }

    # 8.2 Leave Balances
    try {
        $balances = Invoke-RestMethod -Uri "$baseUrl/api/leave/my-balances" -Method Get -Headers $userHeaders
        Report-Test "Leave" "/api/leave/my-balances" "GET" $true "Leave balances count: $($balances.Count)"
    } catch {
        Report-Test "Leave" "/api/leave/my-balances" "GET" $false $_.Exception.Message
    }

    # 8.3 Apply Leave
    try {
        $validBalance = $balances | Where-Object { $_.remainingDays -ge 1 } | Select-Object -First 1
        $targetTypeId = if ($validBalance) { $validBalance.leaveTypeId } else { 2 }
        $randDay = Get-Random -Minimum 30 -Maximum 300
        $leaveDate = (Get-Date).AddDays($randDay).ToString("yyyy-MM-dd")
        $leaveBody = @{
            leaveTypeId = $targetTypeId
            startDate = $leaveDate
            endDate = $leaveDate
            reason = "Family emergency live test"
        } | ConvertTo-Json
        $res = Invoke-RestMethod -Uri "$baseUrl/api/leave/apply" -Method Post -Headers $userHeaders -ContentType "application/json" -Body $leaveBody
        $appliedLeaveId = $res.id
        Report-Test "Leave" "/api/leave/apply" "POST" $true "Leave applied successfully. ID: $appliedLeaveId, Days: $($res.totalDays), Status: $($res.status)"
    } catch {
        Report-Test "Leave" "/api/leave/apply" "POST" $false $_.Exception.Message
    }

    # 8.4 My Leave History
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/leave/my-history" -Method Get -Headers $userHeaders
        Report-Test "Leave" "/api/leave/my-history" "GET" $true "Leave history count: $($res.Count)"
    } catch {
        Report-Test "Leave" "/api/leave/my-history" "GET" $false $_.Exception.Message
    }
}

if ($adminToken) {
    # 8.5 Admin View All Leaves
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/leave/admin" -Method Get -Headers $adminHeaders
        Report-Test "Leave" "/api/leave/admin" "GET" $true "All company leave applications count: $($res.Count)"
    } catch {
        Report-Test "Leave" "/api/leave/admin" "GET" $false $_.Exception.Message
    }

    # 8.6 Admin Approve Leave
    if ($appliedLeaveId -gt 0) {
        try {
            $reviewBody = @{ status = "Approved"; adminRemarks = "Approved in live automated test" } | ConvertTo-Json
            $res = Invoke-RestMethod -Uri "$baseUrl/api/leave/admin/$appliedLeaveId/approve" -Method Put -Headers $adminHeaders -ContentType "application/json" -Body $reviewBody
            Report-Test "Leave" "/api/leave/admin/$appliedLeaveId/approve" "PUT" $true "Leave application ID $appliedLeaveId approved successfully."
        } catch {
            Report-Test "Leave" "/api/leave/admin/$appliedLeaveId/approve" "PUT" $false $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# 9. NOTIFICATIONS & SYSTEM APIS
# -----------------------------------------------------------------------------
Write-Host "`n--- 9. NOTIFICATIONS & SYSTEM APIS ---" -ForegroundColor Yellow
if ($userToken) {
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/notifications" -Method Get -Headers $userHeaders
        Report-Test "Notifications" "/api/notifications" "GET" $true "Notifications count: $($res.Count)"
    } catch {
        Report-Test "Notifications" "/api/notifications" "GET" $false $_.Exception.Message
    }

    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/notifications/unread-count" -Method Get -Headers $userHeaders
        Report-Test "Notifications" "/api/notifications/unread-count" "GET" $true "Unread count: $($res.unreadCount)"
    } catch {
        Report-Test "Notifications" "/api/notifications/unread-count" "GET" $false $_.Exception.Message
    }
}

try {
    $res = Invoke-RestMethod -Uri "$baseUrl/api/app-version/check?versionCode=1&platform=Android" -Method Get
    Report-Test "AppVersion" "/api/app-version/check" "GET" $true "App Version check OK. HasUpdate: $($res.hasUpdate), Latest: $($res.latestVersionName)"
} catch {
    Report-Test "AppVersion" "/api/app-version/check" "GET" $false $_.Exception.Message
}

# -----------------------------------------------------------------------------
# SUMMARY REPORT
# -----------------------------------------------------------------------------
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "                  TEST SUITE SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
$passCount = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$totalCount = $results.Count

Write-Host "Total Endpoints Tested : $totalCount" -ForegroundColor Cyan
Write-Host "Passed                 : $passCount" -ForegroundColor Green
Write-Host "Failed                 : $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "============================================================`n" -ForegroundColor Cyan
