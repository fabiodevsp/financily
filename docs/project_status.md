# Financily — Status do Projeto

> Auditoria técnica completa. Última atualização: 2026-06-11.
> Branch: `master` · Commits: `2639e79` (arquitetura inicial) → `6782076` (preview HTML + docs) → `1fb4c96` (auditoria) → `4142824` (fundação do backend) → **governança e estruturação do projeto (esta sessão, commit pendente)**

---

## Visão Geral por Área (Estado Atual)

| Área | Status | Detalhe |
|---|---|---|
| **Backend** | ✅ Funcional — FastAPI sobe sem erros, 21 rotas registradas, Clean Architecture (`routes` → `services` → `repositories` → `models`) | §3, §12 |
| **Banco de dados** | ✅ Schema completo (`users`, `uploads`, `transactions` + 4 enums Postgres) via Alembic, validado em SQLite (upgrade/downgrade) | §3, §12 |
| **Autenticação** | ✅ JWT completo (`register`/`login`/`refresh`) testado ponta a ponta; falta `/auth/logout` e revogação de refresh token | §3, §4, §12 |
| **Migrations** | ✅ 1 migration inicial (`7132eab5146a_initial_schema`), validada upgrade/downgrade em SQLite + `--sql` offline para Postgres; **nunca rodou contra Postgres real** | §3, §8 |
| **APIs** | 🟡 Contrato completo (21 rotas documentadas no OpenAPI); auth + list endpoints reais, demais (`uploads/pdf`, filtros de transactions, analytics, assistant, reports) ainda stubs `501` | §4, §5, §12 |
| **Frontend** | 🟡 UI de 2 telas (login, dashboard) com dados mock; sem scaffold de plataforma (`flutter create .` nunca executado); não conectado ao backend | §1, §4, §12 |
| **Analytics** | 🟡 `health_score.py` implementado (lógica pura, 4 dimensões), não exposto via API; forecast/behavioral/heatmap não iniciados | §3, §5, §12 |
| **OCR** | 🟡 Pipeline `extractor.py` (pdfplumber → PyMuPDF → Tesseract OCR) codificado, não integrado a nenhum endpoint nem testado em fluxo real | §3, §4, §12 |
| **IA (Categorizador)** | 🟡 Regras por keyword (10 categorias) prontas; pipeline ML (TF-IDF + LogisticRegression) existe, mas `train()` nunca foi chamado — sem `categorizer.joblib` | §3, §4, §12 |
| **Upload de PDF** | ❌ Não iniciado — endpoint `POST /uploads/pdf` ainda não existe; é a próxima tarefa recomendada (Opção A em `docs/next_session.md`) | §5, §13 |

---

## 1. Estrutura real do projeto

