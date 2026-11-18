"""Build the guarded Lua dictionaries from reference world data and koKR exports."""

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIELDS = ("title", "description", "objectives", "progress", "completion")
HANGUL = re.compile(r"[가-힣]")
INSERT = re.compile(
    r"^\s*(?:INSERT(?: IGNORE)?|REPLACE)\s+INTO\s+`?(\w+)`?"
    r"\s*(?:\(([^)]+)\))?\s*VALUES\s*(.*)$",
    re.I,
)
CREATE = re.compile(r"^CREATE TABLE (?:IF NOT EXISTS )?`?(\w+)`?", re.I)
INSERT_TABLE = re.compile(r"^\s*(?:INSERT(?: IGNORE)?|REPLACE)\s+INTO\s+`?(\w+)`?", re.I)
COLUMN = re.compile(r"^\s+`([^`]+)`\s")
VALUE = re.compile(r"'((?:[^'\\]|\\.|'')*)'|\"((?:[^\"\\]|\\.|\"\")*)\"|([^(),'\"\s;]+)|([(),;])", re.S)
ESCAPES = {"0": "\0", "b": "\b", "n": "\n", "r": "\r", "t": "\t", "Z": "\x1a"}
ASCII_LOWER = str.maketrans(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ’‘“”\u00a0", "abcdefghijklmnopqrstuvwxyz''\"\" "
)


def tuples(payload):
    values = None
    tail = 0
    for token in VALUE.finditer(payload):
        if payload[tail:token.start()].strip():
            raise ValueError(f"Invalid SQL near character {tail}")
        tail = token.end()
        single_quoted, double_quoted, bare, delimiter = token.groups()
        if delimiter == "(":
            if values is not None:
                raise ValueError(f"Unexpected opening parenthesis near {payload[max(0, token.start()-65):token.start()+12]!r}")
            values = []
        elif delimiter == ")":
            if values is None:
                raise ValueError("Unexpected closing parenthesis")
            yield values
            values = None
        elif values is None and bare and bare.upper() == "ON":
            # An upsert may follow the last tuple. Only the values are inputs here.
            return
        elif values is not None:
            if single_quoted is not None or double_quoted is not None:
                quote = "'" if single_quoted is not None else '"'
                values.append(re.sub(
                    r"\\(.)|" + quote * 2,
                    lambda match: ESCAPES.get(match[1], match[1]) if match[1] else quote,
                    single_quoted if single_quoted is not None else double_quoted, flags=re.S,
                ))
            elif bare is not None:
                values.append(None if bare.upper() == "NULL" else bare)
    if values is not None or payload[tail:].strip():
        raise ValueError("Unterminated SQL row")


def read_sql(path, tables):
    """Read data rows only, with explicit columns or a preceding CREATE TABLE."""
    schema = {}
    with path.open(encoding="utf-8-sig") as sql:
        for line in sql:
            create = CREATE.match(line)
            if create and create[1].lower() in tables:
                columns = []
                for definition in sql:
                    column = COLUMN.match(definition)
                    if column:
                        columns.append(column[1].lower())
                    if definition.startswith(")"):
                        break
                schema[create[1].lower()] = columns
                continue
            if not line.lstrip().upper().startswith(("INSERT ", "REPLACE ")):
                continue
            header = INSERT_TABLE.match(line)
            if not header or header[1].lower() not in tables:
                continue
            statement = INSERT.match(line)
            if not statement and not line.rstrip().endswith(";"):
                statement = INSERT.match(line.rstrip() + " " + next(sql))
            if not statement:
                raise ValueError(f"{path.name}: unsupported INSERT for {header[1]}")
            table = statement[1].lower()
            columns = (
                [part.strip(" `").lower() for part in statement[2].split(",")]
                if statement[2] else schema[table]
            )
            payload = [statement[3] + "\n"]
            while not payload[-1].rstrip().endswith(";"):
                payload.append(next(sql))
            for values in tuples("".join(payload)):
                if len(columns) != len(values):
                    raise ValueError(f"{path.name}: {table} has {len(values)} values for {len(columns)} columns")
                yield table, dict(zip(columns, values))


