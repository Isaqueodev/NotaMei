# MEL-MEI-01 — Continuidade entre meses

## Recorte autorizado em 12/11/2026

O proprietário escolheu **acumular os registros informados desde o primeiro lançamento, sem saldo inicial manual e sem mudar o banco**. Implementação na branch `feature/continuidade-meses`, iniciada em `ac5b655` e sincronizada antes da PR com `dd73ea5` (merge da PR #26). As correções de texto recebidas da `main` foram preservadas sem alterações adicionais. Integração por PR e ensaio Android permanecem separados desta entrega.

## Comportamento

No Início, o painel expansível **Continuidade entre meses**, após Novo Lançamento/Pagar-me e antes dos recentes, acompanha o mês e o âmbito selecionados:

- **Até o mês anterior:** acumulado de todos os registros de meses civis anteriores ao selecionado.
- **Até o fim de MM/AAAA:** acumulado incluindo todo o mês selecionado; exclui meses posteriores. Não é uma posição até o dia atual.
- **Negócio/Pessoal:** soma entradas comuns menos saídas comuns, mais retiradas recebidas menos retiradas enviadas, reutilizando `EntryTotals`.
- **Todos:** soma movimentos externos dos dois âmbitos, sem incluir nenhuma ponta de retirada interna.
- Meses sem movimento mantêm a continuidade; valores negativos são possíveis. Antes do primeiro registro elegível, os indicadores são zero, sem inferir patrimônio inicial.
- A data inicial é a do primeiro registro elegível do âmbito, não uma declaração de histórico completo. O painel mostra aviso de incompletude e de que o resultado não é saldo bancário nem lucro.
- Edições de valor/data/âmbito e exclusões recalculam a visão após a publicação do snapshot persistido pelo repositório.

## Invariantes e limites

O balanço do mês e seus filtros permanecem independentes. Não há lançamento de transporte de saldo, cópia de registros, saldo inicial persistido, migração de esquema, escrita financeira ou mudança de CSV/PDF/anual. A seleção mensal usa ano/mês civil, coerente com o repositório, sem converter datas UTC para outro mês.

As somas usam `BigInt` do cálculo canônico. Cada resultado líquido é validado independentemente contra `maxMoneyCents` antes de converter para `int`. Resultado fora do intervalo aparece como `—`, com mensagem, sem wrap nem soma parcial; o outro indicador e o balanço mensal não ficam indisponíveis por consequência automática. Entradas/saídas brutas acumuladas não são indicadores deste painel.

## Código e testes

- `lib/finance/recorded_continuity.dart`: projeção somente leitura.
- `lib/finance/recorded_continuity_card.dart`: apresentação expansível e avisos.
- `lib/finance/dashboard_screen.dart`: composição e atualização pelo listener existente; título do aplicativo flexível para 320 px/texto ampliado.
- `test/finance/recorded_continuity_test.dart`: vazio, centavos, meses sem movimento, virada de ano, escopos/retiradas, datas civis, limites positivos/negativos e retroatividade.
- `test/finance/recorded_continuity_screen_test.dart`: balanço mensal separado, exclusão de meses futuros, filtros, edição/exclusão persistidas, mês vazio, retirada, overflow independente e superfície 320 px/texto 2x.
- `test/finance/editorial_b_test.dart`: adaptação de rolagem para a folha lazy abaixo do novo painel, preservando as asserções anteriores.

A primeira integração foi observada falhar por ausência do recurso antes da implementação e passar depois. Na execução de desenvolvimento anterior à sincronização: 37 testes direcionados aprovados; `flutter analyze` limpo; suíte completa com 134 aprovações e os mesmos 34 casos não aprovados do baseline de `ac5b655`, sem novos casos com falha nessa comparação.

Antes da PR, após sincronizar `dd73ea5`: análise limpa e 37 direcionados aprovados. A suíte completa da branch teve 157 aprovações e 11 casos não aprovados (10 erros e 1 falha). O baseline limpo dessa mesma `main`, executado em worktree separada, teve 141 aprovações e os mesmos 11 casos não aprovados, por arquivo/nome. A melhoria do baseline veio da atualização da equipe; esta funcionalidade não reivindica autoria sobre a correção dos textos. Esses resultados não equivalem a suíte totalmente aprovada ou ausência de qualquer regressão possível.

## APK e aceite pendente

APK universal de **teste**, preservando a assinatura de desenvolvimento atual. O build usa número 2 via argumento, sem alterar a versão declarada no `pubspec.yaml`. Logs, hashes e evidências ficam fora do Git. Conferência de ZIP/manifesto/assinatura não substitui instalação e uso real.

Aceite Android pendente: abrir o painel, alternar âmbitos/meses, editar/excluir registro anterior, conferir mês vazio e atualização sobre a versão anterior sem limpeza de dados. Não desinstalar nem apagar banco para esse ensaio. Não afirmar avaliação comunitária ou validação do participante de origem a partir dos testes automatizados.
