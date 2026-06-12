# Financily — Memória de Continuidade

> Gerado em 2026-06-12, ao final da sessão "Fase 4 — Conexão Frontend-Backend".
> A sessão anterior ("Fase 3 — Transactions API completa", commits `7b5f37c`/`f642155`) está documentada em "Última Sessão — Fase 3" de `docs/project_status.md`. O histórico desta sessão está em "Última Sessão — Fase 4" no mesmo arquivo.
>
> **Antes de iniciar qualquer trabalho, siga `docs/session_start.md`.** Ao encerrar, siga `docs/session_end.md`. Regras permanentes de governança (CTO permanente) estão em `CLAUDE_PROJECT_RULES.md` (raiz do projeto).

---

# Onde paramos

A Fase 4 (Conexão Frontend-Backend) está **completa do ponto de vista de código**: o Flutter agora tem `core/network/` (Dio + `AuthInterceptor` com refresh automático em 401), login e registro reais (`/api/v1/auth/*`), JWT persistido via `flutter_secure_storage` com restauração de sessão, upload de PDF real (`POST /uploads/pdf`), tela de transações consumindo `GET /transactions/` (filtros/busca/paginação), tela de resumo consumindo `GET /transactions/summary`, dashboard parcialmente conectado (saldo, receitas/despesas, pizza de categorias, transações recentes) e logout funcional. Roteamento via `GoRouter` com `redirect` reativo baseado em `AuthStatus` (8 telas: splash/login/registro/dashboard/upload/transações/resumo).

**Decisão explícita do usuário**: nesta fase, **sem codegen** — toda a camada `data/` usa `fromJson`/`toJson` manuais e os providers usam Riverpod clássico (`Provider`/`StateNotifierProvider`/`FutureProvider.autoDispose`), sem `freezed`/`build_runner`/`@riverpod`. Documentado como débito técnico temporário em `docs/project_status.md` §8/§9.

**O que falta para considerar a Fase 4 validada de fato**: **nenhum comando do Flutter SDK foi executado** (`pub get`, `create`, `analyze`, `test`, `run`). Todo o código novo (~24 arquivos) foi escrito e revisado manualmente (consistência de imports/tipos/campos contra os schemas Pydantic do backend), mas erros de compilação Dart só serão conhecidos quando esses comandos rodarem. **Isso é o objetivo #1 da próxima sessão (Fase 4.5)**.

O backend **não foi alterado** nesta sessão (segue com 25 rotas, 49/49 testes passando, Fase 3 completa). Analytics/assistant/reports continuam stubs `501`.

---

# O que já funciona

### Backend (inalterado desde a Fase 3)
- `uvicorn app.main:app --reload --port 8000` sobe sem erros, 25 rotas registradas.
- `POST /api/v1/auth/register` → 201, valida e-mail único, hash de senha com bcrypt.
- `POST /api/v1/auth/login` (OAuth2 form: `username`/`password`) → par de tokens JWT (access 15min, refresh 30d).
- `POST /api/v1/auth/refresh` → valida claim `type=="refresh"`, emite novo par.
- `POST /api/v1/uploads/pdf` → recebe PDF, extrai, categoriza, persiste com dedupe, retorna `UploadResult`.
- `GET /api/v1/uploads/` → listagem real, protegida por JWT.
- `GET /api/v1/transactions/` → paginação, filtros (`date_from`/`date_to`/`category`/`type`), busca (`search`), ordenação (`sort_by`/`order`).
- `GET /api/v1/transactions/summary` → `{total_income, total_expenses, balance, transaction_count, by_category, date_from, date_to}`.
- `PATCH /api/v1/transactions/{id}` → corrige `category`/`subcategory`, seta `confidence_score=1.0`; 404 se não for do usuário.
- `DELETE /api/v1/transactions/{id}` → `204`; 404 se não for do usuário.
- `GET /api/v1/analytics/*`, `POST /api/v1/assistant/chat`, `POST /api/v1/reports/*` → `501 Not Implemented` (esperado, contrato documentado).
- `alembic upgrade head` / `alembic downgrade base` → cria/destrói schema completo.
- `pytest backend/tests/ -v` → **49/49 testes passando**.
- `backend/.env.example` documenta todas as vars necessárias; `requirements.txt` sem duplicatas.