def collect(paths, spec, *, korean=False):
    result = defaultdict(dict)
    for path in paths:
        for table, row in read_sql(path, spec):
            if korean and row.get("locale", "koKR") != "koKR":
                continue
            kind, key, fields = spec[table]
            entry = result[kind].setdefault(int(row[key]), {})
            for output, inputs in fields.items():
                value = next((row.get(field) for field in inputs if row.get(field)), None)
                if value:
                    entry[output] = value
    return result


def mapping(*names):
    return {field: tuple(name.split("/")) for field, name in zip(FIELDS, names)}


def names(title, extra):
    return {"title": (title,), "description": (extra,)}


def normalize(text):
    text = text.translate(ASCII_LOWER).replace("|n", " ")
    text = re.sub(r"\$[bB]", " ", text)
    return re.sub(r"[ \t\r\n\v\f]+", " ", text).strip(" ")


def guard(text):
    if not isinstance(text, str) or re.search(r"\$[nrcg]", text, re.I):
        return text
    encoded = normalize(text).encode("utf-8")
    digest = 0
    for byte in encoded:
        digest = (digest * 131 + byte) % 2147483647
    return len(encoded), digest


def mop(reference, ko):
    base = {
        "quest_template": ("quests", "id", mapping("title/logtitle", "details/questdescription", "objectives/logdescription")),
        "quest_offer_reward": ("quests", "id", {"completion": ("rewardtext",)}),
        "quest_request_items": ("quests", "id", {"progress": ("completiontext",)}),
        "creature_template": ("units", "entry", names("name", "subname")),
        "item_template": ("items", "entry", names("name", "description")),
    }
    locale = {
        "quest_template_locale": ("quests", "id", base["quest_template"][2]),
        "quest_offer_reward_locale": base["quest_offer_reward"],
        "quest_request_items_locale": base["quest_request_items"],
        "creature_template_locale": ("units", "entry", names("name", "subname")),
        "item_template_locale": ("items", "id", names("name", "description")),
    }
    return collect([reference], base), collect(sorted(ko.glob("*.sql")), locale, korean=True)


def turtle(reference, ko):
    quest_columns = ("title", "details", "objectives", "requestitemstext", "offerrewardtext")
    base = {
        "quest_template": ("quests", "entry", mapping(*quest_columns)),
        "creature_template": ("units", "entry", names("name", "subname")),
        "item_template": ("items", "entry", names("name", "description")),
        "spell_template": ("spells", "entry", {"title": ("name", "name1", "name_loc0")}),
    }
    locale = {
        "locales_quest": ("quests", "entry", mapping(*(f"{field}_loc1" for field in quest_columns))),
        "locales_creature": ("units", "entry", names("name_loc1", "subname_loc1")),
        "locales_item": ("items", "entry", names("name_loc1", "description_loc1")),
        "locales_spell": ("spells", "entry", {"title": ("name_loc1",)}),
    }
    return (
        collect([reference / f"tw_world_{table}.sql" for table in base], base),
        collect(sorted(ko.glob("locales_*.sql")), locale, korean=True),
    )


def pair_rows(reference, locale):
    data = defaultdict(dict)
    for kind, rows in reference.items():
        for entry, originals in rows.items():
            korean = locale[kind].get(entry, {})
            pairs = {
                field: (text, korean[field]) for field, text in originals.items()
                if text and HANGUL.search(korean.get(field, "")) and not HANGUL.search(text)
            }
            if "title" in pairs:
                data[kind][entry] = pairs
    return data


def wrath_seed(folder):
    from lupa.lua51 import LuaRuntime

    lua = LuaRuntime()
    addon = lua.table()
    for file in ("QuestData.lua", "companion/data/unit_data.lua", "companion/data/item_data.lua", "Labels.lua"):
        chunk = lua.compile((folder / file).read_text(encoding="utf-8-sig"))
        chunk("WoWKorean_WotLK", addon)
    data = defaultdict(dict)
    for entry, row in addon.quests.items():
        if not row.enTitle or not row.title:
            continue
        fields = {"title": (row.enTitle, row.title)}
        for field in FIELDS[1:]:
            translation = row[field]
            if translation:
                original = translation[1]
                guard = original if isinstance(original, str) else (original[1], original[2])
                fields[field] = (guard, translation[2])
        data["quests"][entry] = fields
    for kind, global_name in (("units", "unit_data"), ("items", "item_data")):
        rows = lua.globals()[global_name]
        for entry, row in rows.items():
            if row[1] and row[2] and isinstance(row[1], str) and HANGUL.search(row[2]):
                fields = {"title": (row[1], row[2])}
                labels = addon.labels[global_name][entry]
                if labels:
                    fields["description"] = (labels[1], labels[2])
                data[kind][entry] = fields
    return data


