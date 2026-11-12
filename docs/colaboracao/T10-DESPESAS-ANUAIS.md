# T10 — Despesas no acompanhamento anual

## Responsabilidade e origem

- **Responsável pela implementação:** Raphael Max.
- **Equipamentos informados por Pedro:** computador **Windows** e celular **iPhone**. Flutter/SDK, acesso a Mac e emulador Android não foram confirmados.
- **Revisão técnica:** Matheus Rebelo e Pedro Isaque; Pedro decide integração.
- **Validação Android:** executor a designar por Pedro em T05; não depende de Raphael possuir Android.
- **Situação:** tarefa atribuída para desenvolvimento; funcionalidade ainda não implementada. Nenhum teste deste contrato foi executado como parte da redistribuição.
- **Base inspecionada:** `a3e3764`, após sincronização de `main` com `origin/main`. Confirmar novamente branch/HEAD e alterações alheias antes de programar.
- **Origem:** [MEL-MEI-02](../avaliacao/BACKLOG-MELHORIAS.md#mel-mei-02--despesas-no-acompanhamento-anual), questionário F1, seção F, p.3; [síntese da avaliação](../avaliacao/FEEDBACK-MEI-2026-11-04.md). É uma pessoa em dois instrumentos, não uma demanda comprovada de toda a comunidade.
- **Objetivo:** permitir consultar despesas informadas do Negócio no mesmo acompanhamento anual que hoje apresenta entradas. É evolução funcional, não correção de uma soma de entradas comprovadamente errada.

Ler o [contrato geral](TAREFA-PARA-IA.md) e a [implementação segura](../../.agents/skills/notamei-implementacao-segura/SKILL.md). Esta tarefa não autoriza implementar o restante do backlog, operar aparelhos reais ou realizar commit/push/merge automaticamente.

## Recorte para esta entrega

1. Manter o âmbito **Negócio** do acompanhamento anual atual; não criar seletor de âmbitos nesta fatia.
2. Mostrar **entradas informadas** e **despesas informadas**, em indicadores anuais distintos e em cada um dos doze meses do ano selecionado.
3. Despesas são saídas comuns do Negócio (`EntryType.expense`, `EntryScope.business`, `!entry.isWithdrawal`) no ano civil selecionado. Entradas continuam seguindo a regra já existente; excluir Pessoal e ambas as pontas de retiradas.
4. Usar centavos inteiros, `checkedAddCents` e `formatMoney` existentes. Não usar `double`, novos arredondamentos ou um cálculo financeiro independente dos registros.
5. Manter avisos de histórico parcial e de ausência de apuração fiscal. Mês sem entrada não é mês sem movimentação: pode conter despesa. Ausência de registros não comprova inatividade.
6. Não calcular saldo acumulado, saldo bancário, lucro, teto fiscal, dívida ou obrigação de pagamento. Não criar indicador de diferença entre entradas e despesas nesta entrega.
7. Não alterar banco, dados, criação/edição de lançamentos, filtros do Início/Histórico, retirada vinculada, CSV/PDF, notificações, fontes, assinatura ou dependências.

**Dependência financeira delimitada:** MEL-MEI-01 (continuidade entre meses) permanece fora do escopo e não bloqueia o total de despesas anuais. Retiradas já existem; não implementar outra operação Pagar-me nem contabilizá-las como despesas externas.

## Código existente a preservar

Inspecionados na base acima:

- `lib/annual/annual_summary.dart`: `AnnualRecordedIncome` e `recordedAnnualIncome` já calculam entradas externas comerciais em doze meses, com soma protegida.
- `lib/annual/annual_income_screen.dart`: conferência documental em `9076f3d` confirma que `AnnualIncomeScreen` recebe `entries` e `year`, sem `onYearChanged` ou seletor de ano. A composição passa o ano corrente; a tela apresenta entradas, meses e avisos. A menção anterior ao callback era incorreta e não autoriza criar essa API.
- `test/annual/annual_summary_test.dart` e `test/annual/annual_income_screen_test.dart`: testes existentes, incluindo interpretação de histórico parcial e meses futuros.
- `lib/core/money.dart`: limites e utilitários de soma/formatação.
- `lib/data/entry_record.dart`: tipos, âmbitos e vínculo da retirada; ler antes de montar fixtures.

Confirmar os chamadores antes da alteração. Preservar as APIs de entradas e o construtor da tela; acrescentar o cálculo das despesas sem quebrar consumidores existentes. Se decidir introduzir novo resumo puro em vez de função adicional, manter compatibilidade com as APIs atuais. O nome de uma função nova é decisão de implementação, não API já existente.

## Fronteiras de edição

**Pode editar:**

- `lib/annual/annual_summary.dart`;
- `lib/annual/annual_income_screen.dart`;
- `test/annual/annual_summary_test.dart`;
- `test/annual/annual_income_screen_test.dart`;
- este contrato, somente para registrar execução, evidências e pendências reais.

**Pode criar:** um teste específico em `test/annual/` se ajudar a isolar despesas; informar nome e finalidade no diff.

**Leitura, sem edição nesta fatia:** modelos, repositório, `money.dart`, totais de outros módulos e teste `test/finance/withdrawal_totals_test.dart`. Mudanças em arquivos compartilhados, regras, requisitos, banco ou dependências exigem combinar novo escopo com Pedro. Não refatorar tema/global, corrigir tipografia dos colegas ou alterar outros testes para esconder falhas.

## Aceite verificável

- [ ] **Total anual:** entradas e despesas comerciais comuns aparecem separadas, com ano e rótulos explícitos.
- [ ] **Detalhamento:** os doze meses mostram os dois tipos de valor sem confundir ausência de entrada com ausência de despesa. Janeiro e dezembro pertencem ao mesmo recorte civil; registros de outros anos não entram.
- [ ] **Separação:** registros Pessoais não entram; uma retirada vinculada completa não aumenta entrada nem despesa anual do Negócio.
- [ ] **Só despesas:** com despesas e nenhuma entrada, continuar exibindo despesas; não ocultar a seção inteira por ausência de receitas.
- [ ] **Vazio:** sem registros, mostrar ausência de informação com legenda honesta; não escrever que houve inatividade. Zero acumulado de registros não significa saldo bancário zero.
- [ ] **Histórico e datas:** manter o ano fornecido à tela, meses futuros e histórico parcial; sem converter datas silenciosamente para outro fuso ou limitar ao mês corrente. Troca de ano pode ser testada reconstruindo o widget com outro `year`; não exige adicionar seletor de ano nesta fatia.
- [ ] **Integridade:** consulta não altera registros. Edição/exclusão já refletida na lista de entrada recalcula o resumo; não criar persistência ou cache paralelo.
- [ ] **Limites:** overflow mensal ou anual das despesas não gera valor parcial, negativo por estouro ou total truncado; apresentar aviso seguro e indisponibilidade dos valores afetados. Entradas continuam seguindo sua proteção atual.
- [ ] **Acessibilidade automatizada:** leitura/rótulos distinguem entradas de despesas; doze meses alcançáveis com rolagem e layout de 390 px com texto 2x sem exceção de overflow. Não chamar teste de widget de ensaio TalkBack.
- [ ] **Regressão:** testes de entradas e retirada preservados; não enfraquecer asserções nem pular testes para obter aprovação.

### Fixture mínima proposta — somente dados fictícios

Todos os valores abaixo estão em **centavos**, com datas no ano indicado; usar IDs sintéticos e as duas pontas com o mesmo `withdrawalId`.

| Ano/mês | Tipo/âmbito | Centavos | Efeito esperado no anual de 2026 |
| --- | --- | --- | --- |
| 2026/01 | Entrada comum / Negócio | 12345 | Entrada de janeiro |
| 2026/01 | Saída comum / Negócio | 2500 | Despesa de janeiro |
| 2026/02 | Entrada comum / Negócio | 10000 | Entrada de fevereiro |
| 2026/02 | Saída comum / Negócio | 1000 | Despesa de fevereiro |
| 2026/02 | Retirada enviada / Negócio | 3000 | Excluída de despesas externas |
| 2026/02 | Retirada recebida / Pessoal | 3000 | Excluída de entradas |
| 2026/02 | Entrada comum / Pessoal | 90000 | Excluída |
| 2026/02 | Saída comum / Pessoal | 6000 | Excluída |
| 2025/12 | Saída comum / Negócio | 700 | Outro ano; excluída |
| 2027/01 | Entrada comum / Negócio | 1300 | Outro ano; excluída |

**Esperado:** entradas anuais de `22345` centavos e despesas anuais de `3500` centavos. Acrescentar testes separados de dezembro, somente despesas, lista vazia, troca de ano, atualização da lista e estouro mensal/anual. Não inserir essas fixtures na base real de nenhum participante.

## Execução no computador de Raphael

**Alvo de trabalho: Windows, sem depender do iPhone.** SDK Flutter e dependências precisam estar disponíveis; não é necessário conectar celular nem executar emulador para testes unitários/de widget. Usar branch de trabalho própria, por exemplo `feature/despesas-anual`, sem compartilhar arquivos em edição com outra pessoa.

- Confirmar o ambiente com `flutter --version` e `flutter doctor -v`; registrar somente os bloqueios pertinentes aos testes. Não presumir SDK instalado nem exigir configurar plataformas fora desta tarefa.
- Executar os testes do módulo pelo terminal do Windows. Teste de widget não exige portar ou executar o aplicativo completo para Windows, web ou iOS; a tarefa não autoriza adicionar suporte a essas plataformas.
- O iPhone não executa o APK Android. No fluxo oficial Flutter, compilar iOS exige macOS/Xcode; não atribuir build iOS local no Windows nem presumir que possuir iPhone resolve esse requisito. Nenhuma versão iOS é prometida por esta tarefa.
- O teste de regressão que usa SQLite FFI depende das bibliotecas nativas de teste disponíveis no Windows; se houver bloqueio, registrar o erro e pedir apoio. Não alterar dependências ou trocar o teste por um resultado presumido.
- Um emulador Android no Windows pode ser avaliado separadamente se necessário e viável, mas não é requisito para entregar os testes unitários/de widget. Ensaios nativos continuam em T05 com executor designado por Pedro.

Referências técnicas oficiais para esse recorte: [testes Flutter](https://docs.flutter.dev/testing/overview), [instalação no Windows](https://docs.flutter.dev/install/manual) e [configuração iOS](https://docs.flutter.dev/platform-integration/ios/setup). Não representam verificação do computador de Raphael.

1. Registrar HEAD, `git status --short --branch` e ambiente disponível.
2. Executar os testes existentes do módulo para registrar o baseline; falha anterior deve ser distinguida de regressão nova.
3. Escrever teste mínimo das despesas **antes** do código; registrar falha esperada e só então implementar.
4. Executar a validação abaixo e anotar resultado real, inclusive bloqueios. Não inventar contagens ou afirmar aprovação porque o comando foi sugerido.
5. Solicitar revisão e entregar diff. Pedro coordena o ensaio Android posterior e a integração.

| Comando/cenário | Responsável/ambiente | Execução desta tarefa | Resultado |
| --- | --- | --- | --- |
| `flutter test test/annual` — baseline | Raphael / computador com Flutter | Não | Pendente |
| Novo teste mínimo falhando antes do código | Raphael / teste automatizado | Não | Pendente |
| `flutter test test/annual` — após implementar | Raphael / teste automatizado | Não | Pendente |
| `flutter test test/finance/withdrawal_totals_test.dart` | Raphael / teste automatizado | Não | Pendente |
| `flutter analyze` | Raphael / computador com Flutter | Não | Pendente |
| `flutter test` — suíte completa | Raphael / computador com Flutter | Não | Pendente; registrar falhas preexistentes separadamente |
| `git diff --check` e revisão do diff | Raphael e revisor | Não | Pendente |
| Tela Ano, navegação e leitura no Android | Executor de T05 / candidato identificado | Não | Pendente, separado da entrega automatizada |

Sem SDK ou dependência disponível, registrar bloqueio e pedir apoio; não substituir por um APK não testado. Esta revisão de planejamento não declara o baseline técnico atual aprovado.

## Entrega esperada

- Diff pequeno com a funcionalidade e os testes, sem dados privados.
- Identificação de commit/base, comandos e saídas reais resumidas.
- Cenários novos e regressões cobertos, com resultados de antes/depois.
- Pendências Android explicitamente abertas até T05, com responsável designado por Pedro.
- Ajuste da documentação funcional após revisão, sem declarar o recurso implementado antes do código e dos testes.

**Pronto para revisão de código** e **validado em Android para distribuição** são estados diferentes. Não marcar T10 como concluída apenas por editar este documento.
