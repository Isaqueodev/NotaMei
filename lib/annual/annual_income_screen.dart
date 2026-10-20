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
    return Scaffold(
      backgroundColor: NotaMeiTheme.paper,
      appBar: AppBar(title: const Text('Acompanhamento anual')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Entradas informadas em $year',
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
                        const Text(
                          'TOTAL DE ENTRADAS · NEGÓCIO',
                          style: TextStyle(
                            color: NotaMeiTheme.muted,
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
                          'Este total soma apenas as entradas do negócio registradas por você. Não inclui lançamentos pessoais nem desconta despesas.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '—: sem entrada informada; movimento não confirmado',
                style: TextStyle(color: NotaMeiTheme.muted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: NotaMeiTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Seu histórico parcial não confirma meses sem movimento. Esta soma não é uma apuração fiscal nem indica situação perante limites legais. Confira os canais oficiais.',
                ),
              ),
              const SizedBox(height: 24),
              if (summary.totalCents == 0) ...[
                const Text('Nenhuma entrada do negócio informada neste ano.'),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final amount = summary.monthlyCents[month]!;
                          final value = Semantics(
                            label: amount == 0
                                ? '${_months[month - 1]}: sem entrada informada; movimento não confirmado'
                                : null,
                            child: Text(
                              amount == 0 ? '—' : '+ ${formatMoney(amount)}',
                              style: TextStyle(
                                color: amount == 0
                                    ? NotaMeiTheme.muted
                                    : NotaMeiTheme.income,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                          if (constraints.maxWidth /
                                  MediaQuery.textScalerOf(context).scale(1) <
                              300) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(_months[month - 1]),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: value,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: Text(_months[month - 1])),
                              const SizedBox(width: 16),
                              Flexible(child: value),
                            ],
                          );
                        },
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
}