def coa(folder, curated, reference):
    data = wrath_seed(folder)
    spec = {
        "quest_template": ("quests", "id", mapping("logtitle", "questdescription", "logdescription")),
        "quest_offer_reward": ("quests", "id", {"completion": ("rewardtext",)}),
        "quest_request_items": ("quests", "id", {"progress": ("completiontext",)}),
        "creature_template": ("units", "entry", names("name", "subname")),
        "item_template": ("items", "entry", names("name", "description")),
    }
    originals = collect(sorted(reference.glob("rev_*.sql")), spec)
    entries = json.loads(curated.read_text(encoding="utf-8"))
    for kind, rows in entries.items():
        for entry, fields in rows.items():
            source = originals[kind][int(entry)]
            data[kind][int(entry)] = {field: (source[field], value) for field, value in fields.items()}
    return data


def literal(text):
    # Lua 5.0 recognizes decimal byte escapes, including for control bytes.
    if not isinstance(text, str):
        return "{" + ",".join(map(str, text)) + "}"
    escaped = "".join(
        "\\" + char if char in '\\"' else f"\\{ord(char):03}" if ord(char) < 32 else char
        for char in text
    )
    return '"' + escaped + '"'


def write_data(data, output, target):
    counts = {}
    directory = output / "data"
    directory.mkdir(parents=True, exist_ok=True)
    for kind in ("quests", "units", "items", "spells"):
        for previous in directory.glob(f"{kind}-*.lua"):
            previous.unlink()
        rows = sorted(data[kind].items())
        counts[kind] = len(rows)
        for offset in range(0, len(rows), 5000):
            part = offset // 5000 + 1
            path = directory / f"{kind}-{part:02d}.lua"
            with path.open("w", encoding="utf-8", newline="\n") as file:
                file.write("-- Generated by tools/build_data.py. See README.md for sources.\n")
                file.write(f"local addon = WoWKoreanClient\nif not addon.active then return end\n")
                file.write(f"local rows = addon.{kind}\n")
                for entry, pairs in rows[offset:offset + 5000]:
                    fields = []
                    for field, (original, translated) in pairs.items():
                        if kind == "quests" and field == "title":
                            original = original.removeprefix("[DEPRECATED] ")
                        fields.append(f"{field}={{{literal(guard(original))},{literal(translated)}}}")
                    file.write(f"rows[{entry}]={{{','.join(fields)}}}\n")
    if any(not counts[kind] for kind in ("quests", "units", "items")):
        raise ValueError(f"Missing translation dictionary: {counts}")
    counts["quest_fields"] = sum(len(fields) for fields in data["quests"].values())
    (output / "coverage.json").write_text(
        json.dumps({"target": target, **counts}, indent=2) + "\n", encoding="utf-8"
    )
    print(target, counts)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=("mop", "turtle", "coa"))
    parser.add_argument("reference", type=Path, help="English world SQL, Tortoise sql/base, or extracted WotLK add-on")
    parser.add_argument("locale", type=Path, help="Korean DB export directory or CoA curated JSON")
    parser.add_argument("--coa-sql", type=Path, help="Directory containing the pinned CoA SQL files")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.target == "coa":
        if not args.coa_sql:
            parser.error("CoA generation requires --coa-sql")
        data = coa(args.reference, args.locale, args.coa_sql)
    else:
        data = pair_rows(*{"mop": mop, "turtle": turtle}[args.target](args.reference, args.locale))
    write_data(data, args.output or ROOT / "versions" / args.target, args.target)


if __name__ == "__main__":
    main()
