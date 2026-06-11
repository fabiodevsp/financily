import enum
import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, Enum, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class UploadStatus(str, enum.Enum):
    PENDING    = "pending"
    PROCESSING = "processing"
    COMPLETED  = "completed"
    FAILED     = "failed"


class Upload(Base):
    __tablename__ = "uploads"

    id            = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id       = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    file_name     = Column(String(255), nullable=False)
    bank_detected = Column(String(50))
    status        = Column(Enum(UploadStatus), default=UploadStatus.PENDING, nullable=False)
    error_message = Column(String(500))
    processed_at  = Column(DateTime)
    created_at    = Column(DateTime, default=datetime.utcnow, nullable=False)

    user         = relationship("User", back_populates="uploads")
    transactions = relationship("Transaction", back_populates="upload")
