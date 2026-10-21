# FB08 — Retirada do titular / Pagar-me

Implementação autorizada sobre `9619b3a`, branch `feature/retirada-titular`, com commit local posteriormente autorizado pelo responsável. Sem push, merge, operação de aparelho físico ou acesso a dados privados. O ponto de retorno de código `rollback/pre-retiradas-9619b3a` permanece preservado.

## Escopo e interface

Início → **Pagar-me** abre formulário Flutter nativo com as fontes e marca V5 existentes. Não há quinto destino nem FAB. Valor positivo em pt-BR, data e observação opcional; salvar/cancelar. A operação é manual: Negócio → Pessoal, sem transferência real, folha, encargos, classificação automática de pró-labore/lucros, recorrência ou cálculo de lucro distribuível/capacidade de pagamento. Pode resultar em balanço negativo quando o histórico é parcial.

Recentes e Histórico identificam Retirada do titular, direção e edição/exclusão conjunta. Tocar qualquer ponta abre o formulário próprio (inclusive pela proteção do formulário comum). Edição e exclusão exigem confirmação explícita das DUAS pontas. Durante confirmação/gravação/exclusão, campos, data, botões e retorno são bloqueados. Mensagens antigas de sucesso são retiradas ao abrir novo formulário, para não cobrir Cancelar com texto ampliado e teclado. Erros mantêm o rascunho e o identificador da operação para nova tentativa. Filtros de âmbito e tipo do Histórico continuam independentes e selecionam cada ponta.

## Modelo e migração

`EntryRecord.withdrawalId` é nullable e `isWithdrawal` depende exclusivamente desse campo, nunca de categoria ou nota. SQLite versão 2 acrescenta `withdrawal_id TEXT` por `onUpgrade` com ALTER TABLE; criação nova inclui a coluna. Não há limpeza, recriação da base ou reclassificação de registros antigos. Serviços e preferências de primeiro uso/DAS não foram alterados.

Cada operação tem duas entradas:

- `withdrawal:<operationId>:business`: expense/business.
- `withdrawal:<operationId>:personal`: income/personal.
- Mesmo withdrawal_id, valor, data e nota; categoria visual Retirada do titular.

O formulário gera 128 bits aleatórios em hexadecimal uma única vez por rascunho. Retry reutiliza esse ID; editar conserva o vínculo e ambos os IDs de lançamento. O repositório exige ID não vazio/valor positivo e valida colisões dentro da transação: nunca usa REPLACE. Uma colisão com lançamento comum recusa toda a operação, inclusive se ocorrer na segunda ponta.

`saveWithdrawal` grava ambas as pontas, relê o snapshot e valida limites dentro de uma transação. Só depois do commit substitui o estado em memória e notifica listeners. Falha na segunda escrita ou na conversão dos registros durante a releitura reverte tudo. `upsert` comum recusa registros vinculados e IDs já vinculados consultando o banco; `remove(id)` encontra o vínculo e remove o par em uma única transação na própria fila, sem chamar outra operação enfileirada. Upsert comum também usa transação com releitura antes do commit.

A serialização vale para operações desta instância do repositório. Não há sincronização entre dispositivos ou API externa. ID do rascunho não é persistido antes do salvamento: fechar o processo perde rascunhos não salvos; não há promessa de recuperação desses rascunhos.

## Cálculos

`lib/data/entry_totals.dart` é o cálculo compartilhado por Dashboard, repository.summaryFor e CsvReport. Usa BigInt sem double; converte para int com checagem do intervalo nas telas/repositório. As verificações ordinárias comerciais mensais/anuais são preservadas, agora sem contar internas como despesa operacional. A retirada verifica totais do mês nos três âmbitos antes do commit. O painel também protege dados existentes fora do intervalo e não apresenta somas parciais. CSV mantém BigInt mesmo quando os totais excedem o painel.

- Entradas/Saídas: somente lançamentos comuns.
- Negócio: entradas - saídas - retiradas enviadas.
- Pessoal: entradas - saídas + retiradas recebidas.
- Todos: entradas - saídas comuns, sem internas, mesmo com apenas um tipo selecionado.
- Transferências enviadas/recebidas são demonstradas separadamente e respeitam a seleção de período/tipo.
- Anual: somente entradas comerciais externas registradas, sem conclusão fiscal.

Exemplo testado, em centavos: venda 100000, despesa 20000, retirada 30000. Negócio = 50000; Pessoal = 30000; Todos = 80000; entradas gerais = 100000; despesas gerais = 20000; anual comercial = 100000. Testes acrescentam gasto pessoal de 1000, movem a retirada de outubro para novembro e conferem os filtros mensais.

## CSV e prévia

Ambos usam o mesmo CsvReport e a mesma explicação dos filtros. A exportação continua somente leitura, com snapshot imutável de registros. Foram acrescentadas `natureza`, `withdrawal_id` e `criterio_resumo`: 14 colunas sem notas, 15 com notas. São cinco linhas de resumo: Entradas, Saídas, Transferências enviadas, Transferências recebidas e Balanço dos registros selecionados. Natureza/vínculo distinguem internas sem inferência textual. Mesmo com só Saídas em Todos, a retirada não infla os totais consolidados.

