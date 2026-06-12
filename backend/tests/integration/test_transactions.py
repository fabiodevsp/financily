import uuid
from datetime import datetime

from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transaction import Transaction, TransactionCategory, TransactionType
from app.models.user import User


async def _create_transaction(db_session: AsyncSession, user: User, **overrides) -> Transaction:
    defaults: dict = dict(
        user_id=user.id,
        date=datetime(2026, 5, 1),
        description="UBER TRIP SAO PAULO",
        merchant=None,
        amount=25.50,
        type=TransactionType.DEBIT,
        category=TransactionCategory.TRANSPORT,
        confidence_score=0.95,
        hash=str(uuid.uuid4()),
    )
    defaults.update(overrides)
    transaction = Transaction(**defaults)
    db_session.add(transaction)
    await db_session.commit()
    await db_session.refresh(transaction)
    return transaction


# ── GET /transactions ────────────────────────────────────────────────────────

async def test_list_transactions_empty(client: AsyncClient, auth_headers):
    response = await client.get("/api/v1/transactions/", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body == {"items": [], "total": 0, "skip": 0, "limit": 50}


async def test_list_transactions_pagination(client: AsyncClient, auth_headers, db_session, test_user):
    for i in range(3):
        await _create_transaction(db_session, test_user, description=f"TX {i}", hash=f"hash-{i}")

    response = await client.get("/api/v1/transactions/?limit=2", headers=auth_headers)
    body = response.json()
    assert body["total"] == 3
    assert len(body["items"]) == 2


async def test_list_transactions_filter_by_date(client: AsyncClient, auth_headers, db_session, test_user):
    await _create_transaction(db_session, test_user, date=datetime(2026, 5, 1), hash="may")
    await _create_transaction(db_session, test_user, date=datetime(2026, 6, 1), hash="june")

    response = await client.get(
        "/api/v1/transactions/?date_from=2026-05-15T00:00:00", headers=auth_headers
    )
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["description"] == "UBER TRIP SAO PAULO"
    assert body["items"][0]["date"].startswith("2026-06-01")


async def test_list_transactions_invalid_date_range(client: AsyncClient, auth_headers):
    response = await client.get(
        "/api/v1/transactions/?date_from=2026-06-01T00:00:00&date_to=2026-05-01T00:00:00",
        headers=auth_headers,
    )
    assert response.status_code == 400


async def test_list_transactions_filter_by_category(client: AsyncClient, auth_headers, db_session, test_user):
    await _create_transaction(db_session, test_user, category=TransactionCategory.FOOD, hash="food")
    await _create_transaction(db_session, test_user, category=TransactionCategory.TRANSPORT, hash="transport")

    response = await client.get("/api/v1/transactions/?category=food", headers=auth_headers)
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["category"] == "food"


async def test_list_transactions_filter_by_type(client: AsyncClient, auth_headers, db_session, test_user):
    await _create_transaction(db_session, test_user, type=TransactionType.CREDIT, hash="credit")
    await _create_transaction(db_session, test_user, type=TransactionType.DEBIT, hash="debit")

    response = await client.get("/api/v1/transactions/?type=credit", headers=auth_headers)
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["type"] == "credit"


async def test_list_transactions_search(client: AsyncClient, auth_headers, db_session, test_user):
    await _create_transaction(db_session, test_user, description="UBER TRIP", merchant=None, hash="uber")
    await _create_transaction(
        db_session, test_user, description="ASSINATURA MENSAL", merchant="Netflix Inc", hash="netflix"
    )

    response = await client.get("/api/v1/transactions/?search=netflix", headers=auth_headers)
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["merchant"] == "Netflix Inc"


async def test_list_transactions_sort_by_amount_asc(client: AsyncClient, auth_headers, db_session, test_user):
    await _create_transaction(db_session, test_user, amount=30.0, hash="a")
    await _create_transaction(db_session, test_user, amount=10.0, hash="b")
    await _create_transaction(db_session, test_user, amount=20.0, hash="c")

    response = await client.get(
        "/api/v1/transactions/?sort_by=amount&order=asc", headers=auth_headers
    )
    body = response.json()
    assert [item["amount"] for item in body["items"]] == [10.0, 20.0, 30.0]


async def test_list_transactions_user_isolation(client: AsyncClient, auth_headers, db_session, test_user, other_user):
    await _create_transaction(db_session, test_user, hash="mine")
    await _create_transaction(db_session, other_user, hash="not-mine")

    response = await client.get("/api/v1/transactions/", headers=auth_headers)
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["description"] == "UBER TRIP SAO PAULO"


async def test_list_transactions_without_token(client: AsyncClient):
    response = await client.get("/api/v1/transactions/")
    assert response.status_code == 401


# ── GET /transactions/summary ───────────────────────────────────────────────

async def test_summary_empty(client: AsyncClient, auth_headers):
    response = await client.get("/api/v1/transactions/summary", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["total_income"] == 0.0
    assert body["total_expenses"] == 0.0
    assert body["balance"] == 0.0
    assert body["transaction_count"] == 0
    assert body["by_category"] == []


async def test_summary_with_data(client: AsyncClient, auth_headers, db_session, test_user):
    await _create_transaction(
        db_session, test_user, type=TransactionType.CREDIT, category=TransactionCategory.SALARY,
        amount=5000.0, hash="salary",
    )
    await _create_transaction(
        db_session, test_user, type=TransactionType.DEBIT, category=TransactionCategory.FOOD,
        amount=100.0, hash="food",
    )
    await _create_transaction(
        db_session, test_user, type=TransactionType.DEBIT, category=TransactionCategory.TRANSPORT,
        amount=50.0, hash="transport",
    )

    response = await client.get("/api/v1/transactions/summary", headers=auth_headers)
    body = response.json()
    assert body["total_income"] == 5000.0
    assert body["total_expenses"] == 150.0
    assert body["balance"] == 4850.0
    assert body["transaction_count"] == 3

    by_category = {item["category"]: item for item in body["by_category"]}
    assert by_category["salary"]["total"] == 5000.0
    assert by_category["food"]["total"] == 100.0
    assert by_category["transport"]["total"] == 50.0


async def test_summary_date_filter(client: AsyncClient, auth_headers, db_session, test_user):
    await _create_transaction(db_session, test_user, date=datetime(2026, 5, 1), amount=100.0, hash="may")
    await _create_transaction(db_session, test_user, date=datetime(2026, 6, 1), amount=200.0, hash="june")

    response = await client.get(
        "/api/v1/transactions/summary?date_from=2026-05-15T00:00:00", headers=auth_headers
    )
    body = response.json()
    assert body["transaction_count"] == 1
    assert body["total_expenses"] == 200.0


async def test_summary_without_token(client: AsyncClient):
    response = await client.get("/api/v1/transactions/summary")
    assert response.status_code == 401


# ── PATCH /transactions/{id} ────────────────────────────────────────────────

async def test_update_transaction_category(client: AsyncClient, auth_headers, db_session, test_user):
    transaction = await _create_transaction(
        db_session, test_user, category=TransactionCategory.OTHER, confidence_score=0.0, hash="to-update"
    )

    response = await client.patch(
        f"/api/v1/transactions/{transaction.id}",
        json={"category": "food", "subcategory": "restaurante"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["category"] == "food"
    assert body["subcategory"] == "restaurante"
    assert body["confidence_score"] == 1.0


async def test_update_transaction_not_found(client: AsyncClient, auth_headers):
    response = await client.patch(
        f"/api/v1/transactions/{uuid.uuid4()}", json={"category": "food"}, headers=auth_headers
    )
    assert response.status_code == 404


async def test_update_transaction_other_user(client: AsyncClient, auth_headers, db_session, other_user):
    transaction = await _create_transaction(db_session, other_user, hash="other-users-tx")

    response = await client.patch(
        f"/api/v1/transactions/{transaction.id}", json={"category": "food"}, headers=auth_headers
    )
    assert response.status_code == 404


async def test_update_transaction_invalid_category(client: AsyncClient, auth_headers, db_session, test_user):
    transaction = await _create_transaction(db_session, test_user, hash="invalid-category-target")

    response = await client.patch(
        f"/api/v1/transactions/{transaction.id}", json={"category": "not-a-real-category"}, headers=auth_headers
    )
    assert response.status_code == 422


async def test_update_transaction_without_token(client: AsyncClient):
    response = await client.patch(f"/api/v1/transactions/{uuid.uuid4()}", json={"category": "food"})
    assert response.status_code == 401


# ── DELETE /transactions/{id} ───────────────────────────────────────────────

async def test_delete_transaction(client: AsyncClient, auth_headers, db_session, test_user):
    transaction = await _create_transaction(db_session, test_user, hash="to-delete")

    response = await client.delete(f"/api/v1/transactions/{transaction.id}", headers=auth_headers)
    assert response.status_code == 204

    list_response = await client.get("/api/v1/transactions/", headers=auth_headers)
    assert list_response.json()["total"] == 0


async def test_delete_transaction_not_found(client: AsyncClient, auth_headers):
    response = await client.delete(f"/api/v1/transactions/{uuid.uuid4()}", headers=auth_headers)
    assert response.status_code == 404


async def test_delete_transaction_other_user(client: AsyncClient, auth_headers, db_session, other_user):
    transaction = await _create_transaction(db_session, other_user, hash="other-users-tx-delete")

    response = await client.delete(f"/api/v1/transactions/{transaction.id}", headers=auth_headers)
    assert response.status_code == 404


async def test_delete_transaction_without_token(client: AsyncClient):
    response = await client.delete(f"/api/v1/transactions/{uuid.uuid4()}")
    assert response.status_code == 401