```
financily/
├── CLAUDE.md
├── CLAUDE_PROJECT_RULES.md             ✅ NOVO — regras permanentes de governança (CTO permanente)
├── README.md
├── docs/
│   ├── preview.html                   ✅ protótipo HTML estático (820 linhas, 5 telas)
│   ├── project_status.md              ✅ este documento
│   ├── prompt_inicial.txt             ✅ arquivado
│   ├── next_session.md                ✅ memória de continuidade
│   ├── session_start.md               ✅ NOVO — workflow de início de sessão
│   ├── session_end.md                 ✅ NOVO — workflow de encerramento de sessão
│   └── {api,architecture,design}/     ❌ vazios (scaffolds de documentação)
│
├── backend/
│   ├── requirements.txt               ✅ (bcrypt pinado, ver §6)
│   ├── .env.example                   ✅ NOVO
│   ├── alembic.ini                    ✅ NOVO
│   ├── alembic/                       ✅ NOVO — async env.py + 1 migration
│   │   ├── env.py
│   │   ├── script.py.mako
│   │   └── versions/7132eab5146a_initial_schema.py
│   ├── venv/                          (local, não versionado)
│   └── app/
│       ├── __init__.py                ✅ NOVO (pacote explícito)
│       ├── main.py                    ✅ sobe sem erros — 21 rotas registradas
│       ├── core/
│       │   ├── config.py              ✅ Settings (pydantic-settings)
│       │   ├── database.py            ✅ NOVO — engine async, Base, AsyncSessionLocal, get_db()
│       │   └── security.py            ✅ NOVO — hash/verify password, JWT access+refresh
│       ├── models/
│       │   ├── __init__.py            ✅ NOVO — registra todos os models no Base.metadata
│       │   ├── user.py                ✅ NOVO — User, SubscriptionTier
│       │   ├── upload.py              ✅ NOVO — Upload, UploadStatus
│       │   └── transaction.py         ✅ CORRIGIDO — FKs com ondelete + índices
│       ├── schemas/                   ✅ NOVO
│       │   ├── auth.py                Token, RefreshRequest
│       │   ├── user.py                UserCreate, UserRead
│       │   ├── upload.py              UploadRead
│       │   └── transaction.py         TransactionRead
│       ├── repositories/              ✅ NOVO
│       │   ├── user_repository.py
│       │   ├── upload_repository.py
│       │   └── transaction_repository.py
│       ├── api/v1/
│       │   ├── deps.py                ✅ NOVO — oauth2_scheme, get_current_user
│       │   └── routes/
│       │       ├── auth.py            ✅ NOVO — register, login, refresh (JWT funcional)
│       │       ├── uploads.py         ✅ NOVO — GET / (list, protegido)
│       │       ├── transactions.py    ✅ NOVO — GET / (list, protegido)
│       │       ├── analytics.py       ✅ NOVO — 7 stubs 501 (protegidos)
│       │       ├── assistant.py       ✅ NOVO — stub 501 (protegido)
│       │       └── reports.py         ✅ NOVO — 3 stubs 501 (protegidos)
│       ├── services/
│       │   ├── pdf/extractor.py       ✅ pipeline pdfplumber → OCR (inalterado)
│       │   ├── ai/categorizer.py      ✅ regras + pipeline ML (não treinado, inalterado)
│       │   └── analytics/health_score.py ✅ score 0–100 (inalterado, ainda não exposto via API)
│       ├── middleware/                ❌ vazio (apenas `__init__.py`)
│       └── tests/{unit,integration}/  ❌ vazio
│
└── frontend/
    ├── pubspec.yaml                   ⚠️ refs fontes inexistentes (inalterado)
    ├── assets/{fonts,images}/         ❌ vazio (inalterado)
    └── lib/
        ├── main.dart                  ✅
        ├── core/
        │   ├── theme/app_theme.dart   ✅ AppColors + ThemeData
        │   ├── router/app_router.dart ✅ apenas 2 rotas
        │   ├── network/                ❌ vazio
        │   ├── constants/              ❌ vazio
        │   └── utils/                  ❌ vazio
        ├── features/
        │   ├── auth/.../login_screen.dart        ✅ UI, login mockado
        │   ├── dashboard/.../dashboard_screen.dart ✅ UI completa, dados mock (944 linhas)
        │   ├── upload/                  ❌ vazio
        │   ├── transactions/            ❌ vazio
        │   ├── analytics/               ❌ vazio
        │   ├── assistant/                ❌ vazio
        │   └── reports/                  ❌ vazio
        └── shared/{widgets,models}/    ❌ vazio
```

**Frontend inalterado nesta sessão** (escopo explicitamente fora desta rodada). Continua sem scaffold de plataforma (`flutter create .` nunca executado) — não existem `android/`, `ios/`, `windows/`, `macos/`, `web/`, `linux/`, `test/`, `.metadata`/`analysis_options.yaml`.

---

## 2. Tecnologias e dependências

**Backend** (Python 3.12, `requirements.txt`): FastAPI 0.111, Uvicorn, SQLAlchemy 2.0 (async/asyncpg), Alembic, Pydantic v2 + pydantic-settings, python-jose + passlib (JWT/bcrypt), **`bcrypt==4.0.1` (pin obrigatório — ver §6)**, pdfplumber, PyMuPDF (`fitz`), pytesseract, Pillow, pandas, numpy, scikit-learn, prophet, nltk, joblib, httpx (duplicata removida nesta sessão — ver "Última Sessão"), pytest/pytest-asyncio/pytest-cov/faker.

**Frontend** (Flutter ≥3.3, `pubspec.yaml`): inalterado — flutter_riverpod, riverpod_annotation, go_router, dio, retrofit, flutter_secure_storage, sqflite, hive_flutter, file_picker, desktop_drop, path_provider, fl_chart, google_fonts, shimmer, lottie, flutter_animate, cached_network_image, intl, freezed, json_serializable, dartz, logger, mockito.

> Quase todas as dependências do Flutter (exceto `flutter_riverpod`, `go_router`, `google_fonts` parcialmente) continuam **declaradas mas não usadas**.

---

## 3. Funcionalidades já implementadas (código real e funcional isoladamente)

