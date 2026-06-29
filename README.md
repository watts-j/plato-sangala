# Sangala Reader

A custom build of [Plato](https://github.com/baskerville/plato) for the **Kobo Clara BW**, developed for the Sangala Reader Initiative. It replaces Plato's flat library list with a cascading academic taxonomy and ships a preconfigured library skeleton suitable for classroom deployment.

This is a fork. All credit for Plato itself goes to [@baskerville](https://github.com/baskerville). Modifications here are licensed under the same terms (AGPL-3.0).

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

## Deployment to a Kobo Clara BW

The Sangala Reader is a customized reading interface that runs on Kobo Clara BW e-ink devices. It replaces the native user interface with platform that presents a curated library of textbooks organized by content area. The navigation menu is fully customizable, meaning that the device can be made to align with any school curriculum.

The native clock and dictionary remain intact, but potentially distracting apps and features like games, virtual news-stands, and WIFI have been disabled.

### Files
The installation files for the reader come in two packages.

The Install Package
   
The Content Package

### Installation
For now, installation must be performed manually. I am in the process of developing an installer that will handle both packages as well as setting the User Name, but it is not quite ready yet.

To install the reader on a factory reset Kobo Clara BW eReader follow the steps below. If your device has already been set up as a Kobo eReader, begin by going to “Device Information” under the burger menu in the top right corner of the screen and performing a factory reset.

Turn on the device and proceed through the setup wizard until you reach the screen that scans for Wifi connections.
Connect the device to a computer via USB cable. A prompt on your device screen will ask to connect as a USB device. Click “OK”.
Unzip the contents of the Install package.
Inside the unzipped folder, open the Sangala-Install folder. Inside, you will see eight folders. If you do not see these folders, show hidden files. (On a Mac, press CMD+Shift+. at the same time.)
Copy these eight folders.
Navigate to the device on your computer. It should appear as “KOBOeReader”.
Paste the copied folders into the top level of the device. If prompted, replace duplicate files.
Eject your device from the computer and then unplug the USB cable.
DO NOT POWER OFF THE DEVICE AFTER IT REBOOTS.

The device takes several minutes to process the installation. If this process is inturrupted, files may be corrupted.

After 3-5 minutes, open the burger menu in the top right corner of the screen and select “Dictionary”. Attempt to look up a word. f the definition does not load, wait a few more minutes, tap “Dictionary” at the top of the screen and click “Update dictionary”. Then search again. Once the word definition appears, initial installation is complete.

### Loading Content
To load content onto the device, reconnect to your computer via USB, unzip the Sangala-Library file, and open it to the six subfolders. Copy these subfolders onto the top level of your device, replacing any duplicate files.

Additional content can be added simply by dragging and dropping an .epub document into the desired folder path. (IMPORTANT: The .Menu folder must alway be left empty.)

### Setting the User Name
Open the .adds folder and then the plato folder on the device. Locate and open the Settings file in a text editor.

Under the “[home]” section (line 75), replace the welcome name with the user name, leaving the quotes around it. Save the file and eject the device.

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

- [Plato](https://github.com/baskerville/plato) by Bastien Dejean
- The Sangala Reader Initiative
