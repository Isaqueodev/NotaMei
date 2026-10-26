# Uso de IA na equipe NotaMei

## Pessoas e responsabilidade

**Pedro Isaque é o proprietário do repositório e, no momento, o único integrante que usa Hermes.** Matheus Rocha, Raphael Max e Luchie Bonates podem usar outras IAs, inclusive free tier; ainda não sabemos quais. Os papéis abaixo são uma proposta para Pedro/equipe confirmarem, não uma avaliação de competência nem atribuição já aceita.

| Pessoa | Foco inicial proposto | Skill da atividade |
| --- | --- | --- |
| Matheus Rebelo | Mudanças pequenas, inicialização e preparação da entrega | [Implementação segura](../../.agents/skills/notamei-implementacao-segura/SKILL.md) |
| Raphael Max | Lembretes, testes Android e evidências | [Validação Android](../../.agents/skills/notamei-validacao-android/SKILL.md) |
| Luchie Bonates | Coerência documental, pesquisa e acessibilidade | [Documentação/pesquisa](../../.agents/skills/notamei-documentacao-pesquisa/SKILL.md) |
| Pedro Isaque | Priorizar, aprovar regras/escopo, revisar e integrar contribuições | [Skill geral](../../.agents/skills/notamei-paralelo/SKILL.md) e [AGENTS.md](../../AGENTS.md) |

Uma pessoa pode usar outra skill se a tarefa exigir; os nomes não limitam quem pode programar/testar/documentar. Chaves, publicação e integração final precisam da decisão de Pedro.

## O que carregar em cada tarefa

1. [AGENTS.md](../../AGENTS.md): regras comuns e recorte já implementado.
2. [Skill geral](../../.agents/skills/notamei-paralelo/SKILL.md): procedimento curto de mudança verificável.
3. Apenas a skill da atividade da tabela.
4. A tarefa preenchida conforme [este contrato](TAREFA-PARA-IA.md), arquivos relevantes e testes próximos.

Não envie o repositório inteiro a cada pergunta. Comece pelo contexto necessário; leia dependências reais quando precisar. Não reduza contexto removendo a regra financeira que afeta a tarefa.

## Se a IA não reconhecer skills

O formato de uma skill é uma pasta com `SKILL.md`, metadados YAML e instruções Markdown.[6] `AGENTS.md` é um formato Markdown de orientações do projeto.[7] Isso não significa que toda interface/modelo carregará os arquivos automaticamente. Confirme a leitura; quando necessário, anexe ou cole o conteúdo compartilhável. Nenhuma instalação do Hermes é exigida para os demais.

Prompt inicial sugerido:

```text
Estou colaborando no NotaMei, de Pedro Isaque.
Leia AGENTS.md, a skill geral e a skill da minha atividade que anexei.
Minha tarefa e os arquivos permitidos estão no contrato abaixo.
Antes de editar, diga o que já existe e quais arquivos você realmente leu.
Se não tiver acesso a um arquivo ou terminal, peça o trecho ou a execução.
Não invente funções/testes/resultados, não amplie o escopo e não altere dados.
Não faça commit, merge, push ou troca de dependências/configuração por conta própria.
[cole o contrato preenchido]
```

Anexos/trechos devem ser **somente** código e documentação compartilháveis. Não envie entrevistas, PDFs privados, bancos, credenciais, capturas reais ou estado do Hermes. Confirme as exclusões em AGENTS.md e `.gitignore`.

## Trabalhando com cota/contexto limitados

- Uma tarefa pequena por conversa; não peça “refatore todo o app”.
- Antes do patch, peça uma proposta curta e confirme os arquivos. Pare se a IA começar a inventar backend, biblioteca, regra fiscal ou funcionalidade já existente.
- Exija patch/diff legível e verifique contra o código real, não apenas uma explicação convincente.
- Ao trocar de IA ou perder contexto, leve: tarefa, branch/commit, arquivos alterados, decisões aprovadas, testes realmente executados e pendências. Não transporte raciocínio interno, segredos nem logs privados.
- Erro de cota/provedor não prova defeito do app. Não peça instalação, permissão ampla ou troca global de modelo como atalho.
- Sem execução, a entrega é **proposta não validada**. A pessoa pode executar testes localmente e devolver as saídas sanitizadas.

## Portas de revisão humana

Antes de integrar, Pedro ou revisor designado confirma: escopo, regras preservadas, testes/resultados reais, diff sem arquivos estranhos e privacidade. Cada colaborador trabalha numa branch/escopo combinado; duas pessoas não editam o mesmo arquivo ao mesmo tempo. Não reescrever a main nem substituir arquivos completos para resolver conflito sem revisão.

Skills ajudam a reduzir ambiguidade, mas **não impedem alucinações nem constituem controle de permissões**. Modelos free tier variam em capacidade, limites e suporte a ferramentas. Os testes e a revisão humana continuam obrigatórios.

Consulte [checklist por pessoa](CHECKLIST-EQUIPE.md), [diagnóstico](DIAGNOSTICO-REPOSITORIO.md) e [benchmark de funcionalidades](BENCHMARK-FUNCIONALIDADES.md).

## Sources

[6] https://agentskills.io/specification
[7] https://agents.md
