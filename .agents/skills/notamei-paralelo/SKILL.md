---
name: notamei-paralelo
description: "Trabalhe no NotaMei preservando regras e dados."
license: MIT
metadata:
  author: "Equipe NotaMei, Hermes Agent"
  version: "0.2.0"
---

# NotaMei — mudança pequena e verificável

## Quando usar

Ao analisar, desenvolver ou revisar o NotaMei, em qualquer IA. Não depende de Hermes nem de serviço pago. Pedro Isaque é o proprietário; os demais integrantes usam as ferramentas que escolherem.

## Pré-requisitos

Leia [AGENTS.md](../../../AGENTS.md), a tarefa aprovada e as seções relevantes de [requisitos e RN](../../../docs/hermes/REQUISITOS-ARQUITETURA.md). Caminhos de código citados a seguir são relativos à raiz do clone. Sem acesso a arquivos/terminal, peça os trechos e não finja execução.

## Procedimento

1. Confira branch/HEAD/alterações e identifique arquivos permitidos. Não sobrescreva trabalho alheio nem crie nova implementação de algo já existente.
2. Leia a API real e os testes próximos. Apresente resultado esperado, mudança mínima e como verificar. Se a regra estiver indefinida, peça decisão a Pedro.
3. Preserve as invariantes de AGENTS.md: centavos e totais exatos, âmbitos, vínculo das duas pontas, anual comercial, notas opt-in e seleção comum CSV/PDF. As três funcionalidades CSV, PDF e retirada já existem; relatório não é backup.
4. Faça uma fatia por vez, com teste que reproduza a alteração de comportamento antes do patch. Use os nomes e assinaturas encontrados no código, não os de exemplos externos.
5. Rode o teste direcionado, `flutter analyze` e `flutter test` quando a alteração for executável. Se algo não puder rodar, registre o bloqueio e deixe a validação pendente. Não instale ferramentas nem altere dependências por conta própria.
6. Confira diff/status e entregue arquivos, comandos/resultados reais, riscos e pendências. Commit, merge e push exigem autorização específica; a entrega padrão é o diff para revisão.

## Armadilhas

- Datas/contagens em documentos de migração são históricas, não execução atual.
- `EntryTotals` centraliza resumos; filtro Todos não deve voltar a contar retirada como receita/despesa externa.
- `enable`, `disable` e `refresh` do DAS não têm os mesmos caminhos de falha. Não generalize o comportamento de um para os outros.
- Em testes Flutter/SQLite, confira o padrão local de FFI e `tester.runAsync`; não introduza outra inicialização sem necessidade. Indicador indeterminado com `Completer` pendente não deve ser esperado com `pumpAndSettle` infinito.
- Nunca apague dados/reinstale como recuperação automática. Versão de código não é restauração de banco.
- Preserve marca N/fontes locais. Não envie pesquisa privada, bancos, credenciais ou capturas reais à IA.

## Verificação

Aceite exige escopo atendido, nenhum arquivo inesperado no diff, regras preservadas e evidências reais ou marcação explícita de não executado. Build, instalação, teste nativo e uso observado são verificações distintas. Skill reduz ambiguidade; não garante ausência de alucinação.
