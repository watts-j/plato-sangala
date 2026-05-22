# Plato Sangala — Project State

Last updated: 2026-05-15 (after v2.49 production deployment of ~30 devices)

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

- **v2.49-sangala** — **Current stable.** Ships the GUI installer as `install-sangala-gui.exe` (PS2EXE-compiled in CI by the new `gui-exe` windows-latest job) inside `install-sangala.zip` alongside the CLI .ps1. Verified in production deployment of ~30 factory-reset Clara BW devices (2026-05-15). Three changes over v2.48: (1) GUI installer's WinForms timer rewritten as a single tick handler dispatching by `$script:S.Mode` — fixes a handler-accumulation bug where Phase 2's completion was processed by Phase 1's leftover `On-CopyTick` first, re-ejecting the device and landing at Show-DetectedUpdate instead of Show-Done; (2) GUI installer falls back to `[Environment]::GetCommandLineArgs()[0]` when `$PSScriptRoot` is empty, so the PS2EXE-wrapped .exe can resolve its own directory (under PS2EXE the script is hosted in-memory and `$PSScriptRoot` is empty); (3) GUI's name-prompt status text dropped the stale "Welcome, {name}!" example (home screen has only shown the name itself since v2.45) — now says "e.g. \"John Smith\"". **Production note:** during the deployment ~30 devices installed cleanly; some retries needed but **the failure mode (frozen non-animated three dots after Phase 2) was caused by a flaky USB cable, not the installer.** Swapping the cable resolved every recurrence. The `install-sangala.log` for failing installs showed `CM_Request_Device_Eject` vetoing with veto=5 (`SWD\WPDBUSENUM`) or veto=6 (`STORAGE\Volume`) and falling back to cooperative `Win32_Volume.Dismount` — that path is benign as long as `Flush-Drive` ran first (which it always does); it's noise rather than corruption (see Lesson #27).
- **v2.48-sangala** — Previous stable. Verified end-to-end on factory-reset Clara BW (2026-05-08). CLI installer was the only supported path; the GUI installer (`install-sangala-gui.ps1`) was in the repo but **NOT bundled in `install-sangala.zip`** until v2.49. Three fixes over v2.47: (1) installer adds `IOCTL_STORAGE_EJECT_MEDIA` (after `FSCTL_LOCK_VOLUME` + `FSCTL_DISMOUNT_VOLUME`) before `CM_Request_Device_Eject` — without it, the host-side eject works but the Kobo's screen stays on "Connected" until cable yank; (2) `convert-dictionary.sh` swaps busybox-incompatible `trap '...' ERR` for `set -e` — silences `trap: ERR: invalid signal specification` log noise and gives actual exit-on-error semantics; (3) Plato's `query_to_content` auto-triggers `load_dictionaries()` if the map is empty at lookup time, so the first dictionary lookup after a fresh install no longer requires a manual "Reload Dictionaries" menu pick (provided the user waits for the on-device StarDict→dictd conversion to finish; about 1–2 minutes). Known oddity not in our scope: Kobo's update-processing flow on factory-reset Clara BW splits the KoboRoot.tgz application across two reboots with a spurious "power too low" warning between them; the install completes correctly despite this.
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

**v2.51-sangala** (will ship as pre-release; promote manually on GitHub Releases after device test passes). Queued for v2.51, three changes on top of v2.50:

1. **Drop the GUI `.exe` from `install-sangala.zip`.** Releases ship the CLI `.ps1` only, like v2.48 did. The `gui-exe` job is renamed `gui-exe-parse-check` and no longer uploads to the release — it just verifies the GUI source still PS2EXE-compiles, so we catch regressions if we ever resume shipping it. Motivation: production devices installed via the GUI `.exe` have intermittently performed real factory resets (recovery → OOBE wizard); CLI-installed devices haven't. Root cause is not yet identified (see Lesson #32). The CLI `.ps1` itself has been frozen since v2.48, matching the user's "last known stable" mental model.
2. **Remove "Enable WiFi" from the burger menu** (see Burger Menu section). One observed factory reset coincided with someone trying to connect to the internet; removing the WiFi path eliminates that vector.
3. **Remove the clock from the top bar.** In `crates/core/src/view/top_bar.rs`, dropped the `Clock` child entirely (was index 2 of 6); title label now extends to the battery widget's left edge. Renumbered the remaining children (battery 3→2, frontlight 4→3, menu 5→4) and removed `update_clock_label`. `crates/core/src/view/clock.rs`, the `ClockTick` event, the `ClockMenu` ViewId, and the periodic ClockTick scheduler in `app.rs` are unchanged — harmless dead code, kept so the clock is one-line to re-add if needed.

