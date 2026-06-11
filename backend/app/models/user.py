import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Enum, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class SubscriptionTier(str, enum.Enum):
    FREE = "free"
    PRO = "pro"
    ENTERPRISE = "enterprise"


class User(Base):
    __tablename__ = "users"

    id                = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email             = Column(String(255), unique=True, nullable=False, index=True)
    password_hash     = Column(String(255), nullable=False)
    name              = Column(String(200))
    subscription_tier = Column(Enum(SubscriptionTier), default=SubscriptionTier.FREE, nullable=False)
    is_active         = Column(Boolean, default=True, nullable=False)
    created_at        = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at        = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    uploads      = relationship("Upload", back_populates="user", cascade="all, delete-orphan")
