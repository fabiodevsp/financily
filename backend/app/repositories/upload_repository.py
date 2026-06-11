import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.upload import Upload, UploadStatus


class UploadRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_id(self, upload_id: uuid.UUID, user_id: uuid.UUID) -> Optional[Upload]:
        result = await self.db.execute(
            select(Upload).where(Upload.id == upload_id, Upload.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def list_by_user(self, user_id: uuid.UUID, *, skip: int = 0, limit: int = 50) -> list[Upload]:
        result = await self.db.execute(
            select(Upload)
            .where(Upload.user_id == user_id)
            .order_by(Upload.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def create(self, *, user_id: uuid.UUID, file_name: str, bank_detected: Optional[str] = None) -> Upload:
        upload = Upload(user_id=user_id, file_name=file_name, bank_detected=bank_detected)
        self.db.add(upload)
        await self.db.commit()
        await self.db.refresh(upload)
        return upload

    async def update_status(
        self,
        upload: Upload,
        status: UploadStatus,
        *,
        processed_at: Optional[datetime] = None,
        error_message: Optional[str] = None,
    ) -> Upload:
        upload.status = status
        if processed_at is not None:
            upload.processed_at = processed_at
        if error_message is not None:
            upload.error_message = error_message
        await self.db.commit()
        await self.db.refresh(upload)
        return upload
