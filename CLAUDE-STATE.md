# Plato Sangala — Project State

Last updated: 2026-05-08

## Working Conventions (read first)

Long sessions on this repo have failed in two opposing ways:

1. **Over-trusting accumulated context** — earlier versions of this file carried claims like "v2.20 worked" that turned out to be wrong, and acting on them cost real cycles. This file is **not** authoritative for anything git can answer.
2. **Discarding accumulated context** — treating each turn as fresh causes forgotten work, repeated questions, and missed steps in multi-step flows.

Avoid both. Specifically:

- **Maintain a tracked task list for the session via the TodoWrite tool.** The list is the source of truth for what's pending vs. done. Don't rely on memory of conversation flow.
- **Verify load-bearing facts before claiming or acting.** Run `git tag -l`, `git log --oneline`, `git ls-tree`, or use GitHub MCP read tools to check actual state — especially for tag positions, release flags (latest/pre-release), branch tips, and shipped artifact contents. Trust git/GitHub over prose in this file.
- **Inspect what was actually built before declaring a fix shipped.** Download the release tarball and read the scripts inside. The build succeeding does not mean the right code shipped.
- **Be explicit when extrapolating.** If a recommendation is based on community lore (e.g., `/tmp/end_of_animation` as Nickel's "ready" marker, KFMon's FTE-detection mechanism), flag it as unverified rather than asserting it.

## Reference Versions

