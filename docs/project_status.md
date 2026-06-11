# Financily — Status do Projeto

> Auditoria técnica completa. Última atualização: 2026-06-11.
> Branch: `master` · Commits: `2639e79` (arquitetura inicial) → `6782076` (preview HTML + docs)

---

## 1. Estrutura real do projeto

```
financily/
├── CLAUDE.md
├── README.md
├── Prompt Inicial.txt                 (não versionado)
├── .claude/settings.local.json        (não versionado)
├── docs/
│   └── preview.html                   ✅ protótipo HTML estático (820 linhas, 5 telas)
│
├── backend/
│   ├── requirements.txt               ✅
│   └── app/
│       ├── main.py                    ⚠️ importa módulos inexistentes (não sobe)
│       ├── core/
│       │   └── config.py              ✅ Settings (pydantic-settings)
│       ├── models/
│       │   └── transaction.py         ⚠️ referencia User/Upload inexistentes
│       ├── services/
│       │   ├── pdf/extractor.py       ✅ pipeline pdfplumber → OCR
│       │   ├── ai/categorizer.py      ✅ regras + pipeline ML (não treinado)
│       │   └── analytics/health_score.py ✅ score 0–100
│       ├── api/v1/routes/             ❌ vazio (6 routers faltando)
│       ├── repositories/              ❌ vazio
│       ├── schemas/                   ❌ vazio
│       ├── middleware/                ❌ vazio
│       ├── migrations/                ❌ vazio (sem alembic.ini)
│       └── tests/{unit,integration}/  ❌ vazio
│
└── frontend/
    ├── pubspec.yaml                   ⚠️ refs fontes inexistentes
    ├── assets/{fonts,images}/         ❌ vazio
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

**Atenção:** o projeto Flutter **não tem scaffold de plataforma** — não existem pastas `android/`, `ios/`, `windows/`, `macos/`, `web/`, `linux/`, `test/`, nem `.metadata`/`analysis_options.yaml`. Ou seja, `flutter create` nunca foi executado neste diretório. `flutter pub get` pode funcionar, mas `flutter run`/`flutter build` para qualquer plataforma falharão até o scaffold ser gerado.

---

## 2. Tecnologias e dependências

**Backend** (Python 3.12, `requirements.txt`): FastAPI 0.111, Uvicorn, SQLAlchemy 2.0 (async/asyncpg), Alembic, Pydantic v2 + pydantic-settings, python-jose + passlib (JWT/bcrypt), pdfplumber, PyMuPDF (`fitz`), pytesseract, Pillow, pandas, numpy, scikit-learn, prophet, nltk, joblib, httpx (duplicado — linhas 37 e 49), pytest/pytest-asyncio/pytest-cov/faker.

**Frontend** (Flutter ≥3.3, `pubspec.yaml`): flutter_riverpod, riverpod_annotation, go_router, dio, retrofit, flutter_secure_storage, sqflite, hive_flutter, file_picker, desktop_drop, path_provider, fl_chart, google_fonts, shimmer, lottie, flutter_animate, cached_network_image, intl, freezed, json_serializable, dartz, logger, mockito.

> Quase todas as dependências do Flutter (exceto `flutter_riverpod`, `go_router`, `google_fonts` parcialmente) estão **declaradas mas não usadas** em nenhum arquivo `.dart` ainda.

---

## 3. Funcionalidades já implementadas (código real e funcional isoladamente)

| Item | Local | Observação |
|---|---|---|
| Design tokens + tema dark | `frontend/lib/core/theme/app_theme.dart` | `AppColors` consistente com `docs/preview.html` |
| Tela de Login (UI) | `login_screen.dart` | Glassmorphism, animação fade-in; login é mock (`Future.delayed`) |
| Tela de Dashboard (UI) | `dashboard_screen.dart` | 944 linhas: saldo, health score (custom painter), heatmap, pizza de categorias (custom painter), transações recentes — tudo com dados estáticos mock |
| Roteamento | `app_router.dart` | GoRouter com 2 rotas (`/login`, `/dashboard`) |
| Pipeline de extração de PDF | `services/pdf/extractor.py` | pdfplumber (tabelas) → fallback PyMuPDF+Tesseract OCR; normalização de data/valor BR; hash SHA-256 para dedupe |
| Parser Itaú | `_parse_itau_row` | Implementado |
| Categorizador (regras) | `services/ai/categorizer.py` | 10 categorias, dicionário de keywords PT-BR, confiança 0.95 |
| Categorizador (ML) | idem | Pipeline TF-IDF + LogisticRegression com `train()`/`save`/`load` |
| Health Score | `services/analytics/health_score.py` | 4 dimensões (controle 30% / economia 30% / previsão 25% / dívida 15%), labels PT-BR |
| Modelo `Transaction` | `models/transaction.py` | Enums de tipo/categoria, campos de parcelamento, hash único |
| Configuração | `core/config.py` | `Settings` via pydantic-settings |
| Protótipo navegável | `docs/preview.html` | 5 telas (Dashboard, Upload, Analytics, AI Chat, Config), animações JS |

---

## 4. Funcionalidades parcialmente implementadas

| Item | Status | Pendência |
|---|---|---|
| Backend API (`main.py`) | Skeleton pronto, registra 6 routers | **Nenhum dos 6 routers existe** → app não inicia |
| Banco de dados | Modelo `Transaction` existe | Falta `database.py` (engine/session/Base), e os modelos `User`/`Upload` referenciados via `relationship`/`ForeignKey` não existem → SQLAlchemy vai falhar ao configurar mappers |
| Parser Santander | Função existe | `_parse_santander_row` apenas chama `_parse_itau_row` — placeholder, comentário admite "refine per bank spec" |
| OCR | Pipeline codificado | Regex genérico único, não testado contra OCR real; `bank` recebido mas não usado |
| Categorizador ML | Pipeline completo | `train()` nunca é chamado; sem `categorizer.joblib` (gitignored) → sempre cai em regras ou `OTHER/0.0` |
| Roteamento Flutter | Funciona | `redirect` é `// TODO`; só 2 telas de 8+ planejadas |
| Login | UI completa | `_login()` não chama nenhum provider/API real |
| Projeto Flutter | `pubspec.yaml` rico | Sem scaffold de plataforma; fontes `Syne-*.ttf` referenciadas mas ausentes em `assets/fonts/` |

