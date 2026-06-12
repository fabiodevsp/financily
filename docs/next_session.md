# Financily — Memória de Continuidade

> Gerado em 2026-06-12, ao final da sessão "Fase 3 — Transactions API completa".
> A sessão anterior ("Fase 2 — Upload de PDF end-to-end", commits `1c362f2`/`3ae52b5`) está documentada em "Última Sessão — Fase 2" de `docs/project_status.md`. O histórico desta sessão está em "Última Sessão — Fase 3" no mesmo arquivo.
>
> **Antes de iniciar qualquer trabalho, siga `docs/session_start.md`.** Ao encerrar, siga `docs/session_end.md`. Regras permanentes de governança (CTO permanente) estão em `CLAUDE_PROJECT_RULES.md` (raiz do projeto).

---

# Onde paramos

A Fase 3 (Transactions API completa) está **completa e validada**: `GET /api/v1/transactions/` agora suporta paginação (`skip`/`limit`), filtros (`date_from`/`date_to`/`category`/`type`), busca textual (`search` em `description`/`merchant`) e ordenação (`sort_by`/`order`), retornando `{items, total, skip, limit}`. `GET /api/v1/transactions/summary` retorna totais de receita/despesa/saldo e agregados por categoria. `PATCH /{id}` corrige `category`/`subcategory` (e seta `confidence_score=1.0`). `DELETE /{id}` remove a transação. Tudo isolado por `user_id` (404 em recursos de outro usuário).

23 novos testes de integração (`tests/integration/test_transactions.py`) passam, totalizando **49/49 testes** no projeto. O app sobe com **25 rotas registradas**.

O frontend Flutter **continua exatamente como estava** (fora de escopo): UI mock (login + dashboard), sem scaffold de plataforma, não conectado ao backend. Analytics/assistant/reports continuam stubs `501`.

---

# O que já funciona

- `uvicorn app.main:app --reload --port 8000` sobe sem erros, 25 rotas registradas.
- `POST /api/v1/auth/register` → 201, valida e-mail único, hash de senha com bcrypt.
- `POST /api/v1/auth/login` (OAuth2 form: `username`/`password`) → par de tokens JWT (access 15min, refresh 30d).
- `POST /api/v1/auth/refresh` → valida claim `type=="refresh"`, emite novo par.
- `POST /api/v1/uploads/pdf` → recebe PDF, extrai, categoriza, persiste com dedupe, retorna `UploadResult`.
- `GET /api/v1/uploads/` → listagem real, protegida por JWT.
- **`GET /api/v1/transactions/`** (NOVO) → paginação (`skip`/`limit`), filtros (`date_from`, `date_to`, `category`, `type`), busca (`search`), ordenação (`sort_by`: `date`|`amount`|`description`, `order`: `asc`|`desc`); retorna `{items, total, skip, limit}`.
- **`GET /api/v1/transactions/summary`** (NOVO) → `{total_income, total_expenses, balance, transaction_count, by_category, date_from, date_to}`, com filtro opcional de período.
- **`PATCH /api/v1/transactions/{id}`** (NOVO) → corrige `category`/`subcategory`, seta `confidence_score=1.0`; 404 se não for do usuário.
- **`DELETE /api/v1/transactions/{id}`** (NOVO) → `204`; 404 se não for do usuário.
- `GET /api/v1/analytics/*`, `POST /api/v1/assistant/chat`, `POST /api/v1/reports/*` → `501 Not Implemented` (esperado, contrato documentado).
- `alembic upgrade head` / `alembic downgrade base` → cria/destrói schema completo.
- `pytest backend/tests/ -v` → **49/49 testes passando** (18 unit + 8 integração upload + 23 integração transactions).
- `backend/.env.example` documenta todas as vars necessárias; `requirements.txt` sem duplicatas.

---

# O que ainda não funciona

