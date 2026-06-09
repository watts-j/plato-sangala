#!/usr/bin/env python3
"""Filter a StarDict .syn synonym file to drop entries that shadow a real word.

The source dictionary (reader-dict.com, en-en) ships a `.syn` synonym index.
Most of its ~597k entries are correct lemmatizations of inflected forms that
have no headword of their own -- `mice`->`mouse`, `geese`->`goose`,
`children`->`child` -- and are valuable for lookup. But a subset map a word
that ALREADY has its own headword to an unrelated entry (e.g. `book`->`bake`).
On lookup, that injected entry shadows the real word and shows a wrong
definition. This was the "book/cook return the wrong definition" bug.

Policy: keep a synonym only if its word is NOT already a main headword.
  - Words with their own (substantive) entry resolve to that entry.
  - Inflected forms without their own entry still resolve via the synonym.
  - No word is ever left showing an unrelated word's definition.

Rewrites `<dir>/dictionary.syn` in place and updates `synwordcount` in
`<dir>/dictionary.ifo`. Idempotent: re-running on already-filtered data is a
no-op. The pre-filter `.syn` remains recoverable from git history; the source
is also re-downloadable from reader-dict.com.

StarDict `.syn` records are `word\\0` + uint32 big-endian index into `.idx`
(always 32-bit, independent of idxoffsetbits). `.idx` records are
`word\\0` + uint32 offset + uint32 size.
"""
import os
import re
import sys


def main_headwords(idx_path):
    data = open(idx_path, "rb").read()
    mains = set()
    i, n = 0, len(data)
    while i < n:
        z = data.index(b"\x00", i)
        mains.add(data[i:z])          # raw bytes -> exact, case-sensitive match
        i = z + 9                      # null + 4-byte offset + 4-byte size
    return mains


def filter_dir(dirpath):
    idx = os.path.join(dirpath, "dictionary.idx")
    syn = os.path.join(dirpath, "dictionary.syn")
    ifo = os.path.join(dirpath, "dictionary.ifo")

    mains = main_headwords(idx)
    src = open(syn, "rb").read()

    out = bytearray()
    i, n = 0, len(src)
    kept = dropped = 0
    while i < n:
        z = src.index(b"\x00", i)
        word = src[i:z]
        rec = src[i:z + 5]             # word + null + 4-byte index
        i = z + 5
        if word in mains:
            dropped += 1
        else:
            out += rec
            kept += 1

    open(syn, "wb").write(out)

    txt = open(ifo, "r", encoding="utf-8").read()
    txt, sub = re.subn(r"(?m)^synwordcount=\d+\s*$", f"synwordcount={kept}\n", txt)
    if sub != 1:
        raise SystemExit(f"error: expected exactly one synwordcount line in {ifo}, found {sub}")
    open(ifo, "w", encoding="utf-8").write(txt)

    return kept, dropped


if __name__ == "__main__":
    d = sys.argv[1] if len(sys.argv) > 1 else "sangala/dictionaries"
    kept, dropped = filter_dir(d)
    print(f"kept {kept} synonyms, dropped {dropped} that shadowed a headword")
