# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Financily is a bilingual (PT-BR UI, EN code) AI-powered financial intelligence platform. It reads Brazilian bank PDFs (Itaú, Santander), extracts transactions via OCR/table parsing, categorizes them with NLP, and delivers predictive analytics — not a simple expense tracker.

## Development Commands

### Backend (FastAPI + Python 3.12)
```bash
cd backend
python -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env                               # set DATABASE_URL and SECRET_KEY
alembic upgrade head                               # run migrations
uvicorn app.main:app --reload --port 8000
# API docs: http://localhost:8000/api/docs
```

Run a single test:
```bash
pytest backend/tests/unit/test_categorizer.py -v
pytest backend/tests/ -k "test_extract" -v
```

### Frontend (Flutter 3.x)
```bash
cd frontend
flutter pub get
flutter run -d windows                # desktop dev
flutter run -d chrome                 # web (limited)
flutter build apk --release           # Android
flutter build windows --release       # Windows EXE
```

Generate code (Riverpod, Freezed, Retrofit):
```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch           # watch mode
```

## Architecture

### Backend layers (`backend/app/`)
- `api/v1/routes/` — FastAPI routers (thin: validate input, call service, return schema)
- `services/` — business logic; never import from `api/`
  - `pdf/extractor.py` — 3-stage pipeline: pdfplumber → PyMuPDF → Tesseract OCR
  - `ai/categorizer.py` — keyword rules (fast path) → TF-IDF + LogisticRegression (ML path)
  - `analytics/health_score.py` — 4-dimension score: control 30% + savings 30% + forecast 25% + debt 15%
- `repositories/` — all DB queries; services never query SQLAlchemy directly
- `models/` — SQLAlchemy ORM (UUID PKs, async engine via asyncpg)
- `schemas/` — Pydantic v2 for request/response; separate from ORM models
- `core/config.py` — all env vars via `Settings(BaseSettings)`; import `settings` singleton

### Frontend layers (`frontend/lib/`)
- Clean Architecture per feature: `data/` → `domain/` → `presentation/`
- `core/theme/app_theme.dart` — single source of truth for colors (`AppColors`) and `ThemeData`
- `core/router/app_router.dart` — GoRouter; all navigation here, never `Navigator.push` directly
- `shared/widgets/` — reusable glassmorphism cards, buttons, loading states
- State: Riverpod providers; generated files use `@riverpod` annotation + `build_runner`

### Design system (non-negotiable)
Dark navy fintech aesthetic. All new screens must use tokens from `AppColors` / `_C` — never hardcode hex values. Glassmorphism via `BackdropFilter + ImageFilter.blur`. Staggered entry animations using `AnimationController` with `Interval` curves.

## Key Data Flow

```
PDF upload → extractor.py (pdfplumber/OCR) → RawTransaction list
  → categorizer.py (rules → ML) → category + confidence_score
  → Transaction ORM saved to PostgreSQL
  → analytics endpoints aggregate for dashboard
  → health_score.py computes 0–100 score
```

Duplicate detection: every `RawTransaction` carries a SHA-256 `hash` of its raw text. The `transactions.hash` column has a unique constraint — re-uploading the same PDF is safe.

## Adding a New Bank Parser

1. Add a `_parse_<bank>_row(row)` function in `backend/app/services/pdf/extractor.py`
2. Register it in the `parsers` dict inside `_parse_table()`
3. Add bank name to supported list in `backend/app/core/config.py`
4. Write a test using a sample PDF fixture in `backend/tests/fixtures/`

## Adding a New Feature Screen (Flutter)

Follow the pattern in `features/dashboard/`:
1. `data/` — datasource (API call via Dio/Retrofit) + repository impl
2. `domain/` — abstract repository + use cases (pure Dart, no Flutter deps)
3. `presentation/screens/` — ConsumerWidget; read providers, no business logic here
4. Register route in `core/router/app_router.dart`

## AI Categorizer Retraining

The ML model (`categorizer.joblib`) is not in git. On first run with no model file, categorizer falls back to keyword rules only (returns confidence 0.0). To train:
```python
from app.services.ai.categorizer import categorizer
categorizer.train(descriptions=[...], labels=[...])
```
Model saves to `backend/app/services/ai/models/categorizer.joblib`.

## Environment Variables (`.env`)

| Var | Required | Notes |
|---|---|---|
| `DATABASE_URL` | yes | `postgresql+asyncpg://user:pass@host/db` |
| `SECRET_KEY` | yes | JWT signing — 32+ random chars |
| `TESSERACT_CMD` | Windows only | Path to `tesseract.exe` |
| `DEBUG` | no | Enables FastAPI debug mode |

## Preview HTML

`docs/preview.html` é um protótipo interativo self-contained (sem dependências) com todas as 5 telas navegáveis. Abrir direto no browser. Usar como referência visual antes de implementar qualquer nova tela no Flutter — o design system deve ser idêntico.

## Próximos Passos (Fase 1 restante)

1. `backend/app/core/database.py` — async engine + session factory
2. `backend/app/repositories/` — TransactionRepository, UserRepository
3. `backend/app/api/v1/routes/auth.py` — register + login + refresh
4. `backend/app/api/v1/routes/uploads.py` — POST /pdf com SSE progress stream
5. Conectar Flutter ao backend: `frontend/lib/core/network/` (Dio + token interceptor)
6. Treinar categorizer com dados reais de faturas Itaú/Santander

## LGPD Constraints

- PDFs must be processed in memory and not persisted to disk after extraction
- `raw_text` column stores only the extracted text row, not the full PDF
- User deletion must cascade to all related tables (implement in repository layer)
- No PII may appear in application logs
