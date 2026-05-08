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
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Definition) { Split-Path -Parent -Path $MyInvocation.MyCommand.Definition } else { Get-Location }
$LogPath = Join-Path $ScriptDir 'install-sangala.log'

# Win32 P/Invoke: flushes Windows' lazy-write cache for a volume before
# we try to eject it. Without this, Copy-Item can return while writes
# are still buffered in RAM; the eject then fails (or worse, succeeds
# without flushing) and the device sees a partial/corrupted file.
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

# Win32 P/Invoke: programmatic device eject via SetupAPI + Cfgmgr32.
# This is what "Safely Remove Hardware" does. The earlier Win32_Volume
# cooperative dismount returns success but only releases the volume from
# the file-system stack -- the USB device is still attached, and the
# device-side flash controller may not have flushed its internal write
# cache. fsck.fat at next boot then sees the dirty bit and truncates
# files (the v2.46 install on a Clara BW silently corrupted
# dictionary.dict.dz from 32 MB to 14 MB this way). CM_Request_Device_Eject
# issues a real device eject without going through the Shell verb whose
# "drive in use" Continue dialog bricked v2.39.
$ejectType = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class VolumeEjector {
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CreateFile(string fileName, uint desiredAccess, uint shareMode,
        IntPtr securityAttributes, uint creationDisposition, uint flagsAndAttributes, IntPtr templateFile);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool DeviceIoControl(IntPtr hDevice, uint ioControlCode,
        IntPtr inBuffer, uint inBufferSize, IntPtr outBuffer, uint outBufferSize,
        out uint bytesReturned, IntPtr overlapped);

    [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetupDiGetClassDevs(ref Guid classGuid, IntPtr enumerator,
        IntPtr hwndParent, uint flags);
    [DllImport("setupapi.dll", SetLastError = true)]
    private static extern bool SetupDiEnumDeviceInterfaces(IntPtr deviceInfoSet,
        IntPtr deviceInfoData, ref Guid interfaceClassGuid, uint memberIndex,
        ref SP_DID deviceInterfaceData);
    [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern bool SetupDiGetDeviceInterfaceDetail(IntPtr deviceInfoSet,
        ref SP_DID deviceInterfaceData, IntPtr deviceInterfaceDetailData,
        uint deviceInterfaceDetailDataSize, out uint requiredSize, ref SP_DEVINFO devInfo);
    [DllImport("setupapi.dll", SetLastError = true)]
    private static extern bool SetupDiDestroyDeviceInfoList(IntPtr deviceInfoSet);
    [DllImport("setupapi.dll", SetLastError = true)]
    private static extern uint CM_Get_Parent(out uint parentDevInst, uint devInst, uint flags);
    [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern uint CM_Request_Device_Eject(uint devInst, out int vetoType,
        StringBuilder vetoName, uint nameLength, uint flags);

    [StructLayout(LayoutKind.Sequential)]
    private struct SP_DID {
        public uint cbSize;
        public Guid InterfaceClassGuid;
        public uint Flags;
        public IntPtr Reserved;
    }
    [StructLayout(LayoutKind.Sequential)]
    private struct SP_DEVINFO {
        public uint cbSize;
        public Guid ClassGuid;
        public uint DevInst;
        public IntPtr Reserved;
    }

    private static readonly Guid GUID_DEVINTERFACE_DISK =
        new Guid("53F56307-B6BF-11D0-94F2-00A0C91EFB8B");
    private const uint IOCTL_STORAGE_GET_DEVICE_NUMBER = 0x002D1080;
    private const uint DIGCF_PRESENT = 0x02;
    private const uint DIGCF_DEVICEINTERFACE = 0x10;

    // Returns:
    //    0 = device ejected
    //   -1 = couldn't get device number for the volume
    //   -2 = no matching disk found in the device tree
    //   -3 = couldn't walk to USB parent in the device tree
    //  >=1 = CM error (eject vetoed or failed; see status)
    public static int RequestEject(string driveLetter, out string status) {
        status = "";
        int targetNum;

        IntPtr volH = CreateFile(@"\\.\" + driveLetter, 0, 0x3,
            IntPtr.Zero, 3, 0, IntPtr.Zero);
        if (volH == new IntPtr(-1)) {
            status = "CreateFile(volume) win32err=" + Marshal.GetLastWin32Error();
            return -1;
        }
        try {
            int[] sdn = new int[3];
            IntPtr buf = Marshal.AllocHGlobal(12);
            try {
                uint br;
                if (!DeviceIoControl(volH, IOCTL_STORAGE_GET_DEVICE_NUMBER,
                        IntPtr.Zero, 0, buf, 12, out br, IntPtr.Zero)) {
                    status = "IOCTL_STORAGE_GET_DEVICE_NUMBER win32err="
                        + Marshal.GetLastWin32Error();
                    return -1;
                }
                Marshal.Copy(buf, sdn, 0, 3);
                targetNum = sdn[1];
            } finally {
                Marshal.FreeHGlobal(buf);
            }
        } finally {
            CloseHandle(volH);
        }

        Guid g = GUID_DEVINTERFACE_DISK;
        IntPtr set = SetupDiGetClassDevs(ref g, IntPtr.Zero, IntPtr.Zero,
            DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
        if (set == new IntPtr(-1)) {
            status = "SetupDiGetClassDevs win32err=" + Marshal.GetLastWin32Error();
            return -2;
        }
        try {
            for (uint i = 0; ; i++) {
                SP_DID did = new SP_DID();
                did.cbSize = (uint)Marshal.SizeOf(typeof(SP_DID));
                if (!SetupDiEnumDeviceInterfaces(set, IntPtr.Zero, ref g, i, ref did))
                    break;

                uint required = 0;
                SP_DEVINFO devInfo = new SP_DEVINFO();
                devInfo.cbSize = (uint)Marshal.SizeOf(typeof(SP_DEVINFO));
                SetupDiGetDeviceInterfaceDetail(set, ref did, IntPtr.Zero, 0,
                    out required, ref devInfo);
                if (required == 0) continue;

                IntPtr detail = Marshal.AllocHGlobal((int)required);
                try {
                    Marshal.WriteInt32(detail, IntPtr.Size == 8 ? 8 : 6);
                    if (!SetupDiGetDeviceInterfaceDetail(set, ref did, detail, required,
                            out required, ref devInfo)) continue;

                    string devicePath = Marshal.PtrToStringAuto(
                        new IntPtr(detail.ToInt64() + 4));
                    if (string.IsNullOrEmpty(devicePath)) continue;

                    IntPtr diskH = CreateFile(devicePath, 0, 0x3,
                        IntPtr.Zero, 3, 0, IntPtr.Zero);
                    if (diskH == new IntPtr(-1)) continue;

                    int diskNum = -1;
                    try {
                        int[] sdn2 = new int[3];
                        IntPtr buf2 = Marshal.AllocHGlobal(12);
                        try {
                            uint br;
                            if (DeviceIoControl(diskH, IOCTL_STORAGE_GET_DEVICE_NUMBER,
                                    IntPtr.Zero, 0, buf2, 12, out br, IntPtr.Zero)) {
                                Marshal.Copy(buf2, sdn2, 0, 3);
                                diskNum = sdn2[1];
                            }
                        } finally {
                            Marshal.FreeHGlobal(buf2);
                        }
                    } finally {
                        CloseHandle(diskH);
                    }

                    if (diskNum != targetNum) continue;

                    uint parent;
                    uint cr = CM_Get_Parent(out parent, devInfo.DevInst, 0);
                    if (cr != 0) {
                        status = "CM_Get_Parent cr=" + cr;
                        return -3;
                    }

                    int veto;
                    StringBuilder vname = new StringBuilder(260);
                    uint result = CM_Request_Device_Eject(parent, out veto,
                        vname, (uint)vname.Capacity, 0);
                    if (result == 0 && veto == 0) {
                        status = "ejected";
                        return 0;
                    }
                    status = "CM_Request_Device_Eject cr=" + result
                        + " veto=" + veto + " name=" + vname.ToString();
                    return result == 0 ? (1000 + veto) : (int)result;
                } finally {
                    Marshal.FreeHGlobal(detail);
                }
            }
            status = "no disk in device tree matches drive " + driveLetter;
            return -2;
        } finally {
            SetupDiDestroyDeviceInfoList(set);
        }
    }
}
"@
function Initialize-EjectType {
    if (-not ('VolumeEjector' -as [type])) {
        try {
            Add-Type -TypeDefinition $script:ejectType -ErrorAction Stop
        }
        catch {
            Write-Log 'WARN' "Could not compile VolumeEjector wrapper: $($_.Exception.Message)"
        }
    }
}

function Write-Log {
    param([string]$Level, [string]$Message)
    try {
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        "$ts [$Level] $Message" | Out-File -FilePath $script:LogPath -Append -Encoding utf8 -ErrorAction Stop
    }
    catch {
        # Logging is best-effort; never let it terminate the script.
    }
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

function Flush-Drive($driveLetter) {
    # Force-flush Windows' write cache for the drive. Returns $true on success.
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

function Eject-Device($driveLetter) {
    # Programmatic device-tree eject (CM_Request_Device_Eject). Returns
    # $true if the device was ejected; $false if we couldn't (caller falls
    # back to Eject-Drive's volume-level dismount).
    Initialize-EjectType
    if (-not ('VolumeEjector' -as [type])) {
        Write-Log 'WARN' 'VolumeEjector wrapper unavailable; skipping device-tree eject.'
        return $false
    }
    try {
        $status = ''
        $rc = [VolumeEjector]::RequestEject($driveLetter, [ref]$status)
        if ($rc -eq 0) {
            Write-Log 'INFO' "Ejected $driveLetter via CM_Request_Device_Eject"
            return $true
        }
        Write-Log 'WARN' "CM_Request_Device_Eject for $driveLetter rc=$rc ($status)"
    }
    catch {
        Write-Log 'WARN' "Eject-Device exception for $driveLetter`: $($_.Exception.Message)"
    }
    return $false
}

function Eject-Drive($driveLetter) {
    # Fallback path: cooperative volume dismount, then force-dismount.
    # Force is safe here because Flush-Drive already ran (writes are
    # durable on disk), so the only thing force closes is stale read
    # handles. We deliberately do NOT use Shell.Application.InvokeVerb("Eject"),
    # because that path shows Windows' "drive in use" dialog whose
    # Continue button forcibly dismounts and corrupts in-flight writes
    # (factory-reset hazard, bricked v2.39's test device).
    try {
        $vol = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter }
        if ($vol) {
            $result = $vol.Dismount($false, $false)
            if ($result.ReturnValue -eq 0) {
                Write-Log 'INFO' "Dismounted $driveLetter via Win32_Volume (cooperative)"
                return
            }
            Write-Log 'WARN' "Cooperative dismount returned $($result.ReturnValue) for $driveLetter; trying force"
            $result = $vol.Dismount($true, $false)
            if ($result.ReturnValue -eq 0) {
                Write-Log 'INFO' "Force-dismounted $driveLetter (data already flushed)"
                return
            }
            Write-Log 'WARN' "Force dismount returned $($result.ReturnValue) for $driveLetter"
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
    Write-Host "Flushing writes and ejecting $driveLetter..." -ForegroundColor Cyan
    Flush-Drive $driveLetter | Out-Null
    Start-Sleep -Seconds 1

    # Primary path: device-tree eject (Safely Remove Hardware equivalent).
    # Falls back to volume-level dismount if the device-tree call fails.
    if (-not (Eject-Device $driveLetter)) {
        Write-Log 'INFO' "Falling back to volume-level dismount for $driveLetter"
        Eject-Drive $driveLetter
    }

    if (-not (Wait-ForDriveGone $driveLetter)) {
        Write-Host ""
        Write-Host "*** WARNING ***" -ForegroundColor Red
        Write-Host "The device didn't disconnect automatically. DO NOT click 'Continue' on" -ForegroundColor Red
        Write-Host "any 'drive in use' dialog Windows may show -- that can corrupt the install" -ForegroundColor Red
        Write-Host "and brick the device, requiring a factory reset." -ForegroundColor Red
        Write-Host ""
        Write-Host "Instead:" -ForegroundColor Yellow
        Write-Host "  1. Click Cancel on any Windows dialog about the drive being in use." -ForegroundColor Yellow
        Write-Host "  2. Use 'Safely Remove Hardware' (system tray icon) to eject the Kobo." -ForegroundColor Yellow
        Write-Host "  3. Wait for Windows' notification that it's safe to remove." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter ONLY after the device has fully disconnected"
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
        $statusLine = '{0} of {1} files ({2}%)' -f $done, $total, $pct
        Write-Progress -Activity $activity -Status $statusLine -PercentComplete $pct
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
            $waitMsg = '  Still waiting... ({0} seconds). Make sure USB is plugged in and tap ''Connect USB'' on the device.' -f $elapsed
            Write-Host $waitMsg -ForegroundColor DarkYellow
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
    $dq = [char]34
    $pattern = "welcome-name\s*=\s*$dq([^$dq]*)$dq"
    if ($content -match $pattern) {
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
    $dq = [char]34
    $escaped = $name.Replace([string]$dq, '\' + $dq)
    $pattern = "welcome-name\s*=\s*$dq[^$dq]*$dq"
    $replacement = "welcome-name = $dq" + $escaped + $dq
    $patched = $content -replace $pattern, $replacement
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
        Exit-WithMessage 'Install package not found. Expected a folder matching ''plato-sangala-v*-sangala-install'' next to this script, or pass -InstallPath <path> explicitly.'
    }
    if (-not $UpdatePath -or -not (Test-Path $UpdatePath)) {
        Exit-WithMessage 'Update package not found. Expected a folder matching ''plato-sangala-v*-sangala-update'' next to this script, or pass -UpdatePath <path> explicitly.'
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
