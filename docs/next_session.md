# Financily — Memória de Continuidade

> Gerado em 2026-06-11, ao final da sessão "Fase 1.5 — Governança e Estruturação do Projeto".
> A sessão anterior ("Fase 1 — Fundação do Backend", commit `4142824`) está documentada na seção "Sessão Anterior — Fase 1" de `docs/project_status.md`. O histórico desta sessão está em "Última Sessão — Fase 1.5" no mesmo arquivo.
>
> **Antes de iniciar qualquer trabalho, siga `docs/session_start.md`.** Ao encerrar, siga `docs/session_end.md`. Regras permanentes de governança (CTO permanente) estão em `CLAUDE_PROJECT_RULES.md` (raiz do projeto).

---

# Onde paramos

A fundação do backend (Fase 1: FastAPI + SQLAlchemy 2.0 async + Alembic + JWT) está **completa, validada e committada** (`4142824`).

Esta sessão (Fase 1.5) **não alterou nenhuma funcionalidade de runtime** — foi uma sessão de governança/estruturação, conforme pedido explícito do usuário. O que mudou:

- Criada a camada permanente de governança: `CLAUDE_PROJECT_RULES.md` (raiz), `docs/session_start.md`, `docs/session_end.md`.
- `docs/project_status.md` reescrito com uma visão consolidada por área ("Visão Geral por Área") e um roadmap atualizado por fases (§15).
- Auditoria rápida executada (sem achados críticos novos) — único fix aplicado: removida a duplicata de `httpx==0.27.0` em `backend/requirements.txt`.

O frontend Flutter **continua exatamente como estava**: UI mock (login + dashboard), sem scaffold de plataforma, não conectado ao backend.

---

# O que já funciona

- `uvicorn app.main:app --reload --port 8000` sobe sem erros.
- `POST /api/v1/auth/register` → 201, valida e-mail único, hash de senha com bcrypt.
- `POST /api/v1/auth/login` (OAuth2 form: `username`/`password`) → par de tokens JWT (access 15min, refresh 30d).
- `POST /api/v1/auth/refresh` → valida claim `type=="refresh"`, emite novo par.
- `GET /api/v1/uploads/` e `GET /api/v1/transactions/` → listagem real (vazia até existir dado), protegidos por JWT.
- `GET /api/v1/analytics/*`, `POST /api/v1/assistant/chat`, `POST /api/v1/reports/*` → `501 Not Implemented` (esperado, contrato documentado).
- `alembic upgrade head` / `alembic downgrade base` → cria/destrói schema completo (`users`, `uploads`, `transactions` + 4 enums Postgres).
- `backend/.env.example` documenta todas as vars necessárias.
- `backend/requirements.txt` sem dependências duplicadas (corrigido nesta sessão).

---

# O que ainda não funciona

- **Upload de PDF real** — endpoint `POST /uploads/pdf` não existe; `extractor.py` e `categorizer.py` não estão integrados a nenhuma rota.
- **Transactions API** — apenas `GET /` (list bruto, sem paginação/filtros/summary).
- **Analytics API** — todos os 7 endpoints são stubs `501` (incluindo `health-score`, que já tem lógica pronta em `services/analytics/health_score.py`, só não está conectada).
- **Assistente IA** — stub `501`.
- **Exportação PDF/Excel/CSV** — stubs `501`; faltam libs (`openpyxl`, `reportlab`/`weasyprint`).
- **Frontend ↔ Backend** — Flutter não tem `core/network/`, login/dashboard continuam mockados.
- **Scaffold Flutter** — `flutter create .` nunca executado; `flutter run`/`build` falham.
- **Categorizador ML** — `train()` nunca chamado, sem `categorizer.joblib`.
- **PostgreSQL real** — Alembic só foi validado em SQLite + `--sql` offline para Postgres; nunca rodou contra um Postgres de verdade.
- **Testes automatizados** — zero testes no projeto inteiro.
- **3 módulos não importam no venv mínimo** (`services/ai/categorizer`, `services/analytics/health_score`, `services/pdf/extractor`) por faltar instalar `joblib`/`pandas`/`pdfplumber` — já estão em `requirements.txt`, é só rodar `pip install -r requirements.txt` completo.

---

# Próximo objetivo

Conectar uma fatia vertical completa **ponta a ponta**: usuário se registra/loga pelo Flutter (via backend real) **e/ou** faz upload de um PDF da fatura Itaú que é processado, categorizado e salvo no banco — encerrando o ciclo "fundação pronta → primeira feature de valor real visível" (Fase 2 do roadmap em `docs/project_status.md` §15).

---

# Próximo módulo recomendado

**Upload de PDF (backend)** — módulo que conecta `api/v1/routes/uploads.py` + `services/pdf/extractor.py` + `services/ai/categorizer.py` + `repositories/transaction_repository.py`.

