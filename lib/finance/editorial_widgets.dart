import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
import '../theme/notamei_theme.dart';
import 'utils.dart';

/// A single paper surface: the rows are separated by rules, not floating cards.
class LedgerSheet extends StatelessWidget {
  const LedgerSheet({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(),
          children[i],
        ],
      ],
    ),
  );
}

class LedgerEntry extends StatelessWidget {
  const LedgerEntry({super.key, required this.entry, this.onTap});
  final EntryRecord entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final income = entry.type == EntryType.income;
    final color = income ? NotaMeiTheme.income : NotaMeiTheme.expense;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.isWithdrawal ? 'Retirada do titular' : entry.category,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (entry.isWithdrawal)
          const Text('Negócio → Pessoal · edição e exclusão das duas pontas'),
        const SizedBox(height: 4),
        Text(
          '${entry.scope == EntryScope.business ? 'Negócio' : 'Pessoal'} · ${formatShortDate(entry.date)}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
        ),
        if (entry.note?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            entry.note!,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ],
    );
    final amount = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${income ? '+' : '-'} ${formatMoney(entry.amountCents)}',
          textAlign: TextAlign.end,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          income ? 'Entrada' : 'Saída',
          style: TextStyle(color: color, fontSize: 14),
        ),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth /
                      MediaQuery.textScalerOf(context).scale(1) <
                  300;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [details, const SizedBox(height: 12), amount],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: details),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: amount),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class EditorialMonthSelector extends StatelessWidget {
  const EditorialMonthSelector({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Mês anterior',
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Text(
          formatMonthYear(month),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      IconButton(
        tooltip: 'Próximo mês',
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

TextStyle editorialChipLabel(BuildContext context, bool selected) => TextStyle(
  color: selected
      ? Theme.of(context).colorScheme.onPrimary
      : Theme.of(context).colorScheme.onSurface,
  fontSize: 14,
  fontWeight: FontWeight.w600,
);