---

## 5. Funcionalidades planejadas, não iniciadas

- **Auth**: registro/login/refresh/logout, hashing, emissão JWT
- **Upload de PDF**: endpoint + SSE de progresso + tela Flutter
- **Transactions API**: list/filter/paginate/summary/CRUD
- **Analytics API**: dashboard payload, heatmap, categorias, forecast, health-score, behavioral, subscriptions
- **Previsão (Prophet)**: zero código
- **Análise comportamental** (anomaly detection, clustering): zero código
- **Detecção de assinaturas recorrentes**: zero código
- **Assistente IA** (chat): router referenciado mas inexistente; só mock estático no preview.html
- **Exportação PDF/Excel/CSV**: routers inexistentes; **faltam libs** (ex.: `openpyxl`, `reportlab`/`weasyprint`) no requirements
- **Notificações**: nenhum código
- **Tela de Configurações** (Flutter): pasta nem existe
- **Repositories / Schemas**: pastas vazias
- **Alembic**: sem `alembic.ini`/`env.py`/migrations
- **Testes**: zero testes apesar de pytest configurado
- **Multi-plataforma**: scaffold Flutter ausente

---

## 6. Problemas encontrados (bloqueadores)

1. 🔴 **`backend/app/main.py` não inicia** — importa `app.core.database` e `app.api.v1.routes.{auth,transactions,uploads,analytics,reports,assistant}`, nenhum existe. `uvicorn app.main:app` falha com `ModuleNotFoundError` imediato.
2. 🔴 **`models/transaction.py` quebrado** — `relationship("User", ...)`, `relationship("Upload", ...)`, `ForeignKey("users.id")`, `ForeignKey("uploads.id")` apontam para modelos inexistentes. `configure_mappers()` falhará assim que qualquer tabela for tocada.
3. 🔴 **Projeto Flutter sem scaffold de plataforma** — falta `flutter create .` (preservando `lib/`, `pubspec.yaml`, `assets/`).
4. 🟠 `pubspec.yaml` referencia `Syne-Regular.ttf`, `Syne-Bold.ttf`, `Syne-ExtraBold.ttf` em `assets/fonts/`, pasta vazia → build falha por asset ausente.
5. 🟠 Sem `.env.example`, embora README/CLAUDE.md instruam `cp .env.example .env`.
6. 🟠 Sem `alembic.ini`/`versions/`, apesar de `alembic` no requirements e pasta `migrations/` existir vazia.
7. 🟡 Pacotes `backend/app/**` sem `__init__.py` (namespace packages implícitos — funciona, mas é inconsistente).
8. 🟡 `httpx==0.27.0` duplicado em `requirements.txt` (linhas 37 e 49).

