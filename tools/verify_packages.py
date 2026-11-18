"""Verify install ZIP layout and exercise each TOC against representative WoW UI APIs."""

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import tempfile
from zipfile import ZipFile

from package import FONT, ROOT, TARGETS, VERSION


def check_addon(target, folder, path, old_lua):
    _, _, interface, build_number, _ = TARGETS[target]
    with ZipFile(path) as archive:
        assert archive.testzip() is None
        names = archive.namelist()
        assert len(names) == len(set(names))
        assert {PurePosixPath(name).parts[0] for name in names} == {folder}
        toc = archive.read(f"{folder}/{folder}.toc").decode("utf-8").splitlines()
        assert toc[0] == f"## Interface: {interface}"
        loads = [line.replace("\\", "/") for line in toc if line and not line.startswith("#")]
        assert loads[0] == "Config.lua" and loads[-1] == "Core.lua"
        assert len(loads) == len(set(loads))
        assert {name for name in names if name.endswith(".lua")} == {f"{folder}/{load}" for load in loads}
        assert archive.read(f"{folder}/Fonts/{FONT}") == (ROOT / "assets" / FONT).read_bytes()
        counts = json.loads(archive.read(f"{folder}/coverage.json"))
        bootstrap = f'TEST_INTERFACE = {interface}\nTEST_BUILD = "{build_number}"\nEXPECTED_QUESTS = {counts["quests"]}\n'
        fixtures = (ROOT / "tests/game_ui.lua").read_text(encoding="utf-8")
        lua_files = [archive.read(f"{folder}/{load}").decode("utf-8") for load in loads]
        if old_lua and target == "turtle":
            with tempfile.TemporaryDirectory(prefix="wowkorean-") as directory:
                for index, source in enumerate([bootstrap, fixtures, *lua_files, "Verify()"]):
                    (Path(directory) / f"{index}.lua").write_bytes(source.encode("utf-8"))
                sequence = "\n".join(f'dofile("{index}.lua")' for index in range(len(lua_files) + 3))
                (Path(directory) / "run.lua").write_text(sequence, encoding="utf-8")
                subprocess.run([old_lua, "run.lua"], cwd=directory, check=True)
        else:
            from lupa.lua51 import LuaRuntime

            lua = LuaRuntime()
            lua.execute(bootstrap)
            lua.execute(fixtures)
            for load, source in zip(loads, lua_files):
                lua.execute(source, name=load)
            lua.globals().Verify()
    print(hashlib.sha256(path.read_bytes()).hexdigest(), path.name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive-dir", type=Path, default=ROOT / "dist")
    parser.add_argument("--lua50", type=Path)
    args = parser.parse_args()
    for target, (short, _, _, _, client) in TARGETS.items():
        folder = f"WoWKorean_{short}"
        check_addon(target, folder, args.archive_dir / f"{folder}_{client}_v{VERSION}.zip",
                    args.lua50.resolve() if args.lua50 else None)
    patch = args.archive_dir / f"WoWKorean_CoA_FontPatch_v{VERSION}.zip"
    with ZipFile(patch) as archive:
        assert archive.testzip() is None
        fonts = [name for name in archive.namelist() if re.fullmatch(r"Fonts/[A-Z_]+\.TTF", name)]
        assert len(fonts) == 4 and len(archive.namelist()) == 6
        assert all(archive.read(name) == (ROOT / "assets" / FONT).read_bytes() for name in fonts)
        assert archive.read("OFL.txt") == (ROOT / "assets/OFL.txt").read_bytes()
    print(hashlib.sha256(patch.read_bytes()).hexdigest(), patch.name)


if __name__ == "__main__":
    main()
