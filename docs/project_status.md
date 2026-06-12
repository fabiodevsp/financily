# Financily — Status do Projeto

> Auditoria técnica completa. Última atualização: 2026-06-12.
> Branch: `master` · Commits: `2639e79` (arquitetura inicial) → `6782076` (preview HTML + docs) → `1fb4c96` (auditoria) → `4142824` (fundação do backend) → `f8d9b78`/`f7dd82c` (governança) → `1c362f2`/`3ae52b5` (upload de PDF end-to-end) → Transactions API completa → **Conexão Frontend↔Backend (esta sessão, commit pendente)**

---

## Visão Geral por Área (Estado Atual)

| Área | Status | Detalhe |
|---|---|---|
| **Backend** | ✅ Funcional — FastAPI sobe sem erros, 25 rotas registradas, Clean Architecture (`routes` → `services` → `repositories` → `models`) | §3, §12 |
| **Banco de dados** | ✅ Schema completo (`users`, `uploads`, `transactions` + 4 enums Postgres) via Alembic, validado em SQLite (upgrade/downgrade) | §3, §12 |
| **Autenticação** | ✅ JWT completo (`register`/`login`/`refresh`) testado ponta a ponta; falta `/auth/logout` e revogação de refresh token | §3, §4, §12 |
| **Migrations** | ✅ 1 migration inicial (`7132eab5146a_initial_schema`), validada upgrade/downgrade em SQLite + `--sql` offline para Postgres; **nunca rodou contra Postgres real** | §3, §8 |
| **APIs** | 🟡 25 rotas — auth + Transactions API completa + `POST /uploads/pdf`; analytics/assistant/reports ainda stubs `501` | §4, §5, §12 |
| **Frontend** | 🟢 **Conectado ao backend (novo)** — login/registro reais, JWT persistido (`flutter_secure_storage`), upload de PDF, lista de transações (filtros/busca) e resumo financeiro consumindo a API; 8 telas (splash, login, registro, dashboard, upload, transações, resumo). Riverpod "clássico" (sem codegen) — débito documentado. **`flutter create .`/`pub get`/`analyze`/`test` ainda não executados neste ambiente** | §1, §4, §12, Fase 4 |
| **Analytics** | 🟡 `health_score.py` implementado (lógica pura, 4 dimensões), não exposto via API; forecast/behavioral/heatmap não iniciados. `GET /transactions/summary` cobre agregados básicos e agora alimenta o dashboard Flutter | §3, §5, §12 |
| **OCR** | 🟡 Pipeline `extractor.py` (pdfplumber → PyMuPDF → Tesseract OCR), refatorado para operar 100% em memória (bytes) e integrado a `POST /uploads/pdf`; OCR real (Tesseract) ainda não testado em fluxo real | §3, §4, §12 |
| **IA (Categorizador)** | 🟡 Regras por keyword (10 categorias) integradas ao fluxo de upload; pipeline ML (TF-IDF + LogisticRegression) existe, mas `train()` nunca foi chamado — sem `categorizer.joblib`. `PATCH /transactions/{id}` permite correção manual (seta confidence_score=1.0, sinal útil para retreino futuro) | §3, §4, §12 |
| **Upload de PDF** | ✅ `POST /api/v1/uploads/pdf` (MVP síncrono, sem SSE) — extractor → categorizer → repository, dedupe via hash, status PENDING→PROCESSING→COMPLETED/FAILED. **Agora consumido pela tela de Upload do Flutter (novo)** | §5, §13 |
| **Transactions API** | ✅ Completa — `GET /` (paginação/filtros/busca/ordenação), `GET /summary` (agregados por tipo/categoria), `PATCH /{id}` (corrige categoria/subcategoria), `DELETE /{id}`. **Agora consumida pelas telas de Transações/Resumo/Dashboard do Flutter (novo)** | §4, §13 |
| **Testes** | 🟡 **49 testes** (backend, inalterado) — 18 unitários (`extractor.py`) + 31 integração (8 upload + 23 transactions). `core/security.py`, `categorizer.py`, `health_score.py`, rotas de auth, e **todo o frontend Flutter** ainda sem testes | §9, §10 |

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
    ├── pubspec.yaml                   ✅ ATUALIZADO — `http_parser` adicionado; refs a fontes Syne inexistentes (inalterado)
    ├── assets/{fonts,images}/         ❌ vazio (inalterado)
    └── lib/
        ├── main.dart                  ✅ `ProviderScope` + `MaterialApp.router(routerConfig: appRouterProvider)`
        ├── core/
        │   ├── theme/app_theme.dart   ✅ AppColors + ThemeData (inalterado)
        │   ├── router/app_router.dart ✅ REESCRITO — 7 rotas + `redirect` por `AuthStatus` + `GoRouterRefreshListenable`
        │   ├── network/                ✅ NOVO — camada HTTP completa
        │   │   ├── api_config.dart        baseUrl `http://127.0.0.1:8000`, timeouts
        │   │   ├── api_exception.dart      `ApiException.fromDioException` (mensagens PT-BR)
        │   │   ├── auth_interceptor.dart   Bearer token + refresh-and-retry em 401
        │   │   ├── token_storage.dart      `flutter_secure_storage` (tokens + user JSON)
        │   │   ├── dio_client.dart         `createDio()`
        │   │   └── providers.dart          `dioProvider`, `tokenStorageProvider`, `SessionExpiredNotifier`
        │   ├── utils/jwt_utils.dart     ✅ NOVO — `decodeJwtPayload` (claim `sub`, sem libs externas)
        │   └── constants/               ❌ vazio
        ├── features/
        │   ├── auth/                    ✅ CONECTADO — login + registro reais, JWT persistido
        │   │   ├── data/{auth_repository.dart, models/{user_model,token_pair}.dart}
        │   │   └── presentation/{providers/auth_provider.dart, screens/{login_screen,register_screen}.dart}
        │   ├── dashboard/.../dashboard_screen.dart ✅ REESCRITO — saldo/receitas/despesas, pizza de categorias e últimas transações consomem a API; score/heatmap continuam mock (sem endpoint)
        │   ├── upload/                  ✅ NOVO — seleção de banco + PDF (`file_picker`), `POST /uploads/pdf`, resultado com transações criadas/duplicadas
        │   ├── transactions/             ✅ NOVO — lista paginada com filtros (tipo/categoria/busca) e tela de resumo por categoria
        │   ├── splash/                   ✅ NOVO — tela exibida enquanto `AuthStatus.unknown` restaura a sessão
        │   ├── analytics/               ❌ vazio
        │   ├── assistant/                ❌ vazio
        │   └── reports/                  ❌ vazio
        └── shared/{widgets,models}/    ❌ vazio
