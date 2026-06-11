from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.repositories.upload_repository import UploadRepository
from app.schemas.upload import UploadRead

router = APIRouter()


@router.get("/", response_model=list[UploadRead])
async def list_uploads(
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[UploadRead]:
    return await UploadRepository(db).list_by_user(current_user.id, skip=skip, limit=limit)
