Add-Type -AssemblyName System.Drawing

$srcPath = "E:\Downloads\New folder (5)\WhatsApp Image 2026-08-21 at 5.43.44 PM.jpeg"
$resDir = "D:\Shuvo\zynexbd\live_tracking\LiveTrackingSystem\Moxx_App\app\src\main\res"

if (-not (Test-Path $srcPath)) {
    Write-Error "Source image not found: $srcPath"
    exit 1
}

$srcImage = [System.Drawing.Image]::FromFile($srcPath)
Write-Host "Source image loaded: $($srcImage.Width) x $($srcImage.Height)"

function Resize-Image {
    param(
        [System.Drawing.Image]$Image,
        [int]$Width,
        [int]$Height,
        [string]$DestinationPath,
        [bool]$MakeCircular = $false
    )

    $destDir = [System.IO.Path]::GetDirectoryName($DestinationPath)
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $destBitmap = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($destBitmap)
    
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    if ($MakeCircular) {
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddEllipse(0, 0, $Width, $Height)
        $graphics.SetClip($path)
    }

    $graphics.DrawImage($Image, 0, 0, $Width, $Height)
    $graphics.Dispose()

    if (Test-Path $DestinationPath) {
        Remove-Item -Force $DestinationPath
    }

    $destBitmap.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBitmap.Dispose()
    Write-Host "Generated: $DestinationPath ($Width x $Height)"
}

# 1. Launcher Mipmaps (Square & Round)
$mipmapSizes = @{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($folder in $mipmapSizes.Keys) {
    $size = $mipmapSizes[$folder]
    Resize-Image -Image $srcImage -Width $size -Height $size -DestinationPath "$resDir\$folder\ic_launcher.png" -MakeCircular $false
    Resize-Image -Image $srcImage -Width $size -Height $size -DestinationPath "$resDir\$folder\ic_launcher_round.png" -MakeCircular $true
}

# 2. Foreground Icons for Adaptive Icons
$foregroundSizes = @{
    "drawable-mdpi"    = 108
    "drawable-hdpi"    = 162
    "drawable-xhdpi"   = 216
    "drawable-xxhdpi"  = 324
    "drawable-xxxhdpi" = 432
}

foreach ($folder in $foregroundSizes.Keys) {
    $size = $foregroundSizes[$folder]
    Resize-Image -Image $srcImage -Width $size -Height $size -DestinationPath "$resDir\$folder\ic_launcher_foreground.png" -MakeCircular $false
    Resize-Image -Image $srcImage -Width $size -Height $size -DestinationPath "$resDir\$folder\app_logo.png" -MakeCircular $false
    Resize-Image -Image $srcImage -Width $size -Height $size -DestinationPath "$resDir\$folder\ic_tracking_logo.png" -MakeCircular $false
}

# 3. Direct drawables (Notification and in-app logos)
Resize-Image -Image $srcImage -Width 512 -Height 512 -DestinationPath "$resDir\drawable\app_logo.png" -MakeCircular $false
Resize-Image -Image $srcImage -Width 512 -Height 512 -DestinationPath "$resDir\drawable\ic_tracking_logo.png" -MakeCircular $false
Resize-Image -Image $srcImage -Width 96 -Height 96 -DestinationPath "$resDir\drawable\ic_notification_logo.png" -MakeCircular $false

$srcImage.Dispose()
Write-Host "All icons generated successfully!"
