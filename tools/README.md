# tools/

Host-side investigation utilities. Run from a Windows machine with the
Kobo connected and "Connect USB" tapped.

## verify-device-version.ps1

Reports which Sangala build is currently installed on a connected Kobo.

```powershell
.\tools\verify-device-version.ps1
```

Primary signal: `.adds\plato\VERSION` (a one-line file containing the
git tag, shipped from the 2026-05-25 build onward). For older installs
that predate the VERSION stamp, it prints SHA256 fingerprints of the
plato binary, plato.sh, Settings.toml, and KoboRoot.tgz so you can
compare against a known release tarball.

## snapshot-device.ps1

Pulls a labeled snapshot of the Kobo's user partition state (`.kobo/`,
Plato's logs and `Settings.toml`, manifest with sha256 of key files).
Use between every power cycle to find what's drifting until Kobo's
recovery factory-resets the device.

```powershell
.\tools\snapshot-device.ps1 -Label boot1
# power off, wait 20-30s, power on, open a book, dictionary lookup
# tap Connect USB
.\tools\snapshot-device.ps1 -Label boot2
# ...
```

Snapshots are written to `%USERPROFILE%\Desktop\Install\<timestamp>-<label>\` by default. Override with `-OutDir <path>`.

**Note on PowerShell execution policy:** if you see "running scripts is disabled on this system," run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` once per PowerShell window before invoking any of these scripts.

## diff-snapshots.ps1

Compares two snapshot directories and prints what changed: key-file
size/mtime/sha256 deltas, files added/removed under `.kobo/`, and new
lines in `autostart.log`.

```powershell
.\tools\diff-snapshots.ps1 `
    -A "$env:USERPROFILE\Desktop\Install\20260525-100000-boot1" `
    -B "$env:USERPROFILE\Desktop\Install\20260525-101500-boot2"
```

## Factory-reset investigation protocol (CLAUDE-STATE Lessons #29/#31)

1. Install on a fresh Clara BW.
2. After install completes and Plato launches: `snapshot-device.ps1 -Label boot1-post-install`.
3. Open a book, look up a word, close the book. Power off, wait 20–30s.
4. Power on. After Plato is up, snapshot: `boot2`.
5. Repeat steps 3–4 with incremented labels (`boot3`, `boot4`, ...).
6. When the device factory-resets, the last successful snapshot before the reset is the most informative.
7. `diff-snapshots.ps1` between consecutive boots to see what's drifting.

The expectation: between successive snapshots, something in `.kobo/`
should change in a way that escalates each boot — a counter, a log
file growing, or new files appearing. That's the marker Kobo's
bootloader is using to decide the system is broken.
