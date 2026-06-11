from fastapi import APIRouter, Depends, HTTPException, status

from app.api.v1.deps import get_current_user
from app.models.user import User

router = APIRouter()


@router.post("/chat")
async def chat(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, "Assistente IA ainda não implementado")
