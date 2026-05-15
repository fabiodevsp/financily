from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base
from app.api.v1.routes import auth, transactions, uploads, analytics, reports, assistant

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(
    title="Financily API",
    description="AI-powered financial intelligence platform",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,         prefix="/api/v1/auth",         tags=["Auth"])
app.include_router(uploads.router,      prefix="/api/v1/uploads",      tags=["Uploads"])
app.include_router(transactions.router, prefix="/api/v1/transactions",  tags=["Transactions"])
app.include_router(analytics.router,    prefix="/api/v1/analytics",    tags=["Analytics"])
app.include_router(assistant.router,    prefix="/api/v1/assistant",    tags=["AI Assistant"])
app.include_router(reports.router,      prefix="/api/v1/reports",      tags=["Reports"])

@app.get("/health")
async def health():
    return {"status": "ok", "version": "1.0.0"}
