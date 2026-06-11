from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.transaction import TransactionRead

router = APIRouter()


@router.get("/", response_model=list[TransactionRead])
async def list_transactions(
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[TransactionRead]:
    return await TransactionRepository(db).list_by_user(current_user.id, skip=skip, limit=limit)
