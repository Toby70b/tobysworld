"""Mirror site/architecture.yaml into the page's embedded <script type="text/yaml"> block.

architecture.yaml is the source of truth; the embedded copy exists so the page
still works when opened straight off disk. Run this after every YAML edit.

    python scripts/sync_page.py

Idempotent — re-running with nothing changed rewrites the same bytes.
"""

from pathlib import Path

SITE = Path(__file__).resolve().parent.parent / "site"
PAGE = SITE / "cloud-architecture.html"
YAML = SITE / "architecture.yaml"

OPEN_TAG = '<script type="text/yaml" id="architecture">'


def main() -> int:
    html = PAGE.read_text(encoding="utf-8")
    yaml_text = YAML.read_text(encoding="utf-8").rstrip("\n")

    try:
        start = html.index(OPEN_TAG) + len(OPEN_TAG)
        end = html.index("</script>", start)
    except ValueError:
        print(f"could not find the embedded YAML block in {PAGE.name}")
        return 1

    updated = html[:start] + "\n" + yaml_text + "\n" + html[end:]
    if updated == html:
        print("already in sync")
        return 0

    PAGE.write_text(updated, encoding="utf-8")
    print(f"embedded {len(yaml_text.splitlines())} lines into {PAGE.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
