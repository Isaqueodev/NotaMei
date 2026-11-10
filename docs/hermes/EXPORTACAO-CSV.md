# NotaMei — Exportação CSV

**Versão da funcionalidade:** o recorte CSV foi implementado historicamente na branch `feature/exportacao-csv`, sobre o commit `cd68a826a0c75e85cb00068f648872d9552a8f78`. Neste checkout, CSV continua implementado e compartilha regras com PDF e retirada FB08. O commit/branch e as contagens deste documento são históricos; não substituem a inspeção do código atual nem foram reexecutados nesta T04.

> **Evolução PDF:** PDF está implementado neste recorte e conserva a seleção, prévia, `CsvReport` e `EntryTotals` do CSV. `buildPdfReport` renderiza em isolate e `ExportDocument` entrega bytes imutáveis, nome e MIME ao mesmo gateway nativo. A suíte integrada PDF registrada historicamente passou em 142 testes; isso não é execução desta T04. Consulte [PDF, limites e validação](EXPORTACAO-PDF.md).

## Acesso

Ajustes → Exportar CSV. A tela carrega os lançamentos do repositório local e mostra a prévia do intervalo, filtros, contagem e totais antes de gerar o arquivo.

## Seleção de período

A pessoa escolhe uma **data de referência** (anchor) e um **período**:

| Período | Intervalo (inclusive) | Regra de ancoragem |
|---------|----------------------|-------------------|
| Dia | Apenas a data de referência | Início = fim = anchor |
| Semana | Segunda-feira a domingo | Início = segunda da semana do anchor; fim = domingo seguinte |
| Mês | 1º ao último dia do mês | Início = 1º dia do mês do anchor; fim = último dia do mês |
| Ano | 1º de janeiro a 31 de dezembro | Início = 1º jan do ano do anchor; fim = 31 dez do mesmo ano |

A comparação usa **datas civis** (ano/mês/dia) sem componente de hora. O intervalo é **inclusive** em ambas as pontas: `start <= data <= end` (implementado via `start` inclusive e `endExclusive` exclusivo no código).

> **Nota:** o construtor de `ExportSelection` normaliza o `anchor` removendo a componente de hora (`DateTime(anchor.year, anchor.month, anchor.day)`), de modo que a seleção depende apenas da data civil.

## Filtros

- **Âmbito:** Negócio (padrão), Pessoal ou Todos (Negócio + Pessoal).
- **Tipo:** Entradas e saídas (padrão), apenas Entradas ou apenas Saídas.
- **Observações:** Desativado por padrão para reduzir exposição de dados sensíveis. Quando ativado, a coluna `observacao` é incluída.

Os totais consideram **apenas os filtros ativos**, separando entradas/saídas comuns de transferências enviadas/recebidas. No âmbito individual, balanço = entradas - saídas + recebidas - enviadas. Em **Todos**, internas são excluídas dos totais consolidados mesmo com apenas um tipo selecionado; os totais separados de transferências explicam as linhas internas selecionadas. Desde FB08, painel, repositório e CSV usam `EntryTotals` compartilhado. [Detalhes de retirada e migração](RETIRADA-TITULAR.md).

## Formato do arquivo

| Atributo | Especificação |
|----------|---------------|
| Codificação | UTF-8 com BOM (`\uFEFF`) |
| Delimitador | Ponto e vírgula (`;`) |
| Decimal | Vírgula, sem separador de milhares (ex.: `1234,56`) |
| Inteiros/centavos | Registros em centavos inteiros; totais com `BigInt`, sem ponto flutuante |
| Aspas | Todos os campos entre aspas duplas; aspas internas dobradas (`""`) |
| Mitigação de fórmulas | Textos com padrões iniciais perigosos recebem TAB dentro das aspas; a detecção inclui sinais `=`, `+`, `-`, `@`, variantes de largura total e sinais precedidos por whitespace/controles/BOM. Textos iniciados por tabulação ou quebra de linha também recebem prefixo. Valores monetários não recebem prefixo. |
| Fim de linha | CRLF (`\r\n`) |

