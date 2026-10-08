"""Floor-plan analysis: YOLO wall/room/door/window detection + OCR labels.

`analyze_image` returns the document stored in `FloorPlanAnalysis.DetectionJSON`
(see `AnalysisRoom` in `lib/data/models.dart`): rooms carry a name read from
the plan, their size in metres, and a bounding box as percentages of the image.
"""

from __future__ import annotations

import os
import statistics
from dataclasses import dataclass
from pathlib import Path
from statistics import median
from typing import Any

import cv2
import numpy as np

from labels import Dimensions, clean_name, parse_dimensions, parse_overall_length

HERE = Path(__file__).resolve().parent
WEIGHTS = Path(os.environ.get("WALL_DETECTOR_WEIGHTS", HERE / "best.pt"))
CONF = float(os.environ.get("WALL_DETECTOR_CONF", "0.5"))
OCR_MIN_CONF = 0.25

_model = None
_reader = None


@dataclass
class Box:
    x1: float
    y1: float
    x2: float
    y2: float
    conf: float = 1.0
    text: str = ""

    @property
    def w(self) -> float:
        return self.x2 - self.x1

    @property
    def h(self) -> float:
        return self.y2 - self.y1

    @property
    def area(self) -> float:
        return max(self.w, 0) * max(self.h, 0)

    @property
    def cx(self) -> float:
        return (self.x1 + self.x2) / 2

    @property
    def cy(self) -> float:
        return (self.y1 + self.y2) / 2

    def contains_point(self, x: float, y: float) -> bool:
        return self.x1 <= x <= self.x2 and self.y1 <= y <= self.y2

    def intersection(self, o: "Box") -> float:
        iw = min(self.x2, o.x2) - max(self.x1, o.x1)
        ih = min(self.y2, o.y2) - max(self.y1, o.y1)
        return max(iw, 0) * max(ih, 0)

    def iou(self, o: "Box") -> float:
        inter = self.intersection(o)
        union = self.area + o.area - inter
        return inter / union if union else 0.0


def _get_model():
    global _model
    if _model is None:
        from ultralytics import YOLO

        if not WEIGHTS.exists():
            raise FileNotFoundError(
                f"Model weights not found at {WEIGHTS}. Copy best.pt there or "
                "set WALL_DETECTOR_WEIGHTS."
            )
        _model = YOLO(str(WEIGHTS))
    return _model


def _get_reader():
    global _reader
    if _reader is None:
        import easyocr
        import torch

        _reader = easyocr.Reader(["en"], gpu=torch.cuda.is_available(), verbose=False)
    return _reader


def _dedupe_rooms(rooms: list[Box]) -> list[Box]:
    """The model emits overlapping duplicates of one room; keep the best."""
    kept: list[Box] = []
    for r in sorted(rooms, key=lambda b: -b.conf):
        dup = False
        for k in kept:
            inter = r.intersection(k)
            small, big = sorted((r.area, k.area))
            if r.iou(k) > 0.5 or (small and inter / small > 0.9 and big < 2.5 * small):
                dup = True
                break
        if not dup:
            kept.append(r)
    return kept