**v2.50-sangala** shipped (pre-release) on 2026-05-21, contains the dictionary-only-in-install-package fix (Lesson #31) — workflow change so `-update.tar.gz` no longer ships the StarDict source files. Artifact contents verified (update tarball has no `dictionary.{ifo,idx,dict.dz,syn}`; install tarball still has all four). On-device verification deferred pending resolution of the GUI factory-reset issue. The dictionary fix itself is a strict improvement and ships through into v2.51.

**Tagging discipline:** before suggesting any next tag number, fetch tags and check `git ls-remote --tags origin | awk '{print $2}' | sed 's|refs/tags/||;s|\^{}||' | sort -V -u | tail` (or use `mcp__github__list_tags`). The naive `sort -V` on full `ls-remote` output sorts by SHA, not by tag name. A previous session shipped a duplicate v2.46 tag because the assistant reasoned about tag positions from a misread `git rev-parse v2.X-sangala^{commit}` output (PowerShell ate the `{commit}` brace, the resulting `^` returned the parent commit, and the assistant treated that as the tag's commit). Always single-quote refs with `{}` in PowerShell: `'v2.X-sangala^{commit}'`.

**Releasing without softprops/action-gh-release flailing:** see Lesson #29. When a tag is force-deleted then re-pushed (which happened multiple times in v2.49's release cycle), the action sometimes leaves orphan **draft** release objects on GitHub with the same `tag_name`. They're invisible in the regular Releases UI but break the next CI run with `Too many retries / already_exists`. Cleanup procedure documented in Lesson #29.

## Welcome Name

As of v2.45 the home screen renders **just the configured name** (e.g., "Jo"), not "Welcome, Jo!". The text comes from the `welcome-name` field in the `[home]` section of `Settings.toml`. On device, that's `/mnt/onboard/.adds/plato/Settings.toml`; the placeholder shipped in builds is `welcome-name = "[name]"`.

To change a single device's name: edit that file directly (over USB) and reboot. Updates overwrite `Settings.toml` from the package, so per-device names need to be patched at install time.

To change the default that ships in every new build: edit `sangala/Settings.toml` in the repo.

The PowerShell installers prompt for the reader's name on a fresh install and patch the field automatically before copying. On a standalone update they read the existing on-device value and patch the update package with it, so updates don't revert the placeholder.

## Package Structure

Two packages produced per release; a fresh install runs both in sequence:

- **`-install.tar.gz`** — Bootstrap. System partition (`KoboRoot.tgz` with `on-animator.sh` + `plato-autostart.sh`) plus user-partition non-content (Plato app, `Settings.toml`, **dictionaries**, screensaver, `Kobo eReader.conf`). No EPUBs. ~30MB. Triggers Nickel's "updating" screen and an auto-reboot.
- **`-update.tar.gz`** — Content. Same user-partition files as install (Plato app, `Settings.toml`, screensaver, `Kobo eReader.conf`) **plus** the dot-prefixed library skeleton (EPUBs). **Excludes the StarDict dictionary sources** — those ship only in `-install.tar.gz` so subsequent updates don't overwrite the on-device dictd-format `.dict.dz` produced by `convert-dictionary.sh` (see Lesson #31). No `KoboRoot.tgz`. ~80MB.
- **`install-sangala.ps1`** — Separate download. PowerShell installer script.

Fresh install flow: copy install → eject → device updates and reboots → reconnect → copy update → eject. Subsequent updates just reapply the update package.

**Installer scripts** (both shipped inside `install-sangala.zip` from v2.49 onward; v2.48's zip contained only the CLI .ps1):
- `sangala/installer/install-sangala-gui.ps1` — WinForms wizard. Connect → detect → (fresh install: prompt for reader's name) → progress bar → eject → wait-for-reconnect → progress bar → done. Single WinForms Timer with one Tick handler attached for the form's lifetime; the handler dispatches by `$script:S.Mode` to `On-CopyTick` / `On-DisconnectTick` / `On-ReconnectTick`. Background runspace handles the long file copies. **Shipped as `install-sangala-gui.exe`** — PS2EXE-compiled in CI by the `gui-exe` windows-latest job, so end users get a normal double-click .exe with no ExecutionPolicy concerns. Source .ps1 stays in the repo and is editable; the .exe is rebuilt every CI run from whatever .ps1 is on the tag.
- `sangala/installer/install-sangala.ps1` — Console flow with the same logic. Shipped as the raw .ps1 alongside the .exe for users who want to inspect the script before running it.
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
- Applications (Calculator, Dictionary)
- Connect USB
- Power Off

(Removed: Invert Colors, Reboot, Enable WiFi)

**Enable WiFi removed in v2.51.** A production device factory-reset while a user was trying to connect to the internet (see Lesson #32). Nickel runs briefly at every boot before `plato-autostart.sh` kills it; if WiFi comes up during that window, Nickel can do an OTA check and decide the system looks tampered. Removing the menu entry closes that path entirely. The `ToggleWifi` event handler and `scripts/wifi-enable.sh` are still in the tree (so re-adding the entry later is one line in `crates/core/src/view/common.rs`), but there's no user-reachable way to enable WiFi from Plato anymore.

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

## Session-End Handoff (2026-05-15, after v2.49 production deployment)

**v2.49-sangala is shipped stable.** ~30 factory-reset Clara BW devices installed in a single deployment session (2026-05-15). The GUI installer (`install-sangala-gui.exe`, PS2EXE-compiled) drove every install. Some devices needed a second install attempt — root cause turned out to be a **flaky USB cable**, not a software bug. Once the cable was swapped, the failure mode (frozen non-animated three dots after Phase 2) stopped recurring. See Lesson #30.

**Branch `claude/customize-plato-ui-1Edbm` tip: `5e4479d`.** Latest tag: `v2.49-sangala` pointing at `5e4479d`. Verify with `git ls-remote --tags origin | awk '{print $2}' | sed 's|refs/tags/||;s|\^{}||' | sort -V -u | tail`.

### What shipped in v2.49 (commits since v2.48)

- `9545417` / `fefd9f5` — Drop the stale "Welcome, {name}!" copy from the GUI's name-prompt status text and from the CLI's comment header. Now says `e.g. "John Smith"`. (Per CLAUDE-STATE Welcome Name section, the home screen has only shown the name itself since v2.45.)
- `4cb9cb5` — GUI installer: replace per-phase `$script:timer.Add_Tick` / `Remove_Tick({})` churn with a single Tick handler attached for the form's lifetime that dispatches by `$script:S.Mode` to `On-CopyTick` / `On-DisconnectTick` / `On-ReconnectTick`. Fixes a handler-accumulation bug where the Phase 1 `On-CopyTick` handler stayed attached through Phase 2; when the Phase 2 copy completed, the Phase 1 handler fired first, ran `After-InstallStep1` → `Start-Disconnect { Show-WaitingForReconnect }`, re-ejected the device, waited for reconnect, and landed at `Show-DetectedUpdate` instead of `Show-Done`. Phase 2's own success callback never fired because Phase 1's handler had already cleared `$script:S.Bg`. (See Lesson #24.) Success callbacks now live in `$script:S.CopyOnSuccess` / `$script:S.DisconnectOnSuccess` rather than being captured in scriptblock closures, since PowerShell function-local parameters don't reliably resolve when the timer tick fires later.
- `7ce05d5` — Add `gui-exe` job to `.github/workflows/build-and-release.yml` (`runs-on: windows-latest`, `needs: build`). Uses `Install-Module ps2exe` then `Invoke-ps2exe ... -NoConsole` to compile the GUI .ps1 into a .exe. Repackages `install-sangala.zip` with both the CLI .ps1 and the GUI .exe at the archive root, then `gh release upload --clobber`s the build job's .ps1-only zip. End users get a double-click .exe; the .ps1 stays in the zip for users who want to inspect before running. The build job still produces a .ps1-only fallback zip first — if `gui-exe` fails, the release still has a working install path (degraded, no .exe).
- `5e4479d` — GUI installer: resolve `$ScriptDir` via a fallback chain so the PS2EXE-wrapped .exe can find its own directory. Under direct .ps1 invocation `$PSScriptRoot` is set; under PS2EXE it's empty (script is hosted in-memory), which used to make `Join-Path $ScriptDir 'install-sangala.log'` error with "Cannot bind argument to parameter 'Path' because it is an empty string" before the GUI even rendered. Fix uses `[Environment]::GetCommandLineArgs()[0]` (the .exe path) when `$PSScriptRoot` is empty. (See Lesson #28.)

### Production deployment lessons (2026-05-15)

- **The frozen-three-dots failure mode was a USB cable, not the installer.** From `install-sangala.log` it looked exactly like the v2.46 corruption pattern (Phase 2 eject falling back to cooperative `Win32_Volume.Dismount` after `CM_Request_Device_Eject` veto). Was about to push a v2.50 with retry+sleep+force-dismount when the user reported swapping the cable fixed it. **Always verify hardware before chasing software diagnostics.** The log can't see what reached the device's flash. (See Lesson #30.)
- **`SWD\WPDBUSENUM` veto=5 and `STORAGE\Volume` veto=6 from `CM_Request_Device_Eject` are noise, not failure.** They show up on the majority of installs once Windows has built up WPD enumeration state for the device class, but `Flush-Drive` (`FlushFileBuffers`) makes Windows' write cache durable BEFORE the eject sequence, and `ScsiEject`'s `IOCTL_STORAGE_EJECT_MEDIA` does fire (the WARN is only on the subsequent CM call). The cooperative-dismount fallback then succeeds. ~30 production installs confirm this path is safe in practice. **Don't add eject-path retries / longer sleeps / force-dismount changes without real evidence they're needed** — the existing code is working. (See Lesson #27.)
- **`softprops/action-gh-release@v2` accumulates orphan draft releases when a tag is force-deleted and re-pushed.** Hit twice in v2.49's release cycle. Symptoms: CI step "Create GitHub Release" logs `Using release N for tag X instead of duplicate draft M`, uploads succeed, then `Finalizing release...` fails with `HttpError: Validation Failed: already_exists` and "Too many retries". The orphan drafts are invisible in the regular Releases UI; only `gh api repos/<owner>/<repo>/releases` shows them. Cleanup procedure in Lesson #29.

### Known device-side oddity (still present, not in our scope)

On factory-reset Clara BW, the post-Phase-1 reboot shows three loading dots without the expected "Updating" text, then re-enters USBMS, shows a "power too low" warning even when fully charged, applies the update anyway, reboots once more, and *then* shows the proper "Updating" screen before launching Plato. Install completes correctly despite this. Confirmed harmless across the v2.49 production batch.

### Post-v2.49 in-flight fix (2026-05-21)

**Dictionary lookups occasionally returned wrong-offset fragments with raw markup** on devices that didn't reboot between Phase 2 eject and the first lookup. Root cause was the update package re-shipping the StarDict source `.dict.dz` and overwriting the converted dictd `.dict.dz` while leaving the matching `.index` untouched. Workflow fix landed: dictionary files now ship only in `-install.tar.gz`. See Lesson #31 for the full chain. **Not yet tagged** — queued for v2.50 device verification.

### Open questions for future sessions

1. ~~**GUI installer verification.**~~ **DONE.** Verified on factory-reset Clara BW (2026-05-12) and in production deployment (2026-05-15, ~30 devices); ships as `.exe` in v2.49.
2. **Single-package vs two-package install layout.** The two-package layout exists so subsequent updates don't re-trigger Nickel's "updating" reboot (`KoboRoot.tgz` ships only in `-install.tar.gz`). The friction it creates on fresh installs (two ejects, manual Connect USB between them, conversion gets killed mid-run by Phase 2 USB-connect, recovery cycles) was tolerable in the v2.49 batch but added ~2 minutes per device. Worth revisiting if another large-batch deployment is planned.
3. **Reduce first-install boot time by deprioritizing background conversion.** Conversion's disk I/O contends with Plato's startup reads on Clara BW's slow flash. Wrap the backgrounded call with `nice -n 19` and an initial `sleep 30` so Plato has uncontended I/O during startup. Expected savings: 30–60 s. Still listed in Long-term TODO.
4. **GUI: auto-continue Phase 2 after reconnect.** Currently the GUI lands at `Show-DetectedUpdate` post-reconnect and waits for the user to click "Update" again before starting Phase 2. The CLI does it automatically. The extra click cost ~30 user-seconds × 30 devices in the v2.49 batch — annoying, not blocking. One-line change in `On-ReconnectTick`: replace `Show-DetectedUpdate` with the equivalent of `Start-UpdateOnly` for the fresh-install path. Worth doing before v2.50 if another batch is on the horizon.
5. **(NEW) Pre-flight checklist for batch deployments.** v2.49's batch surfaced two avoidable causes of slowdown — flaky USB cable (~5 retries) and per-device second-click-to-Update. Worth writing a short pre-deploy checklist: spare USB cable on hand, charge devices to >50% before starting, stop `WPDBusEnum` + `WSearch` services preemptively (didn't end up needing it for the cable issue but it would tidy up the logs), have `mark-broken.ps1` ready in case a release goes bad mid-batch.

### Risks to watch for in future installer work

- **`IOCTL_STORAGE_EJECT_MEDIA` "drive in use" failures.** If the host has any stale handle on the volume (Search Indexer, antivirus, third-party file manager), the IOCTL may fail. The path swallows the failure (logs WARN, continues to `CM_Request_Device_Eject`). v2.49 batch confirmed this isn't a real failure mode in practice — `Flush-Drive` ran before eject, so even when the fallback chain ends at cooperative `Win32_Volume.Dismount` the data is already durable.
- **PS 5.1 parser regressions** when editing the `$ejectType` here-string. Run `[System.Management.Automation.Language.Parser]::ParseFile` on both installer scripts from PS 5.1 before pushing any tag. The here-string is ~190 lines of inline C# and has tripped parse cascades before.
- **WinForms timer handlers in PowerShell** — see Lesson #24. Single-dispatcher pattern (one `Add_Tick`, `switch` by state variable) is far safer than per-phase Add/Remove churn. If anyone reintroduces per-phase `Add_Tick`/`Remove_Tick` calls, the Phase-2 reversion bug will come back.
- **PS2EXE on windows-latest** — the `gui-exe` job in `.github/workflows/build-and-release.yml` does `Install-Module ps2exe` on every run. If PSGallery is down or the module signing model changes, the .exe build will fail. The build job's `install-sangala.zip` (.ps1 only) still uploads first, so a `gui-exe` failure means users see only the .ps1 in the zip — degraded but not broken.
- **PS2EXE strips `$PSScriptRoot`** — see Lesson #28. The fallback chain in v2.49's GUI handles this. If new code is added that uses `$PSScriptRoot` or `$MyInvocation.MyCommand.Path` directly, it will break under the .exe. Use `$script:ScriptDir` (already-resolved) instead.
- **`softprops/action-gh-release@v2` orphan draft accumulation** — see Lesson #29. If a tag is force-deleted (e.g., to re-tag at a fixed commit), the action's draft management can leave orphans. Use `gh api repos/<owner>/<repo>/releases` to find them; delete by ID before re-pushing the tag.
- **Tag bookkeeping.** Always `git fetch origin --tags` first, then `mcp__github__list_tags` (or `git ls-remote --tags origin | awk '{print $2}' | sed 's|refs/tags/||;s|\^{}||' | sort -V -u`). The naive `sort -V` on full `ls-remote` output sorts by SHA, not by tag name. Single-quote refs with `{}` in PowerShell.
- **`gh` CLI is installed** on the user's Windows machine. The user also has `strip-release-sections.ps1` and `mark-broken.ps1` on `C:\Users\jbw3r\Desktop\Plato\` (or `Install\`) for editing past release bodies. Reuse these patterns rather than re-spawning new ad-hoc scripts.
- **The user works across multiple Windows machines.** v2.49 was tagged from a different machine than the one used for the v2.48 work. When picking up a session, don't assume the user's local repo state matches origin — have them `git fetch && git pull` first.

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
24. **WinForms Timer `Remove_Tick({})` is a silent no-op in PowerShell.** `.NET`'s event-remove path needs the same delegate instance that was added; PowerShell wraps each Add_Tick scriptblock in a separate delegate wrapper, and passing a fresh `{}` to `Remove_Tick` doesn't match anything. Handlers accumulate across phase transitions, and the *first* attached handler keeps firing alongside whatever you thought you swapped in — in the GUI installer this caused Phase 2's completion to be processed by Phase 1's leftover `On-CopyTick` first, which then re-ejected the device. **Safer pattern: attach exactly one Tick handler at script load time and dispatch by a state variable.** Don't try to add/remove handlers across state transitions; you'll either fail silently (PowerShell scriptblock identity) or have to thread the delegate object through your state to remove it later.
25. **GitHub raw URLs are CDN-cached for ~5 minutes.** When iterating an installer script, cache-bust pulls with `?cb=$([guid]::NewGuid().ToString())` to avoid debugging stale code. After this, also re-run the parser pre-flight to confirm what was downloaded matches what was pushed.
26. **Most macOS users won't see the Sangala folders** in Finder by default because they all start with `.`. Cmd+Shift+. toggles hidden-file visibility. Same files exist; Finder just hides them. Tell users this up front.
27. **`CM_Request_Device_Eject` veto=5 (`SWD\WPDBUSENUM`) and veto=6 (`STORAGE\Volume`) are noise, not failure**, *as long as* `Flush-Drive` (`FlushFileBuffers`) ran before the eject sequence. The `WPDBUSENUM` veto fires whenever Windows Portable Devices service has cataloged the device (almost always, after the first install of the session). The fallback path engages cooperative `Win32_Volume.Dismount`; data is already durable from the prior `Flush-Drive` call, so the device disconnects cleanly. v2.49's production batch (~30 devices) confirmed this — the WARN lines look alarming but every install completed correctly in this path. Don't chase eject-path retries / longer sleeps / force-dismount changes purely on the basis of these WARN lines; demand evidence of actual device-side corruption first.
28. **PS2EXE-wrapped scripts have `$PSScriptRoot` empty.** PS2EXE hosts the source in-memory rather than loading it from a .ps1 on disk, so `$PSScriptRoot` (set by PowerShell's script loader) and `$MyInvocation.MyCommand.Path` are both empty. Naive `$ScriptDir = $PSScriptRoot` then `Join-Path $ScriptDir 'log.log'` errors with "Cannot bind argument to parameter 'Path' because it is an empty string" before the GUI even renders, and every later `Out-File -FilePath` then fails with "...because it is null". Use a fallback chain: `if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent ([Environment]::GetCommandLineArgs()[0]) }`. The `[Environment]::GetCommandLineArgs()[0]` returns the running .exe's path under PS2EXE (and PowerShell.exe's path under direct invocation, where `$PSScriptRoot` is non-empty so the fallback isn't reached).
29. **`softprops/action-gh-release@v2` accumulates orphan draft releases when a tag is force-deleted and re-pushed.** If a tag has been re-pushed (e.g., to re-point at a fixed commit), the action's "find existing release for this tag, or create one" logic can race and leave orphan **draft** releases on GitHub with the same `tag_name`. Drafts are invisible in the regular Releases UI but break subsequent CI runs with `HttpError: Validation Failed: already_exists` on the "Finalizing release" PATCH, then "Too many retries / Aborting...". **Cleanup procedure:** (1) list ALL releases including drafts via `gh api repos/<owner>/<repo>/releases | ConvertFrom-Json | Select-Object id, tag_name, draft, name | Format-Table -AutoSize` (the regular `gh release list` may hide drafts); (2) for each release with `tag_name = vX.Y-sangala`, delete by ID with `gh api -X DELETE repos/<owner>/<repo>/releases/<id>`; (3) `git push --delete origin vX.Y-sangala` and `git tag -d vX.Y-sangala`; (4) verify clean state with `git ls-remote --tags origin | Select-String 'vX\.Y'` (nothing) and the gh api call again (no rows for that tag); (5) re-tag and `git push origin vX.Y-sangala`.
30. **Verify hardware before chasing software diagnostics.** v2.49's production batch had a "frozen non-animated three dots after Phase 2" failure mode that looked exactly like FAT corruption from `install-sangala.log` — `CM_Request_Device_Eject` vetoing, fallback to cooperative `Win32_Volume.Dismount`, the v2.46 corruption fingerprint. Was about to push v2.50 with retry+sleep+force-dismount when the user reported swapping the USB cable resolved every recurrence. The flaky cable was dropping writes mid-stream, truncating the Plato binary on the user partition, leaving the device in a state where `plato-autostart.sh` killed `on-animator` (dots stop animating mid-frame) then `exec'd plato.sh` which couldn't run the truncated binary — visible symptom: frozen dots. The host-side log can't see what reached the device's flash, so software-only diagnosis is structurally limited. **Always ask "did anything physical change?" before pushing a software fix for an intermittent install failure.**
31. **The update package must not re-ship the raw StarDict dictionary sources.** Through v2.49 the build used a single `shared-content/` tree for both packages and the dictionary `cp` lived inside it, so both `-install.tar.gz` and `-update.tar.gz` carried `.ifo` / `.idx` / `.dict.dz` (StarDict gzip+dictzip) / `.syn`. On a fresh install: Phase 1 brings StarDict sources → `convert-dictionary.sh` produces dictd-format `.dict.dz` + `.index` (different byte layout, ~+1.3 MB, different chunk boundaries) → Phase 2's USBMS copy overwrites `.dict.dz` with the StarDict-source bytes while leaving the dictd `.index` untouched (`.index` isn't in the package). Both files are valid dictzip headers, so Plato's `load_dict` accepts the mismatched pair; the loaded `.index` then points to offsets that don't correspond to anything in the StarDict `.dict.dz`. Lookups return decompressed chunks from wrong offsets — fragments of unrelated definitions, often containing raw StarDict markers like `[en]` / `[de]` that the conversion's Wiktionary sed step would have wrapped in `<p>...</p>` (visible as "markup leaking through"). Plato never recovers on its own: `app.rs`'s `DeviceEvent::Unplug` handler runs `usb-disable.sh` and `library.reload()` after USBMS but never re-runs `load_dictionaries()`, and the only thing that invokes `convert-dictionary.sh` is `plato.sh` at boot. So the bad state persists until the user reboots. Reported symptom from production: "after install + update, let the device rest 10–15 min, do a dictionary lookup, and the definition is a sentence fragment from a wrong entry with visible markup". **Fix (post-v2.49):** moved the dictionary `cp` out of `shared-content` and into the `Assemble install package` step in `.github/workflows/build-and-release.yml`, so the update tarball no longer carries dictionary files. The conversion artifacts on the device are untouched by Phase 2 / standalone updates. Cost: dictionary content changes won't propagate via standalone update; full reinstall required for that (acceptable — never updated yet, and Long-term TODO #1 to pre-convert in CI would supersede this).
32. **GUI installer (PS2EXE-wrapped .exe) is correlated with real factory resets on production Kobo Clara BW devices; root cause not yet identified.** Symptom: device crashes, enters recovery mode, boots into Kobo's OOBE wizard (real factory reset — user partition wiped, library gone). Often happens immediately after install; sometimes after several reboots or days of use. One observed reset happened while someone was trying to connect to WiFi. **The CLI `.ps1` installer (running on the same host, against the same packages) has not caused this on any device.** Investigated the diff between the two installers and found two relevant deltas: (a) the GUI copies in a background runspace via `[runspacefactory]::CreateRunspace()`, and (b) the GUI's reconnect polling fires every 500 ms vs. the CLI's 3 seconds. Neither is a proven root cause. Could not gather device-side evidence (`info.log`, `dictionary.log`, `KoboReader.sqlite`) because factory reset wipes the user partition. Host-side `install-sangala.log` consistently looks clean on affected devices. **v2.51 action: drop the GUI `.exe` from `install-sangala.zip` entirely.** The GUI .ps1 source stays in the repo; CI still PS2EXE-compiles it as a parse-check but doesn't upload it to releases. Also removed "Enable WiFi" from the burger menu in the same release, on the theory that Nickel's brief pre-plato-autostart window + WiFi could trigger an OTA-based tamper-detect path; this isn't proven either but the WiFi entry was non-essential for the deployment context. **Re-introducing the GUI .exe requires either device-side forensic evidence of what corrupts during install, OR a fundamentally different GUI architecture (e.g., synchronous copy in foreground, no background runspace). Do not flip the upload back on without that.**
