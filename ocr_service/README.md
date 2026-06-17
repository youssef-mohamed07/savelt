# OCR Engine (oocr)

The Flask server (`app.py`) was removed. OCR now runs inside the **unified AI server** at `voice_server/` on port **8000**.

## Endpoint

`POST http://localhost:8000/ocr/scan` — multipart field `image`

## Setup

1. Keep `OPENAI_API_KEY` in `ocr_service/.env` (auto-loaded by the unified server)
2. The `oocr/` folder here is the receipt extraction engine — do not delete
3. Start everything with one command from project root:

```bash
./start.sh --no-app
```

This starts Node API (:3001) which automatically spawns voice + OCR (:8000).
