$ErrorActionPreference = "Continue"

$servers = @(
    "http://104.215.157.203:120"
)

foreach ($baseUrl in $servers) {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host " SEEDING REAL REPORT DATA ON: $baseUrl" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    try {
        # 1. Login Admin
        $adminLogin = '{"username":"admin","password":"User@123"}'
        $adminAuth = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $adminLogin
        $adminHeaders = @{ Authorization = "Bearer $($adminAuth.token)" }
        Write-Host "[OK] Admin Logged In: $($adminAuth.name)" -ForegroundColor Green

        # 2. Fetch Users
        $users = Invoke-RestMethod -Uri "$baseUrl/api/Users" -Method Get -Headers $adminHeaders
        $fieldOfficers = @($users | Where-Object { $_.role -ne "Admin" })

        # If less than 2 officers exist, create them
        if ($fieldOfficers.Count -lt 2) {
            $dummyOfficers = @(
                @{ username = "tanvir_sales"; fullName = "Tanvir Ahmed"; role = "User"; phoneNumber = "01711223344"; password = "User@123" },
                @{ username = "rahim_field"; fullName = "Abdur Rahim"; role = "User"; phoneNumber = "01811556677"; password = "User@123" },
                @{ username = "karim_mkt"; fullName = "Karim Hossain"; role = "User"; phoneNumber = "01911889900"; password = "User@123" }
            )
            foreach ($do in $dummyOfficers) {
                try {
                    $json = $do | ConvertTo-Json
                    $null = Invoke-RestMethod -Uri "$baseUrl/api/Users" -Method Post -Headers $adminHeaders -ContentType "application/json" -Body $json
                    Write-Host "  -> Created officer: $($do.fullName)" -ForegroundColor Green
                } catch {
                    Write-Host "  -> Officer notice: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            $users = Invoke-RestMethod -Uri "$baseUrl/api/Users" -Method Get -Headers $adminHeaders
            $fieldOfficers = @($users | Where-Object { $_.role -ne "Admin" })
        }

        Write-Host "Total Field Officers: $($fieldOfficers.Count)" -ForegroundColor Yellow

        # 3. Create Sample Customers and Visits
        $sampleShops = @(
            @{ name = "Bismillah Super Market"; mobile = "01711001122"; address = "House 14, Road 3, Dhanmondi, Dhaka"; lat = 23.7461; lng = 90.3742 },
            @{ name = "Rahman General Store"; mobile = "01811002233"; address = "Shop 12, Mirpur 10, Dhaka"; lat = 23.8069; lng = 90.3687 },
            @{ name = "Maa Enterprise and Wholesale"; mobile = "01911003344"; address = "Gulsan 1 Market, Dhaka"; lat = 23.7925; lng = 90.4078 },
            @{ name = "Al-Madina Traders"; mobile = "01611004455"; address = "Uttara Sector 7, Dhaka"; lat = 23.8759; lng = 90.3795 },
            @{ name = "Dhaka City Mart"; mobile = "01511005566"; address = "Motijheel CA, Dhaka"; lat = 23.7330; lng = 90.4172 },
            @{ name = "Green Valley Grocery"; mobile = "01722334455"; address = "Banani 11, Dhaka"; lat = 23.7937; lng = 90.4066 }
        )

        $nowIso = (Get-Date).ToUniversalTime().ToString("o")
        $fup1Iso = (Get-Date).AddDays(5).ToUniversalTime().ToString("o")
        $fup2Iso = (Get-Date).AddDays(12).ToUniversalTime().ToString("o")

        for ($i = 0; $i -lt $fieldOfficers.Count; $i++) {
            $officer = $fieldOfficers[$i]
            $officerName = $officer.fullName
            $officerUser = $officer.username
            Write-Host "`nProcessing Officer: $officerName (@$officerUser)" -ForegroundColor Magenta

            $offHeaders = $adminHeaders
            try {
                $offLoginObj = @{ username = $officer.username; password = "User@123" } | ConvertTo-Json
                $offAuth = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -ContentType "application/json" -Body $offLoginObj
                $offHeaders = @{ Authorization = "Bearer $($offAuth.token)" }
            } catch {
                Write-Host "  Using admin headers for $officerUser" -ForegroundColor DarkGray
            }

            $startIndex = ($i * 2) % $sampleShops.Count
            $assignedShops = @($sampleShops[$startIndex])
            if (($startIndex + 1) -lt $sampleShops.Count) {
                $assignedShops += $sampleShops[$startIndex + 1]
            }

            foreach ($shop in $assignedShops) {
                $randomShopName = $shop.name + " #" + (Get-Random -Minimum 10 -Maximum 99)
                $custReq = @{
                    name = $randomShopName
                    mobile = $shop.mobile
                    address = $shop.address
                    latitude = $shop.lat
                    longitude = $shop.lng
                    remarks = "Regular retail partner"
                } | ConvertTo-Json

                try {
                    $createdCust = Invoke-RestMethod -Uri "$baseUrl/api/Customers" -Method Post -Headers $offHeaders -ContentType "application/json" -Body $custReq
                    Write-Host "  [+] Customer Created: $($createdCust.name)" -ForegroundColor Green

                    # Visit 1
                    $visit1 = @{
                        customerId = $createdCust.customerId
                        latitude = $shop.lat
                        longitude = $shop.lng
                        remarks = "Stock audit and catalogue distribution done"
                        visitStatus = "Completed"
                        nextFollowUpDate = $fup1Iso
                    } | ConvertTo-Json
                    $v1 = Invoke-RestMethod -Uri "$baseUrl/api/visits" -Method Post -Headers $offHeaders -ContentType "application/json" -Body $visit1
                    Write-Host "    -> Visit 1 recorded (Follow-up scheduled: $fup1Iso)" -ForegroundColor Green

                    # Visit 2
                    $visit2 = @{
                        customerId = $createdCust.customerId
                        latitude = $shop.lat
                        longitude = $shop.lng
                        remarks = "Payment collection and delivery order finalized"
                        visitStatus = "Completed"
                        nextFollowUpDate = $fup2Iso
                    } | ConvertTo-Json
                    $v2 = Invoke-RestMethod -Uri "$baseUrl/api/visits" -Method Post -Headers $offHeaders -ContentType "application/json" -Body $visit2
                    Write-Host "    -> Visit 2 recorded (Follow-up scheduled: $fup2Iso)" -ForegroundColor Green

                } catch {
                    Write-Host "  [!] Notice: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }

        Write-Host "`n[DONE] Finished seeding data for $baseUrl" -ForegroundColor Green

    } catch {
        $errMsg = $_.Exception.Message
        Write-Host "[ERROR] Failed on $baseUrl - $errMsg" -ForegroundColor Red
    }
}
