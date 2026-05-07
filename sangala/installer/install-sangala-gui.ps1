# Sangala Reader Installer (GUI)
# WinForms wizard wrapping the CLI installer's logic.
#
# By default, picks up `plato-sangala-v*-sangala-install` and
# `plato-sangala-v*-sangala-update` folders next to this script
# (highest version wins if multiple are present).
#
# Errors and notable events are appended to install-sangala.log next to
# the script.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$ScriptDir = $PSScriptRoot
$LogPath = Join-Path $ScriptDir 'install-sangala.log'
$ReconnectTimeoutSeconds = 300

# Win32 P/Invoke: flushes Windows' lazy-write cache for a volume before
# we try to eject it. Without this, the runspace copy can return while
# writes are still buffered in RAM; the eject then fails (or worse,
# succeeds without flushing) and the device sees a partial/corrupted
# file.
$flushType = @"
using System;
using System.Runtime.InteropServices;

public static class VolumeFlush {
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CreateFile(
        string fileName, uint desiredAccess, uint shareMode,
        IntPtr securityAttributes, uint creationDisposition,
        uint flagsAndAttributes, IntPtr templateFile);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool FlushFileBuffers(IntPtr hFile);
    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool CloseHandle(IntPtr hObject);

    public static bool Flush(string driveLetter) {
        IntPtr h = CreateFile(@"\\.\" + driveLetter,
            0x40000000, 0x1 | 0x2, IntPtr.Zero, 3, 0, IntPtr.Zero);
        if (h == new IntPtr(-1)) { return false; }
        bool ok = FlushFileBuffers(h);
        CloseHandle(h);
        return ok;
    }
}
"@
function Initialize-FlushType {
    if (-not ('VolumeFlush' -as [type])) {
        try {
            Add-Type -TypeDefinition $script:flushType -ErrorAction Stop
        }
        catch {
            Write-Log 'WARN' "Could not compile FlushFileBuffers wrapper: $($_.Exception.Message)"
        }
    }
}

# --- Logging --------------------------------------------------------------

function Write-Log {
    param([string]$Level, [string]$Message)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts [$Level] $Message" | Out-File -FilePath $script:LogPath -Append -Encoding utf8
}

# --- Drive / package / settings helpers -----------------------------------

function Get-PackageVersion($name) {
    if ($name -match 'v(\d+)\.(\d+)') {
        return [version]"$($Matches[1]).$($Matches[2])"
    }
    return [version]"0.0"
}

function Find-LatestPackage($suffix) {
    $pattern = "plato-sangala-v*-sangala-$suffix"
    $found = @(Get-ChildItem -Path $script:ScriptDir -Directory -Filter $pattern -ErrorAction SilentlyContinue)
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

function Flush-Drive($driveLetter) {
    Initialize-FlushType
    if (-not ('VolumeFlush' -as [type])) {
        Write-Log 'WARN' 'FlushFileBuffers wrapper unavailable; skipping flush.'
        return $false
    }
    try {
        if ([VolumeFlush]::Flush($driveLetter)) {
            Write-Log 'INFO' "Flushed write cache for $driveLetter"
            return $true
        }
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Log 'WARN' "FlushFileBuffers failed for $driveLetter (Win32 error $err)"
    }
    catch {
        Write-Log 'WARN' "Flush-Drive exception for $driveLetter`: $($_.Exception.Message)"
    }
    return $false
}

function Eject-Drive($driveLetter) {
    # Cooperative dismount only. We deliberately do NOT fall through to
    # Shell.Application.InvokeVerb("Eject"), because that path shows
    # Windows' "drive in use" dialog whose Continue button forcibly
    # dismounts and corrupts in-flight writes (factory-reset hazard).
    try {
        $vol = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter }
        if ($vol) {
            $result = $vol.Dismount($false, $false)
            if ($result.ReturnValue -eq 0) {
                Write-Log 'INFO' "Dismounted $driveLetter via Win32_Volume"
                return
            }
            Write-Log 'WARN' "Win32_Volume.Dismount returned $($result.ReturnValue) for $driveLetter"
        }
    }
    catch {
        Write-Log 'WARN' "Eject failed for $driveLetter`: $($_.Exception.Message)"
    }
}

