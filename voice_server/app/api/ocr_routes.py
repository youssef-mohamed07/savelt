"""
OCR receipt scanning — merged from ocr_service into the unified AI server.
"""
from __future__ import annotations

import os
import sys
import tempfile
import traceback
from pathlib import Path

from dotenv import load_dotenv
from fastapi import APIRouter, File, HTTPException, UploadFile

router = APIRouter(prefix="/ocr", tags=["ocr"])

PROJECT_ROOT = Path(__file__).resolve().parents[3]
OOCR_DIR = PROJECT_ROOT / "ocr_service" / "oocr"
OCR_ENV_PATH = PROJECT_ROOT / "ocr_service" / ".env"
_extractor = None


def _load_ocr_env() -> None:
    """Load OPENAI_API_KEY from ocr_service/.env when not already set."""
    if os.environ.get("OPENAI_API_KEY"):
        return
    if OCR_ENV_PATH.exists():
        load_dotenv(OCR_ENV_PATH, override=False)


_load_ocr_env()


def _ensure_oocr() -> None:
    global _extractor
    if _extractor is not None:
        return

    if not OOCR_DIR.exists():
        raise RuntimeError(
            f"OCR engine not found at {OOCR_DIR}. "
            "Run ocr_service once or clone elamaah/oocr into ocr_service/oocr."
        )

    if str(OOCR_DIR) not in sys.path:
        sys.path.insert(0, str(OOCR_DIR))

    try:
        from extractor import extract_invoice_advanced  # noqa: E402
    except ImportError as exc:
        raise RuntimeError(
            "OCR Python dependencies are missing. "
            "Restart with ./start.sh --no-app to install them."
        ) from exc

    _extractor = extract_invoice_advanced


def _ocr_engine_status() -> dict:
    status = {
        "oocr_path": str(OOCR_DIR),
        "openai_key": bool(os.environ.get("OPENAI_API_KEY")),
        "engine_ready": False,
        "error": None,
    }
    if not OOCR_DIR.exists():
        status["error"] = "missing_oocr"
        return status
    try:
        _ensure_oocr()
        status["engine_ready"] = _extractor is not None
    except Exception as exc:
        status["error"] = str(exc)
    return status


@router.get("/health")
async def ocr_health():
    info = _ocr_engine_status()
    ok = info["engine_ready"] and info["openai_key"]
    return {"status": "ok" if ok else "degraded", "service": "ocr", **info}


@router.post("/scan")
async def scan_receipt(image: UploadFile = File(...)):
    """Scan a receipt image and return structured invoice JSON."""
    api_key = os.environ.get("OPENAI_API_KEY", "")
    if not api_key:
        raise HTTPException(status_code=503, detail="OPENAI_API_KEY not configured")

    if not image.filename:
        raise HTTPException(status_code=400, detail="Empty filename")

    try:
        _ensure_oocr()
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    suffix = Path(image.filename).suffix or ".jpg"
    content = await image.read()

    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(content)
        tmp_path = tmp.name

    try:
        result = _extractor(
            tmp_path,
            save_debug=False,
            preprocess_mode="light",
        )
        return {"success": True, "data": result}
    except Exception as exc:
        print(f"[OCR ERROR] {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
