import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
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
    final today = DateTime.now();
    final lastMonth = year == today.year
        ? today.month
        : (year < today.year ? 12 : 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Acompanhamento anual')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Entradas informadas em $year',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              formatMoney(summary.totalCents),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Este total soma apenas as entradas do negócio registradas por você. Não inclui lançamentos pessoais nem desconta despesas.',
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Seu histórico parcial não confirma meses sem movimento. Esta soma não é uma apuração fiscal nem indica situação perante limites legais. Confira os canais oficiais.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (summary.totalCents == 0)
              const Text('Nenhuma entrada do negócio informada neste ano.'),
            for (var month = 1; month <= 12; month++)
              if (month <= lastMonth || summary.monthlyCents[month]! > 0)
                ListTile(
                  title: Text(_months[month - 1]),
                  subtitle: summary.monthlyCents[month] == 0
                      ? const Text(
                          'Sem entrada informada; movimento não confirmado',
                        )
                      : null,
                  trailing: summary.monthlyCents[month] == 0
                      ? null
                      : Text(formatMoney(summary.monthlyCents[month]!)),
                ),
          ],
        ),
      ),
    );
  }
}
