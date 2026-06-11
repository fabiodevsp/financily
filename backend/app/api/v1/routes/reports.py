from fastapi import APIRouter, Depends, HTTPException, status

from app.api.v1.deps import get_current_user
from app.models.user import User

router = APIRouter()

_NOT_IMPLEMENTED = "Exportação ainda não implementada"


@router.post("/pdf")
async def export_pdf(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)


@router.post("/excel")
async def export_excel(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)


@router.post("/csv")
async def export_csv(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)