| Item | Local | Observação |
|---|---|---|
| Design tokens + tema dark | `frontend/lib/core/theme/app_theme.dart` | `AppColors` consistente com `docs/preview.html` |
| Tela de Login (UI) | `login_screen.dart` | Glassmorphism, animação fade-in; login é mock (`Future.delayed`) |
| Tela de Dashboard (UI) | `dashboard_screen.dart` | 944 linhas, dados estáticos mock |
| Roteamento | `app_router.dart` | GoRouter com 2 rotas (`/login`, `/dashboard`) |
| Pipeline de extração de PDF | `services/pdf/extractor.py` | pdfplumber → fallback PyMuPDF+Tesseract OCR; hash SHA-256 dedupe |
| Parser Itaú | `_parse_itau_row` | Implementado |
| Categorizador (regras + ML) | `services/ai/categorizer.py` | 10 categorias; ML não treinado |
| Health Score | `services/analytics/health_score.py` | 4 dimensões; ainda não exposto via API |
| Protótipo navegável | `docs/preview.html` | 5 telas, animações JS |
| **Configuração de banco async** | `core/database.py` | ✅ NOVO — engine, `Base`, `AsyncSessionLocal`, `get_db()` |
| **Segurança / JWT** | `core/security.py` | ✅ NOVO — `hash_password`, `verify_password`, access (15min) + refresh (30d) tokens |
| **Modelo `User`** | `models/user.py` | ✅ NOVO — `SubscriptionTier` (FREE/PRO/ENTERPRISE), relações com Transaction/Upload (cascade delete — LGPD) |
| **Modelo `Upload`** | `models/upload.py` | ✅ NOVO — `UploadStatus` (PENDING/PROCESSING/COMPLETED/FAILED) |
| **Modelo `Transaction`** | `models/transaction.py` | ✅ CORRIGIDO — FK `user_id` (CASCADE), `upload_id` (SET NULL), índices em `user_id`/`upload_id`/`date`/`category` |
| **Schemas Pydantic v2** | `schemas/` | ✅ NOVO — `UserCreate`, `UserRead`, `Token`, `RefreshRequest`, `TransactionRead`, `UploadRead` (todos `from_attributes=True`) |
| **Repositories** | `repositories/` | ✅ NOVO — `UserRepository`, `UploadRepository`, `TransactionRepository` (única camada de acesso a dados) |
| **Auth API** | `api/v1/routes/auth.py` | ✅ NOVO — `/register` (201), `/login` (OAuth2, JWT pair), `/refresh` (valida `type` claim) |
| **Dependência de auth** | `api/v1/deps.py` | ✅ NOVO — `get_current_user` via `OAuth2PasswordBearer` |
| **Routers stub** | `uploads.py`, `transactions.py`, `analytics.py`, `assistant.py`, `reports.py` | ✅ NOVO — list endpoints reais (uploads/transactions) + 12 stubs `501` documentados no OpenAPI |
| **Alembic** | `alembic/` | ✅ NOVO — `env.py` async, migration inicial cria `users`/`uploads`/`transactions` + 4 enums Postgres |
| **`backend/app` como pacotes explícitos** | `**/__init__.py` | ✅ NOVO — 12 arquivos `__init__.py` adicionados |

---

## 4. Funcionalidades parcialmente implementadas

| Item | Status | Pendência |
|---|---|---|
| Backend API (`main.py`) | ✅ Sobe sem erros, 21 rotas, `/api/docs` funcional | Routers de domínio (`uploads`, `transactions`, `analytics`, `assistant`, `reports`) ainda são stubs/list-only — lógica de negócio não implementada |
| Banco de dados | ✅ Schema completo via Alembic (validado em SQLite) | Não testado contra PostgreSQL real (sem instância local disponível) |
| Auth | ✅ register/login/refresh funcionais ponta a ponta | Sem `/auth/logout`, sem rate limiting, sem refresh token revocation/rotation |
| Parser Santander | Função existe | `_parse_santander_row` ainda é cópia do Itaú — placeholder |
| OCR | Pipeline codificado | Não testado contra OCR real |
| Categorizador ML | Pipeline completo | `train()` nunca chamado; sem `categorizer.joblib` |
| Roteamento Flutter | Funciona | `redirect` é `// TODO`; só 2 telas de 8+ planejadas |
| Login Flutter | UI completa | Não conectado ao backend `/auth/login` real (agora disponível) |
| Projeto Flutter | `pubspec.yaml` rico | Sem scaffold de plataforma; fontes `Syne-*.ttf` ausentes |

---

## 5. Funcionalidades planejadas, não iniciadas