- **Analytics API** — todos os 7 endpoints são stubs `501` (incluindo `health-score`, que já tem lógica pronta em `services/analytics/health_score.py`; `TransactionRepository.get_summary()`, novo, pode ser reaproveitado por `/analytics/dashboard`).
- **Assistente IA** — stub `501`.
- **Exportação PDF/Excel/CSV** — stubs `501`; faltam libs (`openpyxl`, `reportlab`/`weasyprint`).
- **Frontend ↔ Backend** — Flutter não tem `core/network/`, login/dashboard continuam mockados; não há telas de upload/transactions/summary no Flutter.
- **Scaffold Flutter** — `flutter create .` nunca executado; `flutter run`/`build` falham.
- **Categorizador ML** — `train()` nunca chamado, sem `categorizer.joblib`. Correções via `PATCH /transactions/{id}` ainda não alimentam um dataset de retreino.
- **Parser Santander** — `_parse_santander_row` ainda é cópia de `_parse_itau_row` (placeholder).
- **Fixtures de PDF reais** — `backend/tests/fixtures/` não existe; `_try_pdfplumber`/`_try_ocr` nunca exercitados por PDF real.
- **SSE de progresso** — `POST /uploads/pdf` é síncrono.
- **PostgreSQL real** — Alembic só validado em SQLite + `--sql` offline para Postgres.
- **`GET /transactions/{id}`** (detalhe de uma transação) — não foi pedido/implementado nesta fase; `PATCH`/`DELETE` operam por `id` sem endpoint de leitura individual.
- **Endpoint de criação manual de transação** — não existe; criação real é só via `POST /uploads/pdf` (testes seedam via `db_session` direto).
- **Testes para `categorizer.py`, `health_score.py`, `core/security.py`, repositories de user/upload, rotas de auth** — ainda zero.
- **`prophet`/`nltk`** — em `requirements.txt`, não instalados; deferidos para Fase 4 (forecast/behavioral).

---

# Próximo objetivo

Com upload (Fase 2) e Transactions API (Fase 3) prontos no backend, o próximo ciclo "fundação → feature de valor visível" (Fase 4 do roadmap em `docs/project_status.md` §15) é: **conectar o Flutter ao backend** (tornando o produto utilizável por um humano de ponta a ponta) e/ou **expor Analytics real** (`/analytics/health-score`, `/analytics/dashboard`) reaproveitando `health_score.py` e o novo `TransactionRepository.get_summary()`.

---

# Próximo módulo recomendado

**Opção A (recomendada — maior valor visível): Conectar Flutter ao backend**

`frontend/lib/core/network/` (Dio + interceptor de refresh token) + telas de login/registro reais consumindo `/api/v1/auth/*`, mais uma tela simples de upload (`POST /uploads/pdf`) e/ou lista de transações (`GET /transactions/`, já com paginação/filtros prontos no backend). Esta é a primeira oportunidade real de ver o produto funcionando ponta a ponta (humano → Flutter → backend → Postgres/SQLite).

**Por quê este e não outro**: o backend agora tem 3 módulos de domínio prontos (auth, upload, transactions) que o Flutter pode consumir sem mudanças adicionais. Conectar o frontend valida o contrato de API real (não apenas via `/api/docs`) e destrava feedback visual sobre UX antes de investir em Analytics/ML.

**Requer confirmação do usuário**: em algum momento será necessário `flutter create .` (gera scaffold de plataforma) — **pedir confirmação explícita antes**, pois pode sobrescrever/mesclar arquivos existentes em `lib/`/`pubspec.yaml`/`assets/`.

**Alternativa igualmente válida (Opção B): Analytics API real**

`backend/app/api/v1/routes/analytics.py` + conectar `services/analytics/health_score.py`. Implementar `/analytics/health-score` (lógica já pronta, só falta orquestrar com dados reais de `transactions`) e `/analytics/dashboard` (pode reaproveitar `TransactionRepository.get_summary()` da Fase 3). 100% backend, sem dependência do Flutter, mesmo padrão já validado (`routes` → `repositories`/`services`).

> Ambas são independentes. A Opção A não depende da Opção B (mas o dashboard do Flutter, depois, vai querer Analytics real). A Opção B não depende do Flutter.

---

# Ordem recomendada para desenvolvimento

1. ✅ ~~Upload de PDF end-to-end~~ — concluído (Fase 2).
2. ✅ ~~Transactions API completa~~ — concluído (Fase 3).
3. **Conectar Flutter ao backend** (Opção A) — `core/network/`, login/dashboard/upload/transactions reais, e só então `flutter create .`.
4. **Analytics API real** (Opção B) — `/analytics/health-score`, `/analytics/dashboard`.
5. **Categorizador ML** — treinar com dados reais; considerar correções manuais (`PATCH /transactions/{id}`) como dataset.
6. **Parser Santander real** — substituir o stub que hoje é cópia do parser Itaú.
7. **Fixtures de PDF reais** — gerar/coletar PDFs de teste (Itaú/Santander) para `backend/tests/fixtures/`, testar `_try_pdfplumber`/`_try_ocr` ponta a ponta.
8. **Forecast (Prophet) + análise comportamental** — após volume real de transações.
9. **Testes automatizados restantes** — `core/security.py`, repositories de user/upload, rotas de auth, `categorizer.py`, `health_score.py`.
10. **Validar Alembic contra PostgreSQL real** — antes do primeiro deploy.
11. **Hardening de produção** — rate limiting/auth, CORS para produção, CI (`.github/workflows/`), exportações PDF/Excel/CSV, notificações, assistente IA, SSE de progresso para upload.

