#!/usr/bin/env python3
"""Convert StarDict dictionary to dictd format.

Replaces Plato's ARM-only sdunpack + dictfmt + dictzip pipeline
with a pure x86 equivalent for CI builds.
"""
import struct
import gzip
import sys
import subprocess
import os


def read_idx(idx_path):
    """Parse a StarDict .idx file into (headword, offset, size) tuples."""
    with open(idx_path, 'rb') as f:
        data = f.read()

    entries = []
    pos = 0
    while pos < len(data):
        null = data.index(b'\x00', pos)
        headword = data[pos:null].decode('utf-8', errors='replace')
        offset, size = struct.unpack('>II', data[null+1:null+9])
        entries.append((headword, offset, size))
        pos = null + 9
    return entries


def read_syn(syn_path):
    """Parse a StarDict .syn file into (synonym, target_index) tuples."""
    with open(syn_path, 'rb') as f:
        data = f.read()

    synonyms = []
    pos = 0
    while pos < len(data):
        null = data.index(b'\x00', pos)
        word = data[pos:null].decode('utf-8', errors='replace')
        target = struct.unpack('>I', data[null+1:null+5])[0]
        synonyms.append((word, target))
        pos = null + 5
    return synonyms


def read_dict(dict_path):
    """Read a .dict or .dict.dz file."""
    if dict_path.endswith('.dz'):
        with gzip.open(dict_path, 'rb') as f:
            return f.read()
    else:
        with open(dict_path, 'rb') as f:
            return f.read()


def read_ifo(ifo_path):
    """Read bookname and website from .ifo file."""
    info = {}
    with open(ifo_path, 'r') as f:
        for line in f:
            if '=' in line:
                key, val = line.strip().split('=', 1)
                info[key] = val
    return info


def convert(ifo_path, output_base):
    base = ifo_path.rsplit('.', 1)[0]
    ifo = read_ifo(ifo_path)
    bookname = ifo.get('bookname', 'Dictionary')
    website = ifo.get('website', '')

    # Read StarDict files
    idx_entries = read_idx(base + '.idx')

    dict_path = base + '.dict.dz'
    if not os.path.exists(dict_path):
        dict_path = base + '.dict'
    dict_data = read_dict(dict_path)

    # Read synonyms if present
    syn_path = base + '.syn'
    synonyms = read_syn(syn_path) if os.path.exists(syn_path) else []

    # Build synonym map (target_index -> list of synonyms)
    syn_map = {}
    for word, target in synonyms:
        syn_map.setdefault(target, []).append(word)

    # Write text file for dictfmt in -c5 format
    txt_path = output_base + '.txt'
    with open(txt_path, 'w', encoding='utf-8') as f:
        for i, (headword, offset, size) in enumerate(idx_entries):
            definition = dict_data[offset:offset+size].decode('utf-8', errors='replace')
            definition = definition.replace('\r', '')

            # Combine headword with synonyms
            all_words = [headword]
            if i in syn_map:
                all_words.extend(syn_map[i])
            headwords = '|'.join(all_words)

            f.write(f"_____\n{headwords}\n{definition}\n")

    # Run dictfmt to create dictd format
    dictfmt_cmd = [
        'dictfmt', '--quiet', '--utf8',
        '--headword-separator', '|',
        '-s', bookname,
        '-u', website,
        '-c5', output_base,
    ]
    with open(txt_path, 'r') as stdin:
        subprocess.run(dictfmt_cmd, stdin=stdin, check=True)

    # Compress with dictzip
    subprocess.run(['dictzip', output_base + '.dict'], check=True)

    # Clean up text file
    os.remove(txt_path)

    print(f"Converted: {output_base}.dict.dz + {output_base}.index")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.ifo> <output_base>")
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])
