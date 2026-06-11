# CLAUDE_PROJECT_RULES.md

> Regras permanentes de governança técnica do Financily. Este documento posiciona o Claude Code como **CTO permanente do projeto**: toda decisão técnica relevante deve ser avaliada à luz destas regras, não apenas do pedido pontual do usuário.
>
> Relação com outros documentos:
> - `CLAUDE.md` — convenções de código, comandos de desenvolvimento, arquitetura de pastas (o "como").
> - `CLAUDE_PROJECT_RULES.md` (este arquivo) — princípios e restrições permanentes de governança (o "o quê pode/não pode").
> - `docs/session_start.md` / `docs/session_end.md` — procedimentos operacionais de cada sessão (o "quando").
> - `docs/project_status.md` / `docs/next_session.md` — estado e continuidade (o "onde estamos").
>
> Em caso de conflito entre um pedido do usuário e estas regras, **sinalizar o conflito explicitamente antes de prosseguir** — não violar silenciosamente nem recusar silenciosamente.

---

## 1. Arquitetura

1. **Clean Architecture é não-negociável.** Backend: `api/routes` (fino) → `services` (regra de negócio) → `repositories` (acesso a dados) → `models` (ORM). `services/` nunca importa de `api/`. `repositories/` é a única camada que executa queries SQLAlchemy.
2. **Schemas Pydantic ≠ Models ORM.** Toda resposta/request de API passa por `schemas/`, nunca expõe um modelo SQLAlchemy diretamente.
3. **Mudança de schema = migration Alembic.** Nenhuma alteração em `models/` é considerada completa sem a migration correspondente em `alembic/versions/`.
4. **Frontend Clean Architecture por feature**: `data/ → domain/ → presentation/`, conforme `CLAUDE.md`. `domain/` nunca depende de Flutter.
5. **Design system é fonte única de verdade.** Cores/tokens vêm de `AppColors`/`ThemeData`; nunca hardcode hex em telas novas.
6. **Toda nova decisão arquitetural relevante** (ex.: escolha de biblioteca, padrão de cache, estratégia de fila) deve ser registrada em `docs/project_status.md` (seção "Decisões Arquiteturais" / "Última Sessão"), com a justificativa.
7. **Não introduzir abstrações especulativas.** Resolver o problema de hoje; documentar (não implementar) hooks para o problema de amanhã.

---

## 2. Segurança

1. **Nunca commitar segredos.** `SECRET_KEY`, credenciais de banco, tokens de API — sempre via `.env` (gitignored), nunca hardcoded, nunca em exemplos com valores reais.
2. **`SECRET_KEY` default (`"change-me-in-production"`) é proibido em produção.** Validar obrigatoriamente via env antes de qualquer deploy.
3. **Hashing de senha**: `bcrypt` via passlib é o padrão. **`bcrypt` deve permanecer pinado em `4.0.1`** enquanto `passlib==1.7.4` for usado (incompatibilidade conhecida com `bcrypt>=4.1` — ver `docs/project_status.md`). Qualquer upgrade de uma das duas libs exige re-validação completa do fluxo de auth antes do merge.
4. **JWT**: tokens de access (curta duração) e refresh (longa duração) são distinguidos por claim `"type"`. Nunca aceitar um refresh token onde se espera um access token, e vice-versa.
5. **Toda nova rota autenticada** usa `Depends(get_current_user)`. Rotas que tocam dados de usuário sempre filtram por `user_id` do token — nunca por ID vindo do payload/query sem validação de posse.
6. **CORS**: nunca usar `allow_origins=["*"]` com `allow_credentials=True`. Lista explícita de origens permitidas.
7. **Validação de entrada em fronteiras do sistema** (uploads, payloads externos, respostas de APIs de terceiros) — nunca confiar em dados vindos de fora sem validar tipo/tamanho/formato.
8. **Rate limiting / proteção brute-force em auth** é débito técnico conhecido — deve ser implementado antes de qualquer exposição pública (não-localhost) da API.
9. **Logs nunca contêm PII** (e-mail, senha, nome, dados financeiros) — ver seção LGPD.

---

## 3. SaaS

1. **Multi-tenancy por `user_id`** é o modelo atual (single-tenant por usuário, dados isolados via FK + `ON DELETE CASCADE`). Qualquer query que retorna dados de domínio (`transactions`, `uploads`, etc.) deve ser escopada por `user_id` do usuário autenticado.
2. **`SubscriptionTier`** (`FREE`/`PRO`/`ENTERPRISE`) já existe no modelo `User` — qualquer feature premium futura deve checar o tier via dependency/decorator centralizado, não checks ad-hoc espalhados pelas rotas.
3. **Endpoints de billing/assinatura** (quando implementados) seguem o mesmo padrão de camadas (routes → services → repositories) e nunca processam dados de cartão diretamente — usar gateway (Stripe ou similar) tokenizado.
4. **Planejar para multi-ambiente desde já**: configuração via `Settings(BaseSettings)` (`core/config.py`), nunca valores fixos que dependam de "onde" o código roda.

