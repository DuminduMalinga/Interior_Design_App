"""Analyses floor plans the app uploads and writes the result for it to read.

    set SUPABASE_SERVICE_KEY=<service_role key>     (never ship this in the app)
    python worker.py

Finds `FloorPlan` rows with no `FloorPlanAnalysis` yet, downloads the image
from the private `floorplans` bucket, runs the detector and stores the result
in `FloorPlanAnalysis.DetectionJSON` with Status `Detected` (or `Failed`),
which is what `ProcessingScreen` polls for.
"""

from __future__ import annotations

import os
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote

import httpx

from detector import analyze_image

URL = os.environ.get("SUPABASE_URL", "https://tzmjtbemafzsdlstwmgg.supabase.co").rstrip("/")
KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")
BUCKET = os.environ.get("SUPABASE_BUCKET", "floorplans")
POLL_SECONDS = 3

HEADERS = {"apikey": KEY, "Authorization": f"Bearer {KEY}"}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def pending(client: httpx.Client) -> list[dict]:
    plans = client.get(
        f"{URL}/rest/v1/FloorPlan",
        params={"select": "FloorPlanID,UserID,ImagePath", "Status": "eq.Uploaded"},
    )
    plans.raise_for_status()
    done = client.get(f"{URL}/rest/v1/FloorPlanAnalysis", params={"select": "FloorPlanID"})
    done.raise_for_status()
    analysed = {r["FloorPlanID"] for r in done.json()}
    return [p for p in plans.json() if p["FloorPlanID"] not in analysed]


def save(client: httpx.Client, plan: dict, status: str, detection: dict) -> None:
    resp = client.post(
        f"{URL}/rest/v1/FloorPlanAnalysis",
        params={"on_conflict": "FloorPlanID"},
        headers={"Prefer": "resolution=merge-duplicates,return=minimal"},
        json={
            "FloorPlanID": plan["FloorPlanID"],
            "UserID": plan["UserID"],
            "DetectionJSON": detection,
            "Status": status,
            "CreatedAt": now(),
            "UpdatedAt": now(),
        },
    )
    resp.raise_for_status()


def process(client: httpx.Client, plan: dict) -> None:
    path = plan["ImagePath"]
    img = client.get(f"{URL}/storage/v1/object/{BUCKET}/{quote(path)}")
    img.raise_for_status()
    suffix = Path(path).suffix or ".png"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(img.content)
    try:
        detection = analyze_image(tmp.name)
    finally:
        Path(tmp.name).unlink(missing_ok=True)
    save(client, plan, "Detected", detection)
    print(f"{plan['FloorPlanID']}: {len(detection['rooms'])} rooms")


def main() -> int:
    if not KEY:
        print("Set SUPABASE_SERVICE_KEY (Supabase dashboard > Project Settings > API).")
        return 2
    failed: set[str] = set()
    with httpx.Client(headers=HEADERS, timeout=120) as client:
        print(f"Watching {URL} for uploaded floor plans...")
        while True:
            try:
                for plan in pending(client):
                    if plan["FloorPlanID"] in failed:
                        continue
                    try:
                        process(client, plan)
                    except Exception as e:  # report to the app instead of hanging it
                        failed.add(plan["FloorPlanID"])
                        print(f"{plan['FloorPlanID']}: failed: {e}", file=sys.stderr)
                        try:
                            save(client, plan, "Failed", {"error": str(e)})
                        except Exception as e2:
                            print(f"  could not record failure: {e2}", file=sys.stderr)
            except httpx.HTTPError as e:
                print(f"Supabase request failed: {e}", file=sys.stderr)
            time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    sys.exit(main())
