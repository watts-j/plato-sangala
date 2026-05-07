# Sangala Reader Installer (CLI)
# Detects Kobo device, determines install vs update, and copies files.
#
# By default, picks up `plato-sangala-v*-sangala-install` and
# `plato-sangala-v*-sangala-update` folders next to this script
# (highest version wins if multiple are present). Override with
# -InstallPath / -UpdatePath if you need a specific folder.
#
# On a fresh install, prompts for the reader's name and patches it into
# the package's Settings.toml so the home screen welcome line reads
# "Welcome, <name>!". On an update, the existing on-device name is
# preserved (read from the device's Settings.toml and patched into the
# update package before copying), so updates don't revert the name.
#
# Errors and notable events are appended to install-sangala.log next to
# the script.

param(
    [string]$InstallPath,
    [string]$UpdatePath
)

$ErrorActionPreference = 'Stop'
$LogPath = Join-Path $PSScriptRoot 'install-sangala.log'

function Write-Log {
    param([string]$Level, [string]$Message)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts [$Level] $Message" | Out-File -FilePath $LogPath -Append -Encoding utf8
}

function Get-PackageVersion($name) {
    if ($name -match 'v(\d+)\.(\d+)') {
        return [version]"$($Matches[1]).$($Matches[2])"
    }
    return [version]"0.0"
}

function Find-LatestPackage($suffix) {
    $pattern = "plato-sangala-v*-sangala-$suffix"
    $found = @(Get-ChildItem -Path $PSScriptRoot -Directory -Filter $pattern -ErrorAction SilentlyContinue)
    if ($found.Count -eq 0) {
        return $null
    }
    $sorted = $found | Sort-Object { Get-PackageVersion $_.Name } -Descending
    return $sorted[0].FullName
}

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
    try {
        $vol = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter }
        if ($vol) {
            $result = $vol.Dismount($false, $false)
            if ($result.ReturnValue -eq 0) {
                Write-Log 'INFO' "Dismounted $driveLetter via Win32_Volume"
                return
            }
            Write-Log 'WARN' "Win32_Volume.Dismount returned $($result.ReturnValue) for $driveLetter; falling back to Shell eject"
        }
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace(17)
        $item = $folder.ParseName($driveLetter + "\")
        if ($item) {
            $item.InvokeVerb("Eject")
            Write-Log 'INFO' "Ejected $driveLetter via Shell.Application"
        }
    }
    catch {
        Write-Log 'WARN' "Eject failed for $driveLetter`: $($_.Exception.Message)"
    }
}

