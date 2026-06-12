from datetime import datetime

from httpx import AsyncClient

from app.core.config import settings
from app.services.pdf.extractor import RawTransaction

PDF_BYTES = b"%PDF-1.4 fake content for tests"


def _fake_raw_transactions() -> list[RawTransaction]:
    return [
        RawTransaction(
            date=datetime(2026, 5, 1),
            description="UBER TRIP SAO PAULO",
            amount=25.50,
            is_credit=False,
            raw_text="01/05/2026 | UBER TRIP SAO PAULO | 25,50",
            hash="fake-hash-1",
        ),
        RawTransaction(
            date=datetime(2026, 5, 2),
            description="SALARIO EMPRESA",
            amount=5000.0,
            is_credit=True,
            raw_text="02/05/2026 | SALARIO EMPRESA | 5000,00",
            hash="fake-hash-2",
        ),
    ]


async def test_upload_pdf_happy_path(client: AsyncClient, auth_headers, monkeypatch):
    monkeypatch.setattr(
        "app.api.v1.routes.uploads.extract_transactions",
        lambda content, bank: _fake_raw_transactions(),
    )

    response = await client.post(
        "/api/v1/uploads/pdf",
        files={"file": ("fatura.pdf", PDF_BYTES, "application/pdf")},
        data={"bank": "itau"},
        headers=auth_headers,
    )

    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "completed"
    assert body["bank_detected"] == "itau"
    assert body["transactions_created"] == 2
    assert body["duplicates_skipped"] == 0


async def test_upload_pdf_dedup_on_reupload(client: AsyncClient, auth_headers, monkeypatch):
    monkeypatch.setattr(
        "app.api.v1.routes.uploads.extract_transactions",
        lambda content, bank: _fake_raw_transactions(),
    )

    first = await client.post(
        "/api/v1/uploads/pdf",
        files={"file": ("fatura.pdf", PDF_BYTES, "application/pdf")},
        data={"bank": "itau"},
        headers=auth_headers,
    )
    assert first.json()["transactions_created"] == 2

    second = await client.post(
        "/api/v1/uploads/pdf",
        files={"file": ("fatura.pdf", PDF_BYTES, "application/pdf")},
        data={"bank": "itau"},
        headers=auth_headers,
    )
    body = second.json()
    assert body["status"] == "completed"
    assert body["transactions_created"] == 0
    assert body["duplicates_skipped"] == 2


async def test_upload_pdf_without_token(client: AsyncClient):
    response = await client.post(
        "/api/v1/uploads/pdf",
        files={"file": ("fatura.pdf", PDF_BYTES, "application/pdf")},
        data={"bank": "itau"},
    )
    assert response.status_code == 401


async def test_upload_pdf_invalid_content_type(client: AsyncClient, auth_headers):
    response = await client.post(
        "/api/v1/uploads/pdf",
        files={"file": ("fatura.txt", b"not a pdf", "text/plain")},
        data={"bank": "itau"},
        headers=auth_headers,
    )
    assert response.status_code == 400


async def test_upload_pdf_unsupported_bank(client: AsyncClient, auth_headers):
    response = await client.post(
        "/api/v1/uploads/pdf",
        files={"file": ("fatura.pdf", PDF_BYTES, "application/pdf")},
        data={"bank": "nubank"},
        headers=auth_headers,
    )
    assert response.status_code == 400


async def test_upload_pdf_too_large(client: AsyncClient, auth_headers, monkeypatch):
    monkeypatch.setattr(settings, "MAX_UPLOAD_SIZE_MB", 0)

    response = await client.post(
        "/api/v1/uploads/pdf",
        files={"file": ("fatura.pdf", PDF_BYTES, "application/pdf")},
        data={"bank": "itau"},
        headers=auth_headers,
    )
    assert response.status_code == 413


async def test_upload_pdf_no_transactions_found(client: AsyncClient, auth_headers, monkeypatch):
    monkeypatch.setattr("app.api.v1.routes.uploads.extract_transactions", lambda content, bank: [])

    response = await client.post(
        "/api/v1/uploads/pdf",
        files={"file": ("fatura.pdf", PDF_BYTES, "application/pdf")},
        data={"bank": "itau"},
        headers=auth_headers,
    )

    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "failed"
    assert body["transactions_created"] == 0
    assert body["error_message"]


async def test_upload_pdf_extraction_error(client: AsyncClient, auth_headers, monkeypatch):
    def _boom(content: bytes, bank: str):
        raise ValueError("corrupted PDF internals")

    monkeypatch.setattr("app.api.v1.routes.uploads.extract_transactions", _boom)

    response = await client.post(
        "/api/v1/uploads/pdf",
        files={"file": ("fatura.pdf", PDF_BYTES, "application/pdf")},
        data={"bank": "itau"},
        headers=auth_headers,
    )

    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "failed"
    assert "corrupted PDF internals" not in body["error_message"]
