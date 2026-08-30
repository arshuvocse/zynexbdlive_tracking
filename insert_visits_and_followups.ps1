$ErrorActionPreference = "Continue"

$servers = @(
    "http://104.215.157.203:120"
)

foreach ($baseUrl in $servers) {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host " INSERTING EXTENSIVE VISITS & FOLLOW-UPS ON: $baseUrl" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    try {
        # 1. Login Admin
        $adminLogin = '{"username":"admin","password":"User@123"}'
        $adminAuth = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $adminLogin
        $adminHeaders = @{ Authorization = "Bearer $($adminAuth.token)" }
        Write-Host "[OK] Admin Logged In" -ForegroundColor Green

        # 2. Fetch Users
        $users = Invoke-RestMethod -Uri "$baseUrl/api/Users" -Method Get -Headers $adminHeaders
        $fieldOfficers = @($users | Where-Object { $_.role -ne "Admin" })

        # 3. Fetch Customers (or create some if none exist)
        $customers = Invoke-RestMethod -Uri "$baseUrl/api/Customers" -Method Get -Headers $adminHeaders
        if ($customers.Count -lt 5) {
            $newShops = @(
                @{ name = "Shikdar Electronics"; mobile = "01712345678"; address = "Gulshan Circle 2, Dhaka"; lat = 23.7937; lng = 90.4066; remarks = "Electronics Retailer" },
                @{ name = "Prime Mart Ltd"; mobile = "01812345678"; address = "Dhanmondi 27, Dhaka"; lat = 23.7533; lng = 90.3756; remarks = "Departmental Store" },
                @{ name = "New Star General Store"; mobile = "01912345678"; address = "Mirpur 1, Dhaka"; lat = 23.8000; lng = 90.3541; remarks = "Wholesale Grocery" },
                @{ name = "Padma Enterprise"; mobile = "01612345678"; address = "Motijheel commercial area, Dhaka"; lat = 23.7330; lng = 90.4172; remarks = "Stationery and Corporate" },
                @{ name = "Sonar Bangla Pharmacy"; mobile = "01512345678"; address = "Uttara Sector 3, Dhaka"; lat = 23.8687; lng = 90.3980; remarks = "Medicine & Health Care" }
            )
            foreach ($ns in $newShops) {
                $nsJson = $ns | ConvertTo-Json
                $created = Invoke-RestMethod -Uri "$baseUrl/api/Customers" -Method Post -Headers $adminHeaders -ContentType "application/json" -Body $nsJson
                Write-Host "  -> Created Customer: $($created.name)" -ForegroundColor Green
            }
            $customers = Invoke-RestMethod -Uri "$baseUrl/api/Customers" -Method Get -Headers $adminHeaders
        }

        Write-Host "Total Customers: $($customers.Count), Total Officers: $($fieldOfficers.Count)" -ForegroundColor Yellow

        $visitRemarksList = @(
            "Delivered product sample catalogue and explained bulk discount rates.",
            "Met shop owner Mr. Hasan. Received monthly stock requirement list.",
            "Collected cash payment ৳35,000 for previous delivery invoice #1042.",
            "Conducted shelf display arrangement and verified promotional banner.",
            "Order confirmed for 150 cartons of primary inventory. Delivery requested tomorrow.",
            "Discussed festival season advance booking and credit terms agreement.",
            "Follow-up visit: Shop manager confirmed next bulk order for next week."
        )

        $now = Get-Date

        # 4. Insert multiple visits & follow-ups for each officer
        for ($i = 0; $i -lt $fieldOfficers.Count; $i++) {
            $officer = $fieldOfficers[$i]
            $officerName = $officer.fullName
            $officerUser = $officer.username

            $offHeaders = $adminHeaders
            try {
                $offLoginObj = @{ username = $officer.username; password = "User@123" } | ConvertTo-Json
                $offAuth = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $offLoginObj
                $offHeaders = @{ Authorization = "Bearer $($offAuth.token)" }
            } catch {
                # Fallback to admin headers
            }

            Write-Host "`nInserting Visits for: $officerName (@$officerUser)" -ForegroundColor Magenta

            # Pick 2-3 customers for this officer
            $custIndex1 = ($i * 2) % $customers.Count
            $custIndex2 = ($i * 2 + 1) % $customers.Count
            $targetCusts = @($customers[$custIndex1], $customers[$custIndex2])

            foreach ($cust in $targetCusts) {
                # Visit 1: Completed Visit with an upcoming follow-up
                $rem1 = $visitRemarksList[$i % $visitRemarksList.Count]
                $fupDate1 = $now.AddDays(3 + ($i % 5)).ToUniversalTime().ToString("o")

                $vReq1 = @{
                    customerId = $cust.customerId
                    latitude = if ($cust.latitude) { $cust.latitude } else { 23.7500 }
                    longitude = if ($cust.longitude) { $cust.longitude } else { 90.3800 }
                    remarks = $rem1
                    visitStatus = "Completed"
                    nextFollowUpDate = $fupDate1
                } | ConvertTo-Json

                try {
                    $vRes1 = Invoke-RestMethod -Uri "$baseUrl/api/visits" -Method Post -Headers $offHeaders -ContentType "application/json" -Body $vReq1
                    Write-Host "  [+] Visit: $($cust.name) -> $rem1" -ForegroundColor Green
                    Write-Host "      Scheduled Follow-up: $fupDate1" -ForegroundColor DarkCyan
                } catch {
                    Write-Host "  [!] Error: $($_.Exception.Message)" -ForegroundColor Red
                }

                # Visit 2: Follow-up visit with completed status or next month follow-up
                $rem2 = $visitRemarksList[($i + 3) % $visitRemarksList.Count]
                $fupDate2 = $now.AddDays(10 + ($i % 7)).ToUniversalTime().ToString("o")

                $vReq2 = @{
                    customerId = $cust.customerId
                    latitude = if ($cust.latitude) { $cust.latitude } else { 23.7500 }
                    longitude = if ($cust.longitude) { $cust.longitude } else { 90.3800 }
                    remarks = $rem2
                    visitStatus = "Completed"
                    nextFollowUpDate = $fupDate2
                } | ConvertTo-Json

                try {
                    $vRes2 = Invoke-RestMethod -Uri "$baseUrl/api/visits" -Method Post -Headers $offHeaders -ContentType "application/json" -Body $vReq2
                    Write-Host "  [+] Visit: $($cust.name) -> $rem2" -ForegroundColor Green
                    Write-Host "      Scheduled Follow-up: $fupDate2" -ForegroundColor DarkCyan
                } catch {
                    Write-Host "  [!] Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }

        Write-Host "`n[DONE] Successfully inserted visits and follow-ups on $baseUrl" -ForegroundColor Green

    } catch {
        $msg = $_.Exception.Message
        Write-Host "[ERROR] Failed on $baseUrl - $msg" -ForegroundColor Red
    }
}
