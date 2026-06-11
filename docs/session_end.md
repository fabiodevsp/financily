# Workflow de Encerramento de Sessão

> Procedimento obrigatório a ser executado pelo Claude Code (atuando como CTO permanente do Financily) **ao final de toda sessão de trabalho** que tenha alterado código, documentação ou configuração — mesmo sessões pequenas.
>
> Objetivo: garantir que o projeto possa ser retomado "a frio" em qualquer sessão futura, sem depender do histórico de chat, e que o repositório remoto reflita o estado mais recente de forma organizada e rastreável.

---

## 1. Atualizar documentação

- Revisar se alguma decisão tomada nesta sessão precisa ser refletida em:
  - `CLAUDE.md` (convenções/comandos — raramente muda)
  - `CLAUDE_PROJECT_RULES.md` (regras permanentes — muda raramente e só com sinalização explícita, ver regra 13.4)
  - `README.md` (se houver mudança de roadmap, status geral ou instruções de setup)
- Garantir que nenhuma funcionalidade nova esteja documentada como "implementada" se for apenas stub/placeholder.

## 2. Atualizar `docs/project_status.md`

- Adicionar/atualizar uma seção "## Última Sessão" (ou equivalente) com:
  - O que foi feito nesta sessão (features, correções, refatorações, governança).
  - Problemas encontrados e corrigidos.
  - Pendências/débitos técnicos novos ou resolvidos.
  - Atualizar a tabela de módulos/features (implementado / parcial / planejado) se aplicável.
  - Reavaliar o percentual de conclusão do MVP, com justificativa da mudança (ou ausência dela).

## 3. Atualizar `docs/next_session.md`

Reescrever para a próxima sessão, contendo no mínimo:

- Onde paramos
- O que já funciona
- O que ainda não funciona
- Próximo objetivo
- Próximo módulo recomendado / Próxima tarefa recomendada
- Arquivos mais importantes para revisar
- Riscos conhecidos
- Decisões arquiteturais tomadas (acumulativo — não remover decisões antigas ainda válidas)
- Ordem recomendada para desenvolvimento

Este documento deve ser **autossuficiente**: uma sessão futura (mesmo com outro modelo/ferramenta) deve conseguir retomar o trabalho lendo apenas `CLAUDE_PROJECT_RULES.md` + `docs/project_status.md` + `docs/next_session.md`.

## 4. Revisar alterações

```bash
git status
git diff --stat
git diff
```

- Ler o diff completo antes de adicionar ao stage. Confirmar que:
  - Nenhuma alteração não intencional está presente (ex.: arquivos de configuração local, debug prints).
  - Nenhum segredo (`.env`, chaves, tokens) está sendo incluído.
  - Toda mudança em `models/` tem migration correspondente em `alembic/versions/` (regra de Arquitetura #3).

## 5. Revisar dependências

- Se `requirements.txt` (backend) ou `pubspec.yaml` (frontend) foram alterados:
  - Confirmar que não há duplicatas.
  - Confirmar que novas dependências são justificadas e documentadas (em `project_status.md` se relevante).
  - Confirmar pins críticos (ex.: `bcrypt==4.0.1`) não foram alterados sem validação explícita.

## 6. Executar testes

```bash
cd backend
pytest -v
```

- Se não houver testes ainda (débito técnico conhecido), ao menos validar:
  - Sintaxe de todos os arquivos Python alterados (`python -m py_compile` ou `ast.parse`).
  - Import da aplicação principal (`from app.main import app`), quando dependências estiverem instaladas.
  - Se houver migration nova: `alembic upgrade head` + `alembic downgrade -1` (mínimo via SQLite local).
- Documentar em `project_status.md` caso testes não possam ser executados por falta de dependências no ambiente (não tratar como falha silenciosa).

## 7. Fazer commit

- Agrupar alterações logicamente relacionadas.
- Usar **Conventional Commits** (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`), com mensagem explicando o "porquê".
- **Excluir sempre**: `venv/`, `__pycache__/`, `.env`, arquivos temporários, bancos `.db` locais, `.claude/settings.local.json`, modelos `.joblib`, caches (`.dart_tool/`, `build/`).
- Adicionar arquivos explicitamente por nome (nunca `git add -A`/`git add .` sem revisão prévia do `git status`).

## 8. Fazer push

- `git push origin master` **somente após confirmação explícita do usuário** (ver `CLAUDE_PROJECT_RULES.md`, regra de Git #3) — mesmo que o restante deste procedimento já tenha sido pré-autorizado.
- Apresentar ao usuário: resumo do(s) commit(s) a serem enviados, e perguntar se deve prosseguir com o push.

## 9. Gerar resumo executivo

Ao final, apresentar ao usuário um resumo contendo:

1. Arquivos criados
2. Arquivos atualizados
3. Commit(s) gerado(s) e suas mensagens
4. Hash do(s) commit(s)
5. Confirmação se o push foi realizado (ou se está pendente de aprovação)
6. Estado atual do MVP (resumo)
7. Percentual aproximado de conclusão
8. Próxima tarefa recomendada (deve coincidir com o que foi escrito em `docs/next_session.md`)

---

## Notas

- Ver também: [`docs/session_start.md`](session_start.md) para o procedimento simétrico de início de sessão.
- Este procedimento aplica-se inclusive a sessões cujo objetivo foi puramente de governança/documentação (como esta) — a diferença é que os passos 6 (testes) e 5 (dependências) podem concluir rapidamente "sem mudanças relevantes" se nenhum código de runtime foi alterado.
