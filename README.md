# Financily — AI-Powered Financial Intelligence Platform

> Platform de inteligência financeira pessoal com IA, extração de PDFs e analytics preditivos.

---

## Vision

Financily não é um simples rastreador de gastos. É um **assistente financeiro inteligente** que lê faturas, extrai transações automaticamente, detecta padrões comportamentais e gera insights preditivos — como ter um CFO pessoal no bolso.

---

## Tech Stack

| Camada | Tecnologia |
|---|---|
| Frontend | Flutter 3.x · Riverpod · GoRouter · Material 3 |
| Backend | Python 3.12 · FastAPI · SQLAlchemy · PostgreSQL |
| AI/ML | Pandas · NumPy · Scikit-Learn · Prophet |
| PDF | pdfplumber · PyMuPDF · Tesseract OCR |
| Charts | FL Chart |
| Auth | JWT · encrypted local storage |
| Local DB | SQLite (offline) |

---

## Architecture

```
financily/
├── frontend/                    # Flutter App
│   └── lib/
│       ├── core/
│       │   ├── constants/       # app constants, env
│       │   ├── theme/           # design tokens, colors, typography
│       │   ├── network/         # dio client, interceptors, token refresh
│       │   └── utils/           # formatters, validators, extensions
│       ├── features/
│       │   ├── auth/            # login, register, JWT handling
│       │   │   ├── data/        # auth_repository_impl, auth_remote_datasource
│       │   │   ├── domain/      # auth_repository (abstract), use_cases
│       │   │   └── presentation/
│       │   ├── dashboard/       # main overview screen
│       │   ├── upload/          # PDF upload (drag-drop + mobile)
│       │   ├── transactions/    # transaction list, detail, filter
│       │   ├── analytics/       # predictive charts, behavioral analysis
│       │   ├── assistant/       # AI conversational assistant
│       │   └── reports/         # PDF/Excel/CSV export
│       └── shared/
│           ├── widgets/         # GlassCard, AppButton, LoadingOverlay
│           └── models/          # shared DTOs
│
├── backend/                     # FastAPI Backend
│   └── app/
│       ├── api/v1/routes/       # auth, transactions, uploads, analytics
│       ├── core/                # config, security, database
│       ├── models/              # SQLAlchemy ORM models
│       ├── schemas/             # Pydantic request/response schemas
│       ├── services/
│       │   ├── pdf/             # extraction pipeline
│       │   └── ai/              # categorization, forecasting, behavioral
│       └── repositories/        # data access layer
│
├── ai/                          # AI/ML Modules
│   ├── ocr/                     # Tesseract OCR pipeline
│   ├── categorization/          # NLP transaction classifier
│   ├── forecasting/             # Prophet time-series models
│   └── behavioral/              # pattern detection, anomaly detection
│
└── docs/
    ├── architecture/            # ADRs, system design
    ├── api/                     # OpenAPI specs
    └── design/                  # wireframes, design system
```

---

## Database Schema

```sql
-- Users
users (id, email, password_hash, name, created_at, subscription_tier)

-- Financial Accounts
accounts (id, user_id, bank, type, name, balance, currency, created_at)

-- Uploaded Files
uploads (id, user_id, file_name, file_path, bank_detected, status, processed_at)

-- Transactions (core entity)
transactions (
  id, user_id, account_id, upload_id,
  date, description, merchant,
  amount, currency, type,         -- DEBIT | CREDIT
  category, subcategory,
  is_recurring, is_subscription, is_installment,
  installment_current, installment_total,
  confidence_score,               -- AI categorization confidence 0-1
  raw_text, created_at
)

-- Subscriptions (detected)
subscriptions (id, user_id, merchant, amount, frequency, next_billing, status)

-- Financial Health Score
health_scores (id, user_id, score, control_score, savings_score,
               forecast_score, debt_score, computed_at)

-- AI Insights
insights (id, user_id, type, title, body, priority, is_read, created_at)
```

---

## API Endpoints

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
DELETE /api/v1/auth/logout

POST   /api/v1/uploads/pdf              # upload fatura/extrato
GET    /api/v1/uploads/                 # list uploads
GET    /api/v1/uploads/{id}/status      # processing status (SSE stream)

GET    /api/v1/transactions/            # list + filter + paginate
GET    /api/v1/transactions/summary     # income/expense/balance totals
PUT    /api/v1/transactions/{id}        # manual category correction
DELETE /api/v1/transactions/{id}

GET    /api/v1/analytics/dashboard      # full dashboard payload
GET    /api/v1/analytics/heatmap        # 7-day spending heatmap
GET    /api/v1/analytics/categories     # category distribution
GET    /api/v1/analytics/forecast       # 3-month Prophet forecast
GET    /api/v1/analytics/health-score   # financial health score breakdown
GET    /api/v1/analytics/behavioral     # behavioral pattern insights
GET    /api/v1/analytics/subscriptions  # detected recurring charges

