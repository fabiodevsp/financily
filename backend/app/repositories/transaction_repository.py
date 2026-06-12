import uuid
from datetime import datetime
from typing import Any, Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql.selectable import Select

from app.models.transaction import Transaction, TransactionCategory, TransactionType

SORTABLE_FIELDS = {
    "date": Transaction.date,
    "amount": Transaction.amount,
    "description": Transaction.description,
}


class TransactionRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    def _apply_filters(
        self,
        stmt: Select,
        user_id: uuid.UUID,
        *,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
        category: Optional[TransactionCategory] = None,
        type: Optional[TransactionType] = None,
        search: Optional[str] = None,
    ) -> Select:
        stmt = stmt.where(Transaction.user_id == user_id)
        if date_from is not None:
            stmt = stmt.where(Transaction.date >= date_from)
        if date_to is not None:
            stmt = stmt.where(Transaction.date <= date_to)
        if category is not None:
            stmt = stmt.where(Transaction.category == category)
        if type is not None:
            stmt = stmt.where(Transaction.type == type)
        if search:
            pattern = f"%{search}%"
            stmt = stmt.where(
                Transaction.description.ilike(pattern) | Transaction.merchant.ilike(pattern)
            )
        return stmt

    async def get_by_id(self, transaction_id: uuid.UUID, user_id: uuid.UUID) -> Optional[Transaction]:
        result = await self.db.execute(
            select(Transaction).where(Transaction.id == transaction_id, Transaction.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_hash(self, hash_: str) -> Optional[Transaction]:
        result = await self.db.execute(select(Transaction).where(Transaction.hash == hash_))
        return result.scalar_one_or_none()

    async def list_by_user(
        self,
        user_id: uuid.UUID,
        *,
        skip: int = 0,
        limit: int = 50,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
        category: Optional[TransactionCategory] = None,
        type: Optional[TransactionType] = None,
        search: Optional[str] = None,
        sort_by: str = "date",
        order: str = "desc",
    ) -> list[Transaction]:
        stmt = self._apply_filters(
            select(Transaction),
            user_id,
            date_from=date_from,
            date_to=date_to,
            category=category,
            type=type,
            search=search,
        )

        column = SORTABLE_FIELDS.get(sort_by, Transaction.date)
        stmt = stmt.order_by(column.asc() if order == "asc" else column.desc())

        stmt = stmt.offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def count_by_user(
        self,
        user_id: uuid.UUID,
        *,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
        category: Optional[TransactionCategory] = None,
        type: Optional[TransactionType] = None,
        search: Optional[str] = None,
    ) -> int:
        stmt = self._apply_filters(
            select(func.count(Transaction.id)),
            user_id,
            date_from=date_from,
            date_to=date_to,
            category=category,
            type=type,
            search=search,
        )
        result = await self.db.execute(stmt)
        return result.scalar_one()

    async def get_summary(
        self,
        user_id: uuid.UUID,
        *,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
    ) -> dict[str, Any]:
        by_type_stmt = self._apply_filters(
            select(Transaction.type, func.sum(Transaction.amount), func.count(Transaction.id)),
            user_id,
            date_from=date_from,
            date_to=date_to,
        ).group_by(Transaction.type)

        by_category_stmt = self._apply_filters(
            select(Transaction.category, func.sum(Transaction.amount), func.count(Transaction.id)),
            user_id,
            date_from=date_from,
            date_to=date_to,
        ).group_by(Transaction.category)

        by_type_result = await self.db.execute(by_type_stmt)
        by_category_result = await self.db.execute(by_category_stmt)

        totals = {TransactionType.CREDIT: 0.0, TransactionType.DEBIT: 0.0}
        for tx_type, total, _count in by_type_result.all():
            totals[tx_type] = float(total or 0.0)

        by_category = [
            {"category": category, "total": float(total or 0.0), "count": count}
            for category, total, count in by_category_result.all()
        ]
        transaction_count = sum(item["count"] for item in by_category)

        return {
            "total_income": totals[TransactionType.CREDIT],
            "total_expenses": totals[TransactionType.DEBIT],
            "balance": totals[TransactionType.CREDIT] - totals[TransactionType.DEBIT],
            "transaction_count": transaction_count,
            "by_category": by_category,
        }

    async def create(self, **fields: Any) -> Transaction:
        transaction = Transaction(**fields)
        self.db.add(transaction)
        await self.db.commit()
        await self.db.refresh(transaction)
        return transaction

    async def update(self, transaction: Transaction, **fields: Any) -> Transaction:
        for key, value in fields.items():
            setattr(transaction, key, value)
        await self.db.commit()
        await self.db.refresh(transaction)
        return transaction

    async def delete(self, transaction: Transaction) -> None:
        await self.db.delete(transaction)
        await self.db.commit()
