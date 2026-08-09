#!/usr/bin/env python3
"""Build the small runtime font from the licensed full Noto Sans CJK font.

Install the build-only dependency with ``python3 -m pip install fonttools``.
The full source font stays in the repository for future story text; exports use
the generated subset so Web and iOS players do not download unused glyphs.
"""

from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_FONT = ROOT / "assets/fonts/NotoSansCJKsc-Regular.otf"
OUTPUT_FONT = ROOT / "assets/fonts/NotoSansCJKsc-GameSubset.otf"
RUNTIME_TEXT_FILES = [
    ROOT / "project.godot",
    *sorted((ROOT / "scenes").glob("*.tscn")),
    *sorted((ROOT / "scripts").glob("*.gd")),
]


def main() -> None:
    text = "".join(path.read_text(encoding="utf-8") for path in RUNTIME_TEXT_FILES)
    # Keep printable ASCII even if a character is not present in today's copy.
    text += "".join(chr(codepoint) for codepoint in range(0x20, 0x7F))

    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = [0, 1, 2, 3, 4, 5, 6]
    options.name_languages = [0x409, 0x804]
    options.notdef_glyph = True
    options.notdef_outline = True
    options.recalc_timestamp = False

    font = TTFont(SOURCE_FONT, recalcTimestamp=False)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text=text)
    subsetter.subset(font)
    font.save(OUTPUT_FONT, reorderTables=False)

    glyph_count = len(font.getGlyphOrder())
    print(f"Wrote {OUTPUT_FONT.relative_to(ROOT)} with {glyph_count} glyphs")


if __name__ == "__main__":
    main()
