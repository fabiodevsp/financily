# Workflow de Início de Sessão

> Procedimento obrigatório a ser executado pelo Claude Code (atuando como CTO permanente do Financily) **no início de toda sessão de trabalho**, antes de qualquer implementação, correção ou alteração de código.
>
> Objetivo: garantir que cada sessão comece com contexto completo e atualizado, evitando retrabalho, regressões e decisões inconsistentes com o histórico do projeto.

---

## 1. Ler `CLAUDE_PROJECT_RULES.md`

- Releia as regras permanentes de governança (Arquitetura, Segurança, SaaS, Fintech, Product Management, Análise de Dados, IA, Git, Documentação, Testes, Escalabilidade, LGPD, Continuidade do Projeto).
- Estas regras têm prioridade sobre preferências pontuais — qualquer pedido do usuário que conflite com elas deve ser sinalizado explicitamente antes de prosseguir.

## 2. Ler `docs/project_status.md`

- Este é o **estado oficial do projeto**: o que está implementado, parcialmente implementado, planejado; problemas conhecidos; débitos técnicos; estimativa de conclusão do MVP.
- Não assumir que o estado mudou desde a última sessão além do que está documentado — mas também não assumir que nada mudou sem checar o Git (passo 4).

## 3. Ler `docs/next_session.md`

- Este é o documento de **memória de continuidade**, escrito ao final da sessão anterior especificamente para a sessão atual.
- Prestar atenção especial a:
  - "Onde paramos" e "Próximo objetivo" / "Próximo módulo recomendado"
  - "Riscos conhecidos" — coisas que podem quebrar se mexidas sem cuidado (ex.: pin de `bcrypt==4.0.1`)
  - "Decisões arquiteturais tomadas" — não revisitar/desfazer sem motivo explícito
  - "Ordem recomendada para desenvolvimento"

## 4. Validar estado do Git

Executar e revisar:

```bash
git status
git log --oneline -5
git diff --stat
```

- Confirmar que a árvore de trabalho está como esperado pelos documentos de continuidade (limpa, ou com alterações conhecidas/documentadas).
- Se houver alterações não commitadas ou não documentadas em `next_session.md`, **investigar antes de prosseguir** — pode ser trabalho em andamento de uma sessão anterior que não foi fechada corretamente.
- Confirmar que a branch atual é `master` (ou a branch esperada) e que está sincronizada com `origin` (ou que a divergência é conhecida/esperada).

## 5. Verificar pendências

- Cruzar a lista de "Próximos Passos" / "Pendências" / "Débitos técnicos" de `docs/project_status.md` e `docs/next_session.md` com a tarefa que o usuário está pedindo nesta sessão.
- Identificar se a tarefa pedida:
  - Está alinhada com a "Próxima tarefa recomendada" — ótimo, prosseguir.
  - É diferente da recomendação — aceitar a prioridade do usuário, mas mencionar brevemente o que estava planejado, caso seja relevante (ex.: dependências não atendidas).
  - Depende de algo listado como "não funciona ainda" ou "risco conhecido" — sinalizar isso ao usuário antes de começar.

## 6. Apresentar diagnóstico antes de qualquer implementação

Antes de escrever ou alterar qualquer código, apresentar ao usuário um resumo curto contendo:

1. Estado atual resumido (1-2 frases, baseado nos passos 2-4).
2. Qualquer alerta relevante (alterações não commitadas, divergência de branch, risco conhecido que afeta a tarefa pedida).
3. Confirmação de entendimento da tarefa pedida nesta sessão e como ela se encaixa no roadmap/pendências.
4. Caso a tarefa pedida conflita com `CLAUDE_PROJECT_RULES.md` ou com decisões arquiteturais já tomadas, expor o conflito explicitamente.

Somente após esse diagnóstico — e sem necessidade de aprovação formal do usuário para tarefas dentro do escopo já combinado — iniciar a implementação.

---

## Notas

- Este procedimento é leve por design: a maior parte é leitura de documentos já mantidos pelo próprio projeto (~poucos minutos). O custo de pular este passo é alto: retrabalho, regressões em decisões já tomadas, ou perda de continuidade entre sessões.
- Ver também: [`docs/session_end.md`](session_end.md) para o procedimento simétrico de encerramento.
