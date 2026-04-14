# Sangala Reader

A custom build of [Plato](https://github.com/baskerville/plato) for the **Kobo Clara BW**, developed for the Sangala Reader Initiative. It replaces Plato's flat library list with a cascading academic taxonomy and ships a preconfigured library skeleton suitable for classroom deployment.

This is a fork. All credit for Plato itself goes to [@baskerville](https://github.com/baskerville). Modifications here are licensed under the same terms (AGPL-3.0).

---

## What's different from upstream Plato

- **Cascading taxonomy menu.** The title-bar library menu is a hierarchical structure (STEM → Mathematics → Algebra, etc.) rather than a flat list of libraries.
- **New event variant `LoadLibraryAndSelectDirectory`.** Allows a single menu entry to switch libraries *and* apply a directory filter atomically.
- **Four top-level libraries:** STEM, Humanities, Enrichment, Resources. Sub-disciplines are subfolders within each, surfaced through the cascading menu.
- **Library skeleton included.** `sangala/library-skeleton/` contains the empty folder structure to drop onto a device.
- **Preconfigured `Settings.toml`** pointing at the four libraries in database mode.

---

## Repository layout

```
crates/                  Modified Plato source (see `git diff upstream/master`)
sangala/
  Settings.toml          Drop into /mnt/onboard/.adds/plato/ on the device
  library-skeleton/      Copy contents to /mnt/onboard/ on the device
README-sangala.md        This file
```

---

## Build prerequisites

Plato for Kobo must be built against an old toolchain because Kobo firmware ships GLIBC 2.18.

- **Linaro GCC 4.9.4** — `gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf` (download from the Linaro releases archive)
- **Rust** stable toolchain with the `arm-unknown-linux-gnueabihf` target installed
- **WSL2** (Ubuntu 22 or similar) or native Linux. Native Windows is not supported.
- Plato's standard `thirdparty/` dependencies (mupdf, djvulibre, etc.) — built with the same Linaro toolchain

> **Why Linaro 4.9.4 specifically:** newer GCCs link against GLIBC symbols Kobo's runtime doesn't provide. `readelf -V plato | grep GLIBC_` on a working build should show no version higher than `GLIBC_2.18`.

---

## Building

```bash
# Set the cross-compiler in your shell
export PATH=/path/to/gcc-linaro-4.9.4-.../bin:$PATH
export CC=arm-linux-gnueabihf-gcc

# Build Plato's bundled C dependencies
cd thirdparty
./download.sh && ./build.sh
cd ..

# Build the wrapper static library
cd crates/mupdf_wrapper
./build.sh
cd ../..

# Build only the Plato binary (skip the fetcher crate, which transitively
# pulls in aws-lc-sys; that crate's ARMv8 crypto assembly is incompatible
# with the Linaro 4.9.4 assembler)
cargo build -p plato --release --target arm-unknown-linux-gnueabihf

# Strip
arm-linux-gnueabihf-strip target/arm-unknown-linux-gnueabihf/release/plato
```

The output binary is `target/arm-unknown-linux-gnueabihf/release/plato` (~6 MB stripped).

---

## Deployment to a Kobo Clara BW

1. Connect the Kobo via USB and mount it (`/mnt/onboard` from the device's perspective; appears as a removable drive on the host).
2. Sideload Plato per the upstream Plato instructions: copy the `.adds/plato/` tree, the KoboRoot.tgz launcher, etc.
3. Replace the default `Settings.toml` with `sangala/Settings.toml`.
4. Replace the `plato` binary with your build.
5. Copy the contents of `sangala/library-skeleton/` into `/mnt/onboard/` so the four taxonomy roots exist.
6. Eject and let the device restart.

After first run, each empty subfolder will contain a `.fat32-epoch` file. This is Plato's workaround for FAT32's 2-second timestamp resolution — leave it alone.

---

## Customizing the taxonomy

The taxonomy is defined in two places that must be kept in sync:

- **Folder structure** under `sangala/library-skeleton/` (and on the device)
- **Menu structure** in `crates/core/src/view/home/mod.rs`, inside `toggle_title_menu` — look for the `find_lib` closure and the `EntryKind::SubMenu(...)` tree it builds

To add a new sub-discipline: create the folder on disk, then add a corresponding `EntryKind::Command(... LoadLibraryAndSelectDirectory(idx, PathBuf::from("Subfolder/Name")))` entry in the menu builder.

To add a new top-level library: also add it to `Settings.toml` under `[[libraries]]`.

---

## License

AGPL-3.0, inherited from upstream Plato. Any redistributed binary built from this source must be accompanied by the corresponding source.

---

## Acknowledgements

- [Plato](https://github.com/baskerville/plato) by Bastien Dejean
- The Sangala Reader Initiative