function Test-DriveGone($driveLetter) {
    -not (Test-Path "$driveLetter\")
}

function Remove-OldLibraries($destDrive) {
    $oldFolders = @("STEM", "Humanities", "Enrichment", "Resources", "Vocational", "Menu")
    foreach ($folder in $oldFolders) {
        $path = Join-Path "$destDrive\" $folder
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
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

# --- Background copy ------------------------------------------------------

function Start-BackgroundCopy($sourcePath, $destDrive) {
    $bgState = [hashtable]::Synchronized(@{
        Total = 0
        Done = 0
        Status = 'Running'
        Error = $null
    })

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.Open()
    $rs.SessionStateProxy.SetVariable('bgState', $bgState)
    $rs.SessionStateProxy.SetVariable('source', $sourcePath)
    $rs.SessionStateProxy.SetVariable('dest', $destDrive)

    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript({
        try {
            $files = @(Get-ChildItem -Path $source -Recurse -Force -File)
            $bgState.Total = $files.Count
            foreach ($file in $files) {
                $relative = $file.FullName.Substring($source.Length).TrimStart('\','/')
                $destPath = Join-Path $dest $relative
                $destDir = Split-Path $destPath -Parent
                if ($destDir -and -not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                Copy-Item -Path $file.FullName -Destination $destPath -Force
                $bgState.Done++
            }
            $bgState.Status = 'Done'
        }
        catch {
            $bgState.Error = $_.Exception.Message
            $bgState.Status = 'Error'
        }
    })

    $handle = $ps.BeginInvoke()

    return @{
        State = $bgState
        PowerShell = $ps
        Handle = $handle
        Runspace = $rs
    }
}

function Stop-BackgroundCopy($bg) {
    if (-not $bg) { return }
    try {
        if ($bg.PowerShell) {
            $bg.PowerShell.Dispose()
        }
        if ($bg.Runspace) {
            $bg.Runspace.Close()
            $bg.Runspace.Dispose()
        }
    }
    catch { }
}

# --- Shared state ---------------------------------------------------------

$script:S = @{
    Drive = $null
    InstallPath = $null
    UpdatePath = $null
    Name = $null
    IsFreshInstall = $false
    Bg = $null
    ReconnectStart = $null
    LastError = $null
}

# --- Form / controls ------------------------------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Sangala eReader Installer"
$form.Size = New-Object System.Drawing.Size(520, 340)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.MinimizeBox = $true

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 20)
$statusLabel.Size = New-Object System.Drawing.Size(470, 130)
$statusLabel.TextAlign = 'MiddleCenter'
$statusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$form.Controls.Add($statusLabel)

$nameLabel = New-Object System.Windows.Forms.Label
$nameLabel.Location = New-Object System.Drawing.Point(20, 155)
$nameLabel.Size = New-Object System.Drawing.Size(470, 22)
$nameLabel.TextAlign = 'MiddleCenter'
$nameLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$nameLabel.Text = "Enter the user's name:"
$nameLabel.Visible = $false
$form.Controls.Add($nameLabel)

$nameInput = New-Object System.Windows.Forms.TextBox
$nameInput.Location = New-Object System.Drawing.Point(135, 180)
$nameInput.Size = New-Object System.Drawing.Size(240, 24)
$nameInput.MaxLength = 40
$nameInput.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$nameInput.Visible = $false
$form.Controls.Add($nameInput)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(40, 175)
$progressBar.Size = New-Object System.Drawing.Size(440, 26)
$progressBar.Style = 'Continuous'
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Location = New-Object System.Drawing.Point(20, 205)
$progressLabel.Size = New-Object System.Drawing.Size(470, 20)
$progressLabel.TextAlign = 'MiddleCenter'
$progressLabel.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$progressLabel.Visible = $false
$form.Controls.Add($progressLabel)

# Two side-by-side buttons + one centered button. We toggle visibility per state.
$primaryButton = New-Object System.Windows.Forms.Button
$primaryButton.Size = New-Object System.Drawing.Size(140, 36)
$primaryButton.Location = New-Object System.Drawing.Point(110, 250)
$primaryButton.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$form.Controls.Add($primaryButton)

$secondaryButton = New-Object System.Windows.Forms.Button
$secondaryButton.Size = New-Object System.Drawing.Size(140, 36)
$secondaryButton.Location = New-Object System.Drawing.Point(265, 250)
$secondaryButton.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$form.Controls.Add($secondaryButton)

$centerButton = New-Object System.Windows.Forms.Button
$centerButton.Size = New-Object System.Drawing.Size(140, 36)
$centerButton.Location = New-Object System.Drawing.Point(190, 250)
$centerButton.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$centerButton.Visible = $false
$form.Controls.Add($centerButton)

# Timer used both for copy progress polling and reconnect-wait polling.
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500

# --- Helpers --------------------------------------------------------------

function Hide-AllControls {
    $script:nameLabel.Visible = $false
    $script:nameInput.Visible = $false
    $script:progressBar.Visible = $false
    $script:progressLabel.Visible = $false
    $script:primaryButton.Visible = $false
    $script:secondaryButton.Visible = $false
    $script:centerButton.Visible = $false
    $script:primaryButton.Remove_Click({})
    $script:secondaryButton.Remove_Click({})
    $script:centerButton.Remove_Click({})
}

function Reset-ButtonClickHandler($button) {
    # Replace the click handler on a button by recreating it. There's no
    # public API to clear all handlers, so we use a sentinel.
    while ($button.Tag -is [scriptblock]) {
        $button.Remove_Click($button.Tag)
        $button.Tag = $null
    }
}

function Set-PrimaryButton($text, $handler) {
    Reset-ButtonClickHandler $script:primaryButton
    $script:primaryButton.Text = $text
    $script:primaryButton.Visible = $true
    $script:primaryButton.Enabled = $true
    $script:primaryButton.Tag = $handler
    $script:primaryButton.Add_Click($handler)
}

function Set-SecondaryButton($text, $handler) {
    Reset-ButtonClickHandler $script:secondaryButton
    $script:secondaryButton.Text = $text
    $script:secondaryButton.Visible = $true
    $script:secondaryButton.Enabled = $true
    $script:secondaryButton.Tag = $handler
    $script:secondaryButton.Add_Click($handler)
}

function Set-CenterButton($text, $handler) {
    Reset-ButtonClickHandler $script:centerButton
    $script:centerButton.Text = $text
    $script:centerButton.Visible = $true
    $script:centerButton.Enabled = $true
    $script:centerButton.Tag = $handler
    $script:centerButton.Add_Click($handler)
}

# --- State transitions ----------------------------------------------------

function Show-Initial {
    $script:timer.Stop()
    Hide-AllControls
    $script:statusLabel.Text = "Welcome to the Sangala eReader Installer.`n`nConnect your device by USB, then click below."
    Set-CenterButton "Connect to Device" {
        Show-Detecting
    }
}

function Show-Detecting {
    Hide-AllControls
    $script:statusLabel.Text = "Looking for Kobo device..."
    $script:form.Refresh()
    Start-Sleep -Milliseconds 200

    $drive = Find-Kobo
    if (-not $drive) {
        Write-Log 'WARN' 'No Kobo device found'
        Show-NoDeviceError
        return
    }

    $script:S.Drive = $drive
    Write-Log 'INFO' "Kobo detected at $drive"

    if (Test-Path "$drive\.adds\plato\plato") {
        $script:S.IsFreshInstall = $false
        Show-DetectedUpdate
    } else {
        $script:S.IsFreshInstall = $true
        Show-DetectedFresh
    }
}

function Show-NoDeviceError {
    Hide-AllControls
    $script:statusLabel.Text = "No Kobo device found.`n`nPlease connect the device by USB and try again."
    Set-PrimaryButton "Retry" { Show-Detecting }
    Set-SecondaryButton "Close" { $script:form.Close() }
}

function Show-DetectedFresh {
    Hide-AllControls
    $script:statusLabel.Text = "Kobo detected at $($script:S.Drive).`n`nNo existing Plato installation found.`nClick Install to begin a fresh installation."
    Set-PrimaryButton "Install" { Show-NamePrompt }
    Set-SecondaryButton "Cancel" { $script:form.Close() }
}

function Show-DetectedUpdate {
    Hide-AllControls
    $script:statusLabel.Text = "Kobo detected at $($script:S.Drive).`n`nExisting Plato installation found.`nClick Update to copy library content to the device."
    Set-PrimaryButton "Update" { Start-UpdateOnly }
    Set-SecondaryButton "Cancel" { $script:form.Close() }
}

function Show-NamePrompt {
    Hide-AllControls
    $script:statusLabel.Text = "The name will appear on the device's home screen as `"Welcome, {name}!`"."
    $script:nameLabel.Visible = $true
    $script:nameInput.Visible = $true
    $script:nameInput.Text = ''
    $script:nameInput.Focus()

    Set-PrimaryButton "Continue" {
        $entered = $script:nameInput.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($entered)) {
            return
        }
        $script:S.Name = $entered
        Start-FreshInstallStep1
    }
    Set-SecondaryButton "Cancel" { $script:form.Close() }
    $script:primaryButton.Enabled = -not [string]::IsNullOrWhiteSpace($script:nameInput.Text)
    $script:nameInput.Add_TextChanged({
        $script:primaryButton.Enabled = -not [string]::IsNullOrWhiteSpace($script:nameInput.Text.Trim())
    })
}

function Start-FreshInstallStep1 {
    try {
        Set-PackageWelcomeName $script:S.InstallPath $script:S.Name
        Set-PackageWelcomeName $script:S.UpdatePath $script:S.Name
        Write-Log 'INFO' "Set welcome name: $($script:S.Name)"
    }
    catch {
        Write-Log 'ERROR' "Failed to patch welcome name: $($_.Exception.Message)"
        Show-CopyError $_.Exception.Message { Show-NamePrompt }
        return
    }

    Hide-AllControls
    $script:statusLabel.Text = "Your device will reboot during the installation process.`nDo not disconnect it from your computer until prompted."
    $script:progressBar.Value = 0
    $script:progressBar.Visible = $true
    $script:progressLabel.Text = "Copying system files..."
    $script:progressLabel.Visible = $true

    Write-Log 'INFO' 'Starting copy of install package'
    $script:S.Bg = Start-BackgroundCopy $script:S.InstallPath $script:S.Drive
    $script:timer.Stop()
    $script:timer.Remove_Tick({})
    $script:timer.Add_Tick({ On-CopyTick { After-InstallStep1 } })
    $script:timer.Start()
}

function Start-UpdateOnly {
    # Standalone update path: preserve the existing on-device welcome name.
    $existing = Get-DeviceWelcomeName $script:S.Drive
    if ($existing) {
        try {
            Set-PackageWelcomeName $script:S.UpdatePath $existing
            Write-Log 'INFO' "Preserved welcome name: $existing"
        }
        catch {
            Write-Log 'WARN' "Failed to preserve welcome name: $($_.Exception.Message)"
        }
    }
    Remove-OldLibraries $script:S.Drive
    Start-UpdateCopy { Start-Disconnect { Show-Done } }
}

function Start-UpdateCopy($onSuccess) {
    Hide-AllControls
    $script:statusLabel.Text = "Copying library content to the device.`nDo not disconnect during this step."
    $script:progressBar.Value = 0
    $script:progressBar.Visible = $true
    $script:progressLabel.Text = "Copying library content..."
    $script:progressLabel.Visible = $true

    Write-Log 'INFO' 'Starting copy of update package'
    $script:S.Bg = Start-BackgroundCopy $script:S.UpdatePath $script:S.Drive
    $script:timer.Stop()
    $script:timer.Remove_Tick({})
    $script:timer.Add_Tick({ On-CopyTick $onSuccess })
    $script:timer.Start()
}

function On-CopyTick($onSuccess) {
    $bg = $script:S.Bg
    if (-not $bg) { return }
    $st = $bg.State

    if ($st.Total -gt 0) {
        $script:progressBar.Maximum = [int]$st.Total
        $script:progressBar.Value = [Math]::Min([int]$st.Done, [int]$st.Total)
        $pct = [int](100 * $st.Done / $st.Total)
        $script:progressLabel.Text = "Copied $($st.Done) of $($st.Total) files ($pct%)..."
    }

    if ($st.Status -eq 'Done') {
        $script:timer.Stop()
        Stop-BackgroundCopy $bg
        $script:S.Bg = $null
        Write-Log 'INFO' 'Copy complete'
        & $onSuccess
    }
    elseif ($st.Status -eq 'Error') {
        $script:timer.Stop()
        $err = $st.Error
        Stop-BackgroundCopy $bg
        $script:S.Bg = $null
        Write-Log 'ERROR' "Copy failed: $err"
        Show-CopyError $err {
            if ($script:S.IsFreshInstall -and $script:S.Drive -and -not (Test-Path "$($script:S.Drive)\.adds\plato\plato")) {
                Start-FreshInstallStep1
            } else {
                Start-UpdateCopy { Start-Disconnect { Show-Done } }
            }
        }
    }
}

function After-InstallStep1 {
    Start-Disconnect { Show-WaitingForReconnect }
}

function Start-Disconnect($onSuccess) {
    Hide-AllControls
    $script:statusLabel.Text = "Flushing writes and ejecting the device..."
    $script:S.DisconnectStart = Get-Date
    $script:S.DisconnectOnSuccess = $onSuccess
    $script:form.Refresh()

    # Force Windows' lazy-write cache to disk BEFORE eject. Skipping
    # this risks a partial KoboRoot.tgz write which can brick the device.
    Flush-Drive $script:S.Drive | Out-Null
    Start-Sleep -Seconds 1

    Eject-Drive $script:S.Drive

    $script:timer.Stop()
    $script:timer.Remove_Tick({})
    $script:timer.Add_Tick({ On-DisconnectTick })
    $script:timer.Start()
}

function On-DisconnectTick {
    if (Test-DriveGone $script:S.Drive) {
        $script:timer.Stop()
        Write-Log 'INFO' "Device disconnected at $($script:S.Drive)"
        & $script:S.DisconnectOnSuccess
        return
    }
    $elapsed = (Get-Date) - $script:S.DisconnectStart
    if ($elapsed.TotalSeconds -ge 60) {
        $script:timer.Stop()
        Write-Log 'WARN' "Device did not disconnect within 60 seconds; prompting user"
        Show-DisconnectError
    }
}

function Show-DisconnectError {
    Hide-AllControls
    $script:statusLabel.Text = "The device didn't disconnect automatically.`n`nWARNING: Do NOT click 'Continue' on any 'drive in use' dialog Windows shows — that can corrupt the install and brick the device.`n`nInstead: click Cancel on Windows' dialog, use 'Safely Remove Hardware' (system tray) to eject the Kobo, wait for the safe-to-remove notification, then click Continue below."
    Set-PrimaryButton "Continue" {
        Start-Disconnect $script:S.DisconnectOnSuccess
    }
    Set-SecondaryButton "Cancel" { $script:form.Close() }
}

function Show-WaitingForReconnect {
    Hide-AllControls
    $script:statusLabel.Text = "Waiting for the device to reconnect.`n`nAfter the device finished updating, you may need to tap 'Connect USB' in the top-right menu."
    $script:S.ReconnectStart = Get-Date
    Set-SecondaryButton "Cancel" { $script:form.Close() }

    Write-Log 'INFO' 'Waiting for device to reconnect'
    $script:timer.Stop()
    $script:timer.Remove_Tick({})
    $script:timer.Add_Tick({
        $drive = Find-Kobo
        if ($drive) {
            $script:timer.Stop()
            $script:S.Drive = $drive
            Write-Log 'INFO' "Device reconnected at $drive"
            Show-DetectedUpdate
            return
        }
        $elapsed = (Get-Date) - $script:S.ReconnectStart
        if ($elapsed.TotalSeconds -ge $script:ReconnectTimeoutSeconds) {
            $script:timer.Stop()
            Write-Log 'ERROR' "Device did not reconnect within $script:ReconnectTimeoutSeconds seconds"
            Show-ReconnectError
        }
    })
    $script:timer.Start()
}

function Show-ReconnectError {
    Hide-AllControls
    $script:statusLabel.Text = "Device didn't reconnect within 5 minutes.`n`nMake sure USB is plugged in and try again."
    Set-PrimaryButton "Retry" { Show-WaitingForReconnect }
    Set-SecondaryButton "Close" { $script:form.Close() }
}

function Show-CopyError($message, $retryAction) {
    Hide-AllControls
    $script:statusLabel.Text = "An error occurred during installation:`n`n$message`n`nDetails written to the log file."
    Set-PrimaryButton "Retry" $retryAction
    Set-SecondaryButton "Close" { $script:form.Close() }
}

function Show-Done {
    Hide-AllControls
    if ($script:S.IsFreshInstall) {
        Write-Log 'INFO' 'Fresh install complete'
        $script:statusLabel.Text = "Installation complete!`n`nYou may now disconnect your device.`nDo not power it off for 15 minutes — updates are still processing."
    } else {
        Write-Log 'INFO' 'Update complete'
        $script:statusLabel.Text = "Update complete!`n`nYou may now disconnect your device."
    }
    Set-CenterButton "OK" { $script:form.Close() }
}

# --- Startup --------------------------------------------------------------

Write-Log 'INFO' '--- GUI installer started ---'

# Resolve packages once so we can fail fast if missing.
$script:S.InstallPath = Find-LatestPackage 'install'
$script:S.UpdatePath = Find-LatestPackage 'update'

if (-not $script:S.InstallPath -or -not (Test-Path $script:S.InstallPath) -or
    -not $script:S.UpdatePath -or -not (Test-Path $script:S.UpdatePath)) {
    Write-Log 'ERROR' 'Install or update package not found next to script'
    [System.Windows.Forms.MessageBox]::Show(
        "Couldn't find the install or update package next to this script.`n`nMake sure both 'plato-sangala-vX-sangala-install' and '-update' folders are in the same folder as install-sangala-gui.ps1.",
        "Sangala eReader Installer", 'OK', 'Error') | Out-Null
    exit 1
}

Show-Initial
[void]$form.ShowDialog()

# Cleanup any lingering background work
if ($script:S.Bg) {
    Stop-BackgroundCopy $script:S.Bg
}
$script:timer.Stop()
$script:timer.Dispose()
$form.Dispose()
Write-Log 'INFO' '--- GUI installer ended ---'
