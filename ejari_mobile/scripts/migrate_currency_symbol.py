#!/usr/bin/env python3
"""Replace hardcoded Egyptian currency symbol with CurrencyFormatter.symbol."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"
SKIP = {
    "utils/currency_formatter.dart",
    "models/app_region.dart",
    "l10n/app_localizations.dart",
}


def rel_import(from_file: Path) -> str:
    rel = from_file.relative_to(ROOT)
    depth = len(rel.parts) - 1
    prefix = "../" * depth if depth else ""
    return f"import '{prefix}utils/currency_formatter.dart';"


def transform(content: str) -> str:
    if "ج.م" not in content:
        return content

    # Whole-literal symbol usages
    content = re.sub(r"'ج\.م'", "CurrencyFormatter.symbol", content)
    content = re.sub(r'"ج\.م"', "CurrencyFormatter.symbol", content)

    # Parenthesized / suffix forms inside strings
    content = content.replace("(ج.م)", "(${CurrencyFormatter.symbol})")
    content = content.replace(" ج.م", " ${CurrencyFormatter.symbol}")
    content = content.replace("/ج.م", "/${CurrencyFormatter.symbol}")
    content = content.replace("ج.م/", "${CurrencyFormatter.symbol}/")

    # Any remaining bare symbol inside single/double quotes fragments
    # e.g. leftover at start of a segment
    content = content.replace("ج.م", "${CurrencyFormatter.symbol}")

    return content


def ensure_import(path: Path, content: str) -> str:
    if "CurrencyFormatter" not in content:
        return content
    if "currency_formatter.dart" in content:
        return content
    import_line = rel_import(path)
    lines = content.splitlines(keepends=True)
    insert_at = 0
    last_import = -1
    for i, line in enumerate(lines):
        if line.startswith("import "):
            last_import = i
        elif last_import >= 0 and line.strip() and not line.startswith("//"):
            break
    insert_at = last_import + 1 if last_import >= 0 else 0
    lines.insert(insert_at, import_line + "\n")
    return "".join(lines)


def main() -> None:
    changed = 0
    for path in sorted(ROOT.rglob("*.dart")):
        rel = str(path.relative_to(ROOT))
        if rel in SKIP:
            continue
        original = path.read_text(encoding="utf-8")
        if "ج.م" not in original:
            continue
        updated = ensure_import(path, transform(original))
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            changed += 1
            print(f"updated: {rel}")
    print(f"done: {changed} files")


if __name__ == "__main__":
    main()
