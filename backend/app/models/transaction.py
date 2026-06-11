from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey, Enum, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import enum
import uuid
from datetime import datetime
from app.core.database import Base

class TransactionType(str, enum.Enum):
    DEBIT  = "debit"
    CREDIT = "credit"

class TransactionCategory(str, enum.Enum):
    FOOD           = "food"
    TRANSPORT      = "transport"
    SHOPPING       = "shopping"
    SUBSCRIPTIONS  = "subscriptions"
    HEALTH         = "health"
    TRAVEL         = "travel"
    ENTERTAINMENT  = "entertainment"
    BILLS          = "bills"
    SALARY         = "salary"
    INVESTMENTS    = "investments"
    OTHER          = "other"

class Transaction(Base):
    __tablename__ = "transactions"

    id                  = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id             = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    upload_id           = Column(UUID(as_uuid=True), ForeignKey("uploads.id", ondelete="SET NULL"), nullable=True, index=True)
    date                = Column(DateTime, nullable=False, index=True)
    description         = Column(String(500), nullable=False)
    merchant            = Column(String(200))
    amount              = Column(Float, nullable=False)
    type                = Column(Enum(TransactionType), nullable=False)
    category            = Column(Enum(TransactionCategory), default=TransactionCategory.OTHER, index=True)
    subcategory         = Column(String(100))
    is_recurring        = Column(Boolean, default=False)
    is_subscription     = Column(Boolean, default=False)
    is_installment      = Column(Boolean, default=False)
    installment_current = Column(Float)
    installment_total   = Column(Float)
    confidence_score    = Column(Float, default=0.0)
    raw_text            = Column(Text)
    hash                = Column(String(64), unique=True)
    created_at          = Column(DateTime, default=datetime.utcnow)

    user   = relationship("User", back_populates="transactions")
    upload = relationship("Upload", back_populates="transactions")
