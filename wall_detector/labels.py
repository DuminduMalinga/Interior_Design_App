"""Pure text parsing for floor-plan OCR: room names and dimensions in metres.

Kept free of OCR/YOLO imports so it can be unit-tested on its own.
"""

from __future__ import annotations

import difflib
import re
from dataclasses import dataclass

FT_TO_M = 0.3048
IN_TO_M = 0.0254
SQFT_TO_M2 = 0.09290304

_NUM = r"\d+(?:[.,]\d+)?"
_SEP = r"\s*[x×*]\s*"

# 12'0" x 11'0"   12' x 11'   12 ft 6 in x 11 ft
_FT_VALUE = rf"(?P<{{p}}ft>\d+)\s*(?:'|ft\.?|feet)\s*(?:(?P<{{p}}in>{_NUM})\s*(?:\"|in\.?)?)?"
_FT_PAIR = re.compile(
    _FT_VALUE.format(p="a") + _SEP + _FT_VALUE.format(p="b"), re.IGNORECASE
)

# 3.5 x 4.0 m   3.5m x 4.0m   3500 x 4000 mm   3.5 x 4.0
_METRIC_PAIR = re.compile(
    rf"(?P<a>{_NUM})\s*(?P<au>mm|cm|m)?\b{_SEP}(?P<b>{_NUM})\s*(?P<bu>mm|cm|m)?\b",
    re.IGNORECASE,
)

# 10.5 m²   10.5 m2   10.5 sq m   10.5 sqm   120 sq ft
_AREA = re.compile(
    rf"(?P<v>{_NUM})\s*(?P<u>m\s*[²2?]|sq\.?\s*m\b|sqm|m\^2|sq\.?\s*ft\b|sqft|ft\s*[²2])",
    re.IGNORECASE,
)

# Words that are annotation, not part of a room name.
_NOISE_WORDS = {
    "ft", "m", "mm", "cm", "in", "sq", "sqm", "sqft", "area", "approx", "x",
    "n", "s", "e", "w", "up", "dn", "down", "scale", "plan", "floor",
}


@dataclass
class Dimensions:
    width_m: float | None = None
    height_m: float | None = None
    area_m2: float | None = None
    source: str | None = None  # "ocr" (both sides) | "ocr_area" (area only)


def normalize(text: str) -> str:
    """Fold the quote/degree variants OCR produces into plain ASCII."""
    t = text.replace("’", "'").replace("‘", "'").replace("′", "'")
    t = t.replace("”", '"').replace("“", '"').replace("″", '"').replace("''", '"')
    t = t.replace("°", "'").replace("²", "2")
    t = re.sub(r"(?<=\bm)\?", "2", t)  # OCR reads "m²" as "m?"
    return re.sub(r"\s+", " ", t).strip()


def _num(s: str) -> float:
    return float(s.replace(",", "."))


def _ft_in(feet: str, inches: str | None) -> float:
    return int(feet) * FT_TO_M + (_num(inches) * IN_TO_M if inches else 0.0)


def _metric(value: float, unit: str | None) -> float:
    unit = (unit or "").lower()
    if unit == "mm":
        return value / 1000
    if unit == "cm":
        return value / 100
    if unit == "m":
        return value
    # No unit: the app works in metres, but bare numbers >= 100 are
    # almost certainly millimetres.
    return value / 1000 if value >= 100 else value


def parse_dimensions(text: str) -> Dimensions | None:
    """Extract a room's size in metres from label text, or None."""
    t = normalize(text)

    m = _FT_PAIR.search(t)
    if m:
        w = _ft_in(m["aft"], m["ain"])
        h = _ft_in(m["bft"], m["bin"])
        return Dimensions(round(w, 2), round(h, 2), round(w * h, 2), "ocr")

    m = _METRIC_PAIR.search(t)
    if m:
        # A unit on either side applies to both ("3.5 x 4.0 m").
        unit = m["au"] or m["bu"]
        w = _metric(_num(m["a"]), m["au"] or unit)
        h = _metric(_num(m["b"]), m["bu"] or unit)
        if 0.5 <= w <= 50 and 0.5 <= h <= 50:
            return Dimensions(round(w, 2), round(h, 2), round(w * h, 2), "ocr")

    m = _AREA.search(t)
    if m:
        area = _num(m["v"])
        if "ft" in m["u"].lower():
            area *= SQFT_TO_M2
        if 1 <= area <= 500:
            return Dimensions(None, None, round(area, 2), "ocr_area")
    return None


def is_dimension_text(text: str) -> bool:
    return parse_dimensions(text) is not None or bool(
        re.fullmatch(r"[\d\s.,'\"xX×*mfti²-]*", normalize(text))
    )


_VOCAB = [
    "bedroom", "bathroom", "kitchen", "living", "dining", "room", "study",
    "balcony", "garage", "hall", "hallway", "corridor", "entry", "entrance",
    "toilet", "laundry", "pantry", "store", "storage", "office", "closet",
    "wardrobe", "ensuite", "master", "guest", "kids", "utility", "porch",
    "patio", "terrace", "lobby", "foyer", "area", "family", "lounge", "wc",
    "walk-in", "powder", "common", "main", "bath", "attic", "basement",
]


def _snap(word: str) -> str:
    """Fix OCR typos ("Bathoom") by snapping to the nearest known room word."""
    low = word.lower()
    if low in _VOCAB or len(low) < 4:
        return word
    match = difflib.get_close_matches(low, _VOCAB, n=1, cutoff=0.8)
    return match[0] if match else word


def clean_name(lines: list[str]) -> str:
    """Join the alphabetic label lines of a room into a display name."""
    parts: list[str] = []
    for line in lines:
        if is_dimension_text(line):
            continue
        words = [
            w
            for w in re.findall(r"[A-Za-z&]+|\b\d{1,2}\b", normalize(line))
            if w.lower() not in _NOISE_WORDS
        ]
        words = [_snap(w) for w in words if len(w) >= 2 or w in "&123456789"]
        if sum(c.isalpha() for w in words for c in w) >= 3:
            parts.append(" ".join(words))
    name = " ".join(parts).strip()
    return " ".join(w.capitalize() if w != "&" else w for w in name.split())


_OVERALL = re.compile(r"^(?P<v>\d+(?:[.,]\d+)?)\s*(?P<u>ft|feet|m|')$", re.IGNORECASE)


def parse_overall_length(text: str) -> float | None:
    """A lone "40 ft" / "12 m" overall-dimension annotation, in metres."""
    m = _OVERALL.match(normalize(text))
    if not m:
        return None
    v = _num(m["v"])
    return v if m["u"].lower() == "m" else v * FT_TO_M