### Frontend (NOVO nesta sessão — validado por revisão manual, NÃO por `flutter analyze`/`run`)
- `core/network/`: `dio_client.dart`, `auth_interceptor.dart` (Bearer + refresh-and-retry em 401), `token_storage.dart` (`flutter_secure_storage`), `providers.dart` (`SessionExpiredNotifier`), `api_exception.dart` (mensagens PT-BR), `api_config.dart` (`baseUrl = 'http://127.0.0.1:8000'`).
- `core/utils/jwt_utils.dart` — decodifica claim `sub` do JWT manualmente.
- Login (`login_screen.dart`) e Registro (`register_screen.dart`) conectados a `authControllerProvider` → `/api/v1/auth/*`.
- Persistência de sessão: `tryRestoreSession()` + `SplashScreen` (`AuthStatus.unknown` enquanto restaura).
- Upload (`upload_screen.dart`) → `POST /api/v1/uploads/pdf` via `file_picker` + `Dio.MultipartFile` (pacote `http_parser` adicionado ao `pubspec.yaml`).
- Transações (`transactions_screen.dart`) → `GET /api/v1/transactions/` com filtros/busca/paginação.
- Resumo (`summary_screen.dart`) → `GET /api/v1/transactions/summary` (totais + breakdown por categoria).
- Dashboard (`dashboard_screen.dart`) → saldo, receitas/despesas, pizza de categorias (top-5 + "Outros") e transações recentes consomem dados reais; `_FinancialHealthScoreCard`/`_SpendingHeatmapWidget` permanecem mock.
- Logout funcional (bottom sheet de Configurações no dashboard).
- `app_router.dart` → `GoRouterRefreshListenable` + `redirect` por `AuthStatus`, 7 rotas (`/splash`, `/login`, `/register`, `/dashboard`, `/upload`, `/transactions`, `/summary`).

---

# O que ainda não funciona

- **`flutter pub get`/`create`/`analyze`/`test`/`run` nunca executados** — prioridade #1 da próxima sessão (Fase 4.5). Pode haver erros de compilação nos ~24 arquivos novos não detectados pela revisão manual.
- **Decisão de codegen (`freezed`/`json_serializable`/`riverpod_generator`/`build_runner`)** — adiada até `flutter analyze`/`flutter test` rodarem com sucesso.
- **Scaffold de plataforma Flutter** — `flutter create .` nunca executado; `flutter run`/`build` falham até então.
- **Analytics API** — todos os 7 endpoints são stubs `501` (incluindo `health-score`, que já tem lógica pronta em `services/analytics/health_score.py`). `_FinancialHealthScoreCard`/`_SpendingHeatmapWidget` no dashboard Flutter dependem disso.
- **Assistente IA** — stub `501`; tela "AI Chat" no Flutter é placeholder "Em breve".
- **Exportação PDF/Excel/CSV** — stubs `501`; faltam libs (`openpyxl`, `reportlab`/`weasyprint`).
- **Categorizador ML** — `train()` nunca chamado, sem `categorizer.joblib`. Correções via `PATCH /transactions/{id}` ainda não alimentam um dataset de retreino.
- **Parser Santander** — `_parse_santander_row` ainda é cópia de `_parse_itau_row` (placeholder).
- **Fixtures de PDF reais** — `backend/tests/fixtures/` não existe; `_try_pdfplumber`/`_try_ocr` nunca exercitados por PDF real.
- **SSE de progresso** — `POST /uploads/pdf` é síncrono.
- **PostgreSQL real** — Alembic só validado em SQLite + `--sql` offline para Postgres.
- **`GET /transactions/{id}`** (detalhe de uma transação) — não existe no backend nem no Flutter.
- **Endpoint de criação manual de transação** — não existe; criação real é só via `POST /uploads/pdf`.
- **Testes Flutter** — zero (`flutter test` deve retornar "no tests found" até serem escritos).
- **Testes backend para `categorizer.py`, `health_score.py`, `core/security.py`, repositories de user/upload, rotas de auth** — ainda zero.
- **`prophet`/`nltk`** — em `requirements.txt`, não instalados; deferidos para forecast/behavioral.

---

# Próximo objetivo

**Fase 4.5 — Validar o ambiente Flutter** (bloqueia tudo o que depende do frontend): rodar `flutter pub get && flutter create . && flutter analyze && flutter test && flutter run -d windows`, corrigir qualquer erro de compilação encontrado nos ~24 arquivos novos da Fase 4, e então **decidir** se vale migrar para codegen (`freezed`/`riverpod_generator`/`build_runner`) ou manter o padrão clássico/manual.

Em paralelo (sem dependência), o backend pode avançar com **Analytics API real** (`/analytics/health-score`, `/analytics/dashboard`) — ver "Próximo módulo recomendado" abaixo.

---

# Próximo módulo recomendado

**Opção A (recomendada — prioridade, desbloqueia o resto do frontend): Validar SDK Flutter (Fase 4.5)**

