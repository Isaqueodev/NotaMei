import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
import '../finance/editorial_widgets.dart';
import '../theme/notamei_theme.dart';
import 'annual_summary.dart';

/// Acompanhamento dos lançamentos informados, sem inferir faturamento fiscal.
class AnnualIncomeScreen extends StatelessWidget {
  const AnnualIncomeScreen({
    super.key,
    required this.entries,
    required this.year,
  });

  final List<EntryRecord> entries;
  final int year;

  static const _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  Widget build(BuildContext context) {
    final summary = recordedAnnualIncome(entries, year);
    final expenses = recordedAnnualExpenses(entries, year);
    final noRecordedMovements =
        summary.totalCents == 0 &&
        expenses.totalCents == 0 &&
        !expenses.hasOverflow;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Acompanhamento anual')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Acompanhamento anual de $year',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              LedgerSheet(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'TOTAL DE ENTRADAS · NEGÓCIO · $year',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatMoney(summary.totalCents),
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: NotaMeiTheme.income,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Este total soma apenas as entradas do negócio registradas por você. Não inclui registros pessoais ou retiradas vinculadas.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LedgerSheet(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'TOTAL DE DESPESAS · NEGÓCIO · $year',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          expenses.totalCents == null
                              ? 'Indisponível'
                              : formatMoney(expenses.totalCents!),
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: NotaMeiTheme.expense,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Este total soma apenas as despesas comuns do negócio registradas por você. Não inclui registros pessoais ou retiradas vinculadas.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '—: sem registro daquele tipo; movimento não confirmado',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              if (expenses.hasOverflow) ...[
                const SizedBox(height: 16),
                _notice(
                  context,
                  'Alguns valores de despesas estão indisponíveis por exceder o limite de soma.',
                ),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Seu histórico parcial não confirma meses sem movimento. Este acompanhamento não é uma apuração fiscal nem indica situação perante limites legais. Confira os canais oficiais.',
                ),
              ),
              const SizedBox(height: 24),
              if (noRecordedMovements) ...[
                const Text(
                  'Nenhuma entrada ou despesa do negócio informada neste ano.',
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Meses de $year',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              LedgerSheet(
                children: [
                  for (var month = 1; month <= 12; month++)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _months[month - 1],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _monthlyAmountRow(
                            context,
                            month: _months[month - 1],
                            label: 'Entradas',
                            cents: summary.monthlyCents[month],
                            isExpense: false,
                          ),
                          const SizedBox(height: 8),
                          _monthlyAmountRow(
                            context,
                            month: _months[month - 1],
                            label: 'Despesas',
                            cents: expenses.monthlyCents[month],
                            isExpense: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthlyAmountRow(
    BuildContext context, {
    required String month,
    required String label,
    required int? cents,
    required bool isExpense,
  }) {
    final amount = cents == null
        ? 'Indisponível'
        : cents == 0
        ? '—'
        : formatMoney(cents);
    final color = cents == null
        ? Theme.of(context).colorScheme.error
        : cents == 0
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : isExpense
        ? NotaMeiTheme.expense
        : NotaMeiTheme.income;
    final semanticLabel = cents == null
        ? '$label de $month: indisponível por limite de soma'
        : cents == 0
        ? '$month: ${isExpense ? 'sem despesa' : 'sem entrada'} informada; movimento não confirmado'
        : '$label de $month: ${formatMoney(cents)}';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticLabel,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice(BuildContext context, String message) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(message),
  );
}