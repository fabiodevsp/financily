import uuid
from typing import Any, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transaction import Transaction


class TransactionRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_id(self, transaction_id: uuid.UUID, user_id: uuid.UUID) -> Optional[Transaction]:
        result = await self.db.execute(
            select(Transaction).where(Transaction.id == transaction_id, Transaction.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_hash(self, hash_: str) -> Optional[Transaction]:
        result = await self.db.execute(select(Transaction).where(Transaction.hash == hash_))
        return result.scalar_one_or_none()

    async def list_by_user(self, user_id: uuid.UUID, *, skip: int = 0, limit: int = 50) -> list[Transaction]:
        result = await self.db.execute(
            select(Transaction)
            .where(Transaction.user_id == user_id)
            .order_by(Transaction.date.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def create(self, **fields: Any) -> Transaction:
        transaction = Transaction(**fields)
        self.db.add(transaction)
        await self.db.commit()
        await self.db.refresh(transaction)
        return transaction

    async def delete(self, transaction: Transaction) -> None:
        await self.db.delete(transaction)
        await self.db.commit()