---

## 7. Código morto / duplicado / não utilizado

- `httpx` duplicado no requirements.
- `_parse_santander_row` é cópia funcional de `_parse_itau_row` (placeholder, não "morto" mas redundante).
- Quase toda a árvore de dependências do `pubspec.yaml` (Hive, sqflite, Retrofit, Freezed, dartz, lottie, shimmer, etc.) — declaradas, zero uso.
- `prophet`, `nltk`, `numpy`, `python-jose`, `passlib` no requirements — zero referências no código atual.
- Volume grande de diretórios vazios criados como scaffold (esperado para arquitetura futura, mas vale lembrar que não são "funcionalidades" prontas).

---

## 8. Riscos arquiteturais

- Backend não sobe → bloqueia qualquer integração incremental.
- Ordem de dependência: `Transaction` precisa que `User` e `Upload` existam primeiro.
- Sem `repositories/`/`schemas/`, há risco de violar a regra do CLAUDE.md ("services never query SQLAlchemy directly") se rotas forem criadas apressadamente.
- Categorizador ML depende de artefato `.joblib` não versionado — sem pipeline de treino real, fica permanentemente em modo "regras".
- OCR depende de Tesseract instalado no SO (`TESSERACT_CMD`), sem verificação/tratamento se ausente.
- Flutter sem scaffold = primeira tentativa de `flutter run` vai falhar.
- Zero testes automatizados = sem rede de segurança para regressões futuras.

---

## 9. Débitos técnicos

- [ ] Criar `core/database.py` (engine async + sessionmaker + `Base` + `get_db`)
- [ ] Criar modelos `User` e `Upload`, completar relationships do `Transaction`
- [ ] Criar `schemas/` (Pydantic, separados do ORM)
- [ ] Criar `repositories/` (UserRepository, TransactionRepository, UploadRepository)
- [ ] Setup Alembic (init async, primeira migration)
- [ ] `.env.example` com todas as vars do CLAUDE.md
- [ ] `__init__.py` nos pacotes Python (decisão deliberada)
- [ ] Remover duplicata `httpx` do requirements
- [ ] Testes unitários para `extractor.py`, `categorizer.py`, `health_score.py` (lógica pura — fácil de começar)
- [ ] `flutter create .` para gerar scaffold de plataforma
- [ ] Resolver fontes `Syne` (adicionar `.ttf` ou usar `google_fonts.GoogleFonts.syne()`)

---

## 10. Possíveis gargalos de performance

- OCR a 300 DPI por página via Tesseract — caro para faturas longas; sem paralelismo/cache.
- `health_score` recria `pandas.DataFrame` a cada chamada — ok em escala pequena, revisar se virar hot path.
- Falta de paginação especificada nos endpoints de transações planejados.
- Único índice definido é `hash` (unique); `user_id`, `date`, `category` provavelmente precisarão de índices para queries de dashboard/analytics.

