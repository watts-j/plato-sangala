# tools/

Host-side investigation utilities. Run from a Windows machine with the
Kobo connected and "Connect USB" tapped.

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

Snapshots are written to `%USERPROFILE%\Desktop\Snapshots\<timestamp>-<label>\`.

## diff-snapshots.ps1

Compares two snapshot directories and prints what changed: key-file
size/mtime/sha256 deltas, files added/removed under `.kobo/`, and new
lines in `autostart.log`.

```powershell
.\tools\diff-snapshots.ps1 `
    -A "$env:USERPROFILE\Desktop\Snapshots\20260525-100000-boot1" `
    -B "$env:USERPROFILE\Desktop\Snapshots\20260525-101500-boot2"
```

## Factory-reset investigation protocol (CLAUDE-STATE Lessons #32/#33/#34/#35)

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
