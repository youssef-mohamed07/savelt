"""
LLM-based financial transaction extraction for voice/text input.

Uses OpenAI structured outputs when OPENAI_API_KEY is configured.
Falls back gracefully so rule-based NLP can handle the request.
"""
from __future__ import annotations

import asyncio
import json
import os
import uuid
from functools import lru_cache
from pathlib import Path
from typing import List, Optional

from dotenv import load_dotenv

from app.core.logging import get_logger
from app.models.domain import Transaction, TransactionType
from app.utils.text_utils import normalize_arabic_text, strip_conversational_prefix

logger = get_logger("llm_transaction_extractor")

PROJECT_ROOT = Path(__file__).resolve().parents[3]
OCR_ENV_PATH = PROJECT_ROOT / "ocr_service" / ".env"
VOICE_ENV_PATH = PROJECT_ROOT / "voice_server" / ".env"

APP_CATEGORIES = [
    "Food & Drinks",
    "Transportation",
    "Shopping",
    "Health & Beauty",
    "Bills & Utilities",
    "Entertainment",
    "Clothes & Fashion",
    "Salary & Income",
    "Education",
    "Other",
]

SYSTEM_PROMPT = """You extract Egyptian Arabic and English personal finance transactions from spoken expense notes.

Rules:
- Ignore greetings and small talk (مرحبا، كيف حالك، etc.).
- Split multiple purchases into separate transactions (e.g. شيبسي 30 + كراتي 10 + كوكيز 5).
- `item` must be ONLY the product/service name in the user's language (short), NOT the full sentence.
- Convert Arabic number words to numeric amounts (خمسة=5, تلاتين=30, مية=100).
- Default currency is EGP.
- Use transaction_type "income" only for salary/wages received; otherwise "expense".
- Pick category from the allowed list only.
- merchant is optional (store/place name if mentioned).
- confidence_score: 0.0-1.0 based on clarity of amount and item.
"""


def _load_openai_env() -> None:
    if VOICE_ENV_PATH.exists():
        load_dotenv(VOICE_ENV_PATH, override=False)
    if OCR_ENV_PATH.exists():
        load_dotenv(OCR_ENV_PATH, override=False)


_load_openai_env()


def _strict_schema() -> dict:
    tx_schema = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "amount": {"type": "number", "description": "Amount in EGP"},
            "transaction_type": {
                "type": "string",
                "enum": ["expense", "income"],
            },
            "category": {
                "type": "string",
                "enum": APP_CATEGORIES,
            },
            "item": {
                "type": "string",
                "description": "Short product/service name only",
            },
            "merchant": {"type": ["string", "null"]},
            "extracted_text": {
                "type": "string",
                "description": "Original phrase for this transaction",
            },
            "confidence_score": {"type": "number"},
        },
        "required": [
            "amount",
            "transaction_type",
            "category",
            "item",
            "merchant",
            "extracted_text",
            "confidence_score",
        ],
    }

    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "transactions": {
                "type": "array",
                "items": tx_schema,
            },
            "language_detected": {"type": "string"},
        },
        "required": ["transactions", "language_detected"],
    }


@lru_cache(maxsize=1)
def _openai_client():
    from openai import OpenAI

    api_key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY not configured")
    return OpenAI(api_key=api_key)


def is_llm_available() -> bool:
    return bool(os.environ.get("OPENAI_API_KEY", "").strip())


def _extract_sync(text: str, language: str) -> Optional[dict]:
    if not is_llm_available():
        return None

    cleaned = normalize_arabic_text(strip_conversational_prefix(text))
    if len(cleaned.strip()) < 3:
        return None

    model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
    client = _openai_client()

    user_prompt = (
        f"Language hint: {language}\n"
        f"Transcription:\n{cleaned}\n\n"
        "Extract every distinct purchase or income mentioned."
    )

    response = client.chat.completions.create(
        model=model,
        temperature=0,
        max_tokens=1200,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt},
        ],
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "voice_transactions",
                "strict": True,
                "schema": _strict_schema(),
            },
        },
    )

    raw = response.choices[0].message.content
    if not raw:
        return None
    return json.loads(raw)


def _to_domain_transactions(payload: dict, original_text: str) -> List[Transaction]:
    rows = payload.get("transactions") or []
    results: List[Transaction] = []

    for row in rows:
        amount = row.get("amount")
        if amount is None or float(amount) <= 0:
            continue

        tx_type_raw = (row.get("transaction_type") or "expense").lower()
        tx_type = (
            TransactionType.INCOME
            if tx_type_raw == "income"
            else TransactionType.EXPENSE
        )

        category = row.get("category") or "Other"
        if category not in APP_CATEGORIES:
            category = "Other"

        item = (row.get("item") or "").strip()
        if not item:
            continue

        segment = (row.get("extracted_text") or item).strip()
        merchant = row.get("merchant")
        confidence = float(row.get("confidence_score") or 0.85)
        confidence = max(0.0, min(confidence, 1.0))

        results.append(
            Transaction(
                id=str(uuid.uuid4()),
                amount=float(amount),
                transaction_type=tx_type,
                category=category,
                item=item,
                merchant=merchant,
                confidence_score=confidence,
                extracted_from=segment or original_text,
            )
        )

    return results


async def extract_transactions_llm(
    text: str,
    language: str = "ar",
) -> Optional[List[Transaction]]:
    """Extract transactions via OpenAI. Returns None if unavailable or failed."""
    if not is_llm_available():
        return None

    try:
        payload = await asyncio.to_thread(_extract_sync, text, language)
        if not payload:
            return None

        transactions = _to_domain_transactions(payload, text)
        if not transactions:
            logger.warning("LLM returned no valid transactions")
            return None

        logger.info(
            "LLM extracted %d transaction(s) (model=%s)",
            len(transactions),
            os.environ.get("OPENAI_MODEL", "gpt-4o-mini"),
        )
        return transactions

    except Exception as exc:
        logger.warning("LLM extraction failed, using rule-based fallback: %s", exc)
        return None
