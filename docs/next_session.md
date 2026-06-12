# Financily — Memória de Continuidade

> Gerado em 2026-06-12, ao final da sessão "Fase 2 — Upload de PDF end-to-end".
> A sessão anterior ("Fase 1.5 — Governança e Estruturação", commits `f8d9b78`/`f7dd82c`) está documentada em "Última Sessão — Fase 1.5" de `docs/project_status.md`. O histórico desta sessão está em "Última Sessão — Fase 2" no mesmo arquivo.
>
> **Antes de iniciar qualquer trabalho, siga `docs/session_start.md`.** Ao encerrar, siga `docs/session_end.md`. Regras permanentes de governança (CTO permanente) estão em `CLAUDE_PROJECT_RULES.md` (raiz do projeto).

---

# Onde paramos

A Fase 2 (primeira fatia vertical de valor real) está **completa e validada**: `POST /api/v1/uploads/pdf` agora processa um PDF de ponta a ponta — extrai transações em memória (`extractor.py`, refatorado para `bytes`/`BytesIO`), categoriza cada uma (`categorizer.py`, regras por keyword), persiste via `TransactionRepository.create()` com dedupe por `hash`, e atualiza o status do `Upload` (`PENDING`→`PROCESSING`→`COMPLETED`/`FAILED`).

26 testes automatizados novos (18 unitários para os helpers puros de `extractor.py` + 8 de integração para o endpoint) passam. O venv agora tem todas as deps de PDF/IA/teste instaladas (`pdfplumber`, `pymupdf`, `pytesseract`, `Pillow`, `pandas`, `numpy`, `scikit-learn`, `joblib`, `pytest`, `pytest-asyncio`, `pytest-cov`, `faker`, `aiosqlite`), exceto `prophet`/`nltk` (deferidos para a Fase 3).

O frontend Flutter **continua exatamente como estava** (fora de escopo desta sessão): UI mock (login + dashboard), sem scaffold de plataforma, não conectado ao backend.

---

# O que já funciona

- `uvicorn app.main:app --reload --port 8000` sobe sem erros, 22 rotas registradas.
- `POST /api/v1/auth/register` → 201, valida e-mail único, hash de senha com bcrypt.
- `POST /api/v1/auth/login` (OAuth2 form: `username`/`password`) → par de tokens JWT (access 15min, refresh 30d).
- `POST /api/v1/auth/refresh` → valida claim `type=="refresh"`, emite novo par.
- **`POST /api/v1/uploads/pdf`** (NOVO) → recebe PDF (multipart, `file` + `bank`), valida `content_type`/tamanho/`bank` suportado, extrai transações, categoriza, persiste com dedupe por hash, retorna `UploadResult` (`status`, `transactions_created`, `duplicates_skipped`, `error_message`).
- `GET /api/v1/uploads/` e `GET /api/v1/transactions/` → listagem real (agora pode conter dados reais pós-upload), protegidos por JWT.
- `GET /api/v1/analytics/*`, `POST /api/v1/assistant/chat`, `POST /api/v1/reports/*` → `501 Not Implemented` (esperado, contrato documentado).
- `alembic upgrade head` / `alembic downgrade base` → cria/destrói schema completo (`users`, `uploads`, `transactions` + 4 enums Postgres).
- `pytest backend/tests/ -v` → **26/26 testes passando** (18 unit + 8 integração).
- `backend/.env.example` documenta todas as vars necessárias; `requirements.txt` sem duplicatas.

---

# O que ainda não funciona

- **Transactions API** — apenas `GET /` (list bruto, sem paginação/filtros/summary/update/delete).
- **Analytics API** — todos os 7 endpoints são stubs `501` (incluindo `health-score`, que já tem lógica pronta em `services/analytics/health_score.py`, só não está conectada).
- **Assistente IA** — stub `501`.
- **Exportação PDF/Excel/CSV** — stubs `501`; faltam libs (`openpyxl`, `reportlab`/`weasyprint`).
- **Frontend ↔ Backend** — Flutter não tem `core/network/`, login/dashboard continuam mockados; não há tela de upload no Flutter.
- **Scaffold Flutter** — `flutter create .` nunca executado; `flutter run`/`build` falham.
- **Categorizador ML** — `train()` nunca chamado, sem `categorizer.joblib`; toda transação fora das regras de keyword fica `OTHER`/confidence `0.0`. Já está integrado ao upload (chamando `.categorize()`), só falta o treino.
- **Parser Santander** — `_parse_santander_row` ainda é cópia de `_parse_itau_row` (placeholder).
- **Fixtures de PDF reais** — `backend/tests/fixtures/` não existe; os 8 testes de integração do upload mockam `extract_transactions`, então o caminho real `_try_pdfplumber`/`_try_ocr` nunca foi exercitado por um PDF de verdade.
- **SSE de progresso** — `POST /uploads/pdf` é síncrono (decisão deliberada do MVP); para faturas grandes/OCR pode valer a pena revisitar.
- **PostgreSQL real** — Alembic só foi validado em SQLite + `--sql` offline para Postgres; nunca rodou contra um Postgres de verdade.
- **Testes para `categorizer.py`, `health_score.py`, `core/security.py`, repositories, rotas de auth** — ainda zero (extractor e upload agora cobertos).
- **`prophet`/`nltk`** — em `requirements.txt`, não instalados; deferidos para Fase 3 (forecast/behavioral).

