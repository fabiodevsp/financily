import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict

from app.models.upload import UploadStatus


class UploadRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    file_name: str
    bank_detected: Optional[str] = None
    status: UploadStatus
    error_message: Optional[str] = None
    processed_at: Optional[datetime] = None
    created_at: datetime


class UploadResult(UploadRead):
    """Response of POST /uploads/pdf — adds processing counters to UploadRead."""

    transactions_created: int
    duplicates_skipped: int
