"""initial schema

Revision ID: 7132eab5146a
Revises:
Create Date: 2026-06-11 00:56:51.020932

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '7132eab5146a'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


subscription_tier_enum = postgresql.ENUM(
    "free", "pro", "enterprise", name="subscriptiontier"
)
upload_status_enum = postgresql.ENUM(
    "pending", "processing", "completed", "failed", name="uploadstatus"
)
transaction_type_enum = postgresql.ENUM(
    "debit", "credit", name="transactiontype"
)
transaction_category_enum = postgresql.ENUM(
    "food", "transport", "shopping", "subscriptions", "health", "travel",
    "entertainment", "bills", "salary", "investments", "other",
    name="transactioncategory",
)


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("name", sa.String(200), nullable=True),
        sa.Column("subscription_tier", subscription_tier_enum, nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "uploads",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("file_name", sa.String(255), nullable=False),
        sa.Column("bank_detected", sa.String(50), nullable=True),
        sa.Column("status", upload_status_enum, nullable=False),
        sa.Column("error_message", sa.String(500), nullable=True),
        sa.Column("processed_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_uploads_user_id", "uploads", ["user_id"])

    op.create_table(
        "transactions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("upload_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("date", sa.DateTime(), nullable=False),
        sa.Column("description", sa.String(500), nullable=False),
        sa.Column("merchant", sa.String(200), nullable=True),
        sa.Column("amount", sa.Float(), nullable=False),
        sa.Column("type", transaction_type_enum, nullable=False),
        sa.Column("category", transaction_category_enum, nullable=True),
        sa.Column("subcategory", sa.String(100), nullable=True),
        sa.Column("is_recurring", sa.Boolean(), nullable=True),
        sa.Column("is_subscription", sa.Boolean(), nullable=True),
        sa.Column("is_installment", sa.Boolean(), nullable=True),
        sa.Column("installment_current", sa.Float(), nullable=True),
        sa.Column("installment_total", sa.Float(), nullable=True),
        sa.Column("confidence_score", sa.Float(), nullable=True),
        sa.Column("raw_text", sa.Text(), nullable=True),
        sa.Column("hash", sa.String(64), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["upload_id"], ["uploads.id"], ondelete="SET NULL"),
        sa.UniqueConstraint("hash"),
    )
    op.create_index("ix_transactions_user_id", "transactions", ["user_id"])
    op.create_index("ix_transactions_upload_id", "transactions", ["upload_id"])
    op.create_index("ix_transactions_date", "transactions", ["date"])
    op.create_index("ix_transactions_category", "transactions", ["category"])


def downgrade() -> None:
    op.drop_index("ix_transactions_category", table_name="transactions")
    op.drop_index("ix_transactions_date", table_name="transactions")
    op.drop_index("ix_transactions_upload_id", table_name="transactions")
    op.drop_index("ix_transactions_user_id", table_name="transactions")
    op.drop_table("transactions")

    op.drop_index("ix_uploads_user_id", table_name="uploads")
    op.drop_table("uploads")

    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")

    bind = op.get_bind()
    transaction_category_enum.drop(bind, checkfirst=True)
    transaction_type_enum.drop(bind, checkfirst=True)
    upload_status_enum.drop(bind, checkfirst=True)
    subscription_tier_enum.drop(bind, checkfirst=True)