---

# Próximo objetivo

Continuar a expansão do domínio backend ou conectar o frontend ao que já existe — em ambos os casos, fechando mais um ciclo "fundação → feature de valor visível" (Fase 3 do roadmap em `docs/project_status.md` §15).

---

# Próximo módulo recomendado

**Opção A (recomendada — continuidade natural): Transactions API completa**

`backend/app/api/v1/routes/transactions.py` + `repositories/transaction_repository.py`.

**Por quê este e não outro**: agora que `POST /uploads/pdf` popula a tabela `transactions` com dados reais, o endpoint `GET /transactions/` (hoje um list bruto sem paginação/filtros) é o próximo gargalo óbvio — sem ele, não há como consultar/corrigir o que foi importado, e `/analytics/dashboard` (Fase 3) também depende de queries agregadas que hoje não existem no repository. É trabalho 100% backend, sem dependência do Flutter, e segue o mesmo padrão (`routes` → `repositories`) já validado nesta sessão.

**Escopo sugerido**: paginação (`limit`/`offset` ou cursor), filtros (`date_from`/`date_to`, `category`, `type`), `GET /transactions/summary` (totais por categoria/período — possível reaproveitamento parcial de `health_score.py`), `PATCH /transactions/{id}` (correção manual de categoria pelo usuário — importante para retroalimentar o categorizador ML no futuro), `DELETE /transactions/{id}`.

**Alternativa igualmente válida (Opção B): Conectar Flutter ao backend**

`frontend/lib/core/network/` (Dio + interceptor de refresh token) + telas de login/registro reais consumindo `/api/v1/auth/*`, e potencialmente uma tela simples de upload consumindo `POST /uploads/pdf` (já funcional). Desbloqueia a Fase 4 mais cedo e torna o produto utilizável por um humano de ponta a ponta. Requer `flutter create .` em algum momento — **pedir confirmação explícita ao usuário antes**, pois pode sobrescrever/mesclar arquivos existentes em `lib/`/`pubspec.yaml`/`assets/`.

> Ambas são independentes. A Opção A não depende do Flutter; a Opção B não depende da Transactions API (mas a tela de dashboard real, depois, vai precisar dela).

---

# Ordem recomendada para desenvolvimento

1. ✅ ~~Upload de PDF end-to-end~~ — concluído (Fase 2).
2. **Transactions API completa** (Opção A) — paginação, filtros, summary, update (correção manual de categoria), delete.
3. **Conectar Flutter ao backend** (Opção B) — `core/network/`, login/dashboard/upload reais, e só então `flutter create .`.
4. **Analytics API real** — começar por `/analytics/health-score` (lógica já pronta em `health_score.py`), depois `/analytics/dashboard`.
5. **Categorizador ML** — treinar com dados reais (agora existentes via upload real).
6. **Parser Santander real** — substituir o stub que hoje é cópia do parser Itaú.
7. **Fixtures de PDF reais** — gerar/coletar PDFs de teste (Itaú/Santander) para `backend/tests/fixtures/`, testar `_try_pdfplumber`/`_try_ocr` ponta a ponta.
8. **Forecast (Prophet) + análise comportamental** — após volume real de transações.
9. **Testes automatizados restantes** — `core/security.py`, repositories, rotas de auth, `categorizer.py`, `health_score.py`.
10. **Validar Alembic contra PostgreSQL real** — antes do primeiro deploy.
11. **Hardening de produção** — rate limiting/auth, CORS para produção, CI (`.github/workflows/`), exportações PDF/Excel/CSV, notificações, assistente IA, SSE de progresso para upload.

