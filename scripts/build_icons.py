"""Inline the icon artwork in assets/icons/ into the page's ICONS map.

    python scripts/build_icons.py

These are the official AWS Architecture Icons, which carry their own
category-coloured background, so they go in untouched apart from stripping the
XML declaration, the <title> and the fixed width and height.

Anything without official artwork — Steam, generic external services, GitHub —
stays a hand-drawn glyph in the page's GLYPHS map and is rendered on a
category-coloured tile instead. See assets/icons/SOURCES.md.

Re-run after dropping a newer AWS package into assets/icons/. The map is
generated, so don't hand-edit it in the page.
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "assets" / "icons"
PAGE = ROOT / "site" / "cloud-architecture.html"

START = "  const ICONS = {"
END = "  };\n"


def clean(svg: str) -> str:
    svg = re.sub(r"<\?xml[^>]*\?>", "", svg)
    svg = re.sub(r"<title>.*?</title>", "", svg, flags=re.S)
    svg = re.sub(r'\s(width|height)="[^"]*"', "", svg, count=2)
    return re.sub(r"\s+", " ", svg).strip()


def main() -> int:
    if not ICON_DIR.is_dir():
        print(f"no icon directory at {ICON_DIR}")
        return 1

    entries = [
        f"    '{f.stem}': `{clean(f.read_text(encoding='utf-8'))}`,"
        for f in sorted(ICON_DIR.glob("*.svg"))
    ]
    if not entries:
        print(f"no .svg files in {ICON_DIR}")
        return 1

    block = START + "\n" + "\n".join(entries) + "\n  };\n"

    html = PAGE.read_text(encoding="utf-8")
    start = html.find(START)
    if start == -1:
        print("the page has no ICONS map to replace")
        return 1
    end = html.index(END, start) + len(END)

    PAGE.write_text(html[:start] + block + html[end:], encoding="utf-8")
    print(f"inlined {len(entries)} icons ({sum(len(e) for e in entries) // 1024} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