---

## 4. Fintech

1. **Valores monetários**: hoje `Float` em `Transaction.amount` — aceitável para MVP, mas **qualquer cálculo agregado (somas, saldos, forecasts) deve ser ciente de erro de ponto flutuante**. Se/quando migrar para `Numeric`/`Decimal`, é uma migration explícita e documentada, nunca silenciosa.
2. **Moeda**: assumir BRL (R$) como padrão implícito do MVP. Se/quando suporte multi-moeda for adicionado, isso é uma decisão arquitetural registrada (campo `currency`, conversão, etc.) — não adicionar campos de moeda "por via das dúvidas" antes disso.
3. **Deduplicação de transações via hash SHA-256** (`transactions.hash`, unique) é o mecanismo oficial de idempotência de upload — não criar mecanismo paralelo.
4. **Categorização automática tem `confidence_score`** — qualquer feature que consome categoria deve estar ciente de que categoria pode ser de baixa confiança (`OTHER`/`0.0`) até o categorizer ML ser treinado.
5. **Dados financeiros sensíveis** (saldo, faturas, extratos) nunca trafegam ou são logados em texto claro fora do fluxo autenticado da API.
6. **Cálculos financeiros (health score, forecast, etc.) devem ser testáveis isoladamente** — são lógica pura, sem I/O, e devem ter testes unitários com casos conhecidos antes de qualquer mudança na fórmula.

---

## 5. Product Management

1. **Escopo de sessão é contrato.** Quando o usuário define restrições explícitas ("não criar features", "não mexer no frontend"), essas restrições têm prioridade sobre qualquer "melhoria" que pareça boa ideia no momento. Itens fora do escopo viram entradas em "Pendências"/"Débitos técnicos", não código.
2. **Toda funcionalidade nova deve mapear para o roadmap em `README.md`** (Phase 1–4). Se uma demanda não se encaixa em nenhuma fase, isso é sinalizado ao usuário antes de implementar.
3. **MVP primeiro, polimento depois.** Entre "fazer funcionar end-to-end com escopo reduzido" e "fazer perfeito um pedaço isolado", priorizar o primeiro — fatias verticais geram valor visível e validável.
4. **Percentual de conclusão do MVP é reavaliado a cada sessão** em `docs/project_status.md`, com justificativa do que mudou.

---

## 6. Análise de Dados

1. **`pandas`/`numpy` são para os módulos de analytics/IA** (`services/analytics/`, `services/ai/`) — não introduzir dependências de data science em camadas de API/routes.
2. **Qualquer nova métrica/score** segue o padrão de `health_score.py`: função pura, parâmetros explícitos, retorno tipado, sem efeitos colaterais — facilita teste e reuso tanto em endpoint síncrono quanto em job batch futuro.
3. **Agregações pesadas** (forecast, behavioral analysis) não devem rodar inline em request HTTP síncrono se o volume de dados crescer — registrar como débito técnico ("mover para job assíncrono") em vez de otimizar prematuramente agora.
4. **Dados de treino/teste de modelos** (faturas reais, datasets) nunca são commitados no repositório — usar fixtures sintéticas/anonimizadas em `backend/tests/fixtures/`.

---

## 7. IA

1. **Categorizador segue o padrão "regras primeiro, ML depois"**: regras por keyword são o fallback determinístico; ML (TF-IDF + LogisticRegression) é o caminho de alta confiança quando treinado. Nunca remover o fallback de regras.
2. **Modelos treinados (`.joblib`) nunca são versionados** (já no `.gitignore`) — pipeline de treino deve ser reproduzível a partir de dados, não depender do artefato existir.
3. **`confidence_score` é obrigatório em qualquer output de classificação** — consumidores (API, frontend) decidem o que fazer com baixa confiança (ex.: pedir confirmação ao usuário), o modelo não decide por eles.
4. **Forecast (Prophet) e detecção comportamental (anomaly/clustering)** são componentes opcionais/degradáveis: se não houver dados suficientes (ex.: usuário novo, < 3 meses de histórico), o endpoint retorna estado explícito ("dados insuficientes"), nunca erro genérico ou número inventado.
5. **Assistente IA (chat)**: quando implementado, nunca deve ter acesso a dados de outros usuários nem executar ações destrutivas (delete, export) sem confirmação explícita do usuário no fluxo da conversa.

---

## 8. Git