def _ocr(image: np.ndarray) -> list[Box]:
    """Text lines as boxes with `.text`, upscaled a little for small labels."""
    scale = 1.0
    h, w = image.shape[:2]
    if max(h, w) < 1400:
        scale = 1400 / max(h, w)
        image = cv2.resize(image, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
    out: list[Box] = []
    for pts, text, conf in _get_reader().readtext(image):
        if conf < OCR_MIN_CONF or not text.strip():
            continue
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        out.append(
            Box(min(xs) / scale, min(ys) / scale, max(xs) / scale, max(ys) / scale, conf, text)
        )
    return out


def _nearest_block(room: Box, texts: list[Box]) -> list[Box]:
    """A room box can span two labels (open-plan kitchen/dining); keep the
    block of lines nearest its centre so names and sizes are not mixed."""
    lines = sorted(texts, key=lambda t: (t.cy, t.x1))
    blocks: list[list[Box]] = []
    for t in lines:
        if blocks and t.y1 - blocks[-1][-1].y2 <= 1.2 * t.h:
            blocks[-1].append(t)
        else:
            blocks.append([t])
    if not blocks:
        return []
    best = min(blocks, key=lambda b: abs(statistics.mean(t.cy for t in b) - room.cy))
    return sorted(best, key=lambda t: (round(t.cy / 8), t.x1))


def _read_room_label(room: Box, texts: list[Box]) -> tuple[str, Dimensions | None, list[str]]:
    lines = _nearest_block(room, texts)
    lines_text = [t.text for t in lines]
    dims = None
    for t in lines:
        dims = parse_dimensions(t.text)
        if dims:
            break
    if dims is None and len(lines) > 1:
        # "12'0" x" / "11'0"" split across two OCR lines.
        dims = parse_dimensions(" ".join(lines_text))
    return clean_name(lines_text), dims, lines_text


def _fit_dims(dims: Dimensions, room: Box) -> tuple[float | None, float | None, float | None]:
    """Orient parsed sizes to the room's box; derive sides from area alone."""
    aspect = room.w / room.h if room.h else 1.0
    if dims.width_m is not None and dims.height_m is not None:
        w, h = dims.width_m, dims.height_m
        # Plans write "width x length" inconsistently; match the drawn shape.
        if (w / h - 1) * (aspect - 1) < 0 and abs(w / h - aspect) > abs(h / w - aspect):
            w, h = h, w
        return w, h, dims.area_m2
    area = dims.area_m2
    if area:
        w = (area * aspect) ** 0.5
        return round(w, 2), round(area / w, 2), area
    return None, None, None


def pct_box(b: Box, img_w: int, img_h: int) -> dict[str, float]:
    return {
        "x": round(b.x1 / img_w * 100, 2),
        "y": round(b.y1 / img_h * 100, 2),
        "w": round(b.w / img_w * 100, 2),
        "h": round(b.h / img_h * 100, 2),
    }


def analyze_image(image_path: str | Path) -> dict[str, Any]:
    image = cv2.imread(str(image_path))
    if image is None:
        raise ValueError(f"Could not read image: {image_path}")
    img_h, img_w = image.shape[:2]

    result = _get_model().predict(source=image, conf=CONF, verbose=False)[0]
    names = result.names
    by_class: dict[str, list[Box]] = {"wall": [], "room": [], "door": [], "window": []}
    for b in result.boxes:
        x1, y1, x2, y2 = (float(v) for v in b.xyxy[0].tolist())
        key = str(names[int(b.cls[0])]).lower()
        by_class.setdefault(key, []).append(Box(x1, y1, x2, y2, float(b.conf[0])))

    rooms = sorted(_dedupe_rooms(by_class["room"]), key=lambda b: (round(b.cy / 40), b.cx))
    texts = _ocr(image)

    # Each text line belongs to the smallest room box holding its centre.
    assigned: dict[int, list[Box]] = {i: [] for i in range(len(rooms))}
    for t in texts:
        holders = [i for i, r in enumerate(rooms) if r.contains_point(t.cx, t.cy)]
        if holders:
            assigned[min(holders, key=lambda i: rooms[i].area)].append(t)

    parsed = []
    for i, room in enumerate(rooms):
        name, dims, raw = _read_room_label(room, assigned[i])
        w, h, area = _fit_dims(dims, room) if dims else (None, None, None)
        parsed.append((name, w, h, area, dims.source if dims else None, raw))

    # Metres per pixel from rooms whose size was written on the plan, used
    # to estimate the rest. Only both-sided sizes give a trustworthy scale.
    ratios = []
    for room, (_, w, h, _, src, _) in zip(rooms, parsed):
        if src == "ocr" and w and h and room.w and room.h:
            ratios += [w / room.w, h / room.h]
    m_per_px = median(ratios) if ratios else None
    scale_from = "ocr_labels" if m_per_px else None

    if m_per_px is None:
        # No sizes on the rooms: fall back to a horizontal overall-dimension
        # annotation ("40 ft") and take it to span the walls' full width.
        walls = by_class["wall"]
        span = max((w.x2 for w in walls), default=0) - min((w.x1 for w in walls), default=0)
        overall = [
            parse_overall_length(t.text)
            for t in texts
            if t.w > t.h and not any(r.contains_point(t.cx, t.cy) for r in rooms)
        ]
        overall = [v for v in overall if v]
        if span > 0 and overall:
            m_per_px, scale_from = max(overall) / span, "overall_dimension"

    out_rooms = []
    for i, (room, (name, w, h, area, src, raw)) in enumerate(zip(rooms, parsed), start=1):
        if w is None and m_per_px:
            w, h = round(room.w * m_per_px, 2), round(room.h * m_per_px, 2)
            area, src = round(w * h, 2), "estimated"
        out_rooms.append(
            {
                "id": f"room-{i}",
                "name": name,
                "fallbackName": f"Room {i}",
                "labelDetected": bool(name),
                "confidence": round(room.conf, 3),
                "widthM": w,
                "heightM": h,
                "areaM2": area,
                "dimensionsSource": src,
                "bboxPct": pct_box(room, img_w, img_h),
                "ocrText": raw,
            }
        )

    def elements(kind: str) -> list[dict[str, Any]]:
        return [
            {
                "id": f"{kind}-{n}",
                "confidence": round(b.conf, 3),
                "bboxPct": pct_box(b, img_w, img_h),
            }
            for n, b in enumerate(
                sorted(by_class.get(kind, []), key=lambda b: (round(b.cy / 40), b.cx)), start=1
            )
        ]

    return {
        "source": "yolo+easyocr",
        "image": {"widthPx": img_w, "heightPx": img_h},
        "scale": {"metersPerPixel": m_per_px, "from": scale_from},
        "rooms": out_rooms,
        "walls": elements("wall"),
        "doors": elements("door"),
        "windows": elements("window"),
    }
