from datetime import datetime

from app.services.pdf import extractor


# ── _parse_amount ────────────────────────────────────────────────────────────

def test_parse_amount_simple():
    assert extractor._parse_amount("25,50") == 25.50


def test_parse_amount_with_thousands_separator():
    assert extractor._parse_amount("1.234,56") == 1234.56


def test_parse_amount_with_currency_symbol():
    assert extractor._parse_amount("R$ 100,00") == 100.0


def test_parse_amount_negative():
    assert extractor._parse_amount("-50,00") == -50.0


def test_parse_amount_invalid_returns_none():
    assert extractor._parse_amount("abc") is None


# ── _parse_date_br ───────────────────────────────────────────────────────────

def test_parse_date_br_full_year():
    assert extractor._parse_date_br("01/05/2026") == datetime(2026, 5, 1)


def test_parse_date_br_two_digit_year():
    assert extractor._parse_date_br("01/05/26") == datetime(2026, 5, 1)


def test_parse_date_br_iso_format():
    assert extractor._parse_date_br("2026-05-01") == datetime(2026, 5, 1)


def test_parse_date_br_invalid_returns_none():
    assert extractor._parse_date_br("not-a-date") is None


# ── _hash ────────────────────────────────────────────────────────────────────

def test_hash_is_deterministic():
    assert extractor._hash("01/05/2026 | UBER | 25,50") == extractor._hash("01/05/2026 | UBER | 25,50")


def test_hash_differs_for_different_input():
    assert extractor._hash("a") != extractor._hash("b")


def test_hash_is_sha256_hex():
    assert len(extractor._hash("anything")) == 64


# ── _deduplicate ─────────────────────────────────────────────────────────────

def _make_tx(hash_: str) -> extractor.RawTransaction:
    return extractor.RawTransaction(
        date=datetime(2026, 5, 1),
        description="desc",
        amount=10.0,
        is_credit=False,
        raw_text="raw",
        hash=hash_,
    )


def test_deduplicate_removes_repeated_hashes():
    txs = [_make_tx("a"), _make_tx("b"), _make_tx("a")]
    result = extractor._deduplicate(txs)
    assert [tx.hash for tx in result] == ["a", "b"]


# ── _parse_itau_row ──────────────────────────────────────────────────────────

def test_parse_itau_row_valid():
    row = ["01/05/2026", "UBER TRIP SAO PAULO", "", "25,50"]
    tx = extractor._parse_itau_row(row)
    assert tx is not None
    assert tx.date == datetime(2026, 5, 1)
    assert tx.description == "UBER TRIP SAO PAULO"
    assert tx.amount == 25.50
    assert tx.hash == extractor._hash(tx.raw_text)


def test_parse_itau_row_too_short_returns_none():
    assert extractor._parse_itau_row(["01/05/2026", "25,50"]) is None


def test_parse_itau_row_invalid_date_returns_none():
    assert extractor._parse_itau_row(["not-a-date", "DESC", "25,50"]) is None


def test_parse_itau_row_invalid_amount_returns_none():
    assert extractor._parse_itau_row(["01/05/2026", "DESC", "not-a-number"]) is None


# ── _parse_santander_row delegates to _parse_itau_row ────────────────────────

def test_parse_santander_row_matches_itau():
    row = ["01/05/2026", "COMPRA DEBITO", "", "100,00"]
    assert extractor._parse_santander_row(row) == extractor._parse_itau_row(row)
