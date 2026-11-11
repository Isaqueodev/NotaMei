# ADR-003 — Representar dinheiro em centavos inteiros e compartilhar os totais

- **Data do registro:** 2026-11-11.
- **Status:** decisão observada em `9076f3d`; registro retrospectivo, ratificação pendente.
- **Data da decisão original:** não estabelecida; nenhuma fórmula foi alterada por este ADR.
- **Relação anterior:** ARQ-03, preservada no [C4](../C4-NOTAMEI.md).

## Contexto

RF01–RF04 e RF07 precisam manter os valores informados; FB04/FB05 devem corresponder à seleção e aos totais da prévia. RN02 e RN06–RN09 delimitam representação e balanço; RN13 impede dupla contagem de internas; RN16 exige coerência do relatório. RNF03 mede exatidão e RNF07 delimita o volume do PDF, não uma segunda fórmula financeira.

## Alternativas consideradas

### A — Centavos inteiros, validação de limite e acumuladores exatos (observada)

**A favor:** corresponde à entrada monetária de até duas casas do produto e permite conferir os exemplos em unidades inteiras; reutiliza a mesma regra de totais em painel/repositório/relatórios.

**Contra:** não modela automaticamente moedas com outra escala ou cálculos de juros/arredondamentos fiscais; exige conferir limites ao converter acumuladores para o intervalo aceito.

### B — Representação decimal de precisão arbitrária

**A favor:** permitiria definir outras escalas e políticas explícitas de arredondamento caso surgissem requisitos para isso.

**Contra:** exigiria outra representação, política de persistência/conversão e avaliação de dependência; não existe uma necessidade aprovada desse novo modelo no MVP.

São alternativas explicativas, não prova de discussão histórica. Cálculos em texto de IA ou ponto flutuante binário sem política não são substitutos aprovados para o modelo atual.

## Decisão documentada

O valor de cada registro usa centavos inteiros positivos; `EntryType` representa a direção. `parseMoney`, `formatMoney` e `checkedAddCents` explicitam formato e limites. `EntryTotals` usa `BigInt` na agregação e conversão verificada; o anual filtra entradas comerciais comuns e usa adição protegida. CSV/PDF compartilham `CsvReport`, em vez de implementar outra regra financeira.

Não deduzir despesas no total atual de entradas do Ano. T10/MEL-MEI-02 propõe mostrar despesas separadas e ainda não está implementada nesta base. Movimentações internas continuam excluídas dos totais externos; balanço não é lucro nem saldo bancário.

## Consequências positivas

- Regras de cálculo passíveis de testes determinísticos com fixtures.
- Seleção, prévia e relatórios podem ser comparados em centavos, sem depender de formatação visual.
- Limite técnico não é confundido com teto legal de receita.

## Consequências negativas

- Exatidão aritmética não garante classificação correta, completude do histórico ou adequação contábil.
- Toda entrada, soma e saída exige respeitar a faixa e a escala; um erro de implementação ainda pode violar a decisão.
- Limites de PDF e disponibilidade de assets são restrições distintas; a regra de cálculo compartilhada não comprova geração ou compartilhamento bem-sucedidos.

## Evidências e verificação

- Código: [`money.dart`](../../../lib/core/money.dart), [`entry_totals.dart`](../../../lib/data/entry_totals.dart), [`annual_summary.dart`](../../../lib/annual/annual_summary.dart), [`csv_export.dart`](../../../lib/export/csv_export.dart), [`pdf_export.dart`](../../../lib/export/pdf_export.dart).
- Cobertura existente: [`money_test.dart`](../../../test/core/money_test.dart), [`withdrawal_totals_test.dart`](../../../test/finance/withdrawal_totals_test.dart), [`withdrawal_csv_test.dart`](../../../test/export/withdrawal_csv_test.dart).
- Plano: RNF03/RNF07 e [rastreabilidade](../RASTREABILIDADE.md); nenhum novo resultado de execução ou aprovação fiscal foi produzido por esta documentação.