function Wait-ForDriveGone($driveLetter, $timeoutSeconds = 60) {
    # Polls until the drive letter is no longer mounted, or the timeout elapses.
    # Returns $true if the drive is gone, $false on timeout.
    $elapsed = 0
    while ($elapsed -lt $timeoutSeconds) {
        if (-not (Test-Path "$driveLetter\")) {
            return $true
        }
        Start-Sleep -Seconds 1
        $elapsed++
    }
    return $false
}

function Disconnect-Kobo($driveLetter) {
    Write-Host "Ejecting device..." -ForegroundColor Cyan
    Eject-Drive $driveLetter
    if (-not (Wait-ForDriveGone $driveLetter)) {
        Write-Host ""
        Write-Host "The device didn't disconnect automatically. If Windows shows a dialog" -ForegroundColor Yellow
        Write-Host "saying the drive is in use, click Cancel and use 'Safely Remove Hardware'" -ForegroundColor Yellow
        Write-Host "(system tray icon) to eject the Kobo. Or simply unplug and replug the USB cable." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter once the device has disconnected"
        # Brief extra wait in case the user pressed Enter prematurely.
        Wait-ForDriveGone $driveLetter 10 | Out-Null
    }
    Write-Host "Device disconnected." -ForegroundColor Green
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
    $files = @(Get-ChildItem -Path $sourcePath -Recurse -Force -File)
    $total = $files.Count
    if ($total -eq 0) {
        Write-Host "  (no files to copy)" -ForegroundColor DarkGray
        return
    }
    $done = 0
    $activity = "Copying to $destDrive"
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($sourcePath.Length).TrimStart('\','/')
        $destPath = Join-Path "$destDrive\" $relative
        $destDir = Split-Path $destPath -Parent
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -Path $file.FullName -Destination $destPath -Force
        $done++
        $pct = [int](100 * $done / $total)
        Write-Progress -Activity $activity -Status "$done of $total files ($pct%)" -PercentComplete $pct
    }
    Write-Progress -Activity $activity -Completed
    Write-Host "Copy complete. $total files copied." -ForegroundColor Green
}

function Wait-ForKobo {
    Write-Host ""
    Write-Host "Waiting for the device to reconnect..." -ForegroundColor Yellow
    Write-Host "After the device finishes updating, you may need to tap 'Connect USB' in the top-right menu."
    Write-Host ""

    $drive = $null
    $elapsed = 0
    while ($null -eq $drive) {
        Start-Sleep -Seconds 3
        $elapsed += 3
        $drive = Find-Kobo
        if ($elapsed % 30 -eq 0 -and $elapsed -gt 0) {
            Write-Host "  Still waiting... ($elapsed seconds). Make sure USB is plugged in and tap 'Connect USB' on the device." -ForegroundColor DarkYellow
        }
    }
    Write-Host "Kobo detected at $drive" -ForegroundColor Green
    return $drive
}

function Get-DeviceWelcomeName($driveLetter) {
    $settingsFile = Join-Path "$driveLetter\" '.adds\plato\Settings.toml'
    if (-not (Test-Path $settingsFile)) {
        return $null
    }
    $content = Get-Content -Raw -Path $settingsFile
    if ($content -match 'welcome-name\s*=\s*"([^"]*)"') {
        return $Matches[1]
    }
    return $null
}

function Set-PackageWelcomeName($packagePath, $name) {
    $settingsFile = Join-Path $packagePath '.adds\plato\Settings.toml'
    if (-not (Test-Path $settingsFile)) {
        throw "Settings.toml not found in package: $settingsFile"
    }
    $content = Get-Content -Raw -Path $settingsFile
    $escaped = $name -replace '"', '\"'
    $patched = $content -replace 'welcome-name\s*=\s*"[^"]*"', ('welcome-name = "{0}"' -f $escaped)
    Set-Content -Path $settingsFile -Value $patched -NoNewline
}

function Exit-WithMessage($message) {
    Write-Log 'ERROR' $message
    Write-Host ""
    Write-Host "ERROR: $message" -ForegroundColor Red
    Write-Host "Details written to: $LogPath" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Main ---

Write-Log 'INFO' '--- CLI installer started ---'

try {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    Write-Host "  Sangala Reader Installer" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor White
    Write-Host ""

    # Auto-detect package folders next to this script if not explicitly provided
    if (-not $InstallPath) {
        $InstallPath = Find-LatestPackage "install"
    }
    if (-not $UpdatePath) {
        $UpdatePath = Find-LatestPackage "update"
    }

    # Validate package paths
    if (-not $InstallPath -or -not (Test-Path $InstallPath)) {
        Exit-WithMessage "Install package not found. Expected a folder matching 'plato-sangala-v*-sangala-install' next to this script, or pass -InstallPath <path> explicitly."
    }
    if (-not $UpdatePath -or -not (Test-Path $UpdatePath)) {
        Exit-WithMessage "Update package not found. Expected a folder matching 'plato-sangala-v*-sangala-update' next to this script, or pass -UpdatePath <path> explicitly."
    }

    Write-Host "Install package: $(Split-Path $InstallPath -Leaf)" -ForegroundColor DarkGray
    Write-Host "Update package:  $(Split-Path $UpdatePath -Leaf)" -ForegroundColor DarkGray
    Write-Host ""

    # Detect Kobo
    Write-Host "Looking for Kobo device..." -ForegroundColor Cyan
    $koboDrive = Find-Kobo

    if ($null -eq $koboDrive) {
        Exit-WithMessage "No Kobo device found. Please connect the device via USB and try again."
    }

    Write-Host "Kobo detected at $koboDrive" -ForegroundColor Green
    Write-Log 'INFO' "Kobo detected at $koboDrive"

    # Determine install vs update
    $isUpdate = Test-Path "$koboDrive\.adds\plato\plato"

    if ($isUpdate) {
        Write-Host ""
        Write-Host "Existing Plato installation found. Performing UPDATE." -ForegroundColor Cyan
        Write-Host ""

        # Preserve the existing on-device welcome name through the update
        $existingName = Get-DeviceWelcomeName $koboDrive
        if ($existingName) {
            Write-Host "Preserving welcome name: $existingName" -ForegroundColor DarkGray
            Set-PackageWelcomeName $UpdatePath $existingName
            Write-Log 'INFO' "Preserved welcome name: $existingName"
        } else {
            Write-Log 'WARN' 'No existing welcome name found on device; update package will use the placeholder.'
        }

        Write-Host "Cleaning up old library folders..." -ForegroundColor Cyan
        Remove-OldLibraries $koboDrive

        Copy-Package $UpdatePath $koboDrive

        Write-Host ""
        Disconnect-Kobo $koboDrive
        Write-Host ""
        Write-Host "Update complete. You may disconnect the device." -ForegroundColor Green
        Write-Host "Power off and power on to load the new version." -ForegroundColor Yellow
        Write-Log 'INFO' 'Update complete'

    } else {
        Write-Host ""
        Write-Host "No existing Plato installation. Performing FRESH INSTALL." -ForegroundColor Cyan
        Write-Host "This is a two-step process." -ForegroundColor Yellow
        Write-Host ""

        # Prompt for the reader's name and patch both packages
        Write-Host ""
        $name = ''
        while ([string]::IsNullOrWhiteSpace($name)) {
            $name = Read-Host "Enter the user's name"
            $name = $name.Trim()
        }
        Set-PackageWelcomeName $InstallPath $name
        Set-PackageWelcomeName $UpdatePath $name
        Write-Log 'INFO' "Set welcome name: $name"

        # Step 1: Install package
        Write-Host ""
        Write-Host "--- Step 1 of 2: Installing system files ---" -ForegroundColor White
        Copy-Package $InstallPath $koboDrive

        Write-Host ""
        Disconnect-Kobo $koboDrive

        Write-Host ""
        Write-Host "The device will now process system files and reboot." -ForegroundColor Yellow
        Write-Host "This may take a few minutes. Do NOT disconnect the USB cable." -ForegroundColor Yellow

        # Step 2: Wait for reconnect, then apply update
        $koboDrive = Wait-ForKobo

        Write-Host ""
        Write-Host "--- Step 2 of 2: Applying update ---" -ForegroundColor White
        Copy-Package $UpdatePath $koboDrive

        Write-Host ""
        Disconnect-Kobo $koboDrive
        Write-Host ""
        Write-Host "Installation complete! The device will launch Plato on next boot." -ForegroundColor Green
        Write-Host "Do not power off the device for 15 minutes; updates are still processing." -ForegroundColor Yellow
        Write-Log 'INFO' 'Fresh install complete'
    }

    Write-Host ""
    Read-Host "Press Enter to exit"
}
catch {
    Write-Log 'ERROR' "Unhandled exception: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Details written to: $LogPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
