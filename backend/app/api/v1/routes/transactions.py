import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.database import get_db
from app.models.transaction import TransactionCategory, TransactionType
from app.models.user import User
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.transaction import TransactionList, TransactionRead, TransactionSummary, TransactionUpdate

router = APIRouter()


@router.get("/", response_model=TransactionList)
async def list_transactions(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    category: Optional[TransactionCategory] = None,
    type: Optional[TransactionType] = None,
    search: Optional[str] = None,
    sort_by: str = Query("date", pattern="^(date|amount|description)$"),
    order: str = Query("desc", pattern="^(asc|desc)$"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TransactionList:
    if date_from and date_to and date_from > date_to:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "date_from não pode ser posterior a date_to")

    repo = TransactionRepository(db)
    filters = dict(date_from=date_from, date_to=date_to, category=category, type=type, search=search)

    items = await repo.list_by_user(current_user.id, skip=skip, limit=limit, sort_by=sort_by, order=order, **filters)
    total = await repo.count_by_user(current_user.id, **filters)
    return TransactionList(items=items, total=total, skip=skip, limit=limit)


@router.get("/summary", response_model=TransactionSummary)
async def get_transactions_summary(
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TransactionSummary:
    if date_from and date_to and date_from > date_to:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "date_from não pode ser posterior a date_to")

    summary = await TransactionRepository(db).get_summary(current_user.id, date_from=date_from, date_to=date_to)
    return TransactionSummary(**summary, date_from=date_from, date_to=date_to)


@router.patch("/{transaction_id}", response_model=TransactionRead)
async def update_transaction(
    transaction_id: uuid.UUID,
    payload: TransactionUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TransactionRead:
    repo = TransactionRepository(db)
    transaction = await repo.get_by_id(transaction_id, current_user.id)
    if not transaction:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Transação não encontrada")

    updates = payload.model_dump(exclude_unset=True)
    if not updates:
        return transaction

    updates["confidence_score"] = 1.0
    return await repo.update(transaction, **updates)


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_transaction(
    transaction_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    repo = TransactionRepository(db)
    transaction = await repo.get_by_id(transaction_id, current_user.id)
    if not transaction:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Transação não encontrada")

    await repo.delete(transaction)
