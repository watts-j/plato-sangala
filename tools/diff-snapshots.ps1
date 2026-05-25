# diff-snapshots.ps1
#
# Compares two snapshot directories produced by snapshot-device.ps1 and
# prints what changed between them. Use to identify cumulative state
# drift across boots in the factory-reset investigation.
#
# Usage:
#   .\tools\diff-snapshots.ps1 -A '...\20260525-100000-boot1' -B '...\20260525-101500-boot2'

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$A,

    [Parameter(Mandatory = $true)]
    [string]$B
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $A)) { Write-Error "Snapshot A not found: $A"; return }
if (-not (Test-Path $B)) { Write-Error "Snapshot B not found: $B"; return }

$manA = Get-Content (Join-Path $A 'manifest.json') -Raw | ConvertFrom-Json
$manB = Get-Content (Join-Path $B 'manifest.json') -Raw | ConvertFrom-Json

Write-Host ("A: {0}  ({1})" -f $manA.label, $manA.timestamp)
Write-Host ("B: {0}  ({1})" -f $manB.label, $manB.timestamp)
Write-Host ''

# 1. Key-file changes (size / mtime / hash).
$keys = @($manA.files.PSObject.Properties.Name + $manB.files.PSObject.Properties.Name | Select-Object -Unique)
Write-Host '--- key file changes ---'
foreach ($k in $keys) {
    $a = $manA.files.$k
    $b = $manB.files.$k
    if ($null -eq $a -and $null -eq $b) { continue }
    if ($null -eq $a) { Write-Host ('  + {0} (new in B)' -f $k); continue }
    if ($null -eq $b) { Write-Host ('  - {0} (gone in B)' -f $k); continue }
    if ($a.sha256 -ne $b.sha256) {
        Write-Host ('  ~ {0}' -f $k)
        Write-Host ('      size : {0} -> {1} ({2:+#;-#;0})' -f $a.size, $b.size, ($b.size - $a.size))
        Write-Host ('      mtime: {0} -> {1}' -f $a.mtime, $b.mtime)
        Write-Host ('      sha  : {0}... -> {1}...' -f $a.sha256.Substring(0,12), $b.sha256.Substring(0,12))
    }
}

# 2. .kobo catalog changes (any new/removed files in .kobo/).
Write-Host ''
Write-Host '--- .kobo catalog changes ---'
$catA = Get-Content (Join-Path $A 'catalog-kobo.txt') -ErrorAction SilentlyContinue
$catB = Get-Content (Join-Path $B 'catalog-kobo.txt') -ErrorAction SilentlyContinue

$extractPath = { param($line) ($line -split ' ', 3)[2] }

$setA = $catA | ForEach-Object { & $extractPath $_ } | Sort-Object -Unique
$setB = $catB | ForEach-Object { & $extractPath $_ } | Sort-Object -Unique

$added   = Compare-Object $setA $setB | Where-Object { $_.SideIndicator -eq '=>' } | ForEach-Object { $_.InputObject }
$removed = Compare-Object $setA $setB | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject }

if ($added)   { foreach ($f in $added)   { Write-Host ('  + {0}' -f $f) } }
if ($removed) { foreach ($f in $removed) { Write-Host ('  - {0}' -f $f) } }
if (-not $added -and -not $removed) { Write-Host '  (no file additions or removals)' }

# 3. Plato's autostart.log diff (text comparison).
$autoA = Join-Path $A '.adds\plato\autostart.log'
$autoB = Join-Path $B '.adds\plato\autostart.log'
if ((Test-Path $autoA) -and (Test-Path $autoB)) {
    Write-Host ''
    Write-Host '--- new lines in autostart.log (B since A) ---'
    $linesA = Get-Content $autoA -ErrorAction SilentlyContinue
    $linesB = Get-Content $autoB -ErrorAction SilentlyContinue
    $newLines = $linesB | Select-Object -Skip $linesA.Count
    if ($newLines) { $newLines | ForEach-Object { Write-Host ('  | {0}' -f $_) } }
    else { Write-Host '  (no new lines)' }
}

Write-Host ''
Write-Host 'Tip: for the deepest comparison of KoboReader.sqlite, open both copies in a SQLite viewer and run a row-count diff per table.'
