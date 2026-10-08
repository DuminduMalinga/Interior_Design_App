"""CLI: python run.py plan1.jpeg [plan2.png ...]  -> writes <name>.detection.json"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from detector import analyze_image


def main(paths: list[str]) -> int:
    if not paths:
        print(__doc__)
        return 2
    for p in paths:
        doc = analyze_image(p)
        out = Path(p).with_suffix(".detection.json")
        out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
        print(f"\n{p}: {len(doc['rooms'])} rooms -> {out}")
        for r in doc["rooms"]:
            size = (
                f"{r['widthM']} x {r['heightM']} m ({r['areaM2']} m2, {r['dimensionsSource']})"
                if r["widthM"]
                else "size unknown"
            )
            print(f"  {r['id']:<8} {r['name'] or r['fallbackName']:<22} {size}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
