#!/usr/bin/env python3
"""Update or check the source inventory in Docs/Architecture.md."""

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCUMENT = ROOT / "Docs/Architecture.md"
START = "<!-- directory-tree:start -->"
END = "<!-- directory-tree:end -->"
COLLAPSED = {"Assets.xcassets", "Notes.xcodeproj"}
EXCLUDED = {"Secrets.xcconfig", "__pycache__", "build", "DerivedData", "node_modules"}


def entries(directory):
    return sorted(
        (p for p in directory.iterdir()
         if not p.name.startswith(".")
         and p.name not in EXCLUDED),
        key=lambda p: (not p.is_dir(), p.name),
    )


def render(directory, prefix=""):
    children = entries(directory)
    lines = []
    for index, path in enumerate(children):
        last = index == len(children) - 1
        lines.append(prefix + ("└── " if last else "├── ") + path.name + ("/" if path.is_dir() else ""))
        if path.is_dir() and path.name not in COLLAPSED:
            lines.extend(render(path, prefix + ("    " if last else "│   ")))
    return lines


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source = DOCUMENT.read_text()
    before, rest = source.split(START, 1)
    _, after = rest.split(END, 1)
    tree = "\n```text\nNotes/ (repository root)\n" + "\n".join(render(ROOT)) + "\n```\n"
    updated = before + START + tree + END + after
    if args.check:
        if updated != source:
            raise SystemExit("Architecture inventory is outdated. Run: python3 Scripts/update_architecture.py")
        print("Architecture inventory is current.")
    else:
        DOCUMENT.write_text(updated)
        print("Updated Docs/Architecture.md")


if __name__ == "__main__":
    main()
