"""Build a text-only MPQ overlay for a pinned CoA client archive."""

import argparse
import gzip
import hashlib
from io import BytesIO
import json
import struct
import zlib
from pathlib import Path
from zipfile import ZipFile

HEADER = struct.Struct("<4s4I")
WORD = struct.Struct("<I")
MPQ_HEADER = struct.Struct("<4sIIHHIIII")
DBC_COLUMNS = {"Spell.dbc": {170, 187}}
LUA_PATHS = {
    "CharacterCreate.lua": r"Interface\GlueXML\CharacterCreate.lua",
    "CharacterSelect.lua": r"Interface\GlueXML\CharacterSelect.lua",
}
CHARACTER_LABEL_SITES = {
    "self:SetText(raceName)": "self:SetText(WoWKoreanCharacterLabel(raceName))",
    "CharCreateClassInfoFrame.title:SetText(className)": "CharCreateClassInfoFrame.title:SetText(WoWKoreanCharacterLabel(className))",
    'self:SetText(className:gsub(" ([^ ]*)$", "\\n%1", 1))':
        'self:SetText(WoWKoreanCharacterLabel(className):gsub(" ([^ ]*)$", "\\n%1", 1))',
}
UINT32 = 0xFFFFFFFF


def patch_dbc(original, columns):
    magic, count, width, row_size, string_size = HEADER.unpack_from(original)
    text_start = HEADER.size + count * row_size
    if magic != b"WDBC" or row_size != width * 4 or len(original) != text_start + string_size:
        raise ValueError("Malformed WDBC file")
    if any(column <= 0 or column >= width for column in columns):
        raise ValueError("Unsupported WDBC text column")

    records = bytearray(original[:text_start])
    strings = bytearray(original[text_start:])
    offsets = {}
    changed = {column: 0 for column in columns}
    for index in range(count):
        row = HEADER.size + index * row_size
        entry = WORD.unpack_from(original, row)[0]
        for column, labels in columns.items():
            text = labels.get(str(entry))
            if not text:
                continue
            encoded = text.encode("utf-8")
            if b"\0" in encoded:
                raise ValueError(f"Embedded NUL in DBC text for {entry}")
            previous = WORD.unpack_from(original, row + column * 4)[0]
            if previous >= string_size or original[text_start + previous] == 0:
                raise ValueError(f"Missing English DBC text for {entry}, column {column}")
            if encoded not in offsets:
                offsets[encoded] = len(strings)
                strings.extend(encoded + b"\0")
            WORD.pack_into(records, row + column * 4, offsets[encoded])
            changed[column] += 1
    for column, labels in columns.items():
        if changed[column] != len(labels):
            raise ValueError(f"Unmatched DBC rows for column {column}")
    WORD.pack_into(records, 16, len(strings))
    records.extend(strings)
    return records, changed


def patch_lua(original, spec):
    source = original.decode("utf-8")
    for english, korean in spec["replacements"].items():
        old = json.dumps(english, ensure_ascii=False)
        new = json.dumps(korean, ensure_ascii=False)
        if source.count(old) != 1:
            raise ValueError(f"Expected one exact Lua label: {english[:100]}")
        source = source.replace(old, new)
    for english, korean in spec.get("lore", {}).items():
        old = "[==[" + english + "]==]"
        if "]==]" in korean or source.count(old) != 1:
            raise ValueError(f"Expected one exact Lua lore entry: {english[:80]}")
        source = source.replace(old, "[==[" + korean + "]==]")
    names = spec.get("display_names", {})
    if names:
        for old, new in CHARACTER_LABEL_SITES.items():
            if source.count(old) != 1:
                raise ValueError(f"Expected one character UI text assignment: {old[:80]}")
            source = source.replace(old, new)
        pairs = "\n".join(
            f"    [{json.dumps(english, ensure_ascii=False)}] = {json.dumps(korean, ensure_ascii=False)},"
            for english, korean in sorted(names.items())
        )
        source = ("local wowKoreanCharacterLabels = {\n" + pairs + "\n}\n"
                  "local function WoWKoreanCharacterLabel(name)\n"
                  "    return wowKoreanCharacterLabels[name] or name\nend\n" + source)
    return source.encode("utf-8")


def crypt_table():
    table = [0] * 0x500
    seed = 0x100001
    for start in range(256):
        for index in range(start, 0x500, 256):
            seed = (seed * 125 + 3) % 0x2AAAAB
            upper = (seed & 0xFFFF) << 16
            seed = (seed * 125 + 3) % 0x2AAAAB
            table[index] = upper | (seed & 0xFFFF)
    return table


CRYPT = crypt_table()


