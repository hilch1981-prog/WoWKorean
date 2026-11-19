"""Create deterministic install ZIPs without including local DB or client files."""

import argparse
import hashlib
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.1.0"
TARGETS = {
    "mop": ("MoP", "판다리아 5.4.8", 50400, "18414", "5.4.8", "0.1.1"),
    "turtle": ("Turtle", "터틀 와우 1.18.1", 11200, "", "1.18.1", VERSION),
    "coa": ("CoA", "CoA Custom 1.9.2", 30300, "", "Custom_1.9.2", "0.2.0"),
}
FONT = "NanumGothic-Regular.ttf"


def zip_files(path, members):
    with ZipFile(path, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for name, source in members.items():
            info = ZipInfo(name, date_time=(2026, 11, 19, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            content = source.read_bytes() if isinstance(source, Path) else source.encode("utf-8")
            archive.writestr(info, content)
    return path


def build(target, output):
    short, label, interface, build_number, client, version = TARGETS[target]
    edition = ROOT / "versions" / target
    folder = "WoWKorean_" + short
    config = f'''local _, build, _, interface = GetBuildInfo()
WoWKoreanClient = {{
    folder = "{folder}", label = "{label}", version = "{version}", interface = {interface},
    active = (tonumber(interface) == {interface}{" or interface == nil" if target == "turtle" else ""})
        and ("{build_number}" == "" or tostring(build) == "{build_number}"),
    useFont = GetLocale() ~= "koKR",
    quests = {{}}, units = {{}}, items = {{}}, spells = {{}},
    worldText = {"{}" if target == "coa" else "nil"},
}}
'''
    parts = sorted((edition / "data").glob("*.lua"))
    if not parts:
        raise ValueError(f"Missing generated data for {target}")
    loads = [f"data\\{file.name}" for file in parts]
    modules = ["Core.lua"] + (["CoAWorld.lua"] if target == "coa" else [])
    toc = "\r\n".join([
        f"## Interface: {interface}", f"## Title: 와우 한글화 · {label}",
        "## Notes: 기본 퀘스트와 툴팁의 한국어 표시", f"## Version: {version}",
        "## Author: 취미연구가", "## DefaultState: enabled",
        "Config.lua", *loads, *modules, "",
    ])
    members = {
        f"{folder}/{folder}.toc": toc,
        f"{folder}/Config.lua": config,
        **{f"{folder}/data/{file.name}": file for file in parts},
        **{f"{folder}/{module}": ROOT / "addon" / module for module in modules},
        f"{folder}/Fonts/{FONT}": ROOT / "assets" / FONT,
        f"{folder}/Fonts/OFL.txt": ROOT / "assets/OFL.txt",
        f"{folder}/README.md": edition / "README.md",
        f"{folder}/coverage.json": edition / "coverage.json",
        f"{folder}/COPYING": ROOT / "COPYING",
    }
    if target == "coa":
        members[f"{folder}/FONT-PATCH.md"] = edition / "FONT-PATCH.md"
        members[f"{folder}/CLIENT-PATCH.md"] = edition / "CLIENT-PATCH.md"
    return zip_files(output / f"{folder}_{client}_v{version}.zip", members)


def coa_fonts(output):
    font = ROOT / "assets" / FONT
    original_names = ("ARIALN.TTF", "FRIZQT__.TTF", "MORPHEUS.TTF", "SKURRI.TTF")
    members = {f"Fonts/{name}": font for name in original_names}
    members["OFL.txt"] = ROOT / "assets/OFL.txt"
    members["README.md"] = ROOT / "versions/coa/FONT-PATCH.md"
    return zip_files(output / f"WoWKorean_CoA_FontPatch_v{VERSION}.zip", members)


def coa_client_patch(output, mpq):
    _, _, _, _, client, version = TARGETS["coa"]
    font = ROOT / "assets" / FONT
    members = {
        "Data/patch-ZZZY.MPQ": mpq,
        **{f"Fonts/{name}.TTF": font for name in ("ARIALN", "FRIZQT__", "MORPHEUS", "SKURRI")},
        "OFL.txt": ROOT / "assets/OFL.txt",
        "README.md": ROOT / "versions/coa/CLIENT-PATCH.md",
        "coverage.json": ROOT / "versions/coa/client-coverage.json",
    }
    return zip_files(output / f"WoWKorean_CoA_{client}_ClientPatch_v{version}.zip", members)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=(*TARGETS, "all"), default="all", nargs="?")
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    parser.add_argument("--coa-client-patch", type=Path, help="Pack an already verified CoA MPQ")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    targets = TARGETS if args.target == "all" else [args.target]
    packages = [build(target, args.output) for target in targets]
    if "coa" in targets:
        if args.coa_client_patch:
            packages.append(coa_client_patch(args.output, args.coa_client_patch))
        else:
            packages.append(coa_fonts(args.output))
    for path in packages:
        print(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}")


if __name__ == "__main__":
    main()