> Esta ordem corresponde às Fases 3–5 do roadmap em `docs/project_status.md` §15 ("Roadmap Atualizado").

---

# Dependências para a próxima sessão

- `backend/venv/` já tem **todas** as deps de PDF/IA/teste instaladas (`pdfplumber`, `pymupdf`, `pytesseract`, `Pillow`, `pandas`, `numpy`, `scikit-learn`, `joblib`, `pytest`, `pytest-asyncio`, `pytest-cov`, `faker`, `httpx`, `aiosqlite`) — confirmado nesta sessão, 26/26 testes passando. `bcrypt==4.0.1` permanece intocado.
- `prophet`/`nltk` ainda **não instalados** (não bloqueiam Opção A nem B) — instalar apenas quando a Fase 3 (forecast/behavioral) começar.
- **Sem PostgreSQL local**: continuar usando SQLite (`sqlite+aiosqlite:///:memory:` para testes, ou `sqlite+aiosqlite:///./<nome>.db` para smoke test manual) via override de `DATABASE_URL`, OU subir um Postgres local (Docker: `docker run -e POSTGRES_PASSWORD=... -p 5432:5432 postgres:16`) para validar a migration contra o dialeto real.
- Para Opção B (Flutter): `flutter pub get` e depois `flutter create .` — **confirmar com o usuário antes**, pois `flutter create .` pode sobrescrever/mesclar arquivos existentes.
- Se for testar OCR real: `TESSERACT_CMD` precisa apontar para um Tesseract instalado no Windows.

---

# Arquivos mais importantes para revisar

| Arquivo | Por quê |
|---|---|
| `CLAUDE_PROJECT_RULES.md` | Regras permanentes de governança (Arquitetura, Segurança, SaaS, Fintech, IA, Git, LGPD, etc.) — ler antes de qualquer decisão técnica |
| `docs/session_start.md` | Procedimento obrigatório de início de sessão |
| `docs/session_end.md` | Procedimento obrigatório de encerramento de sessão |
| `backend/app/api/v1/routes/uploads.py` | Endpoint `POST /pdf` real (Fase 2) — padrão de referência (validação → service → repository → estado explícito) para a Transactions API |
| `backend/app/repositories/transaction_repository.py` | Ponto de entrada da Opção A — hoje só tem `create`/`get_by_hash`/`list_by_user`; precisa de paginação/filtros/summary/update/delete |
| `backend/app/services/pdf/extractor.py` | Pipeline de extração, agora operando em `bytes`/`BytesIO` (100% memória, LGPD) |
| `backend/app/services/ai/categorizer.py` | Categorizador integrado ao upload; aguardando treino real (`train()`) |
| `backend/app/services/analytics/health_score.py` | Lógica pronta para `/analytics/health-score` (Fase 3, item 4) |
| `backend/tests/conftest.py` | Fixtures de teste (`db_session`, `client`, `test_user`, `auth_headers`) — reusar para novos testes (Transactions API, etc.) |
| `backend/tests/integration/test_uploads.py` | Padrão de referência para testes de integração com `AsyncClient` + `monkeypatch` |
| `backend/app/core/config.py` | `Settings` — `MAX_UPLOAD_SIZE_MB`, `SUPPORTED_BANKS` (novos nesta sessão) |
| `backend/alembic/versions/7132eab5146a_initial_schema.py` | Migration inicial — qualquer mudança de schema gera nova revision a partir desta |
| `docs/project_status.md` | Status completo — "Visão Geral por Área", §15 "Roadmap Atualizado", e seções "Sessão Anterior"/"Última Sessão" com todo o histórico |

---

# Riscos conhecidos

