from fastapi import APIRouter, Depends, HTTPException, status

from app.api.v1.deps import get_current_user
from app.models.user import User

router = APIRouter()

_NOT_IMPLEMENTED = "Endpoint planejado - implementação prevista nas próximas fases"


@router.get("/dashboard")
async def dashboard(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)


@router.get("/heatmap")
async def heatmap(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)


@router.get("/categories")
async def categories(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)


@router.get("/forecast")
async def forecast(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)


@router.get("/health-score")
async def health_score(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)


@router.get("/behavioral")
async def behavioral(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)


@router.get("/subscriptions")
async def subscriptions(current_user: User = Depends(get_current_user)):
    raise HTTPException(status.HTTP_501_NOT_IMPLEMENTED, _NOT_IMPLEMENTED)
