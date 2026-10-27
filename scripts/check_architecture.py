"""Validate the architecture map. Exits non-zero on any problem.

    python -m pip install pyyaml
    python scripts/check_architecture.py

Catches the things the page would otherwise report as a "needs attention"
notice, plus the one it can't: a resource type added to the YAML without a
matching entry in TYPES, and artwork in either ICONS or GLYPHS, which would
silently render as a grey box.
"""

import re
import sys
from pathlib import Path

import yaml

SITE = Path(__file__).resolve().parent.parent / "site"
PAGE = SITE / "cloud-architecture.html"
YAML_FILE = SITE / "architecture.yaml"

OPEN_TAG = '<script type="text/yaml" id="architecture">'


def keys_of(html: str, obj_name: str) -> set[str]:
    """Pull the top-level keys out of the TYPES / GLYPHS object literal."""
    match = re.search(rf"const {obj_name} = \{{(.*?)\n  \}};", html, re.S)
    if not match:
        return set()
    body = match.group(1)
    return set(re.findall(r"^\s*'?([a-zA-Z0-9_-]+)'?\s*:", body, re.M))


def embedded_yaml(html: str) -> str:
    start = html.index(OPEN_TAG) + len(OPEN_TAG)
    end = html.index("</script>", start)
    return html[start:end].strip("\n")


def main() -> int:
    html = PAGE.read_text(encoding="utf-8")
    raw = YAML_FILE.read_text(encoding="utf-8")
    problems: list[str] = []

    try:
        doc = yaml.safe_load(raw) or {}
    except yaml.YAMLError as err:
        print(f"architecture.yaml does not parse: {err}")
        return 1

    if embedded_yaml(html) != raw.rstrip("\n"):
        problems.append(
            "the page's embedded YAML differs from architecture.yaml "
            "- run scripts/sync_page.py"
        )

    resources = doc.get("resources") or []
    projects = doc.get("projects") or []
    connections = doc.get("connections") or []

    ids = {str(r.get("id")) for r in resources}
    project_ids = {str(p.get("id")) for p in projects}
    types = keys_of(html, "TYPES")
    # Official artwork lives in ICONS, hand-drawn fallbacks in GLYPHS; a type
    # only needs to appear in one of them.
    artwork = keys_of(html, "GLYPHS") | keys_of(html, "ICONS")

    if not types or not artwork:
        problems.append("could not read TYPES/GLYPHS/ICONS out of the page")

    seen: set[str] = set()
    for r in resources:
        rid = str(r.get("id"))
        if rid in seen:
            problems.append(f"duplicate resource id '{rid}'")
        seen.add(rid)

        rtype = r.get("type")
        if types and rtype not in types:
            problems.append(f"'{rid}' uses type '{rtype}', which is not in TYPES")
        if artwork and rtype not in artwork:
            problems.append(f"'{rid}' uses type '{rtype}', which has no artwork in ICONS or GLYPHS")

        if not r.get("projects"):
            problems.append(f"'{rid}' is not tagged with any project")
        for p in r.get("projects") or []:
            if str(p) not in project_ids:
                problems.append(f"'{rid}' is tagged with unknown project '{p}'")

        status = r.get("status", "deployed")
        if status not in ("deployed", "planned"):
            problems.append(f"'{rid}' has status '{status}' (expected deployed or planned)")

    for p in projects:
        pid = str(p.get("id"))
        if not re.fullmatch(r"[a-z0-9-]+", pid):
            problems.append(f"project id '{pid}' is not kebab-case")

    for c in connections:
        for end in ("from", "to"):
            if str(c.get(end)) not in ids:
                problems.append(f"connection {c.get('from')} -> {c.get('to')}: "
                                f"'{c.get(end)}' is not a listed resource")

    if problems:
        print(f"{len(problems)} problem(s):")
        for p in problems:
            print(f"  - {p}")
        return 1

    print(
        f"ok - {len(resources)} resources, {len(connections)} connections, "
        f"{len(projects)} projects; embedded copy in sync"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