O TAB acrescentado permanece no dado exportado e pode afetar importações programáticas. A mitigação destina-se à leitura em planilhas e não garante segurança universal, sobretudo se outro programa remover o prefixo ou reprocessar o arquivo. Referência: [OWASP CSV Injection](https://owasp.org/www-community/attacks/CSV_Injection).

### Estrutura uniforme de linhas

Todas as linhas (incluindo cabeçalho, lançamentos e resumo) têm as mesmas colunas:

```
secao;periodo_inicio;periodo_fim;filtro_ambito;filtro_tipo;id;data;tipo;ambito;valor_brl;categoria;natureza;withdrawal_id;criterio_resumo;observacao?
```

- Linhas `secao = Lancamento`: um lançamento por linha, com metadados repetidos (período, filtros).
- Linhas `secao = Resumo`: cinco linhas de totais (Entradas, Saídas, Transferências enviadas, Transferências recebidas, Balanço dos registros selecionados), com `id` e `data` vazios, `tipo` = rótulo do total, `ambito` = rótulo do filtro de âmbito, `categoria`, `natureza` e `withdrawal_id` vazios.
- Desde FB08, `natureza` distingue lançamento comum de retirada do titular e `withdrawal_id` identifica o par de linhas Negócio/Pessoal. `criterio_resumo` explica a seleção e a exclusão de internas em Todos em todas as linhas; a mesma explicação aparece na prévia. São 14 colunas sem notas e 15 com notas. A identificação não torna o relatório um backup restaurável.

O nome do arquivo segue o padrão: `notamei_YYYY-MM-DD_YYYY-MM-DD.csv` (início e fim do intervalo selecionado).

## Ações de saída

Dois botões independentes, ambos desabilitados durante a geração ou se não houver lançamentos no intervalo/filtros:

1. **Salvar CSV** — Abre o seletor de documentos do sistema (`flutter_file_dialog`, `localOnly: true`). A pessoa escolhe a pasta; o app não faz upload automático de rede nem altera o banco/esquema.
2. **Compartilhar CSV** — Entrega o arquivo ao **Share Sheet nativo** do Android (`share_plus`). O app não controla o que o aplicativo de destino faz com o arquivo (cópia, envio, nuvem, etc.). **Compartilhar não prova transmissão** bem-sucedida nem entrega ao destinatário final.

### Estados de resultado

- `saved` — Arquivo gravado no local escolhido.
- `shared` — Arquivo entregue ao app escolhido; **confirme nele o envio**.
- `cancelled` — Pessoa cancelou o seletor ou o share sheet; nenhum lançamento foi alterado.
- `unconfirmed` — Share sheet aberto; resultado final desconhecido pelo app.
- Erro inesperado — Mensagem genérica; nenhum lançamento foi alterado.

### Proteções de concorrência

- Botões desabilitados durante a operação (`_busy`).
- `PopScope` impede retorno enquanto exporta.
- Nenhuma gravação no repositório financeiro; a exportação é somente leitura.

## O que **não** é

| Conceito | Não confundir com |
|----------|-------------------|
| **Backup restaurável** | O CSV não pode ser importado para restaurar o banco. Não há esquema de versão, integridade referencial nem migração. |
| **Documento fiscal / comprovante** | Não certifica faturamento, lucro, limite legal, regularidade ou meses sem movimento. |
| **Sincronização / nuvem** | Não há envio automático, conta no app nem backend. |

## Privacidade e sensibilidade dos dados exportados

- O arquivo contém **dados financeiros pessoais e do negócio** (valores, categorias, observações opcionais, datas, âmbitos).
- Uma vez fora do app (salvo no armazenamento compartilhado ou entregue a outro app), **o NotaMei não tem controle** sobre cópias, backups do sistema, sincronização de nuvem do destino, acesso de outros apps ou vazamento.
- O plugin de compartilhamento pode materializar **cópias temporárias em cache** do sistema/do app destino. **Não há promessa de limpeza garantida nem confidencialidade** após a entrega ao Share Sheet.
- Recomendação: use armazenamento criptografado do aparelho, evite apps de destino não confiáveis e trate o CSV como documento sensível.

## Verificação histórica do recorte CSV

| Item | Resultado |
|------|-----------|
| Baseline, antes das alterações CSV | 95 testes aprovados; análise estática limpa |
| Suíte integrada final | **110 testes aprovados** |
| `flutter analyze` | Sem problemas |
| `flutter build apk --debug` | Sucesso; aviso de compatibilidade futura do plugin Kotlin Gradle usado por `flutter_file_dialog` |
| Testes unitários | Períodos por datas civis, filtros combinados, soma exata, CSV, escaping, mitigação de fórmulas, notas opt-in e contratos de gateway com fronteiras nativas simuladas |
| Testes de widget | Filtros, prévia, ações injetadas, falha/nova tentativa, cancelamento, vazio, bloqueio de ação duplicada e 390 px com texto 2x |
| Validação nativa em dispositivo nesta sessão | **Não realizada**; nenhum dispositivo conectado |

A documentação histórica de FB01/FB02 registra 76 testes; a de V5 registra 95; o recorte CSV registra 110 e o PDF registra 142. Essas contagens não são testes executados nesta T04. A conferência de CSV real com dados fictícios e parser independente também pertence ao histórico do recorte CSV.

## Rollback seguro

**Atenção desde FB08:** as instruções abaixo documentam o retorno histórico do incremento CSV, que não mudava o banco. Não são autorização para instalar código/esquema 1 sobre uma base já migrada para esquema 2. Consulte [reversibilidade da retirada](RETIRADA-TITULAR.md); não há downgrade de dados implementado.

Branch da feature: `feature/exportacao-csv`
Commit base (branch anterior `feature/lancamentos-sequencia-filtro-inicio`): `cd68a826a0c75e85cb00068f648872d9552a8f78`
Branch de segurança (snapshot do baseline): `rollback/pre-csv-cd68a82`
Bundle externo verificado: `C:/Users/Usuario/Documents/GitHub/NotaMei-pre-csv-cd68a82.bundle`

### Instruções de rollback (preservam alterações atuais primeiro)

```bash
# 1. Guarda alterações em andamento (inclui arquivos não rastreados; ignorados não entram no stash)
git stash push -u -m "wip exportacao-csv"

# 2. Volta para a branch de desenvolvimento anterior
git switch feature/lancamentos-sequencia-filtro-inicio

# 3. Restaura dependências
flutter pub get
```

**Avisos:**
- `git stash` **não** inclui arquivos ignorados (`.gitignore`); backups manuais de arquivos ignorados, se houver, devem ser feitos à parte.
- **Não use** `git reset --hard` nem `git clean` — eles descartam trabalho não commitado irreversivelmente.
- O rollback de **código** não apaga CSVs já exportados nem restaura o banco SQLite a um estado anterior. O bundle contém código e histórico Git, **não dados do aplicativo**. Recuperação dos registros exige backup de dados próprio, ainda não implementado pelo NotaMei; não presuma que o bundle recupere lançamentos.

## Validação física posterior — resultado parcial

O APK foi atualizado em um Samsung A17 com Android 16, sem desinstalação ou limpeza de dados; a identidade binária instalada foi conferida. O seletor nativo de documentos abriu e o cancelamento retornou ao NotaMei com a mensagem correspondente. **Na automação pelo agente, o salvamento completo com releitura do CSV e o compartilhamento nativo não foram concluídos.** As execuções OpenCode foram interrompidas por erros de rotas de modelos (HTTP 410 e HTTP 404); isso não demonstra, por si só, defeito no aplicativo.

Os registros fictícios foram removidos exclusivamente pela interface, com confirmação e conferência de cada exclusão. O estado final dos lançamentos foi comparado integralmente à cópia inicial (IDs e conteúdo), e as preferências Flutter foram conferidas semanticamente. O app foi deixado no Início. Snapshots, logs e relatório detalhado permanecem privados fora do Git. Esta rodada não equivale à aprovação completa da exportação nativa; os cenários restantes devem ser retomados com uma rota de execução funcional.

**Evidência manual complementar:** o responsável forneceu uma captura do CSV aberto no Google Sheets, com as colunas de lançamentos e as linhas de resumo. A imagem comprova visualmente a abertura/importação nessa planilha, sem constituir conferência independente de todos os valores ou de cada etapa do salvamento/compartilhamento. A captura e os dados financeiros nela presentes não integram o repositório. O responsável considerou a validação suficiente para este incremento e autorizou o commit.

## Versionamento e reversibilidade

O incremento reúne a exportação CSV, testes, documentação e a anotação de backlog FB08 (pró-labore, sem implementação). O histórico Git identifica o commit e seu pai para eventual reversão. A branch de segurança e o bundle descritos acima preservam a base anterior. Snapshots privados, APKs, logs e dados financeiros não fazem parte do commit. Merge e push exigem autorização separada.