```bash
cd frontend
flutter pub get
flutter create .          # gera scaffold de plataforma (windows/android/web), preservando lib/ e pubspec.yaml — PEDIR CONFIRMAÇÃO ANTES
flutter analyze            # primeira validação do compilador Dart sobre os ~24 arquivos novos da Fase 4
flutter test                # nenhum teste escrito ainda — espera-se "no tests found"
flutter run -d windows      # smoke test visual: login → upload → transações → resumo
```

Corrigir erros de `flutter analyze` (provavelmente imports, tipos `dynamic` em `fromJson`, nullability). Após `analyze`/`test` passarem, decidir com o usuário se migra para codegen — se sim, planejar a migração como sessão dedicada (não misturar com novas features).

**Requer confirmação explícita do usuário antes de `flutter create .`** — pode sobrescrever/mesclar arquivos existentes em `lib/`/`pubspec.yaml`/`assets/`.

**Alternativa independente (Opção B): Analytics API real**

`backend/app/api/v1/routes/analytics.py` + conectar `services/analytics/health_score.py`. Implementar `/analytics/health-score` (lógica já pronta) e `/analytics/dashboard` (reaproveitar `TransactionRepository.get_summary()`). 100% backend, mesmo padrão `routes` → `repositories`/`services` já validado. Depois de pronta, conectar `_FinancialHealthScoreCard`/`_SpendingHeatmapWidget` no Flutter (depende da Opção A já ter sido feita, para não compilar em cima de um SDK não validado).

> A Opção A é prioritária porque toda a Fase 4 está com risco de compilação desconhecido. A Opção B não depende da Opção A e pode ser feita em paralelo/antes se o Flutter SDK não estiver disponível na próxima sessão também.

---

# Ordem recomendada para desenvolvimento

1. ✅ ~~Upload de PDF end-to-end~~ — concluído (Fase 2).
2. ✅ ~~Transactions API completa~~ — concluído (Fase 3).
3. ✅ ~~Conectar Flutter ao backend~~ — concluído (Fase 4, esta sessão).
4. **Validar SDK Flutter** (Fase 4.5, Opção A) — `pub get`/`create`/`analyze`/`test`/`run`, corrigir erros, decidir codegen.
5. **Analytics API real** (Opção B) — `/analytics/health-score`, `/analytics/dashboard`; depois conectar `_FinancialHealthScoreCard`/`_SpendingHeatmapWidget`.
6. **Categorizador ML** — treinar com dados reais; considerar correções manuais (`PATCH /transactions/{id}`) como dataset.
7. **Parser Santander real** — substituir o stub que hoje é cópia do parser Itaú.
8. **Fixtures de PDF reais** — gerar/coletar PDFs de teste (Itaú/Santander) para `backend/tests/fixtures/`, testar `_try_pdfplumber`/`_try_ocr` ponta a ponta.
9. **Forecast (Prophet) + análise comportamental** — após volume real de transações.
10. **Testes automatizados restantes** — backend (`core/security.py`, repositories de user/upload, rotas de auth, `categorizer.py`, `health_score.py`) e Flutter (zero hoje).
11. **Validar Alembic contra PostgreSQL real** — antes do primeiro deploy.
12. **Hardening de produção** — rate limiting/auth, CORS para produção, CI (`.github/workflows/`), exportações PDF/Excel/CSV, notificações, assistente IA, SSE de progresso para upload.

> Esta ordem corresponde às Fases 4.5–6 do roadmap em `docs/project_status.md` §15 ("Roadmap Atualizado").

---

# Dependências para a próxima sessão

- `backend/venv/` já tem **todas** as deps de PDF/IA/teste instaladas — 49/49 testes passando, `bcrypt==4.0.1` intocado. Backend não precisa de nenhuma ação adicional para a Opção B.
- **Flutter SDK**: precisa estar instalado e no `PATH` para a Opção A (`flutter --version` deve funcionar). Se não estiver disponível, seguir direto para a Opção B.
- `flutter pub get` (instala `http_parser` e demais deps já em `pubspec.yaml`) → depois `flutter create .` — **confirmar com o usuário antes** do `create .`.
- `prophet`/`nltk` ainda **não instalados** — não bloqueiam Opções A/B; instalar só na fase de forecast/behavioral.
- **Sem PostgreSQL local**: continuar usando SQLite via override de `DATABASE_URL`, ou subir Postgres local (Docker) para validar a migration contra o dialeto real.
- Se for testar OCR real: `TESSERACT_CMD` precisa apontar para um Tesseract instalado no Windows.

---

# Arquivos mais importantes para revisar