> Esta ordem corresponde às Fases 4–6 do roadmap em `docs/project_status.md` §15 ("Roadmap Atualizado").

---

# Dependências para a próxima sessão

- `backend/venv/` já tem **todas** as deps de PDF/IA/teste instaladas — confirmado novamente nesta sessão, 49/49 testes passando. `bcrypt==4.0.1` permanece intocado.
- `prophet`/`nltk` ainda **não instalados** — não bloqueiam Opção A nem B; instalar só na Fase 4 (forecast/behavioral).
- **Sem PostgreSQL local**: continuar usando SQLite via override de `DATABASE_URL`, ou subir Postgres local (Docker) para validar a migration contra o dialeto real.
- Para Opção A (Flutter): `flutter pub get` e depois `flutter create .` — **confirmar com o usuário antes**.
- Se for testar OCR real: `TESSERACT_CMD` precisa apontar para um Tesseract instalado no Windows.

---

# Arquivos mais importantes para revisar

| Arquivo | Por quê |
|---|---|
| `CLAUDE_PROJECT_RULES.md` | Regras permanentes de governança — ler antes de qualquer decisão técnica |
| `docs/session_start.md` | Procedimento obrigatório de início de sessão |
| `docs/session_end.md` | Procedimento obrigatório de encerramento de sessão |
| `backend/app/api/v1/routes/transactions.py` | Transactions API completa (Fase 3) — padrão de referência para Analytics (Opção B) |
| `backend/app/repositories/transaction_repository.py` | `_apply_filters`, `list_by_user`, `count_by_user`, `get_summary`, `update` — reaproveitar `get_summary` para `/analytics/dashboard` |
| `backend/app/schemas/transaction.py` | `TransactionList`, `TransactionSummary`, `TransactionUpdate` — padrão de schemas de resposta paginada/agregada |
| `backend/app/api/v1/routes/uploads.py` | Endpoint `POST /pdf` real (Fase 2) |
| `backend/app/services/ai/categorizer.py` | Categorizador integrado ao upload; aguardando treino real (`train()`) |
| `backend/app/services/analytics/health_score.py` | Lógica pronta para `/analytics/health-score` (Opção B) |
| `backend/tests/conftest.py` | Fixtures (`db_session`, `client`, `test_user`, `other_user`, `auth_headers`) — reusar para novos testes |
| `backend/tests/integration/test_transactions.py` | Padrão de referência para testes de integração com seed direto via `db_session` |
| `backend/app/core/config.py` | `Settings` — `MAX_UPLOAD_SIZE_MB`, `SUPPORTED_BANKS` |
| `backend/alembic/versions/7132eab5146a_initial_schema.py` | Migration inicial — qualquer mudança de schema gera nova revision a partir desta |
| `docs/project_status.md` | Status completo — "Visão Geral por Área", §15 "Roadmap Atualizado", seções "Última Sessão" com todo o histórico |

---

# Riscos conhecidos

