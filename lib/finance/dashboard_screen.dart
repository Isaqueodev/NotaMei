import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
import '../data/entry_repository.dart';
import '../theme/notamei_theme.dart';
import 'editorial_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final EntryRepository repository;
  final VoidCallback onAdd;
  final VoidCallback onHistory;
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.onAdd,
    required this.onHistory,
  });
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  EntryScope? _scope = EntryScope.business;
  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_onRepoChanged);
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_onRepoChanged);
      widget.repository.addListener(_onRepoChanged);
    }
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  void _changeMonth(int delta) => setState(() {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + delta,
    );
  });

  @override
  Widget build(BuildContext context) {
    final monthEntries = widget.repository
        .forMonth(_selectedMonth)
        .where((entry) => _scope == null || entry.scope == _scope)
        .toList();
    var income = 0;
    var expense = 0;
    var totalsOverflow = false;
    try {
      for (final entry in monthEntries) {
        if (entry.type == EntryType.income) {
          income = checkedAddCents(income, entry.amountCents);
        } else {
          expense = checkedAddCents(expense, entry.amountCents);
        }
      }
    } on RangeError {
      // Never display a wrapped or partial sum as a financial result.
      totalsOverflow = true;
    }
    final summary = MonthSummary(incomeCents: income, expenseCents: expense);
    final summaryTitle = switch (_scope) {
      EntryScope.business => 'Balanço do Negócio (Mês)',
      EntryScope.personal => 'Balanço Pessoal (Mês)',
      null => 'Balanço geral (Mês)',
    };
    final recentEntries = List<EntryRecord>.from(monthEntries)
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayEntries = recentEntries.take(5).toList();
    return Scaffold(
      backgroundColor: NotaMeiTheme.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/brand/notamei.png',
                  width: 32,
                  height: 32,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 10),
                const Text(
                  'NotaMei',
                  style: TextStyle(
                    color: NotaMeiTheme.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            EditorialMonthSelector(
              month: _selectedMonth,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in <(String, EntryScope?)>[
                  ('Negócio', EntryScope.business),
                  ('Pessoal', EntryScope.personal),
                  ('Todos', null),
                ])
                  ChoiceChip(
                    label: Text(option.$1),
                    selected: _scope == option.$2,
                    selectedColor: NotaMeiTheme.ink,
                    checkmarkColor: Colors.white,
                    labelStyle: editorialChipLabel(_scope == option.$2),
                    onSelected: (_) => setState(() => _scope = option.$2),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              key: const Key('monthly-summary'),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NotaMeiTheme.ink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    summaryTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalsOverflow ? '—' : formatMoney(summary.balanceCents),
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_scope == null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Negócio + Pessoal. Total geral dos registros informados.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(color: NotaMeiTheme.muted),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final items = [
                        _summaryItem(
                          'Entradas',
                          totalsOverflow ? '—' : formatMoney(income),
                          Icons.add,
                          NotaMeiTheme.incomeDark,
                        ),
                        _summaryItem(
                          'Saídas',
                          totalsOverflow ? '—' : formatMoney(expense),
                          Icons.remove,
                          NotaMeiTheme.expenseDark,
                        ),
                      ];
                      if (constraints.maxWidth /
                              MediaQuery.textScalerOf(context).scale(1) <
                          300) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            items[0],
                            const SizedBox(height: 16),
                            items[1],
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: items[0]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(left: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: NotaMeiTheme.muted),
                                ),
                              ),
                              child: items[1],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            if (totalsOverflow)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Os totais deste filtro excedem o intervalo suportado.',
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo Lançamento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NotaMeiTheme.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  'Lançamentos Recentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: widget.onHistory,
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LedgerSheet(
              key: const Key('recent-ledger'),
              children: [
                if (displayEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.edit_note,
                          color: NotaMeiTheme.muted,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum lançamento neste mês',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _scope == EntryScope.personal
                              ? 'Nenhum lançamento pessoal neste mês. Você pode registrar uma entrada ou saída pessoal.'
                              : 'Use Novo Lançamento acima para registrar uma entrada ou saída${_scope == EntryScope.business ? ' do negócio' : ''}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: NotaMeiTheme.muted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final entry in displayEntries) LedgerEntry(entry: entry),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Registros manuais e locais. Balanço = entradas menos saídas registradas.',
              style: TextStyle(color: NotaMeiTheme.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}