| Arquivo | Por quê |
|---|---|
| `CLAUDE_PROJECT_RULES.md` | Regras permanentes de governança — ler antes de qualquer decisão técnica |
| `docs/session_start.md` | Procedimento obrigatório de início de sessão |
| `docs/session_end.md` | Procedimento obrigatório de encerramento de sessão |
| `frontend/pubspec.yaml` | Conferir deps antes de `flutter pub get`; `http_parser` foi adicionado nesta sessão |
| `frontend/lib/core/network/` | Camada de rede nova (Dio, interceptor, token storage, exceptions) — primeiro lugar a checar se `flutter analyze` falhar em rede/auth |
| `frontend/lib/core/router/app_router.dart` | `GoRouterRefreshListenable` + `redirect` por `AuthStatus` — 7 rotas |
| `frontend/lib/features/auth/presentation/providers/auth_provider.dart` | `AuthController`/`AuthState`/`AuthStatus` — núcleo do fluxo de sessão |
| `frontend/lib/features/transactions/` | Modelos/providers/telas de transações e resumo — maior volume de código novo |
| `frontend/lib/features/upload/presentation/screens/upload_screen.dart` | Upload real via `file_picker` + Dio multipart |
| `frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Maior diff desta sessão (515 linhas) — dashboard parcialmente conectado |
| `backend/app/api/v1/routes/transactions.py` | Transactions API completa (Fase 3) — padrão de referência para Analytics (Opção B) |
| `backend/app/repositories/transaction_repository.py` | `_apply_filters`, `list_by_user`, `count_by_user`, `get_summary`, `update` — reaproveitar `get_summary` para `/analytics/dashboard` |
| `backend/app/services/analytics/health_score.py` | Lógica pronta para `/analytics/health-score` (Opção B) |
| `backend/tests/conftest.py` | Fixtures (`db_session`, `client`, `test_user`, `other_user`, `auth_headers`) — reusar para novos testes |
| `docs/project_status.md` | Status completo — "Visão Geral por Área", §8/§9 (riscos/débitos da Fase 4), §15 "Roadmap Atualizado", seção "Última Sessão — Fase 4" com todo o detalhe |

---

# Riscos conhecidos

- 🆕 **Nenhum comando do Flutter SDK foi executado nesta sessão** — `flutter analyze`/`flutter test` podem revelar erros de compilação nos ~24 arquivos novos (imports, nullability, tipos em `fromJson`). Prioridade #1 da próxima sessão.
- 🆕 **Decisão de codegen em aberto** — toda `data/` usa `fromJson`/`toJson` manuais; qualquer mudança futura de schema no backend exige editar esses arquivos em paralelo até a decisão de migração ser tomada.
- 🆕 **`_FinancialHealthScoreCard`/`_SpendingHeatmapWidget` continuam 100% mock** — sem endpoint `/analytics/*` real, não há como conectá-los ainda.
- 🆕 **`_C`/`_Grad` (tokens privados duplicados em `dashboard_screen.dart`) vs `AppColors`** — duplicidade pré-existente, não resolvida nesta sessão.
- **Migration nunca testada em PostgreSQL real** — validar no primeiro ambiente com Postgres disponível antes de confiar 100%.
- **`bcrypt` deve permanecer pinado em `4.0.1`** — `passlib==1.7.4` é incompatível com `bcrypt>=4.1` (quebra hashing de senha com `500`). Não atualizar `bcrypt` sem também atualizar/substituir `passlib`.
- **Cobertura de testes backend ainda pontual** — extractor, upload e transactions têm 49 testes, mas `core/security.py`, `categorizer.py`, `health_score.py`, repositories de user/upload e rotas de auth seguem sem rede de segurança. Frontend Flutter tem zero testes.
- **`backend/venv/` é local e não versionado** — recriar com `python -m venv venv && pip install -r requirements.txt` em nova máquina/sessão.
- **Frontend sem scaffold de plataforma** — qualquer tentativa de `flutter run`/`build` falhará até `flutter create .` ser executado (com confirmação do usuário).
- **Dedupe de transações via `transactions.hash` (unique global, não escopado por `user_id`)** — risco baixo, documentado como mecanismo oficial (regra Fintech #3), mudança exigiria nova migration + decisão explícita.
- **`TransactionRepository.create()` comita uma transação por vez** — aceitável para volumes típicos (10–100 linhas); revisar para bulk-insert apenas se virar gargalo real.
- **Caminho OCR (`_try_ocr`/Tesseract) e `_try_pdfplumber` nunca exercitados por PDF real** — testes de integração mockam `extract_transactions`.
- **`GET /transactions/` faz `SELECT` + `COUNT` separados** para montar `total` — duplica custo de leitura por requisição; aceitável para volumes do MVP.
- **`PATCH /transactions/{id}` sempre seta `confidence_score=1.0` quando há mudança** — assume que toda correção manual do próprio usuário é 100% confiável.

---

# Decisões arquiteturais tomadas

### Backend (Fases 1–3, inalteradas)
1. **FK `users.id` → `ON DELETE CASCADE`** em `uploads.user_id` e `transactions.user_id` — exclusão em cascata (LGPD).
2. **FK `uploads.id` → `ON DELETE SET NULL`** em `transactions.upload_id` — preserva histórico de transações mesmo sem o upload original.
3. **JWT com claim `"type"`** (`"access"` | `"refresh"`) no mesmo `SECRET_KEY`.
4. **Schema é responsabilidade exclusiva do Alembic** — sem `Base.metadata.create_all` no lifespan.
5. **Pacotes Python explícitos** (`__init__.py` em todos os subpacotes de `app/`).
6. **Índices** em `transactions.user_id`, `transactions.upload_id`, `transactions.date`, `transactions.category`, `uploads.user_id`, `users.email`.
7. **Migration inicial usa `postgresql.UUID`/`postgresql.ENUM` explicitamente** — `downgrade()` dropa os 4 enums explicitamente.
8. **`bcrypt==4.0.1` pinado** — compatibilidade com `passlib==1.7.4`.
9. **Governança formalizada**: `CLAUDE_PROJECT_RULES.md` + `docs/session_start.md`/`docs/session_end.md`.
10. **`extract_transactions` opera em `bytes`/`BytesIO`/`fitz.open(stream=...)`** — nunca em caminho de arquivo (LGPD).
11. **`UploadResult(UploadRead)`** como schema de resposta dedicado de `POST /uploads/pdf`.
12. **Validação de banco via `Settings.SUPPORTED_BANKS`** (`["itau", "santander"]`).
13. **Estado `FAILED` (com `error_message` amigável)** em vez de erro HTTP genérico para falhas de extração.
14. **MVP síncrono para `POST /uploads/pdf` (sem SSE)**.
15. **Testes de integração do upload mockam `extract_transactions`** via `monkeypatch`.
16. **`amount` sempre positivo, sinal vem de `type`** — `get_summary()` soma por `TransactionType`, nunca pelo sinal de `amount`.
17. **`_apply_filters()` privado e compartilhado** entre `list_by_user`, `count_by_user` e `get_summary`.
18. **`.ilike()` para busca textual** — funciona em SQLite e Postgres sem branch condicional.
19. **Whitelist `SORTABLE_FIELDS`** (`date`/`amount`/`description`) para `sort_by`.
20. **`PATCH /transactions/{id}` seta `confidence_score=1.0`** quando `category`/`subcategory` é alterado.
21. **404 (não 403) em `PATCH`/`DELETE` de transação de outro usuário**.
22. **Sem `GET /transactions/{id}` e sem endpoint de criação manual** — fora do escopo solicitado.

### Frontend (Fase 4, NOVAS)
23. 🆕 **Sem codegen nesta fase** (decisão explícita do usuário) — Riverpod clássico (`Provider`/`StateNotifierProvider`/`FutureProvider.autoDispose`) + `fromJson`/`toJson` manuais em toda `data/`. Revisitar após `flutter analyze`/`flutter test` (Fase 4.5).
24. 🆕 **Camada `domain/` pulada** para `transactions`/`upload` — providers consomem repositórios concretos diretamente, sem use cases intermediários.
25. 🆕 **`SessionExpiredNotifier extends ChangeNotifier`** como ponte entre `core/network` e `features/auth`, evitando import circular.
26. 🆕 **JWT decodificado manualmente** (`jwt_utils.dart::decodeJwtPayload`) para extrair `sub` quando não há `/users/me`.
27. 🆕 **`NumberFormat.currency(locale: 'pt_BR', symbol: 'R$')`** em vez de `DateFormat` com locale pt_BR — evita `initializeDateFormatting()`; datas via helpers manuais.
28. 🆕 **`categoryUiFor()`** centraliza mapeamento categoria→(label PT-BR, ícone, cor), reusado em dashboard/transações/resumo.
29. 🆕 **Ícones padronizados**: Receitas=`arrow_upward_rounded`, Despesas=`arrow_downward_rounded` em todas as telas.
30. 🆕 **`_buildPieCategories()`**: top-5 categorias por `total.abs()` + bucket "Outros" para o restante, fração relativa à soma absoluta total — usado na pizza do dashboard.