```

**Frontend conectado ao backend nesta sessão (Fase 4)** — ver seção "Última Sessão — Fase 4" para o detalhamento completo. Continua sem scaffold de plataforma (`flutter create .` nunca executado) — não existem `android/`, `ios/`, `windows/`, `macos/`, `web/`, `linux/`, `test/`, `.metadata`/`analysis_options.yaml`. **`flutter pub get`, `flutter analyze` e `flutter test` também nunca executados** — todo o código desta sessão foi escrito e revisado manualmente, sem validação do compilador Dart (ver §8 e Fase 4).

---

## 2. Tecnologias e dependências

**Backend** (Python 3.12, `requirements.txt`): FastAPI 0.111, Uvicorn, SQLAlchemy 2.0 (async/asyncpg), Alembic, Pydantic v2 + pydantic-settings, python-jose + passlib (JWT/bcrypt), **`bcrypt==4.0.1` (pin obrigatório — ver §6)**, pdfplumber, PyMuPDF (`fitz`), pytesseract, Pillow, pandas, numpy, scikit-learn, prophet, nltk, joblib, httpx (duplicata removida nesta sessão — ver "Última Sessão"), pytest/pytest-asyncio/pytest-cov/faker.

**Frontend** (Flutter ≥3.3, `pubspec.yaml`): `http_parser: ^4.0.2` adicionado nesta sessão (necessário para `MediaType` no upload multipart). Demais deps inalteradas — flutter_riverpod, riverpod_annotation, go_router, dio, retrofit, flutter_secure_storage, sqflite, hive_flutter, file_picker, desktop_drop, path_provider, fl_chart, google_fonts, shimmer, lottie, flutter_animate, cached_network_image, intl, freezed, json_serializable, dartz, logger, mockito.

> **Agora em uso de fato**: `flutter_riverpod` (providers clássicos), `go_router` (7 rotas + redirect), `dio` (+ `http_parser`), `flutter_secure_storage`, `file_picker`, `intl` (`NumberFormat.currency`). **Ainda declaradas mas não usadas**: `retrofit`, `sqflite`, `hive_flutter`, `desktop_drop`, `path_provider`, `fl_chart`, `google_fonts`, `shimmer`, `lottie`, `flutter_animate`, `cached_network_image`, `dartz`, `logger`, `mockito`. **`freezed`/`json_serializable`/`riverpod_generator`/`retrofit_generator`/`build_runner`** permanecem declaradas mas **deliberadamente não usadas nesta fase** — decisão arquitetural temporária (ver Fase 4: "Decisões arquiteturais").

---

## 3. Funcionalidades já implementadas (código real e funcional isoladamente)

| Item | Local | Observação |
|---|---|---|
| Design tokens + tema dark | `frontend/lib/core/theme/app_theme.dart` | `AppColors` consistente com `docs/preview.html` |
| **Camada de rede (`core/network/`)** | `api_config.dart`, `dio_client.dart`, `auth_interceptor.dart`, `token_storage.dart`, `api_exception.dart`, `providers.dart` | ✅ NOVO — Dio configurado com `baseUrl=http://127.0.0.1:8000`, interceptor injeta Bearer e tenta `/auth/refresh` em 401, tokens/usuário em `flutter_secure_storage`, exceções normalizadas em PT-BR |
| **Auth real (Flutter)** | `features/auth/` | ✅ NOVO — `login`/`register` conectados a `/api/v1/auth/*`; sessão restaurada no boot (`tryRestoreSession`); logout limpa `flutter_secure_storage` |
| Tela de Login (UI) | `login_screen.dart` | ✅ ATUALIZADO — Glassmorphism, animação fade-in; agora chama `authControllerProvider.login()` real |
| **Tela de Registro (UI)** | `register_screen.dart` | ✅ NOVO — nome opcional, e-mail, senha+confirmação, chama `register()` real (auto-login após registro) |
| **Tela de Splash** | `splash/.../splash_screen.dart` | ✅ NOVO — exibida enquanto `AuthStatus.unknown` restaura a sessão salva |
| Tela de Dashboard (UI) | `dashboard_screen.dart` | ✅ REESCRITO — saldo/receitas/despesas (`transactionsSummaryProvider`), pizza de categorias (top-5 + "Outros"), últimas 5 transações (`transactionsProvider`), logout via bottom sheet, pull-to-refresh. Score de saúde e heatmap de gastos permanecem mock (sem endpoint correspondente) |
| **Tela de Transações** | `transactions/.../transactions_screen.dart` | ✅ NOVO — `GET /transactions/` com filtros (tipo/categoria), busca textual, paginação, pull-to-refresh, estados loading/erro/vazio |
| **Tela de Resumo** | `transactions/.../summary_screen.dart` | ✅ NOVO — `GET /transactions/summary`: saldo do período, receitas/despesas, breakdown por categoria com barras de progresso |
| **Tela de Upload** | `upload/.../upload_screen.dart` | ✅ NOVO — seleção de banco (Itaú/Santander) + PDF via `file_picker`, `POST /uploads/pdf`, exibe transações criadas/duplicadas, invalida providers de transações/resumo no sucesso |
| Roteamento | `app_router.dart` | ✅ REESCRITO — GoRouter com 7 rotas (`/splash`, `/login`, `/register`, `/dashboard`, `/upload`, `/transactions`, `/summary`) + `redirect` reativo via `AuthStatus`/`GoRouterRefreshListenable` |
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
| Backend API (`main.py`) | ✅ Sobe sem erros, 25 rotas, `/api/docs` funcional | Routers `analytics`, `assistant`, `reports` ainda são stubs — lógica de negócio não implementada |
| Banco de dados | ✅ Schema completo via Alembic (validado em SQLite) | Não testado contra PostgreSQL real (sem instância local disponível) |
| Auth | ✅ register/login/refresh funcionais ponta a ponta | Sem `/auth/logout`, sem rate limiting, sem refresh token revocation/rotation |
| Upload de PDF | ✅ `POST /uploads/pdf` funcional (MVP síncrono) — testado com extractor mockado | Sem SSE de progresso; sem fixtures de PDF reais para testar `_try_pdfplumber`/`_try_ocr` ponta a ponta |
| **Transactions API** | ✅ `GET /` (paginação/filtros/busca/ordenação), `GET /summary`, `PATCH /{id}`, `DELETE /{id}` — testado com 23 testes de integração | `GET /{id}` (detalhe de uma transação) não foi pedido/implementado; sem endpoint de criação manual de transação |
| Parser Santander | Função existe | `_parse_santander_row` ainda é cópia do Itaú — placeholder |
| OCR | Pipeline codificado, refatorado para memória, integrado ao upload | Caminho OCR (`_try_ocr`/Tesseract) não exercitado por nenhum teste/fixture real ainda |
| Categorizador ML | Pipeline completo, integrado ao upload (`categorize()` chamado por transação); correção manual via `PATCH /transactions/{id}` agora gera sinal `confidence_score=1.0` | `train()` nunca chamado; sem `categorizer.joblib`; toda transação que não bate regra de keyword fica `OTHER`/confidence `0.0`; correções manuais ainda não são usadas como dataset de retreino |
| **Roteamento Flutter** | ✅ 7 rotas + `redirect` reativo por `AuthStatus` | Faltam telas de Analytics/AI Chat/Configurações dedicadas (placeholders "Em breve" no bottom nav) |
| **Login/Registro Flutter** | ✅ Conectados a `/api/v1/auth/*`, JWT persistido | Sem "esqueci minha senha"; sem `/auth/logout` no backend (logout é só client-side) |
| **Dashboard/Transações/Resumo/Upload Flutter** | ✅ Consomem `GET /transactions/`, `GET /transactions/summary`, `POST /uploads/pdf` | Score de saúde financeira e mapa de gastos (heatmap) seguem com dados mock — sem endpoint `/analytics/*` para alimentá-los |
| Projeto Flutter | `pubspec.yaml` rico, `http_parser` adicionado | Sem scaffold de plataforma (`flutter create .`); fontes `Syne-*.ttf` ausentes; `flutter pub get`/`analyze`/`test` nunca executados — código desta sessão não foi validado pelo compilador Dart |

