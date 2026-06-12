"""
PDF extraction pipeline:
  1. pdfplumber (table-based banks)
  2. PyMuPDF + Tesseract OCR (image-based / scanned PDFs)

Operates entirely in memory (bytes in, never written to disk) per LGPD requirements.
"""
import hashlib
import re
from dataclasses import dataclass
from datetime import datetime
from io import BytesIO
from typing import Optional

import pdfplumber
import fitz  # PyMuPDF
import pytesseract
from PIL import Image

from app.core.config import settings

pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_CMD


@dataclass
class RawTransaction:
    date: datetime
    description: str
    amount: float
    is_credit: bool
    raw_text: str
    hash: str


def extract_transactions(pdf_bytes: bytes, bank: str) -> list[RawTransaction]:
    """Entry point: tries pdfplumber first, falls back to OCR."""
    results = _try_pdfplumber(pdf_bytes, bank)
    if not results:
        results = _try_ocr(pdf_bytes, bank)
    return _deduplicate(results)


# ── pdfplumber path ─────────────────────────────────────────────────────────

def _try_pdfplumber(pdf_bytes: bytes, bank: str) -> list[RawTransaction]:
    transactions = []
    with pdfplumber.open(BytesIO(pdf_bytes)) as pdf:
        for page in pdf.pages:
            tables = page.extract_tables()
            for table in tables:
                parsed = _parse_table(table, bank)
                transactions.extend(parsed)
    return transactions


def _parse_table(table: list[list], bank: str) -> list[RawTransaction]:
    parsers = {"itau": _parse_itau_row, "santander": _parse_santander_row}
    parser = parsers.get(bank.lower())
    if not parser:
        return []
    results = []
    for row in table:
        if not row or not any(row):
            continue
        tx = parser(row)
        if tx:
            results.append(tx)
    return results


def _parse_itau_row(row: list) -> Optional[RawTransaction]:
    if len(row) < 3:
        return None
    try:
        date_str = str(row[0]).strip()
        desc     = str(row[1]).strip()
        amount   = _parse_amount(str(row[-1]))
        date     = _parse_date_br(date_str)
        if not date or not amount:
            return None
        raw = " | ".join(str(c) for c in row if c)
        return RawTransaction(
            date=date, description=desc, amount=abs(amount),
            is_credit=amount > 0, raw_text=raw, hash=_hash(raw),
        )
    except Exception:
        return None


def _parse_santander_row(row: list) -> Optional[RawTransaction]:
    return _parse_itau_row(row)  # similar structure; refine per bank spec


# ── OCR path ────────────────────────────────────────────────────────────────

def _try_ocr(pdf_bytes: bytes, bank: str) -> list[RawTransaction]:
    transactions = []
    doc = fitz.open(stream=pdf_bytes, filetype="pdf")
    for page in doc:
        pix  = page.get_pixmap(dpi=300)
        img  = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        text = pytesseract.image_to_string(img, lang="por")
        transactions.extend(_parse_ocr_text(text, bank))
    return transactions


def _parse_ocr_text(text: str, bank: str) -> list[RawTransaction]:
    pattern = re.compile(
        r"(\d{2}/\d{2}/\d{4})\s+(.+?)\s+([\d.,]+)\s*(C|D)?",
        re.MULTILINE,
    )
    results = []
    for m in pattern.finditer(text):
        date   = _parse_date_br(m.group(1))
        desc   = m.group(2).strip()
        amount = _parse_amount(m.group(3))
        credit = m.group(4) == "C" if m.group(4) else amount > 0
        if date and amount:
            raw = m.group(0)
            results.append(RawTransaction(
                date=date, description=desc, amount=abs(amount),
                is_credit=credit, raw_text=raw, hash=_hash(raw),
            ))
    return results


# ── Helpers ──────────────────────────────────────────────────────────────────

def _parse_amount(s: str) -> Optional[float]:
    try:
        clean = re.sub(r"[^\d,.-]", "", s).replace(".", "").replace(",", ".")
        return float(clean)
    except ValueError:
        return None


def _parse_date_br(s: str) -> Optional[datetime]:
    for fmt in ("%d/%m/%Y", "%d/%m/%y", "%Y-%m-%d"):
        try:
            return datetime.strptime(s.strip(), fmt)
        except ValueError:
            continue
    return None


def _hash(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def _deduplicate(txs: list[RawTransaction]) -> list[RawTransaction]:
    seen: set[str] = set()
    unique = []
    for tx in txs:
        if tx.hash not in seen:
            seen.add(tx.hash)
            unique.append(tx)
    return unique