- **Upload de PDF real**: endpoint `POST /uploads/pdf` com SSE de progresso, integração com `extractor.py` + `categorizer.py` + `TransactionRepository`
- **Transactions API completa**: filtros, paginação, summary, update (correção manual de categoria), delete
- **Analytics API real**: dashboard payload, heatmap, categorias, forecast (Prophet), health-score (conectar `health_score.py`), behavioral, subscriptions
- **Análise comportamental** (anomaly detection, clustering): zero código
- **Detecção de assinaturas recorrentes**: zero código
- **Assistente IA** (chat): stub 501 apenas
- **Exportação PDF/Excel/CSV**: stubs 501; faltam libs (`openpyxl`, `reportlab`/`weasyprint`) no requirements
- **Notificações**: nenhum código
- **Tela de Configurações** (Flutter): pasta nem existe
- **Testes automatizados**: zero testes apesar de pytest configurado
- **Multi-plataforma Flutter**: scaffold ausente
- **Conectar Flutter ao backend**: `frontend/lib/core/network/` (Dio + interceptor de token) — backend já expõe `/auth/*` funcional

---

## 6. Problemas encontrados e corrigidos nesta sessão

1. ✅ **CORRIGIDO** — `backend/app/main.py` não subia: importava `app.core.database` e 6 routers inexistentes → todos criados, `app.main:app` agora importa com 21 rotas.
2. ✅ **CORRIGIDO** — `models/transaction.py` referenciava `User`/`Upload` inexistentes → ambos os modelos criados, `relationship()`/`ForeignKey` agora resolvem; `configure_mappers()` ok.
3. ✅ **CORRIGIDO** — Pacotes `backend/app/**` sem `__init__.py` (namespace packages implícitos) → 12 `__init__.py` adicionados.
4. ✅ **CORRIGIDO** — Sem `.env.example` → criado com todas as vars do CLAUDE.md.
5. ✅ **CORRIGIDO** — Sem `alembic.ini`/`versions/` → Alembic configurado (async `env.py`) + migration inicial completa, validada em SQLite (upgrade/downgrade) e via `--sql` para Postgres.
6. 🔴 **BUG CRÍTICO ENCONTRADO E CORRIGIDO** — `passlib==1.7.4` resolve `bcrypt` para `5.0.0` (não pinado), e o self-test interno do passlib (`detect_wrap_bug`) quebra com `ValueError: password cannot be longer than 72 bytes` em `bcrypt>=4.1`. Isso derrubava **qualquer** endpoint que faça hash de senha (`/auth/register`, `/auth/login`) com `500 Internal Server Error`. **Fix**: pin `bcrypt==4.0.1` em `requirements.txt`.
7. ✅ **CORRIGIDO** — `Base.metadata.create_all` no lifespan do FastAPI conflitava com Alembic como dono do schema → removido; lifespan agora só faz `engine.dispose()` no shutdown.
8. ✅ **REMOVIDO** — diretório `backend/migrations/` vazio e redundante (substituído por `backend/alembic/`).

### Pendentes (não corrigidos, fora do escopo desta sessão)
- 🟡 `httpx==0.27.0` duplicado em `requirements.txt` (linhas 37 e 49).
- 🟡 Projeto Flutter sem scaffold de plataforma.
- 🟡 `pubspec.yaml` referencia fontes `Syne-*.ttf` ausentes em `assets/fonts/`.

---

## 7. Código morto / duplicado / não utilizado

- `_parse_santander_row` é cópia funcional de `_parse_itau_row` (placeholder, redundante).
- Quase toda a árvore de dependências do `pubspec.yaml` (Hive, sqflite, Retrofit, Freezed, dartz, lottie, shimmer, etc.) — declaradas, zero uso.
- `prophet`, `nltk`, `numpy` no requirements — zero referências no código atual (scikit-learn/pandas usados pelo categorizer/health_score).
- `app/middleware/` — pacote vazio (apenas `__init__.py`), sem uso ainda.

---

## 8. Riscos arquiteturais

- ✅ **Mitigado**: backend agora sobe — desbloqueia integração incremental.
- Categorizador ML depende de artefato `.joblib` não versionado — sem pipeline de treino real, fica permanentemente em modo "regras".
- OCR depende de Tesseract instalado no SO (`TESSERACT_CMD`), sem verificação/tratamento se ausente.
- Migration inicial validada apenas em SQLite + `--sql` offline para Postgres — **nunca rodou contra um Postgres real**. Risco baixo (DDL gerado é padrão), mas deve ser validado no primeiro deploy/ambiente com Postgres.
- Flutter sem scaffold = primeira tentativa de `flutter run` vai falhar.
- Zero testes automatizados = sem rede de segurança para regressões futuras (incluindo a fundação criada nesta sessão).
- Auth sem rate limiting/brute-force protection — aceitável para MVP local, revisar antes de produção.

---

## 9. Débitos técnicos