---

## 11. Possíveis problemas de segurança

- `SECRET_KEY` tem default inseguro (`"change-me-in-production"`) — precisa validação obrigatória via env em produção.
- CORS default permite apenas `localhost` — revisar antes de produção.
- Upload ainda não existe — ao criar, validar tipo/tamanho de arquivo e processar 100% em memória (requisito LGPD do CLAUDE.md).
- `raw_text` no modelo `Transaction` — confirmar que armazena apenas a linha extraída, nunca o PDF completo.
- Nenhum rate limiting / proteção brute-force planejado para auth ainda.

---

## 12. Status por módulo (MVP)

| Módulo | Status |
|---|---|
| Autenticação | ❌ Não iniciado (UI mock apenas) |
| Dashboard | 🟡 Em desenvolvimento (UI completa + mock; sem backend) |
| Upload de PDFs | ❌ Não iniciado |
| Parser de faturas (Itaú) | 🟡 Em desenvolvimento (lógica existe, não testada/integrada) |
| Parser de extratos (Santander) | ❌ Não iniciado (stub = cópia do Itaú) |
| OCR | 🟡 Em desenvolvimento (pipeline codificado, não validado) |
| Banco de dados | ❌ Não iniciado (sem `database.py`/engine; model quebrado) |
| API | ❌ Não iniciado (app não sobe) |
| Categorização automática | 🟡 Em desenvolvimento (regras prontas; ML não treinado) |
| Previsão financeira | ❌ Não iniciado |
| Assistente IA | ❌ Não iniciado (mock apenas no preview.html) |
| Exportação PDF | ❌ Não iniciado |
| Exportação Excel | ❌ Não iniciado |
| Exportação CSV | ❌ Não iniciado |
| Notificações | ❌ Não iniciado |
| Configurações | ❌ Não iniciado |
| Design System | 🟡 Em desenvolvimento (tokens definidos e usados; fontes faltando) |
| Responsividade | ❌ Não verificado (telas mobile-first apenas) |
| Multi plataforma | ❌ Não iniciado (scaffold Flutter ausente) |

---

## 13. Próximos passos recomendados (ordem ideal)

1. **Desbloquear o backend** (prioridade máxima — sem isso nada mais é testável):
   - `core/database.py` (engine async + `Base` + `get_db`)
   - Modelos `User` e `Upload`
   - `.env.example`
   - Setup Alembic + migration inicial
2. **Camada de persistência mínima**: `schemas/` + `repositories/` (User, Transaction, Upload)
3. **Auth real**: `api/v1/routes/auth.py` (register/login/refresh) + JWT
4. **Stubs dos demais routers** (`uploads`, `transactions`, `analytics`, `assistant`, `reports`) — mesmo que retornem placeholder, para `main.py` importar sem erro e `/api/docs` subir
5. **Validar boot**: `uvicorn app.main:app --reload` sem erros
6. **Frontend — desbloquear scaffold**: `flutter create .` preservando `lib/`/`pubspec.yaml`/`assets/`; resolver fontes Syne
7. **Conectar dashboard real**: `core/network/` (Dio + interceptor) + endpoint `/analytics/dashboard`
8. **Upload de PDF end-to-end**: endpoint + parser Itaú + categorizer + tela Flutter
9. **Parser Santander real** (substituir stub)
10. **Testes**: começar pelos módulos puros (`extractor`, `categorizer`, `health_score`)

---

## 14. Estimativa de conclusão

**~8–10% do escopo total** descrito no `README.md`/`Prompt Inicial.txt`.

O que existe é majoritariamente: (a) arquitetura/scaffold de pastas, (b) 3 módulos de domínio isolados e bem escritos (extractor, categorizer, health score), (c) 2 telas de UI Flutter mockadas, (d) 1 protótipo HTML estático. A camada de integração (DB, API, repositórios, auth) — que é o que conecta tudo — ainda não existe, e é also o que o `main.py` já espera encontrar.