**Por quê este e não outro**: é o módulo que desbloqueia o maior número de features subsequentes — sem transações reais no banco, `transactions API`, `analytics` e o treino do categorizador ML ficam todos bloqueados ou trabalhando com dados sintéticos. Não depende do Flutter, então pode ser feito e validado isoladamente via `/api/docs`.

**Alternativa igualmente válida**: `frontend/lib/core/network/` (network layer do Flutter) — desbloqueia a Fase 4 (frontend completo) mais cedo. Ver "Próxima tarefa recomendada" para os dois caminhos detalhados.

---

# Próxima tarefa recomendada

**Opção A (recomendada — maior valor imediato): Upload de PDF end-to-end**
1. Criar `POST /api/v1/uploads/pdf` em `backend/app/api/v1/routes/uploads.py`:
   - Recebe `UploadFile` (em memória, sem persistir em disco — requisito LGPD do CLAUDE.md)
   - Cria registro `Upload` (status `PENDING` → `PROCESSING`)
   - Chama `services/pdf/extractor.py` para extrair `RawTransaction[]`
   - Chama `services/ai/categorizer.py` para categorizar cada transação
   - Salva via `TransactionRepository.create()` (dedupe por `hash`)
   - Atualiza `Upload.status` → `COMPLETED`/`FAILED`
2. Antes de começar: completar o venv (`pip install -r requirements.txt`) para que `pdfplumber`, `joblib`, `pandas` etc. importem (ver "O que ainda não funciona").
3. Testar com um PDF real de fatura Itaú (fixture em `backend/tests/fixtures/`, se existir, ou solicitar ao usuário).

**Opção B (alternativa — desbloqueia o Flutter): `frontend/lib/core/network/`**
1. Criar `Dio` client + interceptor de refresh token, consumindo `/api/v1/auth/*` (já funcional).
2. Conectar `login_screen.dart` ao `/auth/login` real.
3. Rodar `flutter create .` para gerar scaffold de plataforma (preservando `lib/`/`pubspec.yaml`/`assets/`) — confirmar com o usuário antes, pois pode sobrescrever/mesclar arquivos existentes.

> Ambas são independentes e podem ser feitas em sessões separadas. A Opção A não depende do Flutter; a Opção B não depende do upload.

---

# Ordem recomendada para desenvolvimento

1. **Upload de PDF end-to-end** (Opção A) — gera dados reais de transações.
2. **Transactions API completa** — paginação, filtros, summary, update (correção manual de categoria), delete.
3. **Analytics API real** — começar por `/analytics/health-score` (lógica já pronta em `health_score.py`), depois `/analytics/dashboard`.
4. **Conectar Flutter ao backend** (Opção B) — `core/network/`, login/dashboard reais, e só então `flutter create .`.
5. **Categorizador ML** — treinar com dados reais (agora existentes via upload real do passo 1).
6. **Parser Santander real** — substituir o stub que hoje é cópia do parser Itaú.
7. **Forecast (Prophet) + análise comportamental** — após volume real de transações.
8. **Testes automatizados** — cobrir retroativamente `core/security.py`, repositories, rotas de auth, módulos puros (`extractor`, `categorizer`, `health_score`) e os módulos novos dos passos 1-7.
9. **Validar Alembic contra PostgreSQL real** — antes do primeiro deploy.
10. **Hardening de produção** — rate limiting/auth, CORS para produção, CI (`.github/workflows/`), exportações PDF/Excel/CSV, notificações, assistente IA.

> Esta ordem corresponde às Fases 2–5 do roadmap em `docs/project_status.md` §15 ("Roadmap Atualizado").

---

# Dependências para a próxima sessão

- **Sem PostgreSQL local**: continuar usando SQLite (`sqlite+aiosqlite:///./<nome>.db`) via override de `DATABASE_URL` para smoke tests, OU subir um Postgres local (Docker: `docker run -e POSTGRES_PASSWORD=... -p 5432:5432 postgres:16`) para validar a migration contra o dialeto real.
- `backend/venv/` já existe com dependências mínimas instaladas (fastapi, uvicorn, sqlalchemy, alembic, asyncpg, python-jose, passlib, bcrypt==4.0.1, pydantic, aiosqlite, etc.). Para a Opção A (PDF/OCR/ML), será necessário instalar adicionalmente: `pdfplumber`, `pymupdf`, `pytesseract`, `Pillow`, `pandas`, `scikit-learn`, `joblib` (já estão em `requirements.txt`, só não instalados no venv atual — confirmado nesta sessão via auditoria).
- Para Opção B (Flutter): `flutter pub get` e depois `flutter create .` — confirmar com o usuário antes, pois `flutter create .` pode sobrescrever/mesclar arquivos existentes.
- Se for testar OCR: `TESSERACT_CMD` precisa apontar para um Tesseract instalado no Windows.

---

# Arquivos mais importantes para revisar