---

## 5. Funcionalidades planejadas, não iniciadas

- **SSE de progresso para upload**: `POST /uploads/pdf` hoje é síncrono (MVP); stream de progresso fica como follow-up
- **Analytics API real**: dashboard payload, heatmap, categorias, forecast (Prophet), health-score (conectar `health_score.py`), behavioral, subscriptions — destrava o score/heatmap reais no Flutter
- **Análise comportamental** (anomaly detection, clustering): zero código
- **Detecção de assinaturas recorrentes**: zero código
- **Assistente IA** (chat): stub 501 apenas; tab "AI Chat" no Flutter é placeholder "Em breve"
- **Exportação PDF/Excel/CSV**: stubs 501; faltam libs (`openpyxl`, `reportlab`/`weasyprint`) no requirements
- **Notificações**: nenhum código
- **Tela de Configurações** (Flutter): pasta nem existe; logout hoje vive num bottom sheet acionado pelo tab "Config"
- **Testes automatizados Flutter**: zero testes (e `flutter test` nunca executado — falta scaffold/SDK validado)
- **Testes automatizados backend**: 49 testes cobrem extractor/upload/transactions; `categorizer`, `health_score`, `security`, auth routes ainda sem cobertura
- **Multi-plataforma Flutter**: scaffold ausente (`flutter create .` pendente, com confirmação do usuário)
- **Migração para codegen** (`freezed`/`json_serializable`/`riverpod_generator`): adiada até `flutter analyze`/`flutter test` rodarem com sucesso (ver Fase 4)

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
- 🟡 **Parcialmente mitigado**: 49 testes automatizados (extractor + upload + transactions), mas cobertura ainda é pontual — auth, categorizer, health_score, repositories de user/upload permanecem sem rede de segurança.
- Auth sem rate limiting/brute-force protection — aceitável para MVP local, revisar antes de produção.
- **Dedupe de transações via `transactions.hash` (unique global, não escopado por `user_id`)** — dois usuários diferentes que importem uma linha de extrato byte-idêntica (mesma data+descrição+valor, ex.: assinatura recorrente comum) colidiriam no hash e a segunda seria silenciosamente tratada como duplicata. É o mecanismo oficial documentado (regra Fintech #3) e definido na migration inicial (Fase 1) — não alterado por exigir migration + decisão explícita. Risco baixo na prática (hash inclui data+descrição+valor formatados), mas registrado para decisão futura.
- **`TransactionRepository.create()` comita uma transação por vez** — para faturas com muitas linhas, `POST /uploads/pdf` faz N commits sequenciais. Aceitável para volumes de fatura típicos (10–100 linhas); revisar para bulk-insert se necessário (regra Análise de Dados #3 — não otimizar prematuramente).
- 🆕 **`GET /transactions/?limit=N` faz uma query `SELECT` + uma query `COUNT` separada** para montar `total` — duplica o custo de leitura por requisição. Aceitável para volumes do MVP; revisar (ex.: window function) apenas se virar gargalo medido.
- 🆕 **`PATCH /transactions/{id}` sempre seta `confidence_score=1.0` quando há qualquer campo alterado** — assume que toda correção manual é 100% confiável. Correto para o caso de uso (usuário corrigindo a própria transação), mas é uma decisão de produto implícita; revisar se no futuro outras roles (ex. admin) puderem editar transações de terceiros.
- 🆕 **Frontend sem codegen é decisão temporária, não definitiva** — toda a camada `data/` usa `fromJson`/`toJson` manuais e os providers usam `StateNotifier`/`FutureProvider` clássicos (sem `@riverpod`/`freezed`). Reduz boilerplate de build_runner durante a validação visual, mas qualquer mudança de schema do backend exige editar os `fromJson` manualmente em paralelo. Decisão a ser revisitada após `flutter pub get && flutter analyze && flutter test` rodarem com sucesso (ver Fase 4).
- 🆕 **Nenhum comando do Flutter SDK foi executado nesta sessão** (`pub get`, `create`, `analyze`, `test`, `run`) — todo o código novo (~15 arquivos) foi escrito e revisado manualmente (consistência de imports, tipos e nomes de campos entre `data/models/*` e os schemas Pydantic do backend), mas **erros de compilação Dart só serão detectados quando o usuário rodar `flutter pub get`/`flutter analyze`** em um ambiente com o SDK configurado.
- 🆕 **`_FinancialHealthScoreCard` e `_SpendingHeatmapWidget` no dashboard continuam 100% mock** — não há endpoint `/analytics/*` real para alimentá-los; conectá-los faria parte do trabalho de Analytics (fora do escopo da Fase 4, que cobriu apenas `transactions`/`uploads`/`auth`).
- 🆕 **Dedupe de transações por hash (cross-user) e demais riscos do backend permanecem inalterados** — ver entradas anteriores; Fase 4 não tocou backend além de leitura via Dio.

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
- [x] ~~Instalar deps PDF/IA no venv (`pdfplumber`, `pymupdf`, `pytesseract`, `Pillow`, `pandas`, `scikit-learn`, `joblib`)~~ ✅ feito
- [x] ~~Testes unitários para helpers puros de `extractor.py`~~ ✅ feito (18 testes)
- [x] ~~Transactions API (paginação/filtros/busca/ordenação/summary/update/delete)~~ ✅ feito (esta sessão, 23 testes)
- [ ] Testes unitários para `categorizer.py` (regras), `health_score.py`, `core/security.py`, repositories de user/upload, rotas de auth — ainda zero
- [ ] Fixtures de PDF reais (Itaú/Santander) em `backend/tests/fixtures/` para testar `_try_pdfplumber`/`_try_ocr` ponta a ponta (testes atuais de `POST /uploads/pdf` usam `extract_transactions` mockado)
- [ ] SSE de progresso para `POST /uploads/pdf` — endpoint hoje é síncrono; avaliar necessidade real com faturas grandes/OCR
- [ ] `prophet`/`nltk` listados em `requirements.txt` mas não instalados no venv — deferidos até o trabalho de forecast/behavioral (Fase 3)
- [ ] `flutter create .` para gerar scaffold de plataforma
- [ ] Resolver fontes `Syne` (adicionar `.ttf` ou usar `google_fonts.GoogleFonts.syne()`)
- [ ] Validar `alembic upgrade head` contra PostgreSQL real (Docker local ou Supabase)
- [ ] Implementar `/auth/logout` (revogação de refresh token) — opcional para MVP
- [ ] Usar correções manuais (`PATCH /transactions/{id}`) como dataset de retreino do categorizador ML
- [ ] 🆕 **`flutter pub get && flutter create . && flutter analyze && flutter test`** — primeira validação do ambiente Flutter desta sessão; pré-requisito para qualquer decisão de codegen (regra de continuidade, ver Fase 4)
- [ ] 🆕 **Decidir migração para `freezed`/`json_serializable`/`riverpod_generator` (codegen)** — modelos `data/models/*` hoje são manuais (`fromJson`/`toJson`); providers usam `StateNotifier`/`FutureProvider` clássicos. Decisão adiada para depois de `flutter analyze`/`flutter test` (Fase 4)
- [ ] 🆕 **Conectar `_FinancialHealthScoreCard`/`_SpendingHeatmapWidget` (dashboard) a dados reais** — depende de Analytics API real (`/analytics/health-score`, heatmap)
- [ ] 🆕 **Endpoint `GET /transactions/{id}`** — tela de detalhe de transação ainda não existe no Flutter nem no backend
- [ ] 🆕 **Telas de Analytics/AI Chat/Configurações no Flutter** — atualmente placeholders "Em breve" (SnackBar) no bottom nav

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
- ✅ **Resolvido nesta sessão**: `POST /uploads/pdf` valida `content_type == application/pdf`, tamanho (`MAX_UPLOAD_SIZE_MB`, default 10MB) e banco suportado (`SUPPORTED_BANKS`); PDF processado 100% em memória (bytes/BytesIO, `extractor.py` refatorado — nunca grava em disco).
- `raw_text` no modelo `Transaction` — agora populado por `POST /uploads/pdf` com a linha extraída (texto da tabela/OCR), nunca o PDF completo. Conforme requisito LGPD.
- Nenhum rate limiting / proteção brute-force planejado para auth ainda.
- JWT: `SECRET_KEY` único para access e refresh tokens, diferenciados via claim `"type"` — adequado para MVP, mas sem mecanismo de revogação de refresh tokens (logout não invalida tokens existentes).

---

## 12. Status por módulo (MVP)

| Módulo | Status |
|---|---|
| **Autenticação** | ✅ **Funcional** (register/login/refresh/JWT validados ponta a ponta no backend; **Flutter conectado** — login/registro reais, JWT persistido via `flutter_secure_storage`, refresh automático em 401) — falta apenas logout/revocation no backend |
| **Frontend ↔ Backend (Fase 4)** | 🟢 **Conectado** — `core/network/` (Dio + `AuthInterceptor` + refresh-and-retry), 8 telas (splash/login/registro/dashboard/upload/transações/resumo), GoRouter com `redirect` reativo por `AuthStatus`. Riverpod clássico (sem codegen), `fromJson`/`toJson` manuais — decisão temporária (ver §8/§15) |
| Dashboard | 🟢 **Parcialmente conectado** — saldo, receitas/despesas, pizza de categorias e transações recentes consomem `transactionsSummaryProvider`/`transactionsProvider` reais; `_FinancialHealthScoreCard` e `_SpendingHeatmapWidget` continuam 100% mock (sem `/analytics/*` real) |
| **Upload de PDFs** | ✅ **Funcional** (MVP síncrono) — `POST /uploads/pdf`: extractor → categorizer → repository, dedupe por hash, status PENDING→PROCESSING→COMPLETED/FAILED. **Tela Flutter conectada** (`file_picker` + `Dio.MultipartFile`), exibe resultado (transações criadas/duplicadas). Validado com extractor mockado no backend (sem fixture de PDF real ainda) |
| Parser de faturas (Itaú) | 🟡 Em desenvolvimento (lógica existe e **agora integrada** ao endpoint de upload; sem fixture real de PDF para validar `_try_pdfplumber`) |
| Parser de extratos (Santander) | ❌ Não iniciado (stub = cópia do Itaú) |
| OCR | 🟡 Em desenvolvimento (pipeline refatorado para memória e **integrado ao upload** como fallback; caminho OCR não exercitado por teste real) |
| **Banco de dados** | ✅ **Funcional** — schema completo (`users`, `uploads`, `transactions`), Alembic configurado, migration inicial validada |
| **API** | ✅ **Funcional** — app sobe, `/api/docs` e `/openapi.json` ok, 25 rotas registradas |
| **Transactions API** | ✅ **Funcional** — `GET /` (paginação/filtros/busca/ordenação), `GET /summary` (agregados), `PATCH /{id}` (corrige categoria/subcategoria), `DELETE /{id}`. **Telas Flutter conectadas**: Transações (lista + filtros + busca) e Resumo (totais + categorias) |
| Categorização automática | 🟡 Em desenvolvimento (regras prontas e integradas ao endpoint de upload; ML não treinado — toda transação fora das regras de keyword fica `OTHER`/confidence `0.0`; correção manual via `PATCH /transactions/{id}` agora seta confidence `1.0`) |
| Previsão financeira | ❌ Não iniciado |
| Assistente IA | ❌ Não iniciado (stub 501; tela Flutter "AI Chat" é placeholder "Em breve") |
| Exportação PDF | ❌ Não iniciado (stub 501) |
| Exportação Excel | ❌ Não iniciado (stub 501) |
| Exportação CSV | ❌ Não iniciado (stub 501) |
| Notificações | ❌ Não iniciado |
| Configurações | 🟡 Placeholder (bottom sheet com logout funcional; demais opções "Em breve") |
| Design System | 🟡 Em desenvolvimento (tokens `AppColors` usados nas 8 telas conectadas; fontes Syne ainda faltando; `_C`/`_Grad` duplicados no dashboard permanecem como débito) |
| Responsividade | ❌ Não verificado (telas mobile-first apenas) |
| Multi plataforma | ❌ Não iniciado — `flutter create .`/`pub get`/`analyze`/`test` nunca executados (SDK indisponível nesta sessão) |

---

## 13. Próximos passos recomendados (ordem ideal)

1. ✅ ~~Desbloquear o backend~~ — **concluído na Fase 1**
2. ✅ ~~Upload de PDF end-to-end~~ — **concluído na Fase 2** (MVP síncrono: `POST /api/v1/uploads/pdf`, extractor → categorizer → repository, dedupe por hash)
3. ✅ ~~Transactions API completa~~ — **concluída na Fase 3** (paginação/filtros/busca/ordenação, summary, update de categoria/subcategoria, delete)
4. ✅ ~~Conectar Flutter ao backend~~ — **concluído nesta sessão (Fase 4)**: `core/network/` (Dio + `AuthInterceptor` + refresh), login/registro reais, JWT persistido, upload/transações/resumo conectados, 8 telas, GoRouter com redirect reativo
5. 🔜 **Validar ambiente Flutter** (PRIORIDADE — bloqueia tudo abaixo): `flutter pub get && flutter create . && flutter analyze && flutter test && flutter run -d windows`. Primeira execução do SDK nesta fase do projeto; corrigir erros de compilação encontrados nos ~15 arquivos novos antes de seguir
6. **Decidir migração para codegen** (`freezed`/`json_serializable`/`riverpod_generator`/`build_runner`) com base no resultado do passo 5 — ver §8/§15
7. **Analytics API real**: começar por `/analytics/health-score` (já existe `health_score.py`) e `/analytics/dashboard` (pode reaproveitar `TransactionRepository.get_summary`); depois conectar `_FinancialHealthScoreCard`/`_SpendingHeatmapWidget` no Flutter
8. **Parser Santander real** (substituir stub)
9. **Categorizador ML**: treinar com dados reais de faturas Itaú/Santander; considerar correções manuais (`PATCH /transactions/{id}`) como dataset
10. **Forecast (Prophet) + behavioral**: implementar após volume real de transações
11. **Testes**: cobrir `core/security.py`, repositories de user/upload, rotas de auth, `categorizer.py`, `health_score.py` no backend (49 testes já cobrem extractor/uploads/transactions); iniciar testes Flutter (`flutter test` — zero hoje)
12. **Fixtures de PDF reais (Itaú/Santander)** para testar `_try_pdfplumber`/`_try_ocr` ponta a ponta (atualmente mockado)
13. **Validar Alembic contra PostgreSQL real** antes do primeiro deploy

---

## 14. Estimativa de conclusão

**~42–45% do escopo total** descrito no `README.md`/`Prompt Inicial.txt`.

A Fase 3 havia deixado o backend em ~33–35% (Transactions API completa, 49 testes). Nesta sessão (Fase 4), o **frontend foi conectado ao backend de ponta a ponta pela primeira vez**: login e registro reais (`/api/v1/auth/*`), JWT persistido (`flutter_secure_storage`) com refresh automático em 401, upload de PDF real (`POST /uploads/pdf` via `file_picker` + Dio multipart), tela de transações consumindo `GET /transactions/` (filtros, busca, paginação) e tela de resumo consumindo `GET /transactions/summary`, dashboard parcialmente conectado (saldo, receitas/despesas, pizza de categorias, transações recentes), logout funcional e roteamento reativo (`GoRouter` + `redirect` por `AuthStatus`). Isso é o primeiro fluxo **visualmente utilizável** do produto (login → upload → transações → resumo), justificando o salto de ~8-10 pontos mesmo sem novo código de backend.

O percentual permanece moderado porque: (a) nenhum comando do Flutter SDK foi executado ainda — erros de compilação Dart nos ~15 arquivos novos são desconhecidos até `flutter pub get`/`analyze`/`test`; (b) a decisão de codegen (`freezed`/`riverpod_generator`) está em aberto; (c) `_FinancialHealthScoreCard`/`_SpendingHeatmapWidget` continuam mock (sem Analytics API real); (d) Analytics/forecast/IA permanecem stubs 501; (e) parser Santander, categorizador ML treinado, fixtures de PDF reais e testes Flutter ainda não existem; (f) scaffold de plataforma (`flutter create .`) ainda não gerado.

---

## 15. Roadmap Atualizado

| Fase | Escopo | Status |
|---|---|---|
| **Fase 1 — Fundação do Backend** | Banco de dados, auth JWT, schema, repositórios, Alembic, contrato de API (stubs) | ✅ Concluída (commit `4142824`) |
| **Fase 1.5 — Governança e Estruturação** | `CLAUDE_PROJECT_RULES.md`, `docs/session_start.md`, `docs/session_end.md`, auditoria, atualização de `project_status.md`/`next_session.md` | ✅ Concluída (commits `f8d9b78`/`f7dd82c`) |
| **Fase 2 — Primeira fatia vertical de valor** | Upload de PDF end-to-end (extractor → categorizer → repository), dedupe, 26 testes (18 unit + 8 integração) | ✅ Concluída (commits `1c362f2`/`3ae52b5`) |
| **Fase 3 — Transactions API** | `GET /` (paginação/filtros/busca/ordenação), `GET /summary`, `PATCH /{id}`, `DELETE /{id}`, 23 testes de integração | ✅ Concluída (commits `7b5f37c`/`f642155`) |
| **Fase 4 — Conexão Frontend↔Backend** | `core/network/` (Dio + AuthInterceptor + refresh), login/registro/JWT/logout reais, upload/transações/resumo conectados, GoRouter reativo, 8 telas, Riverpod clássico sem codegen (decisão temporária) | ✅ Concluída (esta sessão, commit pendente) |
| **Fase 4.5 — Validação do SDK Flutter** | `flutter pub get && flutter create . && flutter analyze && flutter test && flutter run`; corrigir erros de compilação dos ~15 arquivos novos; decidir migração para codegen (`freezed`/`riverpod_generator`) | ⏭️ Próxima (ver `docs/next_session.md`) |
| **Fase 5 — Analytics real + Dashboard completo** | `/analytics/health-score` e `/analytics/dashboard` reais; conectar `_FinancialHealthScoreCard`/`_SpendingHeatmapWidget`; Parser Santander real; Categorizador ML treinado; fixtures de PDF reais | ❌ Não iniciada |
| **Fase 6 — Produção** | Testes automatizados restantes (backend + Flutter), PostgreSQL real validado, rate limiting/auth hardening, CI (`.github/workflows/`), exportações PDF/Excel/CSV, notificações, assistente IA, SSE de progresso | ❌ Não iniciada |

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

---

## Última Sessão — Fase 2 (Upload de PDF end-to-end)

**Data**: 2026-06-12
**Objetivo**: Primeira fatia vertical de valor real do produto (Opção A do plano da sessão anterior, aprovada pelo usuário): implementar `POST /api/v1/uploads/pdf` ponta a ponta — recebe um PDF, extrai transações (`extractor.py`), categoriza (`categorizer.py`), persiste via `TransactionRepository`, com dedupe por hash e tratamento explícito de erro. MVP síncrono (sem SSE), conforme decisão da sessão anterior.

### Arquivos criados
- `backend/pytest.ini` — `asyncio_mode = auto`, `testpaths = tests`.
- `backend/tests/__init__.py`, `backend/tests/unit/__init__.py`, `backend/tests/integration/__init__.py` — pacotes de teste explícitos.
- `backend/tests/conftest.py` — fixtures `db_session` (SQLite in-memory + `StaticPool`), `client` (`AsyncClient` + `ASGITransport` com `app.dependency_overrides[get_db]`), `test_user`, `auth_headers`.
- `backend/tests/unit/test_extractor.py` — 18 testes para os helpers puros de `extractor.py` (`_parse_amount`, `_parse_date_br`, `_hash`, `_deduplicate`, `_parse_itau_row`, `_parse_santander_row`).
- `backend/tests/integration/test_uploads.py` — 8 testes de integração para `POST /uploads/pdf` (happy path, dedupe em re-upload, sem token, tipo/banco/tamanho inválido, zero transações extraídas, erro de extração), com `extract_transactions` mockado via `monkeypatch`.

### Arquivos atualizados
- `backend/app/services/pdf/extractor.py` — `extract_transactions` (e `_try_pdfplumber`/`_try_ocr`) refatorados para receber `bytes` em vez de `Path`/caminho de arquivo, usando `BytesIO` (pdfplumber) e `fitz.open(stream=..., filetype="pdf")` (PyMuPDF). Garante 100% processamento em memória (requisito LGPD) — lógica de parsing/regex inalterada.
- `backend/app/core/config.py` — adicionados `MAX_UPLOAD_SIZE_MB: int = 10` e `SUPPORTED_BANKS: List[str] = ["itau", "santander"]`.
- `backend/app/schemas/upload.py` — novo schema `UploadResult(UploadRead)` com `transactions_created: int` e `duplicates_skipped: int`.
- `backend/app/api/v1/routes/uploads.py` — novo endpoint `POST /pdf`: valida `bank` (em `SUPPORTED_BANKS`), `content_type == application/pdf` e tamanho (`MAX_UPLOAD_SIZE_MB`); cria `Upload` (PENDING→PROCESSING), chama `extract_transactions(bytes, bank)`, para cada transação não-duplicada (via `TransactionRepository.get_by_hash`) chama `categorizer.categorize()` e persiste via `TransactionRepository.create()`; finaliza `Upload` como `COMPLETED` ou `FAILED` (com `error_message`, nunca expondo detalhes internos da exceção).
- `backend/requirements.txt` — adicionado `aiosqlite==0.22.1` na seção "# Testing".
- `docs/project_status.md` — este documento (Visão Geral, §4, §5, §8, §9, §11, §12, §13, §14, §15 e esta seção).

### Decisões tomadas
- **MVP síncrono, sem SSE**: `POST /uploads/pdf` processa e responde de forma síncrona. SSE de progresso fica documentado como follow-up (§5, §9) — decisão da sessão anterior, mantida.
- **Dedupe global de `transactions.hash`**: mantido como está (mecanismo oficial, regra Fintech #3). O risco teórico de colisão cross-user em linhas byte-idênticas foi documentado em §8 como risco aceito, não alterado nesta sessão (exigiria migration + decisão explícita).
- **Estado `FAILED` em vez de erro HTTP genérico** para "zero transações extraídas" e "exceção durante extração": resposta `201` com `status="failed"` e `error_message` amigável (sem detalhes internos da exceção), mantendo `Upload` como trilha de auditoria — alinhado à regra 7.4 (estado explícito).
- **`prophet`/`nltk` permanecem não instalados** — deferidos para a Fase 4 (forecast/behavioral), não bloqueiam esta fatia.
- **Testes de integração usam `extract_transactions` mockado** (via `monkeypatch`) em vez de fixtures de PDF reais — gerar PDFs de teste reais (Itaú/Santander) é não-trivial e foi documentado como débito (§9) em vez de bloquear a entrega desta fatia.

### Validação executada
- `pip install pdfplumber pymupdf pytesseract Pillow pandas numpy scikit-learn joblib pytest pytest-asyncio pytest-cov faker httpx aiosqlite` — todas as dependências PDF/IA/teste instaladas no venv sem conflitos (exceto `bcrypt==4.0.1`, intocado).
- `pytest backend/tests/ -v` → **26/26 testes passando** (18 unit + 8 integração) na primeira execução.
- `uvicorn app.main:app` iniciado em background, `GET /health` → 200, `/api/docs` acessível — confirma que o app continua subindo corretamente após as mudanças.

### Critérios de sucesso da sessão
- ✅ `POST /api/v1/uploads/pdf` funcional: recebe PDF, extrai, categoriza, persiste, deduplica
- ✅ Processamento 100% em memória (LGPD) — `extractor.py` refatorado para `bytes`/`BytesIO`
- ✅ Validação de entrada (content-type, tamanho, banco suportado)
- ✅ Estado `FAILED` com `error_message` para falhas de extração/zero resultados
- ✅ 26 testes automatizados passando (extractor + upload endpoint)
- ✅ App sobe sem erros após as mudanças
- ✅ Nenhuma alteração arquitetural fora do escopo aprovado (Opção A)

---

## Última Sessão — Fase 3 (Transactions API completa)

**Data**: 2026-06-12
**Objetivo**: Completar o segundo módulo de domínio do MVP — expor, agregar, corrigir e remover as transações que `POST /uploads/pdf` (Fase 2) já persiste. Escopo explicitamente limitado a `transactions`: sem Analytics, sem Flutter, sem IA/Open Finance/Dashboard.

### Arquivos atualizados
- `backend/app/schemas/transaction.py` — novos schemas `TransactionList` (`items`/`total`/`skip`/`limit`), `CategorySummary`, `TransactionSummary` (`total_income`/`total_expenses`/`balance`/`transaction_count`/`by_category`/`date_from`/`date_to`), `TransactionUpdate` (`category`/`subcategory`, ambos opcionais).
- `backend/app/repositories/transaction_repository.py` — reescrito: `_apply_filters()` (helper privado compartilhado para `user_id` + `date_from`/`date_to`/`category`/`type`/`search`), `list_by_user()` estendido com filtros/busca (`ilike` em `description`/`merchant`)/ordenação (whitelist `SORTABLE_FIELDS` = `date`/`amount`/`description`), novo `count_by_user()`, novo `get_summary()` (duas queries agregadas: por `type` e por `category`), novo `update()`. `get_by_id`/`delete` reaproveitados sem alteração.
- `backend/app/api/v1/routes/transactions.py` — reescrito: `GET /` (paginação + filtros + busca + ordenação, retorna `TransactionList`), `GET /summary` (retorna `TransactionSummary`), `PATCH /{id}` (aplica `TransactionUpdate`, seta `confidence_score=1.0` quando há mudança, 404 se não existir/não for do usuário), `DELETE /{id}` (`204`, 404 se não existir/não for do usuário).
- `backend/tests/conftest.py` — novo fixture `other_user` (segundo usuário, para testes de isolamento).
- `backend/tests/integration/test_transactions.py` (NOVO) — 23 testes cobrindo list (vazio, paginação, filtros de data/categoria/tipo, busca, ordenação, isolamento por usuário, 401), summary (vazio, com dados, filtro de data, 401), PATCH (happy path, 404 inexistente, 404 outro usuário, 422 categoria inválida, 401) e DELETE (happy path, 404 inexistente, 404 outro usuário, 401).
- `docs/project_status.md` — este documento (Visão Geral, §4, §5, §8, §9, §12, §13, §14, §15 e esta seção).

### Decisões tomadas
- **`amount` sempre positivo, sinal vem de `type`**: `get_summary()` soma por `TransactionType` (CREDIT = receita, DEBIT = despesa) em vez de depender do sinal de `amount` — consistente com `_parse_itau_row` (`amount=abs(amount)`).
- **`total` via `COUNT` separado**: `GET /transactions/` faz uma query `SELECT` (paginada) + uma `COUNT` (mesmos filtros) para retornar `total` junto com `items` — custo extra aceito para volumes do MVP (documentado em §8 como possível otimização futura, não prematura).
- **Busca textual via `.ilike()`**: SQLAlchemy traduz automaticamente para `lower()+LIKE` em dialetos sem `ILIKE` nativo (SQLite), então o mesmo código funciona em teste (SQLite) e produção (Postgres) sem branch condicional.
- **Whitelist de ordenação (`SORTABLE_FIELDS`)**: `sort_by` aceita apenas `date`/`amount`/`description` (validado também via `Query(pattern=...)` no FastAPI) — evita acesso arbitrário a atributos do modelo.
- **`PATCH /{id}` seta `confidence_score=1.0`** sempre que `category`/`subcategory` é alterado — correção manual do próprio usuário é tratada como 100% confiável; documentado em §8 como decisão de produto implícita (revisar se outras roles puderem editar transações de terceiros).
- **404 (não 403) em `PATCH`/`DELETE` de transação de outro usuário** — `get_by_id` já filtra por `user_id`; evita confirmar a existência do recurso para quem não é o dono.
- **Sem `GET /transactions/{id}`**: não fazia parte do escopo solicitado; `PATCH`/`DELETE` operam diretamente por `id` sem endpoint de leitura individual — pode ser adicionado depois se o Flutter precisar de uma tela de detalhe.
- **Sem endpoint de criação manual de transação**: testes seedam `Transaction` diretamente via `db_session` (helper `_create_transaction`); criação real continua exclusivamente via `POST /uploads/pdf`.

### Validação executada
- `pytest backend/tests/ -v` → **49/49 testes passando** (18 unit extractor + 8 integração upload + 23 integração transactions).
- `from app.main import app` → 25 rotas registradas, incluindo `GET /api/v1/transactions/`, `GET /api/v1/transactions/summary`, `PATCH /api/v1/transactions/{transaction_id}`, `DELETE /api/v1/transactions/{transaction_id}`.

### Critérios de sucesso da sessão
- ✅ `GET /transactions/` com paginação, filtros (data/categoria/tipo), busca textual e ordenação
- ✅ `GET /transactions/summary` com totais de receita/despesa/saldo e agregados por categoria
- ✅ `PATCH /transactions/{id}` corrige categoria/subcategoria e sinaliza confiança manual
- ✅ `DELETE /transactions/{id}` remove a transação (com isolamento por usuário)
- ✅ 23 novos testes de integração passando (49/49 no total)
- ✅ App sobe sem erros após as mudanças (25 rotas)
- ✅ Nenhuma funcionalidade fora do escopo (Analytics, Flutter, IA, Open Finance, Dashboard) implementada

---

## Última Sessão — Fase 4 (Conexão Frontend-Backend)

**Data**: 2026-06-12
**Objetivo**: Primeira vez que o Financily se torna **visualmente utilizável** — conectar o Flutter ao backend real (sem mocks) cobrindo o fluxo completo: login → upload de PDF → lista de transações → resumo financeiro. Escopo explicitamente limitado a essa conexão: sem IA, sem Open Finance, sem Analytics avançado, sem forecast, sem novas rotas de backend (reuso 100% dos endpoints já existentes das Fases 1-3).

### Decisão arquitetural central (diretriz explícita do usuário)
**Sem codegen nesta fase.** Toda a camada `data/` usa classes JSON manuais (`fromJson`/`toJson` escritos à mão) e os providers usam Riverpod clássico (`Provider`, `StateNotifierProvider`, `FutureProvider.autoDispose`) — **sem** `freezed`, **sem** `build_runner`, **sem** `@riverpod` (codegen). Documentado como **débito técnico temporário** (§8/§9): a decisão de migrar para codegen será revisitada **depois** que `flutter pub get && flutter create . && flutter analyze && flutter test` rodarem com sucesso em um ambiente com o SDK configurado (próxima sessão, Fase 4.5).

### Arquivos criados (24 novos arquivos)

**Camada de rede (`core/network/`)**:
- `api_config.dart` — `baseUrl = 'http://127.0.0.1:8000'`, paths dos endpoints.
- `dio_client.dart` — instância `Dio` configurada (baseUrl, timeouts, interceptors).
- `token_storage.dart` — wrapper sobre `flutter_secure_storage` para access/refresh token + dados do usuário.
- `auth_interceptor.dart` — injeta `Authorization: Bearer`, intercepta `401`, tenta `POST /auth/refresh` e repete a requisição original; em falha do refresh, notifica `SessionExpiredNotifier`.
- `providers.dart` — `secureStorageProvider`, `tokenStorageProvider`, `sessionExpiredProvider` (`SessionExpiredNotifier extends ChangeNotifier`, evita dependência circular `core/network` ↔ `features/auth`), `dioProvider`.
- `api_exception.dart` — `ApiException.fromDioException()` mapeia timeout/connection/400/401/404/409/413/422 para mensagens PT-BR amigáveis.

**`core/utils/jwt_utils.dart`** — `decodeJwtPayload()` decodifica o claim `sub` do JWT manualmente via `dart:convert` (sem dependência de pacote JWT).

**Auth (`features/auth/`)**:
- `data/models/token_pair.dart`, `data/models/user_model.dart` (`UserModel{id, email, name?, subscriptionTier, isActive}` + `displayName`).
- `data/auth_repository.dart` — `register()`, `login()`, `tryRestoreSession()`, `logout()`, `_userFromAccessToken()` (decodifica JWT quando `/users/me` não está disponível).
- `presentation/providers/auth_provider.dart` — `AuthState{status, user, errorMessage}`, enum `AuthStatus{unknown, authenticating, authenticated, unauthenticated}`, `AuthController` (`login`, `register`, `logout`, `_restoreSession`, `_handleSessionExpired`).
- `presentation/screens/register_screen.dart` — formulário nome/e-mail/senha/confirmação, `ref.listen` para erros, chama `register()`.

**Transações (`features/transactions/`)**:
- `data/models/transaction_model.dart` (`TransactionModel` + `isCredit` getter, `TransactionListModel{items, total, skip, limit, hasMore}`).
- `data/models/transaction_summary_model.dart` (`CategorySummaryModel`, `TransactionSummaryModel`).
- `data/transactions_repository.dart` — `getTransactions()` → `GET /api/v1/transactions/`, `getSummary()` → `GET /api/v1/transactions/summary`.
- `presentation/providers/transactions_provider.dart` — `TransactionsFilter`, `TransactionsFilterNotifier`, `transactionsProvider`/`transactionsSummaryProvider` (`FutureProvider.autoDispose`).
- `presentation/screens/transactions_screen.dart` — lista com filtros (data/categoria/tipo), busca, pull-to-refresh, paginação.
- `presentation/screens/summary_screen.dart` — saldo do período, cards de receitas/despesas, breakdown por categoria com barras de progresso.
- `presentation/widgets/category_ui.dart` — `categoryUiFor(String category)`: mapeia categorias do backend para label PT-BR + ícone Material + `AppColors`.

**Upload (`features/upload/`)**:
- `data/models/upload_result_model.dart` (`UploadResultModel{..., isCompleted, isFailed}`).
- `data/upload_repository.dart` — `uploadPdf()` via `FormData` + `MultipartFile.fromFile(..., contentType: MediaType('application','pdf'))` (pacote `http_parser`).
- `presentation/providers/upload_provider.dart` — `StateNotifierProvider` para estado de upload (idle/loading/success/error).
- `presentation/screens/upload_screen.dart` — seleção de PDF (`file_picker`), seleção de banco, envio, exibição do resultado (transações criadas/duplicadas ou erro).

**Splash**:
- `features/splash/presentation/screens/splash_screen.dart` — tela exibida enquanto `AuthController` restaura a sessão salva (`AuthStatus.unknown`).

### Arquivos atualizados (4)
- `frontend/lib/core/router/app_router.dart` — adicionado `GoRouterRefreshListenable extends ChangeNotifier` (escuta `authControllerProvider` via `ref.listen`, chama `notifyListeners()` em mudança de `AuthStatus`); `appRouterProvider` agora usa `refreshListenable` + `redirect` baseado em `AuthStatus` (unknown→`/splash`, authenticated em rota de auth/splash→`/dashboard`, unauthenticated fora de auth→`/login`); 7 rotas registradas (`/splash`, `/login`, `/register`, `/dashboard`, `/upload`, `/transactions`, `/summary`).
- `frontend/lib/features/auth/presentation/screens/login_screen.dart` — conectado a `authControllerProvider` (campos reais de e-mail/senha, `ref.listen` para erros via `SnackBar`, loading state no botão, link para `/register`).
- `frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart` — reescrita parcial (515 linhas alteradas): `_BalanceSummaryCard`, `_CategoryPieWidget` (com `_buildPieCategories()` real, top-5 + "Outros", `centerLabel` dinâmico) e `_RecentTransactionsCard`/`_RecentTransactionsTile` agora consomem `transactionsSummaryProvider`/`transactionsProvider`; `_buildAppBar()` mostra nome real do usuário (via `authControllerProvider`); bottom nav: Upload navega para `/upload`, Configurações abre bottom sheet com logout funcional, Analytics/AI Chat exibem "Em breve". `_FinancialHealthScoreCard` e `_SpendingHeatmapWidget` permanecem mock (fora do escopo — dependem de Analytics API real).
- `frontend/pubspec.yaml` — adicionada dependência `http_parser: ^4.0.2` (necessária para `MultipartFile` com `contentType` explícito no upload).

### Decisões arquiteturais tomadas
- **Sem codegen (ver acima)** — Riverpod clássico + `fromJson`/`toJson` manuais em toda `data/`.
- **Camada `domain/` pulada** para `transactions`/`upload` — providers consomem repositórios concretos diretamente (sem abstrações/use cases intermediários), documentado como simplificação temporária dado o escopo de validação visual.
- **`SessionExpiredNotifier extends ChangeNotifier`** como ponte entre `core/network` e `features/auth`, evitando import circular (`AuthInterceptor` não pode depender de `auth_provider.dart` diretamente).
- **JWT decodificado manualmente** (`jwt_utils.dart::decodeJwtPayload`) para extrair o claim `sub` quando não há endpoint `/users/me` — evita dependência de pacote JWT extra.
- **`NumberFormat.currency(locale: 'pt_BR', symbol: 'R$')`** (pacote `intl`) em vez de `DateFormat` com locale pt_BR, para não precisar chamar `initializeDateFormatting()`; datas formatadas com helpers manuais (`_formatDate`/`_relativeDate`).
- **`categoryUiFor()`** centraliza o mapeamento categoria→(label PT-BR, ícone, cor), reusado em dashboard, transações e resumo.
- **Ícones de Receitas/Despesas padronizados**: `arrow_upward_rounded` (Receitas) / `arrow_downward_rounded` (Despesas) em todas as telas — corrigida inconsistência encontrada em `summary_screen.dart` durante a revisão final.

### Validação executada
- **Revisão manual de consistência** em ~28 arquivos (24 novos + 4 atualizados): nomes de campos em `data/models/*.fromJson` cruzados contra os schemas Pydantic do backend (`schemas/transaction.py`, `schemas/upload.py`, `schemas/user.py`); tipos e getters de providers/repositórios/telas conferidos; `Grep` confirmou ausência de referências residuais a mocks antigos (`_MockTransaction`, `_transactions`, `_categories`, `Navigator.push`, `TODO`).
- **Nenhum comando do Flutter SDK foi executado** (`pub get`, `create`, `analyze`, `test`, `run`) — SDK indisponível neste ambiente. **Checklist para a próxima sessão**:
  ```bash
  cd frontend
  flutter pub get
  flutter create .          # gera scaffold de plataforma (windows/android/web), preservando lib/ e pubspec.yaml
  flutter analyze            # primeira validação do compilador Dart sobre os ~24 arquivos novos
  flutter test                # nenhum teste escrito ainda — espera-se "no tests found"
  flutter run -d windows      # smoke test visual do fluxo login → upload → transações → resumo
  ```

### Critérios de sucesso da sessão
- ✅ Login real conectado ao backend (`POST /auth/login`)
- ✅ Registro real conectado ao backend (`POST /auth/register`)
- ✅ Persistência do JWT (`flutter_secure_storage`, restauração de sessão via `tryRestoreSession()`)
- ✅ Tela de Upload PDF conectada a `POST /api/v1/uploads/pdf`
- ✅ Tela de Transações consumindo `GET /api/v1/transactions/` (com filtros/busca/paginação)
- ✅ Tela de Summary consumindo `GET /api/v1/transactions/summary`
- ✅ Tratamento de loading e erros (`AsyncValue.when` em todas as telas conectadas, `ApiException` com mensagens PT-BR)
- ✅ Logout funcional (limpa tokens, `AuthStatus.unauthenticated`, redireciona para `/login`)
- ✅ Nenhuma funcionalidade fora do escopo (IA, Open Finance, Analytics avançado, Forecast, novas rotas de backend) implementada
- ⏳ **Validação ponta a ponta em runtime** ainda pendente — depende de `flutter pub get`/`analyze`/`run` (Fase 4.5, próxima sessão)
