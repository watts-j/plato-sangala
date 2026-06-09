# Plato Sangala — Project State

Last updated: 2026-06-09 (v2.49 retrofit confirmed working in production multi-cycle. v2.50–v2.54 shipped: UI polish, frontlight cleanup, package-structure rework, EPUB library shipped as separate `-library.tar.gz` artifact populated from user's F:\Library. Factory-reset bug FIXED. PS installer determined unreliable on user's Windows setup; manual drag-drop is the deploy path. Repository branch cleanup 2026-06-09: trunk renamed `sangala-v2.48-base` → `main` and set as the GitHub default, stale branches deleted, discarded experiment archived as the `archive/customize-plato-ui` tag. See the two Session-End Handoffs dated 2026-06-09 below.)

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

- **v2.54-sangala** — Reintroduces a separate library content package as `-library.tar.gz`, replacing the now-removed `-update.tar.gz`. Install package keeps the empty dot-folder structure only (built via `find -type d | xargs mkdir -p`, no file copy). Library package contains the EPUB collection committed to `sangala/library-skeleton/`. Deploy is now "install first, library second" — but with the library phase being pure content copy, there's no overlap with the system install's first-boot conversion. Replaces v2.53's "single-package" claim, which was technically true but precluded shipping library content via the release at all.
- **v2.53-sangala** — Install package includes the empty dot-prefixed library folder structure (`.STEM/`, `.Humanities/`, etc.) pre-created. Single-package deploy (no library content). Update package retained but redundant. Superseded by v2.54's split for projects that ship library content via the release.
- **v2.52-sangala** — Build workflow change: split install/update package responsibilities cleanly. Install = everything except library (Plato + system + KFMon configs + KoboRoot.tgz + screensaver + dictionaries + Settings). Update = library-only (just the empty dot-folder structure since library-skeleton is empty). Fixes the Phase-2-interrupts-dictionary-conversion crash (Lesson #42). Release notes updated to point deployers at manual install with eject-via-taskbar.
- **v2.51-sangala** — Frontlight Save/Guess buttons and presets list removed. Frontlight window is now just sliders (intensity, plus warmth on natural-light devices). `LightPreset` data type and Settings field retained for backwards compat with on-device Settings.toml files; just not surfaced in UI. `TogglePresetMenu` event handler in app.rs is now unreachable orphan.
- **v2.50-sangala** — UI: 12-hour clock display (`time-format = "%-I:%M %p"`), restructured Set Clock menu (AM/PM submenu → Hour 1-12 → Minute 0-9 / 10-19 / 20-29 / 30-39 / 40-49 / 50-59 sub-buckets with per-minute entries). Burger menu trimmed to System Info / Dictionary / Connect USB (Enable WiFi, Applications submenu, Calculator, Power Off removed). Power-off is now hardware-button only or via the 3-minute (idle → suspend) + 3-day (suspend → power-off) timer chain. Library skeleton emptied (all 49 EPUBs removed); content is sideloaded per-device. No architecture changes from v2.49.
- **v2.49-sangala** — KFMon retrofit. Restored v2.19's KFMon + NickelMenu launcher infrastructure verbatim. Confirmed surviving multi-power-cycle testing on Clara BW. Factory-reset bug fixed: Nickel boots fully (~1-2 s home screen visible) before KFMon fires plato.sh, giving Nickel enough time to write its bootloader healthy-boot marker. KoboRoot.tgz grew from ~1 KB to ~780 KB to carry the KFMon daemon, NickelMenu Qt plugin, and udev rule. See Lessons #37-#41 for the investigation that led here.
- **No version before v2.49 is currently confirmed stable.** Update 2026-05-25: the multi-power-cycle protocol (install on fresh device, open a book, dictionary lookup, power off, wait 20–30s, power on, repeat) factory-resets v2.32 on the 4th cycle and v2.47 on cycle 2 (CLI install) or cycle 4 (manual drag-drop install) on previously-never-reset Clara BW devices. WiFi never toggled. **The bug has been latent in the entire pre-v2.49 project**; the v2.45/v2.46 "stable" device may simply not have been power-cycled enough to hit it. The dictionary-removal hypothesis from the 2026-05-23 handoff (#2) is now demoted because v2.32's `convert-dictionary.sh` predates the `cp` fallback and would silently fail on FAT just like v2.45/v2.46 — so v2.32 also has no converted dictionary files yet still resets. Confirmed: bug is structural to the kill-Nickel-on-every-boot architecture, not in dictionary conversion specifically. v2.49's KFMon-based launch is the fix.
- **v2.48.1-sangala** — Pre-release tagged 2026-05-23. v2.48 + 8 EPUBs added to `.STEM/Science/Biology/`. No code or installer changes from v2.48. **Confirmed broken**: factory-resets on multi-power-cycle protocol like every other version tested.
- **v2.48-sangala** — Tip of `sangala-v2.48-base` (current working branch as of 2026-05-23) and the latest stable-marked tag/published release on GitHub. Three follow-on fixes after v2.47's device test (2026-05-08): (1) installer adds `IOCTL_STORAGE_EJECT_MEDIA` before `CM_Request_Device_Eject`; (2) `convert-dictionary.sh` swaps `trap 'exit 1' ERR` for `set -e`; (3) Plato's `query_to_content` auto-triggers `load_dictionaries()` if empty. Tags v2.49-v2.53 and their GitHub releases were deleted on 2026-05-23 (factory-reset bug investigation was not converging; rolled back to v2.48 as the working baseline). The 20 post-v2.48 commits are preserved on `claude/customize-plato-ui-1Edbm` if anything from that era is wanted back. **Note (2026-05-23):** v2.48 was previously marked "verified stable" based on a single install. Today's investigation showed v2.47 (which has the same on-device script set and the same Plato binary as v2.45/v2.46) factory-resets on the first clean power-cycle, so v2.48's "stable" rating must be considered suspect — it was never multi-power-cycle tested. The factory-reset bug now appears to affect at least v2.47 and v2.48 lines.
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
- **v2.32-sangala** — Previously claimed stable (2026-05-06, install-and-boot-once only). **Tested 2026-05-25 with the proper multi-power-cycle protocol — factory-reset on the 4th cycle.** Backgrounded dictionary conversion in `plato.sh`. `plato-autostart.sh` waits for `pidof nickel` + `KoboReader.sqlite` (60 s cap) + 5 s grace.
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

**v2.49 shipped and is confirmed working** via multi-power-cycle test on Clara BW (2026-05-25). It is the first reliably-stable release in the project's history. The factory-reset bug is no longer the active blocker.

**v2.50–v2.54 shipped** with UI polish, frontlight cleanup, package-structure rework, library-folder pre-creation, and (v2.54) a separate library content package. No architectural change from v2.49; KFMon-based launch remains the factory-reset fix.

Next tag should be **v2.55-sangala** for any further code change. Patch-level bumps (e.g., v2.54.1) are appropriate for content-only updates such as adding/removing EPUBs in the library package.

If a no-fix content-only update is wanted (e.g., more EPUBs added), it can ship as v2.48.2 with a release-note warning that the factory-reset bug is unresolved. But this just propagates the problem to more devices, so it's not recommended.

**Tagging discipline:** before suggesting any next tag number, fetch tags and check `git ls-remote --tags origin | grep sangala | sort -V | tail` (or use `mcp__github__list_tags`). This session shipped a duplicate v2.46 tag because the assistant reasoned about tag positions from a misread `git rev-parse v2.X-sangala^{commit}` output (PowerShell ate the `{commit}` brace, the resulting `^` returned the parent commit, and the assistant treated that as the tag's commit). Always single-quote refs with `{}` in PowerShell: `'v2.X-sangala^{commit}'`.

## Welcome Name

As of v2.45 the home screen renders **just the configured name** (e.g., "Jo"), not "Welcome, Jo!". The text comes from the `welcome-name` field in the `[home]` section of `Settings.toml`. On device, that's `/mnt/onboard/.adds/plato/Settings.toml`; the placeholder shipped in builds is `welcome-name = "[name]"`.

To change a single device's name: edit that file directly (over USB) and reboot. Updates overwrite `Settings.toml` from the package, so per-device names need to be patched at install time.

To change the default that ships in every new build: edit `sangala/Settings.toml` in the repo.

The PowerShell installers prompt for the reader's name on a fresh install and patch the field automatically before copying. On a standalone update they read the existing on-device value and patch the update package with it, so updates don't revert the placeholder.

## Package Structure

**As of v2.54+:** install = system, library = content. Two-phase deploy by design (system first, library second), but the second phase is just file copy — no install logic, no eject-while-mid-conversion risk.

- **`-install.tar.gz`** — System install (~70 MB). KFMon daemon + NickelMenu plugin + KFMon-aware `on-animator.sh` + Plato app + `Settings.toml` + dictionaries + screensaver + `Kobo eReader.conf` + KoboRoot.tgz system bootstrap + the empty dot-prefixed library folder structure. Triggers Nickel's "updating" screen and one auto-reboot. No EPUB content.
- **`-library.tar.gz`** — EPUB collection laid out under the dot-prefixed category folders. Pure content. No install script, no system files. Extract and drag-drop onto a device that already has the install package applied. Built from `sangala/library-skeleton/` in the repo. Subject to GitHub's 100 MB per-file cap on commit.
- **`install-sangala.ps1`** — Separate download. PowerShell installer script. **Not recommended for production deploy on the current Windows setup** — see Lesson #42 / fsck-truncation chain.

**Recommended install flow (v2.54+):**
1. Drag-drop `-install.tar.gz` contents to the device.
2. Eject via Windows taskbar.
3. Device reboots into Plato; wait 3 min for first-boot dictionary conversion to finish.
4. Reconnect via USB.
5. Drag-drop `-library.tar.gz` contents to the device.
6. Eject via Windows taskbar.

Library is now a clean second pass — no overlapping writes with the system install. Future EPUB updates: just re-extract the latest `-library.tar.gz` over the device's existing content.

**Subsequent updates:** re-apply the install package (re-triggers Nickel's "updating" screen and reboot, which is fine). The update package no longer contains Plato/Settings/dictionaries, so it cannot be used as a Plato-version update.

**Pre-v2.52 behavior (for reference when reading older session handoffs):** install and update packages BOTH contained `.adds/` + `.kobo/` user-partition content. Update was a superset (added library on top of shared-content). Phase 2 re-copied identical files, which on Clara BW could interrupt the still-running `convert-dictionary.sh` and produce a partial `.dict` file that fsck truncated on next boot, causing Plato to SIGBUS on book-open. v2.52 splits the responsibilities cleanly: install = everything-not-library, update = library-only.

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

**`main`** is the canonical trunk and the GitHub default branch. It is the former `sangala-v2.48-base` (created 2026-05-23 from the `v2.48-sangala` tag, carried the KFMon retrofit and everything through v2.54), renamed on 2026-06-09 as part of a branch cleanup. Fresh clones and new sessions land here automatically because it is the default.

**Branch cleanup (2026-06-09).** The repo had accumulated stale branches that caused new sessions to start from the wrong place — the GitHub default was `sangala-reader` at an ancient commit (`a9a74fd`, 121 commits behind), and `master` carried a stale `CLAUDE.md` pointing sessions at the discarded experimental branch. Resolved by: (1) renaming the trunk to `main` and making it the default; (2) deleting the dead branches `sangala-reader`, `claude/funny-fermat-oufn2k`, `claude/laughing-darwin-hHYv2`, and `master` (all fully merged or trivial); (3) archiving the deliberately-discarded experiment `claude/customize-plato-ui-1Edbm` (27 unique commits) as tag **`archive/customize-plato-ui`** and deleting the branch. A short `CLAUDE.md` was added to `main` so the harness auto-loads session orientation.

The KFMon retrofit was merged into the trunk on 2026-05-25 after the v2.19 device test passed. **Always confirm the working branch with `git branch --show-current` at session start (Lesson #33/#44).** If you ever need the discarded v2.49–v2.53 experiment work back, it's at the `archive/customize-plato-ui` tag — `git checkout -b recover archive/customize-plato-ui`.

## User Working Directory

`C:\Users\jbw3r\plato-sangala`

## Device

Kobo Clara BW (model spaBW/spaBWTPV), 1072x1448 @ 300 DPI. **Hardware buttons: power only.** No LIGHT button, no pinhole reset. Do not invent a button-combo factory-reset gesture from memory of other Kobos — earlier sessions repeatedly wrote "hold LIGHT during power-on" and were corrected. If you need the reset gesture for a recovery instruction, ask the user.

## Architecture (current — `sangala-v2.48-base` tip, post-KFMon-retrofit and ongoing through v2.54)

- Auto-launch: **KFMon daemon + `plato-autostart.sh`, both running in parallel** (v2.19's proven-on-Clara-BW pattern). `on-animator.sh` starts KFMon (`/usr/local/kfmon/bin/kfmon`) and forks `plato-autostart.sh` (`pidof nickel + sleep 10`). KFMon's `plato.ini` config has `on_boot = true`, so when Nickel finishes booting and its scanner indexes `.adds/plato/launch.png`, KFMon fires `plato.sh`. Whichever launcher fires first wins; the other no-ops because `plato.sh`'s first action is `killall -TERM nickel`. The key difference vs. pre-retrofit: Nickel runs its full boot sequence before any kill, so it writes whatever bootloader-side healthy-boot marker we couldn't identify via filesystem snapshots.
- KFMon also installs `libnm.so` (NickelMenu Qt plugin) and ships `.adds/nm/{kfmon, plato}` menu items, giving a manual fallback to launch Plato from Nickel's burger menu if `on_boot` ever fails to fire.

## Architecture (pre-retrofit, on `sangala-v2.48-base` tag and `v2.48*-sangala` releases)

- Auto-launch: `plato-autostart.sh` only. Waits for `pidof nickel`, then for `/mnt/onboard/.kobo/KoboReader.sqlite` to exist (60s cap, near-zero on subsequent boots), plus a 5s grace period; then `pkill -f on-animator` and `exec /mnt/onboard/.adds/plato/plato.sh`. **This is the broken architecture** — kills Nickel within ~1-2s on subsequent boots, before the bootloader marker is written. See Lesson #36/#37.
- Dictionary conversion (`convert-dictionary.sh`) is forked into the background by `plato.sh` so it doesn't block Plato startup. First-launch dictionary lookups would otherwise fail until conversion completes — but as of v2.48, Plato's `query_to_content` auto-rescans `dictionaries/` whenever the dictionary map is empty at lookup time, so once conversion finishes the next lookup picks it up without needing a manual "Reload Dictionaries". Output is captured to `/mnt/onboard/.adds/plato/dictionary.log` — pull this over USB if conversion appears to fail; it shows the timestamped start/end markers, recovery-path hits, and any tool errors.
- **`/mnt/onboard` is vfat or exFAT** — neither supports hardlinks. `ln src dst` returns `EPERM` on these filesystems. This affected v2.45/v2.46 because Option G's crash-safe rework called `ln` unconditionally for backup snapshots; v2.47+ falls back to `cp` on `ln` failure (cost: ~58 MB temporary disk during conversion, cleaned up on success). Do not rewrite the conversion script to assume hardlinks work.
- **busybox `sh` doesn't support `trap '...' ERR`** — that's a bash extension. v2.45/v2.46/v2.47 all carried `trap 'exit 1' ERR` from upstream; busybox logged `trap: ERR: invalid signal specification` and silently didn't install the trap, so errors didn't propagate. v2.48 uses `set -e` instead (which busybox does support). Don't reintroduce `trap ... ERR` here.
- KFMon + NickelMenu reintroduced on `claude/laughing-darwin-hHYv2` (was: "no KFMon, no NickelMenu" on `sangala-v2.48-base`).
- KoboRoot.tgz is `sangala/kobo-assets/KoboRoot.tgz` — **~780 KB on the retrofit branch** (was ~1 KB on `sangala-v2.48-base`). Contains KFMon daemon binaries (`kfmon`, `fbink`, `shim`, `kfmon-ipc`, `kfmon-update.sh`), `libnm.so` NickelMenu plugin, KFMon-aware `on-animator.sh`, v2.19's `plato-autostart.sh`, `99-kfmon.rules` udev rule, and `mnt/onboard/.adds/nm/doc` NickelMenu doc. All vendored from v2.19's release tarball.
- User-partition KFMon/NickelMenu config lives in `sangala/user-content/.adds/{kfmon,nm}/`. Build workflow copies these into `shared-content/` alongside `.adds/plato/`. The 1 × 1 PNG KFMon trigger ships as `sangala/kobo-assets/plato-resources/launch.png` and is copied to `.adds/plato/launch.png` on device.
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
- Dictionary
- Connect USB

(Removed: Invert Colors, Reboot, Enable WiFi, Applications submenu, Calculator, Power Off)

**Power-off note:** as of the burger-menu trim, Power Off is no longer surfaced anywhere in Plato's UI. Users power off via the hardware power button (long press) or wait for the auto-power-off timer (3 min from Settings.toml). The multi-power-cycle test protocol "power off via Plato burger menu" step now becomes "long-press power button until shutdown."

## EPUBs

Library skeleton ships **empty** as of 2026-05-25: every content directory has a `.gitkeep` only. EPUB content is copied to devices manually via USB during install, NOT shipped in the update package. Earlier versions (v2.34–v2.50) shipped ~40-110 MB of EPUBs in the update tarball; removed because some sources exceed GitHub's 100 MB per-file cap and because the manual-copy workflow is preferred for the production deployment. Library folder layout is preserved on the device via the .gitkeep'd directories so Plato's cascading menu still lists the categories.

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

**Update (2026-05-23):** v2.48 was device-tested and superficially passed — but Lesson #33's caveat applies: the test was a single install + boot, not multi-power-cycle. Promote-to-stable decision was made on insufficient evidence. The factory-reset bug surfaced on subsequent power-cycle testing later. Do NOT take this 2026-05-08 handoff's "promote v2.48" recommendation at face value.

Risks to watch for:

- **PS 5.1 parser regressions.** The `$ejectType` here-string grew with the new `ScsiEject` static method. Run `[System.Management.Automation.Language.Parser]::ParseFile` on both installer scripts from PS 5.1 before pushing the tag.
- **`IOCTL_STORAGE_EJECT_MEDIA` "drive in use" failures.** If the host has any stale handle on the volume (Search Indexer, antivirus, third-party file manager), the IOCTL may fail with `ERROR_DRIVE_LOCKED` or similar. The path swallows the failure (logs WARN, continues to `CM_Request_Device_Eject`), but the cable yank workaround would re-emerge. Lock+Dismount in the same C# function should normally close held handles.
- **Tag bookkeeping.** Always `git fetch origin --tags` first, then `mcp__github__list_tags` (or `git ls-remote --tags origin | sort -V`). Single-quote refs with `{}` in PowerShell.

## Session-End Handoff (2026-05-23, factory-reset investigation continued)

### Status

The factory-reset bug is **active and unresolved**. The previous session (also 2026-05-23, captured at the bottom of the discarded `claude/customize-plato-ui-1Edbm` branch) left this bug open with the highest-priority untested hypothesis being "swap USB cable." That hypothesis was tested in subsequent installs and the user has confirmed multiple times the cable is good. This session ruled out additional candidates and narrowed the search.

### Evidence summary

**Stable device** (working long-term):
- Plato binary SHA256: `398C698E75549253ECB98076E7D4C70332BF93D890C2F659BC34823C7FD863F7` — matches v2.45, v2.46, and v2.47 (all three released identical Plato binaries; no Rust changes between them)
- `convert-dictionary.sh` SHA256: `01F85AE3A7EA705A441A31C47E55C400F55D0640B25C5F7906BEA5AEF243AE69` — matches v2.45 / v2.46 only (v2.47 differs because of the `cp` fallback addition)
- Firmware: `N365594030688,4.9.77,4.42.23291,4.9.77,4.9.77,...0391` — model 391, kernel 4.9.77, firmware 4.42.23291
- Stable for **2+ weeks with multiple reboots** in real-world use

**Failing test device** (and per user report, multiple other failing devices across multiple USB ports and multiple host computers):
- Firmware: `N365594030627,4.9.77,4.42.23291,...0391` — **identical firmware string** to stable device, only serial differs
- Factory-resets on v2.47 / v2.48 / v2.48.1 / v2.49-v2.53 (range tested)
- v2.48.1 factory-reset after ~3 clean power-cycles
- v2.47 factory-reset on the FIRST clean manual power-cycle (after install + real-use session, clean shutdown via Plato burger menu, fully booted device on each cycle)

### Hypotheses tested and ruled out this session

| Hypothesis | Ruled out by |
|---|---|
| USB cable (Lesson #30 priority) | User confirmed cable good across multiple installs; bug reproduces with same install on multiple devices and ports |
| Single-unit hardware defect | Multiple devices affected per user report |
| Host USB port / controller | Multiple ports on multiple computers tested |
| eMMC wear from repeated installs | Math: ~3-4 GB of writes across 15-20 cycles is two orders of magnitude below MLC/TLC endurance threshold |
| Kobo firmware tamper detection (Lesson #32) | Stable + failing devices on identical firmware string `4.42.23291` |
| v2.47 → v2.48 code diff introduced bug | v2.47 also factory-resets immediately |
| Rapid-cycle methodology / short on-time | v2.47 factory-reset after one slow, clean cycle with real reading session |
| Force-off / dirty shutdown | User shutdowns are clean via Plato burger menu → Power Off |

### Remaining hypotheses (ranked)

1. **v2.46 → v2.47 diff triggers the bug.** Two parts:
   - `convert-dictionary.sh` got the `cp` fallback in v2.47. Before this, conversion silently failed on FAT (busybox `trap ERR` is a no-op, unconditional `ln` returned EPERM). v2.45/v2.46 devices therefore have un-converted StarDict files on disk, no dictd-format `.dict.dz` or `.index`. v2.47+ devices have successfully converted files. **If Nickel watches `/mnt/onboard/.adds/plato/dictionaries/` or specific file patterns there, the converted state may trigger the bug.**
   - Installer's eject path: v2.45/46 leaves FAT dirty, fsck.fat truncates `dict.dz` and some EPUBs on next boot. v2.47+ does a clean eject; all files intact. **The truncated files in v2.45/46 may be what prevents the bug from triggering.**

2. **Some specific file write pattern from successful dictionary conversion** is the actual trigger. v2.47 writes ~32 MB `.dict.dz` (dictd format, different from StarDict source) + ~14 MB `.index` to `/mnt/onboard/.adds/plato/dictionaries/`. v2.45/46 never wrote these (conversion silently failed). Testing: install v2.47 but remove `dictionaries/` and `convert-dictionary.sh` from device before first boot, see if it survives. **Highest expected-information experiment for next session.**

3. **Some sqlite/Nickel state we haven't snapshotted.** `KoboReader.sqlite` is now in the snapshot function (added 2026-05-23). Compare across boots to look for drift.

4. **fsck.fat cascading damage.** Each boot, if any FAT inconsistency exists, fsck runs and shaves a bit more. Snapshot function now grep's info.log for `fsck` mentions automatically. No evidence yet but easy to confirm in next test.

5. **Something specific about how the stable device was installed.** May have been:
   - Manually drag-dropped from a v2.45 or v2.46 release zip (bypassing all installer eject paths)
   - Installed when firmware was older than 4.42 (would need to check `.kobo/` for any pre-OTA file remnants — but the firmware string matches now)
   - Factory-reset prior to install or not
   We don't currently know.

### Recommended first actions for next session

1. **Don't install v2.47+ on any test device.** It will factory-reset, burning the device. We have enough evidence already.

2. **Run the dictionary-removal experiment.** Procedure:
   - Factory-reset a Clara BW test device.
   - Run `install-sangala.ps1` for v2.47 normally (Phase 1 + Phase 2).
   - Before powering off after Phase 2, with the device still in USBMS mode (Connect USB still active in Plato), delete:
     - `D:\.adds\plato\dictionaries\` (entire directory)
     - `D:\.adds\plato\convert-dictionary.sh`
     - Optionally `D:\.adds\plato\dictionary.log` for cleanliness
   - Eject cleanly, let device reboot into Plato (no dictionaries), then power-cycle 10+ times with the same protocol that factory-reset v2.47 first time.
   - If it survives: dictionaries / conversion is the trigger. v2.45/46 worked because conversion silently failed.
   - If it factory-resets anyway: dictionaries not the trigger; look at #2-5 above.

3. **Investigate the stable device's install history.** Ask the user when and how that device was installed. Differences from the test devices' installs are the variable.

4. **Capture snapshots between every cycle** using the `Snap-Device` PS function (added in this session — defined inline at the end of the conversation; not yet committed to `tools/snapshot-device.ps1`). Look for drift in `KoboReader.sqlite` size/hash and `fsck.fat` hits in info.log.

### Deferred work (cherry-picks from `claude/customize-plato-ui-1Edbm`)

User has confirmed they want these once a working baseline exists:
1. **Remove "Enable WiFi" from burger menu** — commit `b2fc858` on the discarded branch. Single hunk in `crates/core/src/view/common.rs`. One-line cherry-pick.
2. **Auto-reload dictionaries on empty lookup** — already in v2.48 (the v2.47 → v2.48 diff in `crates/core/src/view/dictionary/mod.rs`). On the current v2.48 baseline, this is already shipped.

These should not be added until the factory-reset bug is resolved on whatever the new baseline is.

### Snapshot script (Lesson #34 follow-up)

The PowerShell `Snap-Device` function used in this session captures per-cycle:
- `info.log`, `dictionary.log`, `Settings.toml`, `.kobo/version` (copied)
- SHA256 + size of `plato`, `plato.sh`, `convert-dictionary.sh`, `Settings.toml`, `KoboReader.sqlite` (manifest)
- Automatic grep for `fsck` mentions in info.log

The function body is in this session's conversation. **Worth committing to `tools/snapshot-device.ps1`** in the next session — Lesson #34 still applies.

### v2.48.1 release notes

Tagged 2026-05-23T12:13Z, commit `70abdd5` on `sangala-v2.48-base`. Contains v2.48 + 8 EPUBs added to `.STEM/Science/Biology/` (Plant Nutrition guide, Photosynthesis x4, Plant Transport, Pigment Chromatography Lab, Metabolic Connections — all numbered with prefix `0. ... 7. ...` for reading order). Released as pre-release. Same factory-reset bug as v2.48. EPUB content is independently useful but the release is not safe to deploy broadly until the factory-reset bug is fixed.

## Session-End Handoff (2026-05-25, bug confirmed structural; Nickel ruled out as alternative)

### Status

The factory-reset bug is **structural to the kill-Nickel-on-every-boot architecture**, not a regression in any specific version. The 2026-05-23 hypothesis (v2.46→v2.47 dictionary conversion or eject diff) is demoted — v2.32 also resets and predates both of those changes.

### What was tested this session

1. **Cable swap on a fresh Clara BW.** The new cable resolved install-time frozen dots (Lesson #30 pattern confirmed again) but the device still factory-reset on the 2nd power cycle with the new cable installed. So cable explains the install-time symptom but NOT the post-install reset.
2. **v2.47 manual drag-drop install on a fresh device** (drag the install tarball contents to the drive, Safely Remove Hardware, no installer code at all). Device factory-reset on the 4th slow reboot. **Rules out CLI installer, GUI installer, eject sequence, Flush-Drive — the bug is in WHAT is installed, not HOW.**
3. **v2.32 manual install on a fresh device** with proper protocol (open a book, dictionary lookup, power off, 20–30s wait, power on, repeat). Factory-reset on the 4th cycle. v2.32 is the earliest version ever called stable. **The bug has been latent in the project the entire time** — Lesson #33 was right.
4. **WiFi confirmed never toggled** across all the new-device runs. Rules out the WiFi-tamper-detect hypothesis.
5. **Nickel customization research** (MobileRead Kobo Developer's Corner, NickelMenu, kobopatch, dictutil/Penelope). **Conclusion: Nickel cannot replicate Sangala's UX.** Cascading taxonomy and welcome-screen-with-name are impossible. Plato is structurally required.

### What's ruled out

- All installers (CLI, GUI, manual)
- Eject sequence / Flush-Drive
- USB cable (still relevant for install-time frozen dots only)
- eMMC wear / device-specific hardware fault
- WiFi tamper-detect (never toggled)
- Anything we changed between v2.32 and v2.48 (v2.32 also resets)
- Dictionary-conversion success/failure (v2.32 would silently fail on FAT like v2.45/46 yet still resets — so the 2026-05-23 leading hypothesis is wrong)
- "Move to Nickel" as a path forward (Nickel cannot do hierarchical taxonomies or custom welcome screens)

### Leading hypothesis

Kobo's bootloader has a watchdog-style boot-attempt counter. It increments each time the system boots and resets to 0 when Nickel completes a "healthy" session (writes some marker). Our `plato-autostart.sh` kills Nickel before any such marker is written, so the counter accumulates every boot. When it reaches ~3–5, the bootloader triggers recovery → factory reset. Variable reboot count to reset (2 for v2.47 CLI vs 4 for v2.47 manual vs 4 for v2.32) is consistent with this — slight timing variations affect whether Nickel ever gets to write a partial marker.

### Investigation tools added this session (under `tools/`)

- **`tools/snapshot-device.ps1`** — pulls a labeled snapshot of `.kobo/`, Plato's logs, Settings.toml, and a manifest of SHA256 hashes for key files. Run between every power cycle.
- **`tools/diff-snapshots.ps1`** — compares two snapshots, prints size/mtime/sha changes, added/removed files in `.kobo/`, and new lines in `autostart.log`.
- **`tools/verify-device-version.ps1`** — reads `.adds/plato/VERSION` (new stamp shipped from this commit onward) to identify which Sangala tag is installed; falls back to SHA256 fingerprints for pre-stamp devices.
- **Build workflow now writes `VERSION` into the shared content** so every install/update carries the git tag.

### Recommended first actions for next session

1. **Install v2.48 or v2.48.1 fresh on a Clara BW** (the latest released versions; closest to what production devices have). Skip v2.32 — testing it was useful as a "bug-pre-dates-everything" data point but it's not what we'd ship.

2. **Run the snapshot protocol** via the `tools/` scripts committed this session:
   - `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` (once per PowerShell window)
   - `.\tools\snapshot-device.ps1 -Label boot1-post-install` after install completes
   - Open a book, dictionary lookup, power off via Plato burger menu, wait 20-30s, power on
   - `.\tools\snapshot-device.ps1 -Label boot2`
   - Repeat with `boot3`, `boot4`, ... until the device factory-resets
   - `.\tools\diff-snapshots.ps1 -A <bootN> -B <bootN+1>` between consecutive snapshots
   - Snapshots default to `%USERPROFILE%\Desktop\Install\<timestamp>-<label>\`

3. **Watch specifically for**: changes to `.kobo/Kobo/Kobo eReader.conf` (`sleepOnNextBoot`, `syncOnNextBoot`, `LastFTEStep`), `.kobo/version` (Kobo writes to this every boot), `.kobo/KoboReader.sqlite` size growth, and any new files appearing in `.kobo/`. Any consistently-escalating value or new file is the candidate for Kobo's boot-attempt counter.

4. **If the snapshot reveals a manageable marker**, modify `plato-autostart.sh` to write/reset it after Plato launches successfully. One-line architectural fix; all Sangala UX preserved.

5. **If no marker is found, switch to KFMon-based launching.** KFMon doesn't kill Nickel — it adds a Kobo Reader collection icon that launches Plato as a separate process. v2.28's attempt failed only because we kept `plato-autostart.sh` alongside it (Lesson #13). Properly: remove `plato-autostart.sh` AND the minimal `on-animator.sh`, reintroduce v2.3-era KFMon binaries, configure a KFMon icon that runs `plato.sh`. Substantial work; matches the upstream Plato pattern.

6. **A single v2.19 test could confirm the architecture hypothesis** before committing to the KFMon retrofit — v2.19 was the last KFMon-based build. If v2.19 installs on Clara BW and survives multi-power-cycle, KFMon is the answer. If it fails to install (v2.19 is pre-Clara-BW per CLAUDE-STATE), skip it and go straight to the retrofit on `sangala-v2.48-base`.

7. **Do NOT propose "rebuild in Nickel"** — Lesson #32 documents why it can't work for Sangala's UX.

8. **Production v2.49 batch (~30 devices) is at risk.** No field reports of resets yet, but presumed at-risk under cumulative power-cycling. No remediation possible until the architectural fix lands.

## Single-package vs two-package (open question)

The two-package layout was introduced so subsequent updates don't re-trigger Nickel's "updating" reboot (`KoboRoot.tgz` only ships in `-install.tar.gz`). This adds friction during fresh installs: two ejects, manual Connect USB between them, conversion gets killed mid-run by Phase 2 USB-connect. Single-package would: one copy, one eject, conversion runs uninterrupted, but every standalone update would also trigger the Nickel reboot. Worth revisiting once v2.48 verifies clean — if the install experience is still rough, collapsing back to single-package may be net-better despite the slower update cadence.

## Known Issues / Pending

- **Factory reset on power-cycle (TOP PRIORITY, FIX CANDIDATE PENDING DEVICE TEST).** Confirmed on Clara BW for v2.32, v2.47, v2.48, v2.48.1, and the discarded v2.49-v2.53 line. v2.19 (KFMon + plato-autostart launcher pair, original Sangala launch architecture) confirmed surviving 10+ cycles on Clara BW (2026-05-25). KFMon retrofit ported into `claude/laughing-darwin-hHYv2` ahead of `sangala-v2.48-base`. **Next step is the device test on the retrofit branch.** Build a release from `claude/laughing-darwin-hHYv2`, install on fresh Clara BW, run multi-power-cycle protocol. If it survives 10+ cycles, tag v2.49-sangala. The original snapshot-protocol-to-find-marker plan is shelved — boot-1-vs-boot-2 snapshot diff on v2.48.1 showed zero Nickel writes between boots (subsequent-boot path kills Nickel within 1-2 s), and the reset triggers on power-on (pre-userspace), so the marker is bootloader-side and not visible to filesystem snapshots. Lesson #36 still applies: do NOT propose Nickel as an alternative.
- **Fresh install hang**: fixed in v2.32. Validated on factory-reset Clara BW (2026-05-06). v2.44+'s no-grace-on-subsequent-boots optimization preserves the factory-reset path unchanged. (Note: any "validated stable" claim made before 2026-05-23 should be treated with skepticism — install-and-boot-once isn't sufficient.)

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
24. **GitHub raw URLs are CDN-cached for ~5 minutes.** When iterating an installer script, cache-bust pulls with `?cb=$([guid]::NewGuid().ToString())` to avoid debugging stale code. After this, also re-run the parser pre-flight to confirm what was downloaded matches what was pushed.
25. **Most macOS users won't see the Sangala folders** in Finder by default because they all start with `.`. Cmd+Shift+. toggles hidden-file visibility. Same files exist; Finder just hides them. Tell users this up front.
26. **Don't keep raising hypotheses the user has explicitly ruled out.** This session, the assistant raised "USB cable" as a candidate multiple times after the user had stated the cable was good. Trust user judgment on physical artifacts they can directly inspect; if a hypothesis has been rejected with first-hand evidence, drop it from the ranking entirely rather than re-listing it. Same applies to "single-unit hardware defect" once the user reports multiple devices, "host USB port" once the user reports multiple ports/computers, etc.
27. **Verify degradation-mechanism claims with arithmetic before asserting them.** The assistant cited "eMMC wear from 15+ factory-reset cycles" as a possible cause; user pushed back; on calculation, ~3-4 GB of writes spread across a 6 GB partition by a wear-leveling controller is two orders of magnitude below MLC/TLC endurance. The hypothesis was unsupportable. For any claim of the form "this hardware degradation might be the cause", do the math first — write volume per cycle, total cycles, partition size, wear-leveling assumption, endurance rating — before adding it to a ranked list.
28. **Identical Plato binary across releases doesn't mean identical on-device state.** The stable v2.45/46 device and the failing v2.47 test devices ship the same `plato` binary (same SHA256). But the install state is different: v2.45/46 silently fails to convert the dictionary (broken `trap ERR` + unconditional `ln`) and v2.45/46's installer corrupts FAT during eject (fsck truncates files). So the stable device has UN-converted StarDict files and possibly missing/truncated EPUBs. The failing devices have fully-converted dictd-format dictionary files and a clean filesystem. **The corruption itself may be what bypasses the factory-reset bug.** Two takeaways: (a) "same binary" is not the same as "same configuration"; (b) when an older version "just works", check whether it's working because of brokenness, not despite it.
29. **A test-device install that boots once isn't proof the build is stable. A single power-cycle that reboots into the same state isn't either.** v2.47 factory-reset on the FIRST clean manual power-cycle on this session's test device — after a clean install, a fully-loaded Plato, a real-use session, and a clean shutdown via Plato's burger menu. The previous "stable" rating on v2.47/v2.48 came from device tests that didn't include a manual power-cycle after install. Update the test protocol to require at least 5 clean power-cycles (install → use → power off via menu → power on → repeat) before any "verified stable" claim, with snapshots between each cycle to look for drift.
30. **The v2.46→v2.47 diff was the smallest blast-radius candidate for the factory-reset bug, and was demoted on 2026-05-25.** Between v2.46 and v2.47: (a) `convert-dictionary.sh` got the `cp` fallback so conversion actually completes on FAT (was silent no-op before); (b) installer added `CM_Request_Device_Eject` so the eject doesn't corrupt FAT anymore. The Plato binary, KoboRoot.tgz scripts, and Settings.toml are unchanged across this diff. Original hypothesis: if the bug is introduced between v2.46 and v2.47, it's introduced by either successful dictionary conversion writing new files OR the installer leaving the filesystem in a clean state. **Demoted because v2.32 also factory-resets on multi-power-cycle (Lesson #31)** — v2.32 predates the `cp` fallback and uses the un-EJECT'd installer, yet still resets. The bug pre-dates the v2.46→v2.47 diff. The original hypothesis is preserved here for the record but is no longer the leading candidate.

31. **Multi-power-cycle protocol reveals the factory-reset bug has been latent the entire project.** (2026-05-25) After cable swap (Lesson #30 / older session's Lesson) resolved install-time frozen dots, fresh-device testing with proper protocol — install on a brand-new never-reset Clara BW, use the device (open a book, dictionary lookup), power off via Plato's burger menu, wait 20–30s, power on, repeat — produced factory resets on every version tested: v2.32 (cycle 4), v2.47 CLI install (cycle 2), v2.47 manual drag-drop install (cycle 4), v2.48/v2.48.1/discarded v2.49–v2.53 (all already known to reset). v2.32 is the earliest version we ever called stable. WiFi was never toggled. **The bug is structural to the kill-Nickel-on-every-boot architecture** that all versions share (v2.20+ all use the minimal `plato-autostart.sh` pattern; v2.3/v2.19 used KFMon but were never multi-power-cycle tested either). Earlier "stable" claims pre-2026-05-25 were based on install-and-boot-once tests that didn't surface the cumulative-state problem. The leading hypothesis is now that Kobo's bootloader has a watchdog-style counter incremented on every boot and reset only when Nickel completes a "healthy" session; our `plato-autostart.sh` kills Nickel before that marker can be written, so the counter accumulates until recovery triggers. Variable reboot count to reset (2 vs 4) supports this. The bug is in WHAT is installed, not HOW; both CLI installer and fully manual drag-drop produce the reset.

32. **Nickel cannot replicate Sangala's UX — Plato is structurally required.** (2026-05-25 research via MobileRead Kobo Developer's Corner, NickelMenu, kobopatch, dictutil/Penelope) Per-requirement verdict on stock Nickel + every standard customization tool: (1) cascading hierarchical taxonomy (Menu → STEM → Mathematics → Algebra) — NOT POSSIBLE, Kobo collections are flat tags with no nesting; (2) welcome screen with reader's name — NOT POSSIBLE, home screen is hard-coded, only screensaver is replaceable; (3) restricted menu (remove Sync/WiFi/Store) — kobopatch firmware binary patches only, per-firmware, fragile, Clara BW FW 4.39+ coverage is limited; (4) Wiktionary dictionary — dictutil/Penelope produce a Kobo `dicthtml-*.zip`, but conversion is desktop-only, no on-device StarDict conversion; (5) Libertinus Serif font — native via `.kobo/fonts/`, but pinch-to-zoom step size is Kobo-controlled (integer points, no 0.5pt steps); (6) no clock/date/Share/Sleep prompts — kobopatch only; (7) dot-prefixed folders hidden from scanner — native via `[FeatureSettings] ExcludeSyncFolders=...` regex in `.kobo/Kobo/Kobo eReader.conf` (Sangala already ships this). Requirements 1 and 2 alone make Nickel non-viable as an alternative. Do not propose "rebuild Sangala UX inside Nickel" — the factory-reset fix has to be in how we launch Plato (snapshot to identify Kobo's watchdog marker, or restore KFMon-based launching that doesn't kill Nickel), not in whether we use Plato at all.

33. **Verify the current git branch before committing — CLAUDE-STATE's "Branch" line can be stale.** This session, the assistant trusted the "Branch" line in CLAUDE-STATE on the wrong branch and made eight commits to `claude/customize-plato-ui-1Edbm` while the user was working on `sangala-v2.48-base`. The user discovered the mismatch only after pulling and finding `tools/snapshot-device.ps1` missing. Always run `git branch --show-current` and `git status` at the start of a session and before any commit, regardless of what CLAUDE-STATE says. CLAUDE-STATE prose lags reality whenever a rollback or branch switch happens.

37. **The v2.44+ "skip grace on subsequent boots" optimization is what made the factory-reset bug active in the kill-Nickel architecture.** (2026-05-25 boot-1-vs-boot-2 snapshot diff on v2.48.1.) Between consecutive boots on a v2.48.1 install, every Nickel-managed file in `.kobo/` (`KoboReader.sqlite`, `BookReader.sqlite`, `Analytics.conf`, `device.salt.conf`, `fonts.sqlite`, `.kobo/version`, `ssh-disabled`) had byte-identical contents AND identical mtimes. Nickel did not write anything to disk on boot 2. That happens because `plato-autostart.sh`'s `SUBSEQUENT_BOOT` branch waits only for `pidof nickel` (true within ~1-2 s of Nickel launch) then immediately kills it — Nickel never gets to its file-writing stage. The bootloader's healthy-boot marker (location unknown, probably raw MMC or a partition the bootloader reads) is therefore never written, and the watchdog counter increments toward the recovery threshold every cycle. v2.32 had a 5 s post-DB grace on every boot — that's still too short, which is why v2.32 also resets (Lesson #31). The fix isn't to extend grace; it's to let Nickel finish booting via KFMon's `on_boot` trigger (Lesson #39).

38. **"Two devices stable for weeks on v2.46" is real-world-usage survivorship.** (2026-05-25 user observation.) The factory-reset bug is per-cold-boot, not per-elapsed-time. Real Kobo usage is sleep/wake (closing the cover, screensaver), which keeps Nickel running and doesn't increment the bootloader counter. A reader who power-cycles 0-1 times per week stays under the threshold indefinitely. The multi-power-cycle test protocol burns through cycles 50-100× faster than real use and exposes the bug. Production deployments are still at risk on a slower timeline — a teacher who powers off devices nightly will hit the threshold within weeks. Do not interpret "stable for weeks" as evidence the bug is absent on a device; check the cold-boot count.

39. **Lesson #13 was partly wrong: KFMon + `plato-autostart.sh` running in parallel is NOT fatal on Clara BW.** v2.19's `on-animator.sh` starts KFMon AND forks `plato-autostart.sh`. Both call `plato.sh`. v2.19 survives 10+ multi-power-cycles. v2.28's hang (which Lesson #13 attributed to the race) must have had a different root cause — possibly KFMon binaries themselves not working, or a different Plato/plato.sh behavior between the v2.3-era binaries v2.28 inherited and v2.19's fresh ones. The retrofit ports v2.19's launcher pair verbatim. Don't try to "clean up" by removing one of the launchers without device evidence that the simplified setup works — the working v2.19 config has both, and that's the conservative choice.

40. **v2.3-sangala-full-build was a Clara BW build, not pre-Clara-BW.** CLAUDE-STATE's Reference Versions entry claiming "Pre-Clara BW" for v2.3 was incorrect. The v2.3 release notes explicitly say "Customized Plato build for KOBO Clara BW," and the user confirmed (2026-05-25) that every device used with this repo has been a Clara BW. Implication: v2.3's KFMon binaries are known-good on Clara BW. The retrofit uses v2.19's binaries (newer than v2.3's but same Clara BW target), so this is moot for the retrofit, but the Reference Versions line should be corrected if anyone is re-reading old session handoffs.

41. **Reset-on-power-on confirms the trigger is bootloader-side, not userspace-side. Filesystem snapshots can't surface bootloader-side markers.** (2026-05-25 user observation: boot 2 went straight to factory-reset / setup wizard on power-on; Plato never launched.) That means the decision to factory-reset is made before any `/mnt/onboard` file system is even mounted. U-Boot reads its watchdog counter from raw MMC or a hidden partition (`mmcblk0p1`/`p2`-style), increments on every unhealthy boot, and triggers recovery at the threshold. Our `tools/snapshot-device.ps1` only sees `/mnt/onboard` content, so it can't catch the marker — it can only confirm what Nickel did or didn't do in userspace (which is what gave us Lesson #37). For future device-state inspection of bootloader-readable areas, we'd need ssh/telnet on-device and `dd` of raw MMC sectors. Out of scope while the KFMon retrofit is in test.

42. **The pre-v2.52 two-package install design ships duplicate `.adds/` + `.kobo/` content in Phase 2, which on Clara BW interrupts the still-running `convert-dictionary.sh`, corrupts the dictionary, and crashes Plato on book-open with SIGBUS.** (2026-05-25, after v2.51 deploy to 5 devices: 4/5 crashed.) Failure chain: (1) Phase 1 installs, device reboots, KFMon launches Plato, `plato.sh` forks `convert-dictionary.sh` in background (~1-2 min on Clara BW). (2) User reconnects for Phase 2 within that window. USB-connect remounts /mnt/onboard for USBMS, interrupting `convert-dictionary.sh` mid-`dictfmt`. Partial `.dict` (106 MB) left on disk. (3) User copies Phase 2 (which RE-copies `.adds/plato/dictionaries/*` source files on top of the partial conversion state). (4) User ejects; FAT is dirty from the interrupted write. (5) On next boot, fsck.fat sees the cluster-chain mismatch and truncates `.dict` to 75 MB to match. (6) Plato's dictionary loader mmaps `.dict`, accesses pages past the truncation, gets SIGBUS, crashes. Falls back to Nickel, KFMon re-fires, Plato re-crashes immediately on same file → infinite crash loop. Diagnosis confirmed via `info.log` showing exactly this fsck output + `Bus error`. The 1/5 device that worked got lucky on conversion-vs-Phase-2 timing. **Fix**: v2.52 splits the package responsibilities cleanly — install = everything-not-library, update = library-only, no duplicate `.adds/`+`.kobo/` writes. v2.54 renames the library package to `-library.tar.gz` for clarity. Recovery for affected devices: delete `.adds/plato/dictionaries/` on device, restore from install package, eject cleanly via taskbar, reboot, wait 3+ min for fresh conversion.

43. **Search-verify before stating vendor UI paths or menu locations.** (2026-06-09.) Confidently misstated Calibre's "Polish books" location from memory (claimed it was in the default right-click menu — wrong, has to be added via Toolbars & menus). Then confidently misstated that Polish does aggressive image compression (wrong — Polish is lossless-only; lossy compression is in Edit Book → Tools → Compress images). Both took 2-3 corrections from the user before resolving. A single WebSearch call would have caught either error. Going forward: for any UI-flow question on third-party software (Calibre, Kobo's Nickel, Windows utilities), call WebSearch with a current-year query before stating menu paths, even if confident from memory. The cost of pre-emptive verification (one search) is much lower than the cost of user-side iteration (multiple back-and-forths plus loss of trust).

44. **"New computer" or unexpected clone state — verify with `git branch --show-current` + `git log -1` before running any add/commit/push commands.** (2026-06-09.) User said "I am on a new computer again," ran a `git clone` that silently failed (directory already existed), and ended up doing work in a stale clone on the WRONG branch (`claude/customize-plato-ui-1Edbm` — the discarded experimental branch from May, deleted from session memory two handoffs ago). The robocopy step succeeded; the subsequent `git add` then surfaced a half-done merge from before, mixed with the new library content. Recovery sequence that worked: `git merge --abort; git fetch origin; git checkout -B sangala-v2.48-base origin/sangala-v2.48-base; git reset --hard origin/sangala-v2.48-base`. Note that `git reset --hard` then wiped the robocopied EPUBs (they were treated as tracked content from the old branch); user had to re-robocopy. **For future "new computer" interactions, do not run any state-changing git commands until verifying**: (1) `pwd` (correct path), (2) `git branch --show-current` (correct branch), (3) `git status` (no half-done merges or pre-existing staged changes), (4) `git log -1 --format=%s` (HEAD commit matches the latest known push from prior sessions). All four green = safe to proceed. Any red = recovery first.

45. **The "new session can't find the right place" problem was a wrong default branch, not branch divergence — and merge/rebase was the wrong tool for it.** (2026-06-09.) GitHub's default branch was `sangala-reader` (ancient `a9a74fd`, 121 commits behind the trunk), and `master` carried a stale `CLAUDE.md` pointing sessions at the discarded `claude/customize-plato-ui-1Edbm` branch. Fresh clones/sessions inherit the repo's default branch, so every new session started 121 commits in the past with no `CLAUDE-STATE.md`. Nothing needed merging (only the deliberately-discarded experiment had unique commits, and those were never wanted in the trunk). Fix: rename the trunk to `main`, set it as the GitHub default, delete the dead branches, archive the one branch with unique commits as the `archive/customize-plato-ui` tag, and add a short auto-loaded `CLAUDE.md` on `main` so the harness orients every session. **Operational constraint discovered:** the Claude-on-web managed git proxy returns HTTP 403 on tag pushes AND ref deletions — it only allows creating/updating branches. So changing the default branch (a repo setting), pushing tags, and deleting branches all have to be done by the user from their own machine / GitHub UI. Don't burn retries on these from a web session; hand them to the user with exact commands.

## Session-End Handoff (2026-06-09, UI polish + package rework + library workflow)

### Status

**Factory-reset bug is fixed.** v2.49 retrofit confirmed working in production (multi-cycle, real-use). All releases through v2.54 are shipped (pre-release on GitHub). v2.54 ships an EPUB library package populated from the user's F:\Library; install package ships the empty dot-folder structure only.

### What landed this session

**Tags shipped (pre-released on GitHub):**
- v2.49-sangala — KFMon retrofit. Restores v2.19's KFMon + NickelMenu launcher infrastructure. Factory-reset bug fix.
- v2.50-sangala — UI polish: 12-hour clock (`time-format = "%-I:%M %p"`), restructured Set Clock menu (AM/PM → Hour 1-12 → Minute 0-9/10-19/…/50-59 buckets), trimmed burger menu (System Info / Dictionary / Connect USB only). Library skeleton emptied (49 EPUBs removed); content sideloaded per-device.
- v2.51-sangala — Removed Frontlight Save/Guess buttons and presets list. Frontlight window is just sliders.
- v2.52-sangala — Build workflow split: install package = everything-not-library, update package = library-only. Fixes Lesson #42 (Phase-2-interrupts-conversion crash).
- v2.53-sangala — Install package pre-creates the empty dot-folder library structure. Single-package deploy for repos that don't ship library content.

- v2.54-sangala — Workflow renames `-update.tar.gz` to `-library.tar.gz` (EPUB-only artifact). Install package still ships empty dot-folder structure. User populated the library from F:\Library (commit `61802e3`) and pushed the tag; release built and published as pre-release.

**Code/architecture summary:**
- KFMon-based launching restored (system partition: KFMon daemon + NickelMenu Qt plugin + KFMon-aware `on-animator.sh` + v2.19's simpler `plato-autostart.sh`; user partition: `.adds/kfmon/`, `.adds/nm/`, `.adds/plato/launch.png` 1×1 PNG trigger).
- Settings.toml time-format changed to 12-hour `%-I:%M %p`.
- Clock-set menu uses new EntryId variants `SetClockHour12(u32)`, `SetClockMinute(u32)`, `SetClockAmPm(bool)` (renamed from old `SetTimeHour`/`SetTimeMinute`).
- Burger menu (`view/common.rs::toggle_main_menu`) trimmed; Calculator still in binary but unreachable from menu.
- Frontlight (`view/frontlight.rs`) is sliders-only; preset infrastructure left as orphan code (`LightPreset` type, `frontlight_presets` settings field, `TogglePresetMenu` event handler all retained for serde compat but unreachable).

### Confirmed working

- v2.19's KFMon launcher pattern (KFMon's `on_boot=true` racing v2.19's `plato-autostart.sh sleep 10`): 10+ multi-power-cycles on Clara BW. Lesson #13's "racing launchers are fatal" claim disproved (Lesson #39).
- v2.49 retrofit: "working reliably" per user. Active production deployment.
- v2.50 / v2.51 / v2.52 / v2.53: manually-installed and confirmed running on user's devices.
- Manual drag-drop install procedure (extract install tarball → Explorer copy → taskbar eject → wait 3 min → reconnect → library copy → taskbar eject) is the safe deployment path.

### Confirmed broken

- **PS installer (`install-sangala.ps1`) on user's Windows setup.** PnP eject path is vetoed by some background process (Windows Search Indexer, antivirus, OneDrive, or Explorer window on D:); installer falls back to `Win32_Volume.Dismount (cooperative)` which leaves FAT dirty. On next boot, fsck.fat truncates dictionary.dict; Plato SIGBUSes on first book-open. Failure mode is identical to Lesson #42. **Do not recommend the PS installer for production.** The .ps1 still exists in repo and works on some Windows setups; just not this user's. Code-side hardening (loop-retry CM_Request, refuse cooperative fallback, etc.) is possible but deprioritized — user prefers manual install.
- All pre-v2.49 versions on multi-power-cycle (v2.32 through v2.48.1 — Lesson #31). Don't propose deploying any of those.

### Recommended install flow (v2.54+)

1. Connect Kobo, tap Connect USB.
2. Extract `plato-sangala-vX.Y-sangala-install.tar.gz`. Drag-drop the contents (including hidden `.kobo/` and `.adds/`) to the Kobo drive root.
3. Click the taskbar USB-eject icon, wait for "Safe to Remove."
4. Device shows "updating," reboots into Plato.
5. **Wait 3+ minutes** for first-boot dictionary conversion (otherwise Lesson #42 SIGBUS).
6. Reconnect via USB, tap Connect USB.
7. Extract `plato-sangala-vX.Y-sangala-library.tar.gz`. Drag-drop the contents to the Kobo drive root.
8. Eject via taskbar.

### Open issues / pending decisions

- **Biology 2e at 203 MB exceeded GitHub's 100 MB per-file cap.** User compressed it via Calibre Edit Book → Tools → Compress images (lossy, quality 60–70) successfully — v2.54 commit `61802e3` includes the compressed version (whatever final size). If future EPUBs exceed 100 MB, same procedure.
- **Dictionary on device.** User asked about complete removal but ultimately did not pursue (deleted on one test device then re-installed). Build still ships StarDict source in install package; conversion runs on first boot.
- **`-library.tar.gz` distribution to rural schools with bad internet.** Discussed in the session; user is converging on the pre-stage-on-USB pattern (download once on good internet, hand-carry to schools). No code action needed.
- **Calibre batch image compression.** Lossy compression in Edit Book is one-book-at-a-time GUI work. If user needs to bulk-process the library, a Python script using Calibre's bundled PIL/imagehandling could work. Out of scope this session.
- **Power Off menu entry removed in v2.50.** User confirmed they're OK using long-press of the hardware power button. CLAUDE-STATE Burger Menu section documents this. If a future session is asked to restore Power Off, that's the right place to add it back.

### Recommended first actions for next session

1. **Run the 4-check verification at session start** (Lesson #44): `pwd` → `git branch --show-current` → `git status` → `git log -1 --format='%h %s'`. Confirm: in `C:\Users\jbw3r\plato-sangala`, on `sangala-v2.48-base`, clean working tree, HEAD at `6c56160` or later. The actual last push from this session should be `6c56160 CLAUDE-STATE: 2026-06-09 handoff` on top of `61802e3 library: add EPUB content from F:\Library`.
2. **Check v2.54-sangala release** to confirm artifacts are uploaded (mcp__github__get_release_by_tag). Should have install + library + install-sangala.zip.
3. **Don't recommend the PS installer.** Manual drag-drop is the deployment path.
4. **Don't recommend re-enabling features removed this session** (Calculator, Power Off, Enable WiFi, Frontlight presets) without explicit user request.
5. **If new EPUBs are >100 MB**, the procedure is: Calibre → right-click the book → Edit Book → Tools → Compress images → enable "Enable lossy compression of JPEG images" → quality 60–70 → OK → Ctrl+S. Verify size via right-click in Calibre library → "Open containing folder" (the library window's size column is cached, doesn't refresh).

### Working-style notes from this session

- Search-verify before stating vendor UI paths. See Lesson #43.
- New-computer / clone-weirdness recovery sequence: see Lesson #44.
- User pushed back twice on Calibre UI claims — verify and acknowledge mistakes directly when caught. Don't pad apologies; state what was wrong and what the right answer is.
- User decided several features should go (Calculator, Power Off, WiFi toggle, Frontlight presets). They have specific deployment context (education, library devices). Don't argue feature removals.
- When user says "I have no further changes. Lets mark this as a new version and ship," that means tag-and-release the current branch tip. The user will follow up if more changes come up afterward.

## Session-End Handoff (2026-06-09, branch cleanup)

### Status

Repository branch hygiene fixed. No code or release changes — this was navigation cleanup only. The factory-reset fix (v2.49) and the v2.49–v2.54 releases are unchanged and still current. Everything in the prior 2026-06-09 handoff (UI polish + package rework + library workflow) still stands.

### What landed

- **Trunk renamed `sangala-v2.48-base` → `main`** and set as the GitHub default branch. Fresh clones / new sessions now land on `main` automatically instead of the ancient `sangala-reader`.
- **Added `CLAUDE.md`** to `main` — a short, harness-auto-loaded orientation pointer (canonical branch = `main`, read `CLAUDE-STATE.md` next, the load-bearing don'ts, recovery tag).
- **Deleted stale branches:** `sangala-reader` (was the bad default), `sangala-v2.48-base` (old trunk name), `claude/customize-plato-ui-1Edbm`, `claude/laughing-darwin-hHYv2`, `master`. (`claude/funny-fermat-oufn2k` was already gone from the remote.)
- **Archived the discarded experiment** (`claude/customize-plato-ui-1Edbm`, 27 unique commits) as tag **`archive/customize-plato-ui`** before deleting the branch. Recover with `git checkout -b recover archive/customize-plato-ui`.
- Release tags (`v2.3` … `v2.54`) untouched.

### End state

Exactly **one branch — `main`** (the default) — plus the `archive/customize-plato-ui` recovery tag and the existing release tags. See Lesson #45 for why this was the fix (and why merge/rebase wasn't).

### Recommended first actions for next session

1. **4-check (Lesson #44):** `pwd` → `git branch --show-current` (expect `main`) → `git status` → `git log -1 --format='%h %s'`. If a fresh clone drops you on a `claude/*` branch or an ancient commit with no `CLAUDE-STATE.md`, run `git fetch origin && git checkout main`. The auto-loaded `CLAUDE.md` should also point you here.
2. HEAD on `main` should be this branch-cleanup handoff commit, on top of `28cdf95 branch cleanup: rename trunk to main, add CLAUDE.md orientation pointer`.
3. If extra branches ever reappear at session start, check whether the Claude-on-web **environment is pinned** to a base branch other than the repo default — repoint it to `main`.
4. Nothing functional changed: the v2.54+ manual drag-drop deploy flow and the don't-propose list (Calculator / Power Off / Enable WiFi / Frontlight presets, Nickel, the PS installer for production, any pre-v2.49 version as stable) all still apply.

### Local artifacts note

The user's local clone has untracked installer build outputs under `sangala/installer/` (v2.48 `-install`/`-update` tarballs, their extracted dirs, `install-sangala.log`). Harmless, untracked, not on any branch. A `.gitignore` rule for them was offered but not requested this session.