POST   /api/v1/assistant/chat           # AI assistant (streaming)

POST   /api/v1/reports/pdf
POST   /api/v1/reports/excel
POST   /api/v1/reports/csv
```

---

## AI Pipeline

```
PDF Upload
  │
  ├─► pdfplumber → extract tables + text
  │     ↓ (fallback)
  └─► PyMuPDF → render pages as images
        ↓ (fallback)
        Tesseract OCR → extract text
  
  ↓

Transaction Parser
  - regex patterns per bank (Itaú, Santander, ...)
  - date normalization (BR locale)
  - amount normalization (R$ format)
  - duplicate detection (hash-based)
  - installment detection ("1/12", "parc")

  ↓

AI Categorization (NLP)
  - TF-IDF merchant vectorizer
  - Scikit-Learn multi-class classifier
  - 10 categories + subcategories
  - confidence score per transaction
  - manual correction → retraining feedback loop

  ↓

Analytics Engine
  - Prophet: 90-day balance forecast
  - Isolation Forest: anomaly detection
  - K-Means: spending pattern clustering
  - Custom: behavioral pattern rules

  ↓

Financial Health Score (0–100)
  - Control: % categorized + budget adherence
  - Savings: income vs expense ratio
  - Forecast: projected balance trajectory
  - Debt: installment burden ratio
```

---

## Supported Banks (MVP)

| Bank | Statement PDF | Credit Card PDF |
|------|--------------|-----------------|
| Itaú | ✅ | ✅ |
| Santander | ✅ | ✅ |
| Nubank | 🔜 | 🔜 |
| Inter | 🔜 | 🔜 |
| Bradesco | 🔜 | 🔜 |

---

## MVP Roadmap

### Phase 1 — Core (Weeks 1–4)
- [x] Project architecture & folder structure
- [x] Flutter dashboard UI (dark futuristic design)
- [ ] FastAPI backend with PostgreSQL
- [ ] JWT authentication
- [ ] PDF upload endpoint
- [ ] Itaú PDF parser
- [ ] Basic transaction categorization
- [ ] Dashboard screen

### Phase 2 — AI (Weeks 5–8)
- [ ] NLP categorization engine
- [ ] Santander PDF parser
- [ ] Subscription detection
- [ ] Financial health score
- [ ] Prophet forecasting
- [ ] Behavioral pattern detection
- [ ] AI insight generation

### Phase 3 — Polish (Weeks 9–12)
- [ ] AI conversational assistant
- [ ] PDF/Excel/CSV export
- [ ] Smart notifications
- [ ] Android build
- [ ] iOS build
- [ ] Windows build

### Phase 4 — SaaS (Weeks 13–16)
- [ ] Subscription tiers (Free / Pro / Enterprise)
- [ ] Open Finance integration (Pluggy API)
- [ ] Multi-account support
- [ ] Cloud deployment (Railway / Render)
- [ ] Stripe payment integration

---

## Design System

```
Colors:
  bg:       #0A0E1A  (dark navy)
  surface:  #0F1629
  card:     #151C35
  border:   #1E2D50
  cyan:     #00D4FF  (primary accent)
  income:   #00E676  (green)
  expense:  #FF4D6A  (red)
  purple:   #7C5CEF
  amber:    #FFC947

Typography:
  Display:  Syne (geometric, futuristic)
  Body:     DM Sans (clean, modern)

Effects:
  glassmorphism, backdrop blur
  gradient mesh backgrounds
  smooth staggered animations (800–1200ms)
  glow shadows on accent elements
```

---

## Security & LGPD

- Passwords hashed with bcrypt (cost 12)
- JWT access tokens (15min) + refresh tokens (30d)
- AES-256 encryption for local storage
- PDF files processed in memory, not stored permanently
- User data deletion on request (LGPD Art. 18)
- Audit log for all data access
- No raw PDF content stored after extraction
- HTTPS only in production

---

## Deployment

### Development
```bash
# Backend
cd backend && pip install -r requirements.txt
uvicorn app.main:app --reload

# Frontend
cd frontend && flutter run -d windows
```

### Production
```
Backend:  Railway / Render (Docker)
Database: Supabase PostgreSQL
Storage:  Cloudflare R2 (temp PDF storage)
CDN:      Cloudflare
Mobile:   Google Play + App Store
Desktop:  Windows MSIX installer
```

---

## Getting Started

```bash
git clone https://github.com/fabiodevsp/financily.git
cd financily

# Backend
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # configure your DB
alembic upgrade head
uvicorn app.main:app --reload --port 8000

# Frontend
cd ../frontend
flutter pub get
flutter run
```

---

*Built by Fabio Ferrera · Powered by Claude AI*