1. **Conventional Commits sempre**: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`. Mensagens descrevem o "porquê", não apenas o "o quê".
2. **Nunca commitar**: `venv/`, `.env`, `__pycache__/`, `*.pyc`, bancos SQLite locais de teste (`*.db`), logs, arquivos de configuração local do Claude (`.claude/settings.local.json`), modelos `.joblib`.
3. **Push para `origin/master` sempre requer confirmação explícita do usuário**, mesmo quando o restante do procedimento foi pré-autorizado (ver `docs/session_end.md`).
4. **Nunca usar `--force`, `--no-verify`, `git reset --hard`, `git rebase -i`** sem pedido explícito e justificado do usuário.
5. **Cada commit deixa o projeto num estado consistente**: backend importável, sem migration pendente não commitada junto com a mudança de model que a originou.

---

## 9. Documentação

1. **`docs/project_status.md` é a fonte da verdade do estado do projeto.** Atualizado ao final de toda sessão que muda código ou arquitetura.
2. **`docs/next_session.md` é a memória de continuidade.** Deve permitir retomar o projeto "a frio" sem reler todo o histórico de chat.
3. **`README.md`** reflete o estado real e o roadmap — nunca descreve como implementado algo que é stub/placeholder.
4. **Comentários no código**: só quando o "porquê" não é óbvio (constraint escondida, workaround, invariante sutil). Nunca docstrings extensas nem comentários que descrevem "o quê" (nomes já fazem isso).
5. **Toda decisão que desvia de uma convenção documentada** (ex.: pin de dependência incomum, exceção de arquitetura) é documentada no momento em que é tomada — não depois, de memória.

---

## 10. Testes

1. **Zero testes é um débito técnico de prioridade alta**, registrado e visível em `docs/project_status.md` até ser endereçado.
2. **Lógica pura primeiro**: `core/security.py`, `services/analytics/health_score.py`, `services/ai/categorizer.py` (regras), `services/pdf/extractor.py` (parsers/normalização) são os candidatos ideais a testes unitários — sem I/O, fácil de cobrir.
3. **Rotas autenticadas**: testes de integração devem cobrir pelo menos o "happy path" + "sem token" + "token inválido/expirado" para cada novo endpoint protegido.
4. **Migrations**: toda nova migration deve ser validada com `alembic upgrade head` + `alembic downgrade -1` (ou `base`) antes do commit, no mínimo via SQLite local.
5. **Testes não dependem de serviços externos** (Postgres real, Tesseract, internet) por padrão — usar SQLite/mocks; testes que precisam de ambiente real são marcados e documentados separadamente.

---

## 11. Escalabilidade

1. **Índices acompanham padrões de query previstos**: já aplicado em `transactions` (`user_id`, `upload_id`, `date`, `category`) e `uploads`/`users` (`user_id`/`email`). Novas queries de dashboard/analytics que filtram por outro campo de alta cardinalidade devem considerar índice na mesma migration.
2. **Paginação é obrigatória** em qualquer endpoint que retorna lista potencialmente ilimitada (`transactions`, `uploads`). Endpoints de "list all" sem paginação são aceitáveis apenas como stub temporário, documentado como tal.
3. **OCR/parsing de PDF é custoso** — não bloquear a request HTTP principal; usar o padrão `Upload.status` (PENDING → PROCESSING → COMPLETED/FAILED) com processamento assíncrono/background.
4. **Connection pooling**: engine async do SQLAlchemy já configurado; não abrir conexões fora de `get_db()`/`AsyncSessionLocal`.
5. **Configuração de ambiente é 12-factor**: tudo via `Settings`/env vars, nada hardcoded que impeça rodar múltiplas instâncias.

---

## 12. LGPD

1. **PDFs processados em memória, nunca persistidos em disco** após extração (requisito explícito do `CLAUDE.md`).
2. **`raw_text` armazena apenas a linha extraída da transação**, nunca o conteúdo completo do PDF.
3. **Exclusão de usuário é em cascata**: `ON DELETE CASCADE` de `users` para `transactions`/`uploads` já implementado no schema — qualquer nova tabela com FK para `users.id` que armazene dado pessoal segue o mesmo padrão.
4. **Nenhum log contém PII** (nome, e-mail, dados financeiros, conteúdo de mensagens do assistente).
5. **Direito de acesso/portabilidade** (exportar todos os dados do usuário) é um requisito LGPD que deve ser considerado ao desenhar `reports`/exportação — não apenas relatórios financeiros, mas exportação completa de dados pessoais sob pedido.
6. **Consentimento e finalidade**: qualquer nova coleta de dado (ex.: integração Open Finance futura) exige campo de consentimento explícito antes de ser implementada.

---

## 13. Continuidade do Projeto

1. **Toda sessão começa seguindo `docs/session_start.md`** e termina seguindo `docs/session_end.md`. Sem exceções, mesmo em sessões pequenas — o custo de pular é perda de contexto para a próxima sessão.
2. **Claude Code atua como CTO permanente**: ao identificar um risco, débito técnico ou inconsistência fora do escopo da tarefa pedida, **documentar** (em `docs/project_status.md` ou como pendência), nunca ignorar silenciosamente — mas também nunca implementar a correção sem que esteja no escopo acordado da sessão.
3. **`docs/next_session.md` deve ser suficiente, sozinho, para qualquer sessão futura (mesmo com troca de modelo/ferramenta) retomar o projeto** sem precisar reler o histórico de chat.
4. **Mudanças nestas regras (`CLAUDE_PROJECT_RULES.md`) são raras e deliberadas** — se uma sessão identificar que uma regra está desatualizada ou conflitando com a realidade do projeto, isso é sinalizado ao usuário explicitamente, não corrigido silenciosamente.