- **Migration nunca testada em PostgreSQL real** — validar no primeiro ambiente com Postgres disponível antes de confiar 100%.
- **`bcrypt` deve permanecer pinado em `4.0.1`** — `passlib==1.7.4` é incompatível com `bcrypt>=4.1` (quebra hashing de senha com `500`). Não atualizar `bcrypt` sem também atualizar/substituir `passlib`.
- **Cobertura de testes ainda pontual** — extractor e upload têm 26 testes, mas `core/security.py`, `categorizer.py`, `health_score.py`, repositories e rotas de auth seguem sem rede de segurança.
- **`backend/venv/` é local e não versionado** — uma nova sessão/máquina precisa recriar (`python -m venv venv && pip install -r requirements.txt`); todas as deps (exceto `prophet`/`nltk`) já confirmadas funcionando nesta sessão.
- **Frontend sem scaffold de plataforma** — qualquer tentativa de `flutter run`/`build` falhará até `flutter create .` ser executado.
- 🆕 **Dedupe de transações via `transactions.hash` (unique global, não escopado por `user_id`)** — dois usuários que importem uma linha byte-idêntica colidiriam no hash; a segunda seria tratada como duplicata silenciosamente. Mecanismo oficial (regra Fintech #3), definido na migration inicial — mudança exigiria nova migration + decisão explícita. Risco baixo na prática.
- 🆕 **`TransactionRepository.create()` comita uma transação por vez** — para faturas com muitas linhas, `POST /uploads/pdf` faz N commits sequenciais. Aceitável para volumes típicos (10–100 linhas); revisar para bulk-insert apenas se virar gargalo real (não otimizar prematuramente).
- 🆕 **Caminho OCR (`_try_ocr`/Tesseract) e `_try_pdfplumber` nunca exercitados por PDF real** — os 8 testes de integração mockam `extract_transactions`; um PDF real malformado/diferente do esperado pode se comportar diferente do previsto até existirem fixtures reais.

---

# Decisões arquiteturais tomadas

1. **FK `users.id` → `ON DELETE CASCADE`** em `uploads.user_id` e `transactions.user_id` — atende ao requisito LGPD de exclusão em cascata de todos os dados do usuário.
2. **FK `uploads.id` → `ON DELETE SET NULL`** em `transactions.upload_id` — preserva o histórico de transações mesmo que o registro de upload seja apagado.
3. **JWT com claim `"type"`** (`"access"` | `"refresh"`) no mesmo `SECRET_KEY` — distingue os dois tipos de token sem precisar de chaves separadas; `/refresh` rejeita explicitamente um access token.
4. **Schema é responsabilidade exclusiva do Alembic** — removido `Base.metadata.create_all` do lifespan do FastAPI; em dev/test, rodar `alembic upgrade head` antes de subir o servidor.
5. **Pacotes Python explícitos** (`__init__.py` em todos os subpacotes de `app/`) — evita ambiguidades de namespace package, especialmente para o `target_metadata` do Alembic.
6. **Índices** em `transactions.user_id`, `transactions.upload_id`, `transactions.date`, `transactions.category`, `uploads.user_id`, `users.email` — antecipando os padrões de query do dashboard/analytics.
7. **Migration inicial usa `postgresql.UUID`/`postgresql.ENUM` explicitamente** (não autogenerate) — `downgrade()` dropa os 4 enums explicitamente para evitar tipos órfãos no Postgres.
8. **`bcrypt==4.0.1` pinado** — necessário para compatibilidade com `passlib==1.7.4` (ver "Riscos conhecidos").
9. **Governança formalizada** (Fase 1.5): `CLAUDE_PROJECT_RULES.md` define regras permanentes; `docs/session_start.md`/`docs/session_end.md` definem o procedimento obrigatório de toda sessão. Mudanças nessas regras devem ser raras, deliberadas e sinalizadas explicitamente (regra 13.4).
10. 🆕 **`extract_transactions` opera em `bytes`/`BytesIO`/`fitz.open(stream=...)`**, nunca em caminho de arquivo — requisito LGPD (PDF nunca tocado em disco), decisão da Fase 2.
11. 🆕 **`UploadResult(UploadRead)`** como schema de resposta dedicado de `POST /uploads/pdf` (em vez de estender `UploadRead` diretamente) — mantém `GET /uploads/` com o schema original e adiciona `transactions_created`/`duplicates_skipped` só onde fazem sentido.
12. 🆕 **Validação de banco via `Settings.SUPPORTED_BANKS`** (`["itau", "santander"]`) — alinhado ao passo 3 de "Adding a New Bank Parser" no `CLAUDE.md`; novo banco = adicionar à lista + criar `_parse_<bank>_row`.
13. 🆕 **Estado `FAILED` (com `error_message` amigável) em vez de erro HTTP genérico** para "zero transações extraídas" ou "exceção durante extração" — `Upload` funciona como trilha de auditoria; resposta sempre `201`, detalhes internos da exceção nunca expostos (regra 7.4 — estado explícito).
14. 🆕 **MVP síncrono para `POST /uploads/pdf` (sem SSE)** — decisão da sessão anterior, mantida; SSE de progresso é follow-up explícito (ver "O que ainda não funciona").
15. 🆕 **Testes de integração do upload mockam `extract_transactions`** via `monkeypatch` em vez de usar PDFs reais — fixtures reais ficam como débito explícito (ver "Riscos conhecidos" / item 7 da "Ordem recomendada").
