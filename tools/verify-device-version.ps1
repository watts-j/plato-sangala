# verify-device-version.ps1
#
# Identifies which Sangala build is currently on a connected Kobo.
#
# Primary signal: $Drive\.adds\plato\VERSION (shipped from the build whose
# workflow includes the VERSION-stamp step, 2026-05-25+).
#
# Fallback signals (for older installs that predate the VERSION file):
# - SHA256 of the plato binary, plato.sh, and Settings.toml
# - First-line comment in Settings.toml (often carries a version-ish string)
# - Plato startup banner in info.log (Plato's own CARGO_PKG_VERSION, not the
#   Sangala git tag, but still useful as a sanity check)
#
# Usage:
#   .\tools\verify-device-version.ps1
#   .\tools\verify-device-version.ps1 -Drive D:

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Drive
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

Write-Host ('Device: {0}' -f $Drive)
Write-Host ''

# Primary: VERSION file.
$versionFile = Join-Path $Drive '.adds\plato\VERSION'
if (Test-Path $versionFile) {
    $stamp = (Get-Content -LiteralPath $versionFile -Raw).Trim()
    Write-Host ('Sangala version: {0}' -f $stamp) -ForegroundColor Green
    Write-Host ('  source: {0}' -f $versionFile)
} else {
    Write-Host 'Sangala version: UNKNOWN (no VERSION file -- predates the 2026-05-25 stamp).' -ForegroundColor Yellow
    Write-Host '  Fall back to the fingerprint signals below and compare to a known release.'
}
Write-Host ''

# Fallback signals.
Write-Host '--- fingerprints ---'

function Show-Hash {
    param([string]$Label, [string]$Path)
    if (Test-Path $Path) {
        $info = Get-Item -LiteralPath $Path
        $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
        Write-Host ('  {0,-20} {1}  size={2}  mtime={3}' -f $Label, $hash.Substring(0,16), $info.Length, $info.LastWriteTime.ToString('o'))
    } else {
        Write-Host ('  {0,-20} (missing)' -f $Label)
    }
}

Show-Hash 'plato binary'   (Join-Path $Drive '.adds\plato\plato')
Show-Hash 'plato.sh'       (Join-Path $Drive '.adds\plato\plato.sh')
Show-Hash 'Settings.toml'  (Join-Path $Drive '.adds\plato\Settings.toml')
Show-Hash 'KoboRoot.tgz'   (Join-Path $Drive '.kobo\KoboRoot.tgz')
Write-Host ''

# Settings.toml first comment line (often carries a version string by hand).
$settings = Join-Path $Drive '.adds\plato\Settings.toml'
if (Test-Path $settings) {
    $firstComment = Get-Content -LiteralPath $settings | Select-Object -First 3 | Where-Object { $_ -match '^\s*#' }
    if ($firstComment) {
        Write-Host '--- Settings.toml header ---'
        $firstComment | ForEach-Object { Write-Host ('  {0}' -f $_) }
        Write-Host ''
    }
}

# Plato startup banner in info.log (Plato's own version, not the Sangala tag).
$infoLog = Join-Path $Drive '.adds\plato\info.log'
if (Test-Path $infoLog) {
    $banner = Get-Content -LiteralPath $infoLog | Where-Object { $_ -match 'Plato\s+\d' } | Select-Object -First 1
    if ($banner) {
        Write-Host '--- Plato startup banner (upstream Plato version, not Sangala) ---'
        Write-Host ('  {0}' -f $banner.Trim())
        Write-Host ''
    }
}

if (-not (Test-Path $versionFile)) {
    Write-Host 'To identify the exact Sangala tag for a pre-2026-05-25 install:' -ForegroundColor Yellow
    Write-Host '  1. Download the install or update tarball for the suspected version from GitHub Releases.'
    Write-Host '  2. Extract and compute SHA256 of the plato binary inside.'
    Write-Host '  3. Compare against the "plato binary" hash above.'
    Write-Host '  Once a device is reinstalled with a 2026-05-25+ build, the VERSION file will be present.'
}
