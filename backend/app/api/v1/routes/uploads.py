from datetime import datetime

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.config import settings
from app.core.database import get_db
from app.models.transaction import TransactionType
from app.models.upload import Upload, UploadStatus
from app.models.user import User
from app.repositories.transaction_repository import TransactionRepository
from app.repositories.upload_repository import UploadRepository
from app.schemas.upload import UploadRead, UploadResult
from app.services.ai.categorizer import categorizer
from app.services.pdf.extractor import extract_transactions

router = APIRouter()


@router.get("/", response_model=list[UploadRead])
async def list_uploads(
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[UploadRead]:
    return await UploadRepository(db).list_by_user(current_user.id, skip=skip, limit=limit)


@router.post("/pdf", response_model=UploadResult, status_code=status.HTTP_201_CREATED)
async def upload_pdf(
    file: UploadFile = File(...),
    bank: str = Form(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UploadResult:
    bank = bank.lower()
    if bank not in settings.SUPPORTED_BANKS:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Banco não suportado. Bancos disponíveis: {', '.join(settings.SUPPORTED_BANKS)}",
        )

    if file.content_type != "application/pdf":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Arquivo deve ser um PDF")

    content = await file.read()
    max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(
            status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            f"Arquivo excede o limite de {settings.MAX_UPLOAD_SIZE_MB}MB",
        )

    upload_repo = UploadRepository(db)
    transaction_repo = TransactionRepository(db)

    upload = await upload_repo.create(
        user_id=current_user.id,
        file_name=file.filename or "upload.pdf",
        bank_detected=bank,
    )
    upload = await upload_repo.update_status(upload, UploadStatus.PROCESSING)

    try:
        raw_transactions = extract_transactions(content, bank)
    except Exception:
        upload = await upload_repo.update_status(
            upload,
            UploadStatus.FAILED,
            error_message="Falha ao processar o PDF: arquivo inválido ou formato não suportado.",
        )
        return _to_result(upload, created=0, duplicates=0)

    if not raw_transactions:
        upload = await upload_repo.update_status(
            upload,
            UploadStatus.FAILED,
            error_message="Nenhuma transação reconhecida no PDF para o banco selecionado.",
        )
        return _to_result(upload, created=0, duplicates=0)

    created = 0
    duplicates = 0
    for raw in raw_transactions:
        if await transaction_repo.get_by_hash(raw.hash):
            duplicates += 1
            continue

        category, confidence = categorizer.categorize(raw.description)
        await transaction_repo.create(
            user_id=current_user.id,
            upload_id=upload.id,
            date=raw.date,
            description=raw.description,
            amount=raw.amount,
            type=TransactionType.CREDIT if raw.is_credit else TransactionType.DEBIT,
            category=category,
            confidence_score=confidence,
            raw_text=raw.raw_text,
            hash=raw.hash,
        )
        created += 1

    upload = await upload_repo.update_status(upload, UploadStatus.COMPLETED, processed_at=datetime.utcnow())
    return _to_result(upload, created=created, duplicates=duplicates)


def _to_result(upload: Upload, *, created: int, duplicates: int) -> UploadResult:
    return UploadResult(
        **UploadRead.model_validate(upload).model_dump(),
        transactions_created=created,
        duplicates_skipped=duplicates,
    )
