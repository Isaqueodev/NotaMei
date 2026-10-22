---
name: notamei-implementacao-segura
description: "Implemente mudanças pequenas no NotaMei com testes."
license: MIT
metadata:
  author: "Equipe NotaMei, Hermes Agent"
  version: "0.1.0"
---

# NotaMei — implementação segura

## Quando usar

Para uma alteração de comportamento autorizada, pequena e testável. Foco inicial proposto a Matheus Rocha; qualquer integrante pode usar. Não autoriza implementar todo o backlog.

## Pré-requisitos

Leia [AGENTS.md](../../../AGENTS.md), a tarefa e os arquivos/testes envolvidos. Consulte a skill geral se faltar contexto. Não depende de terminal Hermes: use o terminal disponível ou peça execução humana.

## Procedimento

1. Informe a branch/HEAD, o que já existe e quais arquivos serão alterados. Declare o que não será tocado, especialmente banco, dependências e assinatura.
2. Escreva o critério de aceite em comportamento observável. Para um bug, registre como reproduzir e se é observado ou hipótese estática.
3. Leia chamadores e testes; confirme a assinatura de cada API usada. Não crie um método porque parece existir em Flutter ou num concorrente.
4. Adicione teste mínimo antes da alteração; confirme a falha esperada. Faça o menor patch e confirme o teste passar, sem enfraquecer asserções para esconder regressão.
5. Preserve rascunho/retry, campos/data/âmbito, IDs e publicação após persistência. Mudança de UI não autoriza migração, novo serviço ou cálculo financeiro paralelo.
6. Execute testes direcionados, analyze e suíte quando disponíveis; confira diff/status. Solicite revisão humana antes de integrar.

## Tarefas de partida propostas

- Recuperação visual na falha de inicialização: erro seguro/retry, sem apagar/recriar banco; distinguir falha do banco de falha não bloqueante do lembrete.
- Depois de aprovada, busca textual no Histórico: combinar com filtros existentes sem alterar registros ou totais financeiros fora da seleção aprovada.
- Planejar versão/atualização e roteiro fictício de demonstração. Chaves, assinatura de distribuição e publicação continuam decisões de Pedro.

Esses itens são propostas do checklist, não ordens de implementação nesta sessão. Aceite e arquivos serão confirmados no contrato de cada tarefa.

## Armadilhas

Não use `EntryFormScreen` de edição para clonar um registro e sobrescrever o original. Não duplique ponta de retirada. Não suponha saldo bancário ou limite fiscal. Não faça refatoração geral, atualização de pacotes ou troca de modelo para contornar uma falha. Ao faltar contexto/cota, pare com um resumo do diff e próximos comandos reais.

## Verificação

Entregue mudança, teste que falhou/passou, comandos e saídas resumidas, regressões verificadas e pendências. Sem SDK/terminal, entregue uma proposta marcada como **não executada**, não uma implementação declarada pronta.