- [x] ~~Criar `core/database.py`~~ ✅ feito
- [x] ~~Criar modelos `User` e `Upload`, completar relationships do `Transaction`~~ ✅ feito
- [x] ~~Criar `schemas/`~~ ✅ feito
- [x] ~~Criar `repositories/`~~ ✅ feito
- [x] ~~Setup Alembic (init async, primeira migration)~~ ✅ feito
- [x] ~~`.env.example`~~ ✅ feito
- [x] ~~`__init__.py` nos pacotes Python~~ ✅ feito
- [x] ~~Remover duplicata `httpx` do requirements~~ ✅ feito (sessão de governança)
- [ ] Testes unitários para `extractor.py`, `categorizer.py`, `health_score.py`, e novos módulos (`security.py`, repositories, rotas de auth)
- [ ] `flutter create .` para gerar scaffold de plataforma
- [ ] Resolver fontes `Syne` (adicionar `.ttf` ou usar `google_fonts.GoogleFonts.syne()`)
- [ ] Validar `alembic upgrade head` contra PostgreSQL real (Docker local ou Supabase)
- [ ] Implementar `/auth/logout` (revogação de refresh token) — opcional para MVP

---

## 10. Possíveis gargalos de performance

- OCR a 300 DPI por página via Tesseract — caro para faturas longas; sem paralelismo/cache.
- `health_score` recria `pandas.DataFrame` a cada chamada — ok em escala pequena, revisar se virar hot path.
- Falta de paginação especificada nos endpoints de transações planejados (o stub atual de `/transactions` retorna lista completa sem limit/offset).
- ✅ **Resolvido parcialmente**: índices adicionados em `transactions.user_id`, `transactions.upload_id`, `transactions.date`, `transactions.category`, `uploads.user_id`, `users.email` (via migration inicial).

---

## 11. Possíveis problemas de segurança