| Arquivo | Por quê |
|---|---|
| `CLAUDE_PROJECT_RULES.md` | Regras permanentes de governança (Arquitetura, Segurança, SaaS, Fintech, IA, Git, LGPD, etc.) — ler antes de qualquer decisão técnica |
| `docs/session_start.md` | Procedimento obrigatório de início de sessão |
| `docs/session_end.md` | Procedimento obrigatório de encerramento de sessão |
| `backend/app/core/database.py` | Engine async, `Base`, `get_db()` — base de toda a camada de dados |
| `backend/app/core/security.py` | JWT + hashing — entender antes de mexer em auth |
| `backend/app/models/{user,upload,transaction}.py` | Schema atual — qualquer novo campo precisa de migration |
| `backend/app/repositories/*.py` | Padrão de acesso a dados a seguir para novos repositórios |
| `backend/app/api/v1/routes/uploads.py` | Ponto de entrada da Opção A (upload de PDF) |
| `backend/app/services/pdf/extractor.py` | Pipeline de extração já pronto, aguardando integração |
| `backend/app/services/ai/categorizer.py` | Categorizador já pronto, aguardando integração |
| `backend/app/services/analytics/health_score.py` | Lógica pronta para `/analytics/health-score` |
| `backend/alembic/versions/7132eab5146a_initial_schema.py` | Migration inicial — qualquer mudança de schema gera nova revision a partir desta |
| `docs/project_status.md` | Status completo — "Visão Geral por Área", §15 "Roadmap Atualizado", e seções "Sessão Anterior"/"Última Sessão" com todo o histórico |

---

# Riscos conhecidos

- **Migration nunca testada em PostgreSQL real** — validar no primeiro ambiente com Postgres disponível antes de confiar 100%.
- **`bcrypt` deve permanecer pinado em `4.0.1`** — `passlib==1.7.4` é incompatível com `bcrypt>=4.1` (quebra hashing de senha com `500`). Não atualizar `bcrypt` sem também atualizar/substituir `passlib`.
- **Zero testes automatizados** — qualquer refator na fundação criada na Fase 1 não tem rede de segurança.
- **`backend/venv/` é local e não versionado** — uma nova sessão/máquina precisa recriar (`python -m venv venv && pip install -r requirements.txt`); `bcrypt==4.0.1` e o restante já estão no `requirements.txt`, mas o venv mínimo atual não tem `pdfplumber`/`pandas`/`joblib` instalados (ver "Dependências para a próxima sessão").
- **Frontend sem scaffold de plataforma** — qualquer tentativa de `flutter run`/`build` falhará até `flutter create .` ser executado.

---

# Decisões arquiteturais tomadas

1. **FK `users.id` → `ON DELETE CASCADE`** em `uploads.user_id` e `transactions.user_id` — atende ao requisito LGPD de exclusão em cascata de todos os dados do usuário.
2. **FK `uploads.id` → `ON DELETE SET NULL`** em `transactions.upload_id` — preserva o histórico de transações mesmo que o registro de upload seja apagado.
3. **JWT com claim `"type"`** (`"access"` | `"refresh"`) no mesmo `SECRET_KEY` — distingue os dois tipos de token sem precisar de chaves separadas; `/refresh` rejeita explicitamente um access token.
4. **Schema é responsabilidade exclusiva do Alembic** — removido `Base.metadata.create_all` do lifespan do FastAPI; em dev/test, rodar `alembic upgrade head` antes de subir o servidor.
5. **Pacotes Python explícitos** (`__init__.py` em todos os subpacotes de `app/`) — decisão deliberada para evitar ambiguidades de namespace package, especialmente relevante para o `target_metadata` do Alembic (`from app import models`).
6. **Índices adicionados** em `transactions.user_id`, `transactions.upload_id`, `transactions.date`, `transactions.category`, `uploads.user_id`, `users.email` — antecipando os padrões de query do dashboard/analytics (filtro por usuário + período + categoria).
7. **Migration inicial usa `postgresql.UUID`/`postgresql.ENUM` explicitamente** (não autogenerate) — `op.create_table()` cria os tipos ENUM automaticamente via eventos DDL do SQLAlchemy; `downgrade()` dropa os 4 enums explicitamente para evitar tipos órfãos no Postgres.
8. **`bcrypt==4.0.1` pinado** — necessário para compatibilidade com `passlib==1.7.4` (ver "Riscos conhecidos").
9. **Governança formalizada** (Fase 1.5): `CLAUDE_PROJECT_RULES.md` define regras permanentes; `docs/session_start.md`/`docs/session_end.md` definem o procedimento obrigatório de toda sessão. Mudanças nessas regras devem ser raras, deliberadas e sinalizadas explicitamente ao usuário (regra 13.4 de `CLAUDE_PROJECT_RULES.md`) — não corrigidas silenciosamente em sessões futuras.
