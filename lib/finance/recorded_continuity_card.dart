import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
import 'recorded_continuity.dart';

class RecordedContinuityCard extends StatelessWidget {
  const RecordedContinuityCard({
    super.key,
    required this.entries,
    required this.month,
    required this.scope,
  });

  final Iterable<EntryRecord> entries;
  final DateTime month;
  final EntryScope? scope;

  @override
  Widget build(BuildContext context) {
    final summary = RecordedContinuity.calculate(
      entries,
      month: month,
      scope: scope,
    );
    final scopeLabel = switch (scope) {
      EntryScope.business => 'Negócio',
      EntryScope.personal => 'Pessoal',
      null => 'Todos: Negócio + Pessoal',
    };
    final first = summary.firstRecordedDate;
    final end = '${month.month.toString().padLeft(2, '0')}/${month.year}';
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: const Text('Continuidade entre meses'),
        subtitle: Text('Acumulado dos registros · $scopeLabel'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            first == null
                ? 'Sem registros neste âmbito até o mês selecionado.'
                : 'Desde ${first.day.toString().padLeft(2, '0')}/${first.month.toString().padLeft(2, '0')}/${first.year}.',
          ),
          const SizedBox(height: 12),
          const Text('Até o mês anterior'),
          Text(
            summary.previousCents == null
                ? '—'
                : formatMoney(summary.previousCents!),
            key: const Key('continuity-previous'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text('Até o fim de $end'),
          Text(
            summary.accumulatedCents == null
                ? '—'
                : formatMoney(summary.accumulatedCents!),
            key: const Key('continuity-accumulated'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (summary.previousCents == null ||
              summary.accumulatedCents == null) ...[
            const SizedBox(height: 8),
            const Text(
              'Valor acumulado indisponível: excede o intervalo suportado.',
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Histórico pode estar incompleto. Considera somente os registros informados, sem saldo inicial manual. Não é saldo bancário nem lucro.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Edições e exclusões recalculam o acumulado. Retiradas saem do Negócio e entram no Pessoal; em Todos, não alteram o acumulado.',
          ),
        ],
      ),
    );
  }
}
