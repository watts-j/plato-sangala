#! /bin/sh
# Converts a StarDict dictionary to the dictd format.
# The first argument must be the path to the IFO file.
#
# Crash-safe: source files are hard-linked to .${base}.bak.${ext} before
# any destructive operation, and a .${base}.converting marker is touched.
# If the script gets killed mid-conversion (reboot, USB-connect, low
# battery), the next run sees the marker, wipes any partial state, and
# restores the sources from the hard-linked backups before retrying.

trap 'exit 1' ERR

base=${1%.*}
bindir=bin/utils
short_name=$(grep '^bookname=' "$1" | cut -d '=' -f 2)
url=$(grep '^website=' "$1" | cut -d '=' -f 2)

dir=$(dirname "$1")
base_name=$(basename "$base")
recovery_marker="${dir}/.${base_name}.converting"
backup_prefix="${dir}/.${base_name}.bak."

# --- Recovery -------------------------------------------------------------
# A leftover marker means a previous run died mid-conversion. Wipe partial
# state and restore the source files from the hard-linked backups before
# retrying. Errors here are benign (best-effort cleanup).
if [ -e "$recovery_marker" ]; then
    echo "Recovery: previous conversion of ${short_name} was interrupted; restoring sources."
    trap - ERR
    rm -f "$1" "${base}.idx" "${base}.txt" "${base}.syn" "${base}.dict" "${base}.dict.dz" "${base}.index" 2>/dev/null
    for bak in "${backup_prefix}"*; do
        [ -e "$bak" ] || continue
        ext=${bak##*.bak.}
        ln "$bak" "${base}.${ext}" 2>/dev/null || cp "$bak" "${base}.${ext}"
    done
    trap 'exit 1' ERR
fi

# --- Backup ---------------------------------------------------------------
# Hard-link each source to .bak.<ext>. dictzip -d's unlink of the original
# name doesn't free the inode while the .bak name still references it, so
# we can recover from any partial conversion state below.
for ext in ifo idx dict.dz syn; do
    src="${base}.${ext}"
    bak="${backup_prefix}${ext}"
    if [ -e "$src" ]; then
        rm -f "$bak"
        ln "$src" "$bak"
    fi
done

# Mark conversion as in-progress so the next run can detect interruption.
: > "$recovery_marker"

# --- Conversion (unchanged from upstream) ---------------------------------
echo "Converting ${short_name} (${1})."

[ -e "${base}.dict.dz" ] && "$bindir"/dictzip -d "${base}.dict.dz"

args="${base}.dict"

[ -e "${base}.syn" ] && args="$args ${base}.syn"

# shellcheck disable=SC2086
"$bindir"/sdunpack $args < "${base}.idx" > "${base}.txt"
[ "${short_name%% *}" = "Wiktionary" ] && sed -i 's/^\([\[/].*\)/<p>\1<\/p>/' "${base}.txt"
"$bindir"/dictfmt --quiet --utf8 --index-keep-orig --headword-separator '|' -s "$short_name" -u "$url" -t "$base" < "${base}.txt"
"$bindir"/dictzip "${base}.dict"

rm "$1" "${base}.idx" "${base}.txt"
[ -e "${base}.syn" ] && rm "${base}.syn"

# --- Cleanup --------------------------------------------------------------
# Conversion fully succeeded. Drop the recovery state.
rm -f "${backup_prefix}"* "$recovery_marker"
