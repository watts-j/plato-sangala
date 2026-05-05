# Sangala Reader Installer
# Detects Kobo device, determines install vs update, and copies files.

param(
    [string]$InstallPath = "$PSScriptRoot\plato-sangala-v2.24-sangala-install",
    [string]$UpdatePath = "$PSScriptRoot\plato-sangala-v2.24-sangala-update"
)

function Find-Kobo {
    $drives = Get-WmiObject Win32_LogicalDisk
    foreach ($drive in $drives) {
        $letter = $drive.DeviceID
        if ($drive.VolumeName -eq "KOBOeReader" -or (Test-Path "$letter\.kobo")) {
            return $letter
        }
    }
    return $null
}

function Eject-Drive($driveLetter) {
    $vol = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter }
    if ($vol) {
        $vol.Dismount($false, $false) | Out-Null
    }
    # Fallback: use shell COM object
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace(17)
    $item = $folder.ParseName($driveLetter + "\")
    if ($item) {
        $item.InvokeVerb("Eject")
    }
}

function Remove-OldLibraries($destDrive) {
    $oldFolders = @("STEM", "Humanities", "Enrichment", "Resources", "Vocational", "Menu")
    foreach ($folder in $oldFolders) {
        $path = Join-Path "$destDrive\" $folder
        if (Test-Path $path) {
            Write-Host "  Removing old folder: $folder" -ForegroundColor DarkYellow
            Remove-Item -Path $path -Recurse -Force
        }
    }
}

function Copy-Package($sourcePath, $destDrive) {
    Write-Host "Copying files from $sourcePath to $destDrive\ ..." -ForegroundColor Cyan
    $items = Get-ChildItem -Path $sourcePath -Force
    foreach ($item in $items) {
        $dest = Join-Path "$destDrive\" $item.Name
        if ($item.PSIsContainer) {
            Copy-Item -Path $item.FullName -Destination $dest -Recurse -Force
        } else {
            Copy-Item -Path $item.FullName -Destination $dest -Force
        }
    }
    Write-Host "Copy complete." -ForegroundColor Green
}

function Wait-ForKobo {
    Write-Host ""
    Write-Host "Waiting for Kobo to reconnect..." -ForegroundColor Yellow
    Write-Host "After the device finishes updating, use the burger menu > Connect USB on the device."
    Write-Host ""

    $drive = $null
    $elapsed = 0
    while ($null -eq $drive) {
        Start-Sleep -Seconds 3
        $elapsed += 3
        $drive = Find-Kobo
        if ($elapsed % 30 -eq 0 -and $elapsed -gt 0) {
            Write-Host "  Still waiting... ($elapsed seconds). Make sure USB is plugged in and tap Connect USB on the device." -ForegroundColor DarkYellow
        }
    }
    Write-Host "Kobo detected at $drive" -ForegroundColor Green
    return $drive
}

# --- Main ---

Write-Host ""
Write-Host "========================================" -ForegroundColor White
Write-Host "  Sangala Reader Installer" -ForegroundColor White
Write-Host "========================================" -ForegroundColor White
Write-Host ""

# Validate package paths
if (-not (Test-Path $InstallPath)) {
    Write-Host "ERROR: Install package not found at $InstallPath" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $UpdatePath)) {
    Write-Host "ERROR: Update package not found at $UpdatePath" -ForegroundColor Red
    exit 1
}

# Detect Kobo
Write-Host "Looking for Kobo device..." -ForegroundColor Cyan
$koboDrive = Find-Kobo

if ($null -eq $koboDrive) {
    Write-Host "No Kobo device found. Please connect the device via USB and try again." -ForegroundColor Red
    exit 1
}

Write-Host "Kobo detected at $koboDrive" -ForegroundColor Green

# Determine install vs update
$isUpdate = Test-Path "$koboDrive\.adds\plato\plato"

if ($isUpdate) {
    Write-Host ""
    Write-Host "Existing Plato installation found. Performing UPDATE." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Cleaning up old library folders..." -ForegroundColor Cyan
    Remove-OldLibraries $koboDrive

    Copy-Package $UpdatePath $koboDrive

    Write-Host ""
    Write-Host "Ejecting device..." -ForegroundColor Cyan
    Eject-Drive $koboDrive
    Write-Host ""
    Write-Host "Update complete. You may disconnect the device." -ForegroundColor Green
    Write-Host "Power off and power on to load the new version." -ForegroundColor Yellow

} else {
    Write-Host ""
    Write-Host "No existing Plato installation. Performing FRESH INSTALL." -ForegroundColor Cyan
    Write-Host "This is a two-step process." -ForegroundColor Yellow
    Write-Host ""

    # Step 1: Install package
    Write-Host "--- Step 1 of 2: Installing system files ---" -ForegroundColor White
    Copy-Package $InstallPath $koboDrive

    Write-Host ""
    Write-Host "Ejecting device..." -ForegroundColor Cyan
    Eject-Drive $koboDrive

    Write-Host ""
    Write-Host "The device will now process system files and reboot." -ForegroundColor Yellow
    Write-Host "This may take a few minutes. Do NOT disconnect the USB cable." -ForegroundColor Yellow

    # Step 2: Wait for reconnect, then apply update
    $koboDrive = Wait-ForKobo

    Write-Host ""
    Write-Host "--- Step 2 of 2: Applying update ---" -ForegroundColor White
    Copy-Package $UpdatePath $koboDrive

    Write-Host ""
    Write-Host "Ejecting device..." -ForegroundColor Cyan
    Eject-Drive $koboDrive
    Write-Host ""
    Write-Host "Installation complete! The device will launch Plato on next boot." -ForegroundColor Green
}

Write-Host ""
Read-Host "Press Enter to exit"