def mpq_hash(name, kind):
    seed1, seed2 = 0x7FED7FED, 0xEEEEEEEE
    for byte in name.upper().encode("ascii"):
        seed1 = (CRYPT[(kind << 8) + byte] ^ (seed1 + seed2)) & UINT32
        seed2 = (byte + seed1 + seed2 + (seed2 << 5) + 3) & UINT32
    return seed1


def encrypt_table(source, name):
    seed1, seed2 = mpq_hash(name, 3), 0xEEEEEEEE
    encrypted = bytearray()
    for (value,) in struct.iter_unpack("<I", source):
        seed2 = (seed2 + CRYPT[0x400 + (seed1 & 0xFF)]) & UINT32
        encrypted.extend(WORD.pack((value ^ (seed1 + seed2)) & UINT32))
        seed1 = ((((~seed1 << 21) + 0x11111111) | (seed1 >> 11))) & UINT32
        seed2 = (value + seed2 + (seed2 << 5) + 3) & UINT32
    return encrypted


def create_mpq(path, files):
    files = dict(files)
    files["(listfile)"] = ("\r\n".join(files) + "\r\n").encode("ascii")
    count = len(files)
    hash_count = 1 << (2 * count - 1).bit_length()
    hashes = [None] * hash_count
    blocks = []
    # The files are independent DBC tables. Single-unit zlib also avoids
    # touching original archive metadata or other game assets.
    with path.open("wb") as output:
        output.write(bytes(MPQ_HEADER.size))
        for index, (name, data) in enumerate(files.items()):
            slot = mpq_hash(name, 0) & (hash_count - 1)
            while hashes[slot] is not None:
                slot = (slot + 1) & (hash_count - 1)
            hashes[slot] = struct.pack("<IIHHI", mpq_hash(name, 1), mpq_hash(name, 2), 0, 0, index)
            compressed = b"\x02" + zlib.compress(data, 6)
            if len(compressed) < len(data):
                payload, flags = compressed, 0x81000200
            else:
                payload, flags = data, 0x81000000
            blocks.append(struct.pack("<4I", output.tell(), len(payload), len(data), flags))
            output.write(payload)
        hash_start = output.tell()
        output.write(encrypt_table(b"".join(row or b"\xff" * 16 for row in hashes), "(hash table)"))
        block_start = output.tell()
        output.write(encrypt_table(b"".join(blocks), "(block table)"))
        end = output.tell()
        output.seek(0)
        output.write(MPQ_HEADER.pack(b"MPQ\x1a", MPQ_HEADER.size, end, 0, 3, hash_start, block_start, hash_count, count))


def inputs(path, names):
    if path.is_dir():
        return {name: (path / name).read_bytes() for name in names}
    import mpyq

    with ZipFile(path) as outer:
        members = [name for name in outer.namelist() if name.lower().endswith("/patch-zzzf.mpq")]
        if len(members) != 1:
            raise ValueError("Expected the CoA Custom 1.9.2 Client-5 ZIP")
        archive = mpyq.MPQArchive(BytesIO(outer.read(members[0])), listfile=False)
    return {
        name: archive.read_file(LUA_PATHS.get(name, f"DBFilesClient\\{name}")) or b""
        for name in names
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="CoA Custom 1.9.2 Client-5 ZIP or extracted text files")
    parser.add_argument("catalog", type=Path, help="Korean strings and source SHA-256 values")
    parser.add_argument("output", type=Path, help="New MPQ file")
    args = parser.parse_args()
    if args.catalog.suffix == ".gz":
        with gzip.open(args.catalog, "rt", encoding="utf-8") as source:
            catalog = json.load(source)
    else:
        catalog = json.loads(args.catalog.read_text(encoding="utf-8"))
    if not catalog or not catalog.keys() <= DBC_COLUMNS.keys() | LUA_PATHS.keys():
        raise ValueError("Expected supported CoA client text files in the catalog")
    originals = inputs(args.source, catalog)
    files = {}
    for name, spec in catalog.items():
        content = originals[name]
        if hashlib.sha256(content).hexdigest() != spec["sha256"]:
            raise ValueError(f"{name}: this hash is for a different CoA client")
        if name in LUA_PATHS:
            files[LUA_PATHS[name]] = patch_lua(content, spec)
            print(name, len(spec["replacements"]), "direct labels")
            continue
        columns = {int(column): rows for column, rows in spec["columns"].items()}
        if not columns.keys() <= DBC_COLUMNS[name]:
            raise ValueError(f"Unknown text column in {name}")
        files["DBFilesClient\\" + name], counts = patch_dbc(content, columns)
        print(name, sum(counts.values()), counts)
    if not files:
        raise ValueError("No client text was supplied")
    if args.output.exists():
        raise FileExistsError(f"Choose a new output path: {args.output}")
    try:
        create_mpq(args.output, files)
    except Exception:
        args.output.unlink(missing_ok=True)
        raise


if __name__ == "__main__":
    main()
