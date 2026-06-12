import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict

from app.models.transaction import TransactionCategory, TransactionType


class TransactionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    upload_id: Optional[uuid.UUID] = None
    date: datetime
    description: str
    merchant: Optional[str] = None
    amount: float
    type: TransactionType
    category: TransactionCategory
    subcategory: Optional[str] = None
    is_recurring: bool
    is_subscription: bool
    is_installment: bool
    installment_current: Optional[float] = None
    installment_total: Optional[float] = None
    confidence_score: float
    created_at: datetime


class TransactionList(BaseModel):
    items: list[TransactionRead]
    total: int
    skip: int
    limit: int


class CategorySummary(BaseModel):
    category: TransactionCategory
    total: float
    count: int


class TransactionSummary(BaseModel):
    total_income: float
    total_expenses: float
    balance: float
    transaction_count: int
    by_category: list[CategorySummary]
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None


class TransactionUpdate(BaseModel):
    category: Optional[TransactionCategory] = None
    subcategory: Optional[str] = None