- **v2.48-sangala (next)** — Tip of `claude/customize-plato-ui-1Edbm`. Three follow-on fixes after v2.47's device test (2026-05-08) revealed remaining friction: (1) installer adds `IOCTL_STORAGE_EJECT_MEDIA` before `CM_Request_Device_Eject` so the Kobo exits USBMS automatically — without it, the host-side eject worked cleanly but the device's screen stayed on "Connected" until the user yanked the cable; (2) `convert-dictionary.sh` swaps `trap 'exit 1' ERR` (busybox doesn't recognize the `ERR` signal) for `set -e`, which busybox does support — silences `trap: ERR: invalid signal specification` log noise and gives us actual exit-on-error; (3) Plato's `query_to_content` auto-triggers `load_dictionaries()` if the map is empty at lookup time, so the first dictionary lookup after a fresh install no longer requires a manual "Reload Dictionaries" menu pick (the StarDict-to-dictd conversion finishes after Plato's startup-time `load_dictionaries()` already ran). Not yet tagged.
- **v2.47-sangala** — First v2.x build whose CLI installer doesn't corrupt FAT during eject. Three fixes after v2.46's device test failed: (a) installer uses `CM_Request_Device_Eject` (Safely-Remove-Hardware path) before falling back to volume dismount — confirmed working via `Ejected F: via CM_Request_Device_Eject` log lines and absence of `fsck.fat` corrections in `info.log`; (b) `convert-dictionary.sh` falls back to `cp` when `ln` fails on vfat — turned out to be defensive-only since busybox's missing `ERR` trap meant the original `ln` failure wasn't actually exiting the script (see v2.48); (c) conversion stdout/stderr captured to `/mnt/onboard/.adds/plato/dictionary.log` — confirmed working, gave first direct evidence of the recovery path engaging successfully. Successful end-to-end install verified on factory-reset Clara BW, with two caveats: (1) cable yank still required because no SCSI EJECT, and (2) "Reload Dictionaries" still required for the first lookup. Both fixed in v2.48.
- **v2.46-sangala** — **Has two known regressions; do not redistribute.** (a) Installer eject path leaves FAT dirty, causing fsck-truncation of dict.dz and several EPUBs on next boot. (b) `convert-dictionary.sh`'s unconditional `ln` fails on vfat → conversion can't create backups even with intact sources (though see v2.47 note: the actual `ln` failure was tolerated because busybox's missing `ERR` trap silently skipped it). Identical commit (`6d0f08a`) to v2.45. Both should be removed or marked broken.
- **v2.45-sangala** — Same broken commit as v2.46. Welcome label is now just the configured name (e.g., "Jo") rather than "Welcome, Jo!". `convert-dictionary.sh` was reworked to be crash-safe via hardlink backups (Option G), but the hardlink call breaks on vfat — see v2.47/v2.48 entries above.
- **v2.44-sangala** — `plato-autostart.sh` now skips the 5 s post-DB grace on subsequent boots, so Nickel does not become visible after install (only the loading dots → Plato startup). Factory-reset path unchanged. Untested on device.
- **v2.43-sangala** — PS 5.1 string parser fix: `"$pct%"` rebuilt with the format operator. Earlier installer cycles for v2.41/v2.42 hit cascading parse errors in PS 5.1 only.
- **v2.42-sangala** — Skipped functionally; same content as v2.41.
- **v2.41-sangala** — First version with `Flush-Drive` (FlushFileBuffers via P/Invoke) called before each eject. Removed `Shell.Application.InvokeVerb("Eject")` fallback because its "drive in use" Continue dialog forcibly dismounted with pending writes still in cache and **factory-reset-bricked the test device on v2.39 install**. v2.41 also adds force-dismount fallback after flush (safe because data is already durable).
- **v2.40-sangala** — GUI installer parity with the CLI (same Disconnect-Kobo + retry/cancel error UI; same name-prompt on fresh install + on-update name preservation).
- **v2.39-sangala** — First GUI installer build (WinForms wizard); CLI prompts for the reader's name and preserves it on update. Bricked the test device because the eject path showed Windows' "drive in use" dialog and Continue was clicked while KoboRoot.tgz was mid-write. **Do not redistribute v2.39.**
- **v2.38-sangala** — Stable build, validated on Clara BW (2026-05-06). Title Menu's "About" entry replaced with "Home" → switches to the empty Menu library to show the welcome screen. Welcome label uses new `WELCOME_STYLE` (= 2× `NORMAL_STYLE`). `.Resources/About/Sangala Reader Initiative.epub` flattened to `.Resources/`.
- **v2.37-sangala** — Superseded. Consolidated welcome screen into a single non-tap-handling `WelcomeScreen` view; gated welcome rendering on `at_library_root`; removed the 30 px top padding.
- **v2.36-sangala** — Superseded. First version to ship the resized 1072×772 transparent `home.png`.
- **v2.35-sangala** — Skipped (tag landed on the wrong commit before the new image had pushed).
- **v2.34-sangala** — First version with the home landing page (image + welcome text via `WelcomeScreen`), `install-sangala.zip` packaging, and the .ps1 globbing for `plato-sangala-v*-sangala-{install,update}` rather than hardcoding a version.
- **v2.33-sangala** — Skipped (tag landed on the v2.32 commit; duplicate release object).
- **v2.32-sangala** — Previous stable build, validated on factory-reset Clara BW (2026-05-06). Backgrounded dictionary conversion in `plato.sh`. `plato-autostart.sh` waits for `pidof nickel` + `KoboReader.sqlite` (60 s cap) + 5 s grace.
- **v2.31-sangala** — Pre-release; superseded by v2.32. Hangs on factory-reset (`sleep 12` too short).
- **v2.30-sangala** — Older stable. Verified on factory-reset Clara BW.
- **v2.28-sangala** — Failed KFMon experiment. Do not use.
- **v2.27-sangala** — Pre-fix layout. First boot hangs on factory-reset.
- **v2.19-sangala** — Last KFMon + NickelMenu build.
- **v2.3-sangala-full-build** — Original baseline. Pre-Clara BW.

## Fresh install hang

**Cause.** `plato-autostart.sh` in v2.20–v2.27 used `pidof nickel` + a fixed `sleep 9` before calling `plato.sh`. On factory-reset Clara BW, Nickel takes longer than 9s to finish its boot animation phase, so plato.sh kills Nickel mid-init and the loading dots loop runs forever.

**v2.28 attempt (failed).** Reintroduced KFMon's `on_boot = true` from v2.3's KoboRoot.tgz and kept plato-autostart.sh as a "fallback". v2.3's `on-animator.sh` both starts KFMon and forks plato-autostart.sh; both then call plato.sh, which calls `killall -TERM nickel ... fmon`, and they race each other. Every boot hung on dots. Reverted in v2.29.

**v2.29 fix.** Stay on v2.27's minimal KoboRoot.tgz layout; bump `sleep 9` to `sleep 12` in plato-autostart.sh.

**Recovery from v2.28.** Factory reset is the cleanest path. Without a reset, installing v2.29 will overwrite `on-animator.sh` with the slim no-KFMon version, leaving the v2.3-derived KFMon binaries inert in `/usr/local/kfmon/`. **Note on factory-reset gesture:** the Clara BW has only a power button (no LIGHT button, no pinhole) — earlier sessions of this file claimed "hold LIGHT during power-on for ~10s", which was wrong. Do not repeat that. The user knows the correct procedure for their device; if you need it, ask rather than guess.

## Next Tag Number

**v2.48-sangala** (will ship as pre-release; promote manually on GitHub Releases after device test passes). Adds SCSI EJECT, replaces busybox-incompatible `trap ERR` with `set -e`, and auto-reloads dictionaries on first empty lookup — see Reference Versions.

**Tagging discipline:** before suggesting any next tag number, fetch tags and check `git ls-remote --tags origin | grep sangala | sort -V | tail` (or use `mcp__github__list_tags`). This session shipped a duplicate v2.46 tag because the assistant reasoned about tag positions from a misread `git rev-parse v2.X-sangala^{commit}` output (PowerShell ate the `{commit}` brace, the resulting `^` returned the parent commit, and the assistant treated that as the tag's commit). Always single-quote refs with `{}` in PowerShell: `'v2.X-sangala^{commit}'`.

## Welcome Name

As of v2.45 the home screen renders **just the configured name** (e.g., "Jo"), not "Welcome, Jo!". The text comes from the `welcome-name` field in the `[home]` section of `Settings.toml`. On device, that's `/mnt/onboard/.adds/plato/Settings.toml`; the placeholder shipped in builds is `welcome-name = "[name]"`.

To change a single device's name: edit that file directly (over USB) and reboot. Updates overwrite `Settings.toml` from the package, so per-device names need to be patched at install time.

To change the default that ships in every new build: edit `sangala/Settings.toml` in the repo.

The PowerShell installers prompt for the reader's name on a fresh install and patch the field automatically before copying. On a standalone update they read the existing on-device value and patch the update package with it, so updates don't revert the placeholder.

## Package Structure

Two packages produced per release; a fresh install runs both in sequence:

- **`-install.tar.gz`** — Bootstrap. System partition (`KoboRoot.tgz` with `on-animator.sh` + `plato-autostart.sh`) plus user-partition non-content (Plato app, `Settings.toml`, dictionaries, screensaver, `Kobo eReader.conf`). No EPUBs. ~30MB. Triggers Nickel's "updating" screen and an auto-reboot.
- **`-update.tar.gz`** — Content. Same user-partition files as install **plus** the dot-prefixed library skeleton (EPUBs). No `KoboRoot.tgz`. ~80MB.
- **`install-sangala.ps1`** — Separate download. PowerShell installer script.

Fresh install flow: copy install → eject → device updates and reboots → reconnect → copy update → eject. Subsequent updates just reapply the update package.

**Installer scripts** (both shipped inside `install-sangala.zip`):
- `sangala/installer/install-sangala-gui.ps1` — WinForms wizard. Connect → detect → (fresh install: prompt for reader's name) → progress bar → eject → wait-for-reconnect → progress bar → done. Background runspace handles the long file copies; a 500 ms timer polls progress and reconnect state.
- `sangala/installer/install-sangala.ps1` — Console flow with the same logic.
- Both: auto-detect the Kobo by `KOBOeReader` volume name; determine install vs. update by checking for `\.adds\plato\plato`; clean up old non-dot library folders; log to `install-sangala.log` next to the script; patch `welcome-name` in the package's `Settings.toml` (fresh install) or read it from the device and patch the update package (standalone update); call `FlushFileBuffers` via P/Invoke before any eject; **eject path (v2.48+)**: (1) `IOCTL_STORAGE_EJECT_MEDIA` after FSCTL_LOCK_VOLUME + FSCTL_DISMOUNT_VOLUME to send SCSI EJECT (kicks the Kobo's USBMS handler out of USBMS mode so its screen doesn't stay on "Connected" until the cable is yanked), then (2) `CM_Request_Device_Eject` (Safely-Remove-Hardware equivalent, via SetupAPI/Cfgmgr32) to detach the device from Windows. Falls back to cooperative `Win32_Volume.Dismount` then force-dismount only if both programmatic paths fail. **Never** call `Shell.Application.InvokeVerb("Eject")` — that path's "drive in use" Continue dialog is what bricked v2.39's test device.

**Eject corruption (v2.46 finding).** The flush + cooperative `Win32_Volume.Dismount` path returns success but only releases the volume from the host's filesystem stack. The USB device stays attached and the device-side flash controller can miss the SCSI SYNCHRONIZE CACHE that a real eject would issue. On the v2.46 install on a Clara BW, `install-sangala.log` reported "Dismounted F: via Win32_Volume (cooperative)" both times, but `fsck.fat` at next boot found the dirty bit set, truncated `dictionary.dict.dz` from ~32 MB to ~14 MB, and reported six EPUBs corrupted ("Could not find EOCD"). Reclaimed clusters were salvaged into `FSCK0000.REC`/`FSCK0001.REC` in the drive root. v2.47 fixes this by issuing a real device eject via `CM_Request_Device_Eject` before falling back to the volume dismount.

**Phase 2 reconnect requires manual user action.** After the post-Phase-1 reboot, the device boots straight into Plato — Plato does not auto-enter USB Mass Storage Mode just because a cable is plugged in. The installer's "wait for reconnect" loop polls the host until the drive letter reappears, but the drive only reappears after the user taps **Connect USB** in Plato's burger menu. The CLI installer logs this in `Wait-ForKobo` ("Make sure USB is plugged in and tap 'Connect USB' on the device.") but it could be more prominent. Auto-detecting the reconnect would require Plato itself to enter USBMS on cable detect; out of scope for the installer.

**PS 5.1 parser quirks the installers must work around** (each one was hit during this session):
1. `"$var%"` inside double quotes — PS 5.1 reads `%` as the modulo operator and bails. Use `'{0}%' -f $var` (single-quoted format string + `-f`).
2. `"text ($var word)"` — paren-then-bare-variable inside a double-quoted string trips the same parser. Use the format-operator form.
3. `'... "([^"]*)" ...'` — single-quoted regex with embedded `"` and `[`. PS 5.1 mis-parses; use `[char]34` substituted into a normal double-quoted regex string instead.
4. `here-string @' ... '@` opener — also mis-detected in some PS 5.1 builds (LF vs CRLF line ending sensitivity?). Avoid for short patterns; `[char]34` is safer.
5. Em-dash `—` and other non-ASCII characters — PS 5.1 reads UTF-8 files as Windows-1252 unless they have a BOM. Use ASCII-only (`--`).

**Validation loop**: when iterating the installer scripts, run a parser pre-flight before pushing for CI. From PS 5.1 in the install directory:
```powershell
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile('install-sangala.ps1', [ref]$null, [ref]$errors)
$errors | Select-Object Message, @{n='Line';e={$_.Extent.StartLineNumber}}, @{n='Col';e={$_.Extent.StartColumnNumber}} | Format-Table -AutoSize
```
This shows every parse error in one pass instead of fixing one and rediscovering the next from the cascade.

## Branch

`claude/customize-plato-ui-1Edbm`

## User Working Directory

`C:\Users\jbw3r\plato-sangala`

## Device

Kobo Clara BW (model spaBW/spaBWTPV), 1072x1448 @ 300 DPI. **Hardware buttons: power only.** No LIGHT button, no pinhole reset. Do not invent a button-combo factory-reset gesture from memory of other Kobos — earlier sessions repeatedly wrote "hold LIGHT during power-on" and were corrected. If you need the reset gesture for a recovery instruction, ask the user.

## Architecture

- Auto-launch: `plato-autostart.sh` in system partition (installed via KoboRoot.tgz). Waits for `pidof nickel`, then for `/mnt/onboard/.kobo/KoboReader.sqlite` to exist (60s cap, near-zero on subsequent boots), plus a 5s grace period; then `pkill -f on-animator` and `exec /mnt/onboard/.adds/plato/plato.sh`.
- Dictionary conversion (`convert-dictionary.sh`) is forked into the background by `plato.sh` so it doesn't block Plato startup. First-launch dictionary lookups would otherwise fail until conversion completes — but as of v2.48, Plato's `query_to_content` auto-rescans `dictionaries/` whenever the dictionary map is empty at lookup time, so once conversion finishes the next lookup picks it up without needing a manual "Reload Dictionaries". Output is captured to `/mnt/onboard/.adds/plato/dictionary.log` — pull this over USB if conversion appears to fail; it shows the timestamped start/end markers, recovery-path hits, and any tool errors.
- **`/mnt/onboard` is vfat or exFAT** — neither supports hardlinks. `ln src dst` returns `EPERM` on these filesystems. This affected v2.45/v2.46 because Option G's crash-safe rework called `ln` unconditionally for backup snapshots; v2.47+ falls back to `cp` on `ln` failure (cost: ~58 MB temporary disk during conversion, cleaned up on success). Do not rewrite the conversion script to assume hardlinks work.
- **busybox `sh` doesn't support `trap '...' ERR`** — that's a bash extension. v2.45/v2.46/v2.47 all carried `trap 'exit 1' ERR` from upstream; busybox logged `trap: ERR: invalid signal specification` and silently didn't install the trap, so errors didn't propagate. v2.48 uses `set -e` instead (which busybox does support). Don't reintroduce `trap ... ERR` here.
- No KFMon, no NickelMenu.
- KoboRoot.tgz is the committed minimal `sangala/kobo-assets/KoboRoot.tgz` (~1KB): only `etc/init.d/on-animator.sh` (slim, no KFMon hook) and `usr/local/bin/plato-autostart.sh`.
- Dictionary: Wiktionary English (StarDict format), converted on-device on first use (~1-2 min)
- Metadata extraction: title and author only (series, year, publisher, categories ignored)
- Dictionary rendering: HTML-aware (definitions containing `<` rendered as HTML)
- Library folders: dot-prefixed (.STEM, .Humanities, etc.) to hide from Nickel's scanner
- EPUB font-size: pinch/spread gestures adjust by 0.5pt steps on reflowable docs

## Library Indices (Settings.toml)

| Index | Name       | Path                      |
|-------|------------|---------------------------|
| 0     | STEM       | /mnt/onboard/.STEM        |
| 1     | Humanities | /mnt/onboard/.Humanities  |
| 2     | Enrichment | /mnt/onboard/.Enrichment  |
| 3     | Resources  | /mnt/onboard/.Resources   |
| 4     | Vocational | /mnt/onboard/.Vocational  |
| 5     | Menu       | /mnt/onboard/.Menu        |

`selected-library = 5` (Menu — empty library, top bar always shows "Menu")

## Menu Tree

```
Menu (top bar — always shows "Menu" regardless of active library)
├── About                          → .Resources/About/
├── Enrichment
│   ├── Sangala Story Exchange
│   ├── Drama
│   ├── Fiction
│   ├── Nonfiction
│   └── Poetry
├── Humanities
│   ├── Fine Arts
│   ├── Geography
│   ├── History
│   ├── Languages
│   └── Literature in English
│       ├── Drama
│       ├── Fiction
│       ├── Nonfiction
│       └── Poetry
├── STEM
│   ├── Engineering
│   ├── Mathematics
│   │   ├── Algebra
│   │   ├── Calculus
│   │   ├── Geometry
│   │   └── Trigonometry
│   └── Science
│       ├── Biology
│       ├── Chemistry
│       └── Physics
├── Vocational
│   ├── Agriculture
│   ├── Clothing & Textiles
│   ├── Economics
│   ├── Entrepreneurship
│   └── Food & Nutrition
└── Resources
    └── REACH for Uganda Newsletters
```

## Burger Menu (hamburger icon)

- System Info
- Enable WiFi
- Applications (Calculator, Dictionary)
- Connect USB
- Power Off

(Removed: Invert Colors, Reboot)

## EPUBs Included

### .Enrichment/Drama
- A Doll's House - Henrik Ibsen
- A Midsummer Night's Dream - William Shakespeare
- Hamlet - William Shakespeare
- King John - William Shakespeare
- King Lear - William Shakespeare
- Oedipus Rex - Sophocles
- Oedipus at Colonus - Sophocles
- Richard III - William Shakespeare
- The Cherry Orchard - Anton Chekhov
- The Tempest - William Shakespeare

### .Enrichment/Fiction
- Crime and Punishment - Fyodor Dostoevsky
- Dracula - Bram Stoker
- Fables - Aesop
- Fathers and Children - Ivan Turgenev
- Flatland - Edwin A. Abbott
- Frankenstein - Mary Shelley
- Penrod - Booth Tarkington
- Pride and Prejudice - Jane Austen
- Saint Joan - George Bernard Shaw
- Short Fiction - Anton Chekhov
- Short Fiction - H. G. Wells
- Short Fiction - Herman Melville
- Short Fiction - Leo Tolstoy
- Short Fiction - O. Henry
- Short Science Fiction - Isaac Asimov
- The Country Wife - William Wycherley
- The Iliad - Homer
- The Odyssey - Homer
- The Verger - Somerset Maugham
- The Way of the World - William Congreve

### .Enrichment/Sangala Story Exchange
- A Leopard in the Forest

### .Enrichment/Nonfiction
- Essays - Henry David Thoreau
- South! The Story of Shackleton - Ernest Shackleton
- The Autobiography of Benjamin Franklin
- Walden - Henry David Thoreau
- Wild Animals I Have Known - Ernest Thompson Seton

### .Enrichment/Poetry
- Lyrical Ballads - William Wordsworth
- Poetry - William Carlos Williams
- Poetry - William Shakespeare

### .STEM/Science/Biology
- Photosynthesis (AP level)
- Photosynthesis (Grade 11)
- Photosynthesis (deeper)
- Photosynthesis (overview)
- Pigment Chromatography Lab
- Plant Transport

### .Resources
- Sangala Reader Initiative (About/)
- Newsletter (Fall 2025) - REACH for Uganda (REACH for Uganda Newsletters/)

## Session-End Handoff (2026-05-08, after v2.47 device test)

v2.47 was tested on factory-reset Clara BW. Core fixes confirmed working:
- `CM_Request_Device_Eject` cleanly detaches volume from host (no FAT corruption from host side)
- `convert-dictionary.sh` ran to completion (visible via `dictionary.log` `done:` line)
- Crash-safe recovery engaged when conversion was interrupted by Phase 2 USB-connect, restored sources from backups, and finished on the next boot
- Dictionary lookup worked after a manual "Reload Dictionaries" menu pick

Three remaining-friction items shipped in v2.48 (this branch's tip):
1. **SCSI EJECT** — installer adds `IOCTL_STORAGE_EJECT_MEDIA` (after `FSCTL_LOCK_VOLUME` + `FSCTL_DISMOUNT_VOLUME`) before `CM_Request_Device_Eject`. Without it, the Kobo's screen stayed on "Connected" until the cable was yanked. With it, Nickel's USBMS handler exits cleanly and the device transitions to KoboRoot.tgz processing on its own.
2. **`set -e` not `trap ERR`** — busybox `sh` rejected `trap 'exit 1' ERR` with `trap: ERR: invalid signal specification`, so the trap silently never fired. v2.48 uses `set -e` (busybox-supported).
3. **Auto-reload dictionaries on empty lookup** — Plato's `query_to_content` calls `context.load_dictionaries()` if `context.dictionaries.is_empty()`. First lookup after install no longer requires manually picking "Reload Dictionaries" from the title menu.

To pick up clean: tag v2.48 and retest. Watch for in `install-sangala.log`:

- `Sent IOCTL_STORAGE_EJECT_MEDIA to F:` (new INFO line) — confirms SCSI EJECT fired.
- `Ejected F: via CM_Request_Device_Eject` — same as v2.47, confirms host-side detach.
- Device's screen stops showing "Connected" on its own after each eject — **no cable yank required**. If a yank is still required, capture the `ScsiEject for F: failed (...)` WARN line; the SCSI EJECT path failed and we'll need to investigate the win32err.

After Phase 2 disconnect:
- After ~3 min idle, long-press a word → lookup works **without** manually picking "Reload Dictionaries".
- `dictionary.log` should show `convert-dictionary.sh done: Dictionary` with no `trap: ERR: invalid signal specification` warnings interleaved.

If v2.48 device test passes, promote on GitHub Releases. v2.45 and v2.46 should be marked broken or deleted (see Reference Versions).

Risks to watch for:

- **PS 5.1 parser regressions.** The `$ejectType` here-string grew with the new `ScsiEject` static method. Run `[System.Management.Automation.Language.Parser]::ParseFile` on both installer scripts from PS 5.1 before pushing the tag.
- **`IOCTL_STORAGE_EJECT_MEDIA` "drive in use" failures.** If the host has any stale handle on the volume (Search Indexer, antivirus, third-party file manager), the IOCTL may fail with `ERROR_DRIVE_LOCKED` or similar. The path swallows the failure (logs WARN, continues to `CM_Request_Device_Eject`), but the cable yank workaround would re-emerge. Lock+Dismount in the same C# function should normally close held handles.
- **Tag bookkeeping.** Always `git fetch origin --tags` first, then `mcp__github__list_tags` (or `git ls-remote --tags origin | sort -V`). Single-quote refs with `{}` in PowerShell.

## Single-package vs two-package (open question)

The two-package layout was introduced so subsequent updates don't re-trigger Nickel's "updating" reboot (`KoboRoot.tgz` only ships in `-install.tar.gz`). This adds friction during fresh installs: two ejects, manual Connect USB between them, conversion gets killed mid-run by Phase 2 USB-connect. Single-package would: one copy, one eject, conversion runs uninterrupted, but every standalone update would also trigger the Nickel reboot. Worth revisiting once v2.48 verifies clean — if the install experience is still rough, collapsing back to single-package may be net-better despite the slower update cadence.

## Known Issues / Pending

- **Fresh install hang**: fixed in v2.32. Validated on factory-reset Clara BW (2026-05-06). v2.44+'s no-grace-on-subsequent-boots optimization preserves the factory-reset path unchanged.

## Long-term TODO

- **Pre-convert dictionary in CI (Option B).** `plato.sh` currently forks `convert-dictionary.sh` into the background to avoid blocking Plato startup; first-launch dictionary lookups fail until conversion completes (multiple minutes on Clara BW). Better path: convert StarDict → dictd format in CI, ship only the `.dict.dz` + `.index`, no on-device conversion ever. The previous attempt (commit `306f5a6`, reverted in `4ec30af`) shipped a 79MB `.index` and was reverted with the note "76MB index too large for device RAM" — but the artifacts at `sangala/dictionaries-converted/` look malformed (multiple entries with empty headwords), suggesting the Python `convert-stardict.py` had a bug, not that Plato truly couldn't handle the index. Doing this right needs (1) a working non-ARM converter (e.g., `pyglossary`), and (2) a Clara BW memory test with the resulting index. Now that v2.47 fixes Option G's FAT bug, this is a nice-to-have rather than a blocker.

- **Reduce first-install boot time by deprioritizing background conversion.** v2.32 backgrounds `convert-dictionary.sh` so Plato can launch without waiting on it, but the conversion's disk I/O contends with Plato's startup reads on Clara BW's slow flash. Wrap the backgrounded call with `nice -n 19` and an initial `sleep 30` so Plato has uncontended I/O during its startup. Expected savings: 30–60 s on first boot.

- **Home landing page**: Implemented in `Shelf::update`'s empty-state branch via the single `WelcomeScreen` view. When the active library is intrinsically empty (no books and no subdirs anywhere — verified via `library.list(library.home, None, false)`) and both `home-image` and `welcome-name` are set in `[home]`, Shelf pushes a `WelcomeScreen` (image in the top 2/3 of its rect, scaled to fit via the document framework, plus the welcome label centered in the bottom 1/3) instead of the white filler. As of v2.45 the label is just the configured name; previously it was "Welcome, {name}!". Falls back to white filler if either setting is missing, the image fails to load, or the library has any content (so a search filter yielding zero matches in a populated library doesn't trigger the welcome screen). Also gated on `at_library_root` so a failed `load_library` (rare) doesn't paint the welcome image where the destination shelf should be.

## Key Lessons Learned

1. Never create custom system scripts (on-animator.sh) from scratch — use proven ones
2. KoboRoot.tgz is reprocessed every time files are loaded; separate install and update packages
3. `selected-library = X` works on its own but crashed when combined with HomeImage overlay
4. Dictionary pre-conversion in CI produced a 76MB index too large for device RAM
5. StarDict on-device conversion (v2.17 approach) works and is fast (~1-2 min first use)
6. Always check the reference version before making assumptions about package structure
7. The v2.3-sangala-full-build release on GitHub is the original source of KFMon/NickelMenu binaries
8. Plato reads `belongs-to-collection` for series metadata even when Calibre doesn't show it — strip unwanted metadata fields in extraction code
9. For long sessions, start fresh and read CLAUDE-STATE.md for context
10. Don't reach for a non-trivial fix until you've ruled out a one-line one. The fresh-install hang may simply need a slightly longer post-Nickel sleep, not a marker-based gate or KFMon revival.
11. Nickel ignores directories starting with `.` — use dot-prefixed library folders to prevent Nickel from scanning EPUBs
12. Shell glob `*` does not match dot-files/directories — use `shopt -s dotglob` in bash
13. v2.20 (commit `0189d82`) introduced the minimal KoboRoot.tgz and removed KFMon. v2.28 tried to undo that and made things worse — putting KFMon back alongside our plato-autostart.sh creates two competing launchers, since v2.3's on-animator.sh starts both. If KFMon is ever reintroduced, plato-autostart.sh must be removed (or made a no-op) at the same time.
14. Trust git history over CLAUDE-STATE.md. Verify claims against `git ls-tree`/`git diff` before acting on them.
15. Inspect the actual built artifact (download the install tarball, extract KoboRoot.tgz, read the scripts) before declaring a fix complete. Building correctly does not imply running correctly.
16. **Never use Windows' `Shell.Application.InvokeVerb("Eject")` on a Kobo mid-install.** The "drive in use" Continue dialog forcibly dismounts and discards Windows' lazy-write cache; if KoboRoot.tgz is still buffered, Nickel boots into a corrupted system update and factory-resets the device. v2.39 bricked a test device; v2.41 removed the Shell verb path. **`Win32_Volume.Dismount` cooperative isn't sufficient either** (v2.46 finding) — it returns success but only releases the volume from the FS stack, leaving the device-side flash controller without a SCSI SYNCHRONIZE CACHE. fsck.fat at next boot then truncates files. v2.47 uses `CM_Request_Device_Eject` (Safely-Remove-Hardware path via SetupAPI/Cfgmgr32) for a real device-level eject before falling back to the volume dismount.
17. **PowerShell 5.1 has multiple string-parser quirks that PS 7 doesn't share.** `"$var%"`, `"text ($var word)"`, single-quoted regex with embedded `"` and `[`, here-string opener detection, non-ASCII characters — every one of these tripped this session. Run `[System.Management.Automation.Language.Parser]::ParseFile` from PS 5.1 to pre-flight before pushing.
18. **Tag refs with `{}` need single quotes in PowerShell.** `git rev-parse v2.X-sangala^{commit}` becomes `git rev-parse v2.X-sangala^` (returning the parent commit) when PS 5.1 strips the brace. Always: `git rev-parse 'v2.X-sangala^{commit}'`.
19. **`/mnt/onboard` is FAT — no hardlinks.** `ln src dst` returns `EPERM` on vfat/exFAT. Any conversion script using `ln` for backup snapshots needs an `|| cp` fallback or it'll exit silently before doing any work (v2.45 Option G regression).
20. **An eject log line saying "success" is not evidence the device flushed.** v2.46's `install-sangala.log` happily reported "Dismounted F: via Win32_Volume (cooperative)" while the FAT was being left dirty. Confirm an eject worked by either: (a) checking that the drive letter actually disappeared from the host (`Test-Path "$drive\"` returns false), and (b) inspecting `info.log` from the next boot for any `fsck.fat` output — if fsck ran with corrections, the previous eject was unsafe.
21. **busybox `sh` doesn't recognize `trap '...' ERR`.** It's a bash extension. busybox logs `trap: ERR: invalid signal specification` and silently doesn't install the trap, so errors don't propagate. Use `set -e` instead (busybox supports it). Discovered when v2.47's `dictionary.log` showed the trap-installation error on every conversion attempt — the entire premise of "the failed `ln` exits the script and conversion never runs" turned out to be false because the trap never fired in the first place. (`ln` failure on FAT was real, but the script kept going past it.)
22. **`CM_Request_Device_Eject` alone doesn't tell USB MSC devices to exit USBMS mode.** It cleanly detaches the volume from Windows but doesn't issue SCSI EJECT. On Kobo, that means the device's screen stays on "Connected" until the cable is physically yanked. Send `IOCTL_STORAGE_EJECT_MEDIA` (after `FSCTL_LOCK_VOLUME` + `FSCTL_DISMOUNT_VOLUME`) BEFORE `CM_Request_Device_Eject` to make Nickel's USBMS handler exit cleanly. v2.48 added this; before that, every install required two cable yanks.
23. **Plato's `load_dictionaries()` runs once at startup.** It does not watch the filesystem. If the StarDict→dictd conversion finishes after Plato launched (which is the normal case on fresh install), the user has to manually pick "Reload Dictionaries" from the title menu or restart Plato. v2.48 patches `query_to_content` to auto-rescan when `dictionaries.is_empty()` so the first lookup after install picks up the just-finished conversion.
19. **GitHub raw URLs are CDN-cached for ~5 minutes.** When iterating an installer script, cache-bust pulls with `?cb=$([guid]::NewGuid().ToString())` to avoid debugging stale code. After this, also re-run the parser pre-flight to confirm what was downloaded matches what was pushed.
20. **Most macOS users won't see the Sangala folders** in Finder by default because they all start with `.`. Cmd+Shift+. toggles hidden-file visibility. Same files exist; Finder just hides them. Tell users this up front.
