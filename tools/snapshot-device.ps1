# snapshot-device.ps1
#
# Pulls a labeled snapshot of a connected Kobo's user partition state for
# the factory-reset investigation (CLAUDE-STATE.md, Lessons #32/#34).
#
# Usage:
#   .\tools\snapshot-device.ps1 -Label boot1
#   .\tools\snapshot-device.ps1 -Label boot2 -Drive D:
#
# Run between every power cycle of the multi-cycle test. Diff successive
# snapshots to identify what's drifting on the device until Kobo's
# recovery trips.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Label,

    [Parameter()]
    [string]$Drive,

    [Parameter()]
    [string]$OutDir = (Join-Path $env:USERPROFILE 'Desktop\Snapshots')
)

$ErrorActionPreference = 'Stop'

if (-not $Drive) {
    $kobo = Get-Volume -ErrorAction SilentlyContinue |
            Where-Object { $_.FileSystemLabel -eq 'KOBOeReader' } |
            Select-Object -First 1
    if (-not $kobo) {
        Write-Error "Kobo not detected. Plug in and tap 'Connect USB' on the device."
        return
    }
    $Drive = '{0}:' -f $kobo.DriveLetter
}

if (-not (Test-Path "$Drive\.kobo")) {
    Write-Error "No .kobo directory on $Drive -- is this a Kobo?"
    return
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dest = Join-Path $OutDir ('{0}-{1}' -f $timestamp, $Label)
New-Item -ItemType Directory -Path $dest -Force | Out-Null

Write-Host "Snapshotting $Drive to $dest"

# Mirror .kobo/ but skip the screensaver dir (large, not relevant).
$koboDest = Join-Path $dest '.kobo'
$null = robocopy "$Drive\.kobo" $koboDest /MIR /XD screensaver /NFL /NDL /NJH /NJS /NP /R:1 /W:1

# Pull Plato's logs and settings.
$adds = Join-Path $dest '.adds\plato'
New-Item -ItemType Directory -Path $adds -Force | Out-Null
foreach ($f in 'Settings.toml','info.log','dictionary.log','autostart.log') {
    $src = Join-Path $Drive (Join-Path '.adds\plato' $f)
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $adds $f) -Force
    }
}

# Build a manifest with size, mtime, and sha256 for the files most likely
# to drift between boots. Plato's binary and plato.sh shouldn't change
# without a reinstall; if they do, that's a smoking gun.
$keyFiles = @(
    '.kobo\version',
    '.kobo\Kobo\Kobo eReader.conf',
    '.kobo\KoboReader.sqlite',
    '.adds\plato\plato',
    '.adds\plato\plato.sh',
    '.adds\plato\Settings.toml'
)

$manifest = [ordered]@{
    timestamp = $timestamp
    label     = $Label
    drive     = $Drive
    files     = [ordered]@{}
}

foreach ($rel in $keyFiles) {
    $path = Join-Path $Drive $rel
    if (Test-Path $path) {
        $info = Get-Item -LiteralPath $path
        $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        $manifest.files[$rel] = [ordered]@{
            size   = $info.Length
            mtime  = $info.LastWriteTime.ToString('o')
            sha256 = $hash
        }
    } else {
        $manifest.files[$rel] = $null
    }
}

# Catalog everything in .kobo (not just key files) so any new/removed file
# shows up in a diff.
$catalogPath = Join-Path $dest 'catalog-kobo.txt'
Get-ChildItem "$Drive\.kobo" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\screensaver\\' } |
    Sort-Object FullName |
    ForEach-Object {
        '{0,12} {1} {2}' -f $_.Length, $_.LastWriteTime.ToString('o'), ($_.FullName.Substring($Drive.Length))
    } | Set-Content -LiteralPath $catalogPath -Encoding UTF8

$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $dest 'manifest.json') -Encoding UTF8

Write-Host ("Snapshot saved: {0}" -f $dest)
Write-Host "Next: power off, wait 20-30s, power on, use device (open a book, dictionary lookup), connect USB, run again with the next label (e.g., 'boot2')."
