$baseUrl = "http://104.215.157.203:120"
$token = (Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -ContentType "application/json" -Body '{"username":"moxx_field_319","password":"User@123"}').token
$headers = @{ Authorization = "Bearer $token" }

try {
    $res = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Method Get -Headers $headers
    Write-Host "Get Customers Result: SUCCESS Count = " $res.Count
} catch {
    Write-Host "Get Customers Failed:" $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Error Body:" $reader.ReadToEnd()
    }
}