Preservados BOM UTF-8, CRLF, delimitador ponto e vírgula, escape de aspas, TAB em textos potencialmente perigosos (incluindo o vínculo), dinheiro numérico sem TAB, notas opt-in, aviso de sensibilidade, bloqueio de ações repetidas e gateways nativos existentes. Mitigação de fórmulas não garante segurança universal após processamento por outro aplicativo. CSV não é backup, restauração nem documento fiscal; compartilhamento não comprova transmissão.

## TDD e evidências

Testes foram escritos e executados antes da implementação das respectivas fatias. RED inicial da persistência mostrou API/campo ainda ausentes. REDs comportamentais posteriores observaram: upsert aceitando ponta; remoção deixando par incompleto/ignorando trigger da segunda ponta; despesas contando retirada (50000 em vez de 20000); limite de internas não rejeitado; ação/formulário/rótulos ausentes; colunas e totais de transferências ausentes; estado de exclusão ausente; SnackBar cobrindo Cancelar na sequência com 390px, texto 2x e teclado. Essas fatias foram executadas novamente em GREEN.

Testes novos:

- `test/data/withdrawal_test.dart`: SQLite real FFI, migração v1, preservação de dados/textos antigos e tabela não relacionada, reabertura, retry/IDs, colisão, concorrência entre operações e na mesma operação, editar/excluir par, notificações e fila sem deadlock. Triggers induzem falhas reais de INSERT/UPDATE/DELETE na segunda ponta e data inválida após ambas as escritas para provocar falha de releitura; banco e snapshot anteriores permanecem intactos.
- `test/finance/withdrawal_totals_test.dart`: exemplo de aceitação, anual, outros pessoais, filtro de tipo em Todos e mudança de mês.
- `test/finance/withdrawal_ui_test.dart`: fluxo, validação, data/nota, cancelamento, retry após sucesso de persistência seguido de erro injetado, bloqueios, confirmações, filtros, 390px/texto 2x/teclado e proteção contra mensagem sobreposta.
- `test/export/withdrawal_csv_test.dart`: natureza/vínculo, totais separados, prévia e CSV em Todos + só Saídas. Gera exclusivamente fixture sintética em `build/fb08-synthetic.csv`.
- `test/export/verify_fb08_csv.py`: parser independente da biblioteca padrão Python, conferindo BOM, 10 linhas uniformes de 15 colunas, vínculo, TAB, aspas, multiline e cinco totais.

Adaptações legadas intencionais: versão esperada do SQLite 1→2; contagem de zeros/travessões no painel 3→4 por causa da linha de retirada/recebimento; texto explicativo do rodapé no teste editorial. Nenhum teste foi excluído ou marcado skip. As validações históricas de 110 testes não são resultados desta execução. Logs atuais ficam em `build/fb08-test-final.log` e `build/fb08-build.log`.

Comandos de reprodução na raiz:

```sh
flutter analyze
flutter test --reporter expanded
python test/export/verify_fb08_csv.py
flutter build apk --debug
```

Resultado final desta execução: **127 testes aprovados** (110 legados + 17 novos), `flutter analyze` sem problemas e `git diff --check` sem erros de whitespace. A suíte final não emitiu warnings. Parser Python independente aprovado: 10 linhas x 15 colunas e cinco totais conferidos. APK debug: 188344001 bytes, SHA-256 `5ef85228b740b6edd25258a094e2cec61ea616b3db801457853695f2fafb11cb`.

Build debug executado com sucesso. Avisos reais: compatibilidade futura do KGP usado por flutter_file_dialog e discrepância de versões XML das ferramentas Android SDK. Não foram instalados SDKs, alteradas configurações globais ou operados aparelhos. Validação nativa/atualização de banco em dispositivo e salvar/compartilhar nativos permanecem pendentes.

## Reversibilidade e limites dos dados

A branch preservada aponta para código anterior; não é backup de lançamentos/preferências. Antes de trocar de branch, preservar o diff e arquivos novos por mecanismo Git escolhido pelo responsável (sem incluir dados privados). Não usar reset --hard, clean, desinstalação ou limpeza de dados como retorno automático. Nenhum comando de retorno foi executado nesta tarefa.

Uma base já migrada para esquema 2 não deve ser aberta por APK de esquema 1 sem estratégia de dados explícita e validada. Não há onDowngrade/migração reversa implementada e não se deve prometer compatibilidade com o APK anterior. Para voltar em dispositivo seriam necessários análise e consentimento separados: cópia consistente/verificada dos dados quando tecnicamente disponível e migração reversa que preserve o significado das retiradas, ou versão corretiva que continue entendendo esquema 2. Remover a coluna ou instalar o APK antigo sem isso não é estratégia segura. O CSV não permite restaurar a base e arquivos já compartilhados não são revogados por rollback de código.