- `SECRET_KEY` tem default inseguro (`"change-me-in-production"`) — precisa validação obrigatória via env em produção.
- CORS default permite apenas `localhost` — revisar antes de produção.
- ✅ **Corrigido**: hashing de senha (`bcrypt` via passlib) agora funciona corretamente (ver bug #6 acima).
- Upload ainda não existe — ao criar, validar tipo/tamanho de arquivo e processar 100% em memória (requisito LGPD do CLAUDE.md).
- `raw_text` no modelo `Transaction` — confirmar que armazena apenas a linha extraída, nunca o PDF completo (campo existe, ainda não populado por nenhum endpoint).
- Nenhum rate limiting / proteção brute-force planejado para auth ainda.
- JWT: `SECRET_KEY` único para access e refresh tokens, diferenciados via claim `"type"` — adequado para MVP, mas sem mecanismo de revogação de refresh tokens (logout não invalida tokens existentes).

---

## 12. Status por módulo (MVP)

| Módulo | Status |
|---|---|
| **Autenticação** | ✅ **Funcional** (register/login/refresh/JWT validados ponta a ponta) — falta apenas logout/revocation |
| Dashboard | 🟡 Em desenvolvimento (UI completa + mock; backend `/analytics/dashboard` ainda é stub 501) |
| Upload de PDFs | 🟡 Em desenvolvimento (router + repository + modelo prontos; endpoint de upload real ainda não implementado) |
| Parser de faturas (Itaú) | 🟡 Em desenvolvimento (lógica existe, não integrada ao endpoint de upload) |
| Parser de extratos (Santander) | ❌ Não iniciado (stub = cópia do Itaú) |
| OCR | 🟡 Em desenvolvimento (pipeline codificado, não validado) |
| **Banco de dados** | ✅ **Funcional** — schema completo (`users`, `uploads`, `transactions`), Alembic configurado, migration inicial validada |
| **API** | ✅ **Funcional** — app sobe, `/api/docs` e `/openapi.json` ok, 21 rotas registradas |
| Categorização automática | 🟡 Em desenvolvimento (regras prontas; ML não treinado; não integrada ao endpoint de upload) |
| Previsão financeira | ❌ Não iniciado |
| Assistente IA | ❌ Não iniciado (stub 501) |
| Exportação PDF | ❌ Não iniciado (stub 501) |
| Exportação Excel | ❌ Não iniciado (stub 501) |
| Exportação CSV | ❌ Não iniciado (stub 501) |
| Notificações | ❌ Não iniciado |
| Configurações | ❌ Não iniciado |
| Design System | 🟡 Em desenvolvimento (tokens definidos e usados; fontes faltando) |
| Responsividade | ❌ Não verificado (telas mobile-first apenas) |
| Multi plataforma | ❌ Não iniciado (scaffold Flutter ausente) |

---

## 13. Próximos passos recomendados (ordem ideal)

1. ✅ ~~Desbloquear o backend~~ — **concluído nesta sessão**
2. **Conectar Flutter ao backend**: `frontend/lib/core/network/` (Dio + interceptor de refresh token), telas de login/registro reais consumindo `/api/v1/auth/*`
3. **Upload de PDF end-to-end**: `POST /api/v1/uploads/pdf` — receber arquivo em memória, rodar `extractor.py` → `categorizer.py` → `TransactionRepository.create()`, com SSE de progresso
4. **Transactions API completa**: list com paginação/filtros, summary, update (correção de categoria), delete
5. **Analytics API real**: começar por `/analytics/health-score` (já existe `health_score.py`) e `/analytics/dashboard`
6. **Frontend — desbloquear scaffold**: `flutter create .` preservando `lib/`/`pubspec.yaml`/`assets/`; resolver fontes Syne
7. **Parser Santander real** (substituir stub)
8. **Categorizador ML**: treinar com dados reais de faturas Itaú/Santander
9. **Forecast (Prophet) + behavioral**: implementar após volume real de transações
10. **Testes**: cobrir `core/security.py`, repositories, rotas de auth, e os módulos puros (`extractor`, `categorizer`, `health_score`)
11. **Validar Alembic contra PostgreSQL real** antes do primeiro deploy

---

## 14. Estimativa de conclusão

**~20–25% do escopo total** descrito no `README.md`/`Prompt Inicial.txt`.

A fundação do backend (banco de dados, auth, schema, repositórios, Alembic, contrato de API completo via stubs) está pronta e validada. O que falta é majoritariamente: (a) lógica de negócio dos endpoints de domínio (upload, transactions, analytics), (b) conectar o Flutter ao backend, (c) scaffold de plataforma Flutter, (d) treinar o categorizador ML, (e) testes automatizados.

A sessão de governança (esta sessão) **não altera este percentual** — é puramente estrutural (documentação, regras permanentes, auditoria).

---

## 15. Roadmap Atualizado

| Fase | Escopo | Status |
|---|---|---|
| **Fase 1 — Fundação do Backend** | Banco de dados, auth JWT, schema, repositórios, Alembic, contrato de API (stubs) | ✅ Concluída (commit `4142824`) |
| **Fase 1.5 — Governança e Estruturação** | `CLAUDE_PROJECT_RULES.md`, `docs/session_start.md`, `docs/session_end.md`, auditoria, atualização de `project_status.md`/`next_session.md` | ✅ Concluída (esta sessão) |
| **Fase 2 — Primeira fatia vertical de valor** | Upload de PDF end-to-end (extractor → categorizer → repository) **ou** conexão Flutter↔Backend (`core/network/` + login real) | ⏭️ Próxima (ver `docs/next_session.md`) |
| **Fase 3 — Domínio completo** | Transactions API (paginação/filtros/summary/update/delete), Analytics API real (`health-score`, `dashboard`, forecast), Categorizador ML treinado, Parser Santander real | ❌ Não iniciada |
| **Fase 4 — Frontend completo** | `flutter create .` (scaffold de plataforma), 8+ telas conectadas ao backend, fontes Syne resolvidas | ❌ Não iniciada |
| **Fase 5 — Produção** | Testes automatizados, PostgreSQL real validado, rate limiting/auth hardening, CI (`.github/workflows/`), exportações PDF/Excel/CSV, notificações, assistente IA | ❌ Não iniciada |

---

## Sessão Anterior — Fase 1 (Fundação do Backend)

**Data**: 2026-06-11
**Objetivo**: Implementar a Fase 1 da auditoria — fazer o backend subir sem erros e preparar a fundação para todas as próximas funcionalidades. Sem novas features, sem alterações no frontend/design system, sem OCR/IA/dashboards novos.

### Implementado
- `backend/app/core/database.py` — engine SQLAlchemy 2.0 async (`create_async_engine`), `Base` (DeclarativeBase), `AsyncSessionLocal` (`async_sessionmaker`), `get_db()` (dependency FastAPI).
- `backend/app/core/security.py` — `hash_password`/`verify_password` (passlib/bcrypt), `create_access_token`/`create_refresh_token`/`decode_token` (python-jose, claim `"type"` distingue access/refresh).
- `backend/app/models/user.py` — modelo `User` + enum `SubscriptionTier` (FREE/PRO/ENTERPRISE), relações `transactions`/`uploads` com `cascade="all, delete-orphan"` (requisito de exclusão LGPD).
- `backend/app/models/upload.py` — modelo `Upload` + enum `UploadStatus` (PENDING/PROCESSING/COMPLETED/FAILED).
- `backend/app/models/transaction.py` — corrigido: `user_id` FK `ondelete="CASCADE"`, `upload_id` FK `ondelete="SET NULL"`, índices em `user_id`, `upload_id`, `date`, `category`.
- `backend/app/models/__init__.py` — registra todos os models em `Base.metadata` (necessário para Alembic autogenerate/target_metadata).
- `backend/app/schemas/{auth,user,transaction,upload}.py` — Pydantic v2 (`ConfigDict(from_attributes=True)`).
- `backend/app/repositories/{user,upload,transaction}_repository.py` — única camada de acesso a dados (CRUD básico + `get_by_email`, `get_by_hash`, `list_by_user`, etc.).
- `backend/app/api/v1/deps.py` — `oauth2_scheme` (`OAuth2PasswordBearer`) + `get_current_user` (decodifica JWT, valida `type=="access"`, busca usuário, checa `is_active`).
- `backend/app/api/v1/routes/auth.py` — `POST /register` (201, valida e-mail único), `POST /login` (OAuth2 form, retorna par de tokens), `POST /refresh` (valida `type=="refresh"`, emite novo par).
- `backend/app/api/v1/routes/{uploads,transactions}.py` — `GET /` (list, protegido por `get_current_user`).
- `backend/app/api/v1/routes/{analytics,assistant,reports}.py` — 12 endpoints stub retornando `501 Not Implemented`, todos protegidos e documentados no OpenAPI.
- `backend/app/main.py` — lifespan simplificado (removido `Base.metadata.create_all`; agora só `engine.dispose()` no shutdown — schema é responsabilidade exclusiva do Alembic).
- `backend/.env.example` — todas as variáveis documentadas no CLAUDE.md.
- 12 arquivos `__init__.py` adicionados em `backend/app/**` (pacotes explícitos, fim dos namespace packages implícitos).
- `backend/alembic.ini` + `backend/alembic/env.py` configurados para SQLAlchemy async (`async_engine_from_config` + `connection.run_sync`), lendo `DATABASE_URL` de `app.core.config.settings`.
- `backend/alembic/versions/7132eab5146a_initial_schema.py` — migration inicial: cria `users`, `uploads`, `transactions` + 4 enums Postgres (`subscriptiontier`, `uploadstatus`, `transactiontype`, `transactioncategory`), todas as FKs/índices.
- Removido `backend/migrations/` (diretório vazio redundante).
- `backend/venv/` criado localmente com dependências mínimas instaladas (não versionado).

### Bug crítico encontrado e corrigido
`passlib==1.7.4` + `bcrypt==5.0.0` (resolvido automaticamente pelo pip por falta de pin) quebra o self-test interno do passlib com `ValueError: password cannot be longer than 72 bytes`, causando `500 Internal Server Error` em **qualquer** operação de hash de senha (registro e login). Corrigido adicionando `bcrypt==4.0.1` ao `requirements.txt`.

### Validação executada (SQLite local — sem PostgreSQL disponível)
- `from app.main import app` — importa sem erros, 21 rotas registradas.
- `alembic upgrade head` / `alembic downgrade base` — OK em ambas as direções.
- `alembic upgrade head --sql` (dialeto postgres, offline) — DDL revisado manualmente, `CREATE TYPE`/`DROP TYPE` corretos sem duplicação.
- `uvicorn app.main:app` — sobe, `/health` → 200.
- `/api/docs` e `/openapi.json` → 200, 17 paths documentados.
- Fluxo completo de auth: `register` (201) → `login` (200, JWT access+refresh) → `refresh` (200) → endpoint protegido com token (200) → sem token (401) → e-mail duplicado (409) → senha errada (401) → refresh com access token (401, rejeitado corretamente).
- Stub `/analytics/dashboard` → 501 conforme contrato documentado no `README.md`.

### Critérios de sucesso da sessão — todos atendidos
- ✅ Backend sobe sem erros
- ✅ Documentação OpenAPI disponível
- ✅ `/docs` funcionando
- ✅ Migrations funcionando (upgrade + downgrade)
- ✅ Autenticação funcional (register/login/refresh)

---

## Última Sessão — Fase 1.5 (Governança e Estruturação do Projeto)

**Data**: 2026-06-11
**Objetivo**: Sessão **sem novas funcionalidades**. Estruturar o Financily para desenvolvimento profissional de longo prazo: regras permanentes de governança, workflows de início/fim de sessão, memória de continuidade, documentação e auditoria rápida.

### Arquivos criados
- `CLAUDE_PROJECT_RULES.md` (raiz) — regras permanentes para Arquitetura, Segurança, SaaS, Fintech, Product Management, Análise de Dados, IA, Git, Documentação, Testes, Escalabilidade, LGPD e Continuidade do Projeto. Posiciona o Claude Code como "CTO permanente" do projeto.
- `docs/session_start.md` — procedimento obrigatório de início de sessão (ler regras + status + continuidade, validar Git, verificar pendências, apresentar diagnóstico antes de implementar).
- `docs/session_end.md` — procedimento obrigatório de encerramento (atualizar docs, revisar alterações/dependências, testar, commit Conventional Commits, push com confirmação, resumo executivo).

### Arquivos atualizados
- `backend/requirements.txt` — removida duplicata de `httpx==0.27.0` (estava nas seções "# HTTP Client" e "# Testing"; mantida apenas a primeira).
- `docs/project_status.md` — este documento: nova seção "Visão Geral por Área", nova seção "Roadmap Atualizado" (§15), correções de seções 2/7/9 refletindo o fix do `httpx`, e esta seção.
- `docs/next_session.md` — memória de continuidade atualizada (ver arquivo).

### Auditoria (ETAPA 6) — achados

**Arquivos órfãos**: nenhum encontrado. Os 36 arquivos `.py` em `backend/app/` (mesmo conjunto da auditoria da sessão anterior) estão todos referenciados/importados pela aplicação.

**Dependências duplicadas**: 🔴 encontrada e ✅ corrigida — `httpx==0.27.0` aparecia duas vezes em `backend/requirements.txt` (seções "# HTTP Client" e "# Testing"). Removida a segunda ocorrência.

**Imports inválidos**: nenhum erro de sintaxe — `ast.parse()` limpo em todos os arquivos `app/**/*.py`. Ao varrer todos os 36 módulos `app.*` com `pkgutil.walk_packages` + `importlib`, **3 falham** no venv mínimo local:
- `app.services.ai.categorizer` → `ModuleNotFoundError: No module named 'joblib'`
- `app.services.analytics.health_score` → `ModuleNotFoundError: No module named 'pandas'`
- `app.services.pdf.extractor` → `ModuleNotFoundError: No module named 'pdfplumber'`

Todas as três libs **já constam em `requirements.txt`**, mas não foram instaladas no venv mínimo criado na sessão anterior (ver "Dependências para a próxima sessão" em `docs/next_session.md`). **Não é um bug de código** — é esperado até que o venv seja completado para trabalhar nos módulos de PDF/IA/Analytics.

**Diretórios vazios** (catálogo completo, fora os já listados na árvore da §1):
- `ai/{behavioral,categorization,forecasting,ocr}/` (raiz) — scaffolds do diagrama de arquitetura do README, zero código.
- `.github/workflows/` — sem CI configurado.
- `docs/{api,architecture,design}/` — scaffolds de documentação.
- `backend/app/middleware/` — apenas `__init__.py`, nenhum middleware registrado em `main.py`.
- `backend/tests/{unit,integration}/` — zero testes em todo o projeto, apesar de pytest configurado.
- `frontend/lib/core/{network,constants,utils}/` — `network/` é crítico para a Opção B (conectar Flutter ao backend).
- `frontend/lib/features/{upload,transactions,analytics,assistant,reports}/` — scaffolds de feature vazios.
- `frontend/lib/shared/{widgets,models}/` — vazios.
- `frontend/assets/{fonts,images}/` — vazios (fontes `Syne-*.ttf` referenciadas em `pubspec.yaml` mas ausentes — débito conhecido).

**Problemas de arquitetura**: nenhum novo encontrado. As camadas `api/routes` → `services` → `repositories` → `models` permanecem consistentes; `services/` não importa de `api/`; `repositories/` é a única camada com queries SQLAlchemy.

**Débitos técnicos**: ver §9 (atualizada) — único item resolvido nesta sessão foi a duplicata do `httpx`. Demais itens (testes, scaffold Flutter, fontes Syne, validação contra Postgres real, parser Santander, ML não treinado) permanecem inalterados e documentados.

### Validação executada
- `git status --porcelain=v1` confirmado limpo antes do início da sessão.
- Nenhuma alteração de código de runtime nesta sessão (exceto `requirements.txt`, que é apenas uma remoção de duplicata) — `pytest`/Alembic/boot da app não foram re-executados por não haver mudança que os afete.

### Critérios de sucesso da sessão
- ✅ `CLAUDE_PROJECT_RULES.md` criado com as 13 áreas solicitadas
- ✅ `docs/session_start.md` criado
- ✅ `docs/session_end.md` criado
- ✅ `docs/next_session.md` atualizado (memória de continuidade)
- ✅ `docs/project_status.md` atualizado (estado por área + roadmap)
- ✅ Auditoria executada e documentada
- ✅ Nenhuma nova funcionalidade implementada (conforme restrição explícita do usuário)