- **Migration nunca testada em PostgreSQL real** — validar no primeiro ambiente com Postgres disponível antes de confiar 100%.
- **`bcrypt` deve permanecer pinado em `4.0.1`** — `passlib==1.7.4` é incompatível com `bcrypt>=4.1` (quebra hashing de senha com `500`). Não atualizar `bcrypt` sem também atualizar/substituir `passlib`.
- **Cobertura de testes ainda pontual** — extractor, upload e transactions têm 49 testes, mas `core/security.py`, `categorizer.py`, `health_score.py`, repositories de user/upload e rotas de auth seguem sem rede de segurança.
- **`backend/venv/` é local e não versionado** — recriar com `python -m venv venv && pip install -r requirements.txt` em nova máquina/sessão.
- **Frontend sem scaffold de plataforma** — qualquer tentativa de `flutter run`/`build` falhará até `flutter create .` ser executado.
- **Dedupe de transações via `transactions.hash` (unique global, não escopado por `user_id`)** — risco baixo, documentado como mecanismo oficial (regra Fintech #3), mudança exigiria nova migration + decisão explícita.
- **`TransactionRepository.create()` comita uma transação por vez** — aceitável para volumes típicos (10–100 linhas); revisar para bulk-insert apenas se virar gargalo real.
- **Caminho OCR (`_try_ocr`/Tesseract) e `_try_pdfplumber` nunca exercitados por PDF real** — testes de integração mockam `extract_transactions`.
- 🆕 **`GET /transactions/` faz `SELECT` + `COUNT` separados** para montar `total` — duplica custo de leitura por requisição; aceitável para volumes do MVP, revisar (ex. window function) só se virar gargalo medido.
- 🆕 **`PATCH /transactions/{id}` sempre seta `confidence_score=1.0` quando há mudança** — assume que toda correção manual do próprio usuário é 100% confiável. Correto para o caso de uso atual; revisar se outras roles (ex. admin) puderem editar transações de terceiros.

---

# Decisões arquiteturais tomadas

1. **FK `users.id` → `ON DELETE CASCADE`** em `uploads.user_id` e `transactions.user_id` — exclusão em cascata (LGPD).
2. **FK `uploads.id` → `ON DELETE SET NULL`** em `transactions.upload_id` — preserva histórico de transações mesmo sem o upload original.
3. **JWT com claim `"type"`** (`"access"` | `"refresh"`) no mesmo `SECRET_KEY`.
4. **Schema é responsabilidade exclusiva do Alembic** — sem `Base.metadata.create_all` no lifespan.
5. **Pacotes Python explícitos** (`__init__.py` em todos os subpacotes de `app/`).
6. **Índices** em `transactions.user_id`, `transactions.upload_id`, `transactions.date`, `transactions.category`, `uploads.user_id`, `users.email`.
7. **Migration inicial usa `postgresql.UUID`/`postgresql.ENUM` explicitamente** — `downgrade()` dropa os 4 enums explicitamente.
8. **`bcrypt==4.0.1` pinado** — compatibilidade com `passlib==1.7.4`.
9. **Governança formalizada**: `CLAUDE_PROJECT_RULES.md` + `docs/session_start.md`/`docs/session_end.md` — mudanças raras e sinalizadas (regra 13.4).
10. **`extract_transactions` opera em `bytes`/`BytesIO`/`fitz.open(stream=...)`** — nunca em caminho de arquivo (LGPD).
11. **`UploadResult(UploadRead)`** como schema de resposta dedicado de `POST /uploads/pdf`.
12. **Validação de banco via `Settings.SUPPORTED_BANKS`** (`["itau", "santander"]`).
13. **Estado `FAILED` (com `error_message` amigável)** em vez de erro HTTP genérico para falhas de extração — `Upload` como trilha de auditoria.
14. **MVP síncrono para `POST /uploads/pdf` (sem SSE)**.
15. **Testes de integração do upload mockam `extract_transactions`** via `monkeypatch`.
16. 🆕 **`amount` sempre positivo, sinal vem de `type`** — `get_summary()` soma por `TransactionType` (CREDIT=receita, DEBIT=despesa), nunca pelo sinal de `amount`, consistente com `_parse_itau_row` (`amount=abs(amount)`).
17. 🆕 **`_apply_filters()` privado e compartilhado** entre `list_by_user`, `count_by_user` e `get_summary` — único ponto de verdade para os filtros de `transactions` (user_id, datas, categoria, tipo, busca).
18. 🆕 **`.ilike()` para busca textual** — funciona em SQLite (testes) e Postgres (produção) sem branch condicional (SQLAlchemy traduz para `lower()+LIKE` quando o dialeto não tem `ILIKE` nativo).
19. 🆕 **Whitelist `SORTABLE_FIELDS`** (`date`/`amount`/`description`) para `sort_by` — evita acesso arbitrário a atributos do modelo; reforçado por `Query(pattern=...)` no FastAPI.
20. 🆕 **`PATCH /transactions/{id}` seta `confidence_score=1.0`** quando `category`/`subcategory` é alterado — correção manual tratada como 100% confiável (ver "Riscos conhecidos").
21. 🆕 **404 (não 403) em `PATCH`/`DELETE` de transação de outro usuário** — `get_by_id` filtra por `user_id`; evita confirmar existência do recurso para não-donos.
22. 🆕 **Sem `GET /transactions/{id}` e sem endpoint de criação manual** — fora do escopo solicitado nesta fase; testes seedam `Transaction` via `db_session` direto.
