import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
import '../data/entry_repository.dart';
import '../data/entry_totals.dart';
import 'withdrawal_form_screen.dart';
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
    var summary = const MonthSummary(incomeCents: 0, expenseCents: 0);
    var totalsOverflow = false;
    try {
      summary = EntryTotals.calculate(
        monthEntries,
        scope: _scope,
      ).checkedSummary();
    } on RangeError {
      totalsOverflow = true;
    }
    final income = summary.incomeCents;
    final expense = summary.expenseCents;
    final summaryTitle = switch (_scope) {
      EntryScope.business => 'Balanço do Negócio (Mês)',
      EntryScope.personal => 'Balanço Pessoal (Mês)',
      null => 'Balanço geral (Mês)',
    };
    final recentEntries = List<EntryRecord>.from(monthEntries)
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayEntries = recentEntries.take(5).toList();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                Text(
                  'NotaMei',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
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
                    selectedColor: Theme.of(context).colorScheme.primary,
                    checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                    labelStyle: editorialChipLabel(context, _scope == option.$2),
                    onSelected: (_) => setState(() => _scope = option.$2),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              key: const Key('monthly-summary'),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    summaryTitle,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalsOverflow ? '—' : formatMoney(summary.balanceCents),
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_scope == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Negócio + Pessoal. Total geral dos registros informados.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Divider(color: Theme.of(context).colorScheme.onPrimary.withAlpha(120)),
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
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withAlpha(120)),
                                ),
                              ),
                              child: items[1],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_scope != EntryScope.personal) ...[
                    const SizedBox(height: 16),
                    _summaryItem(
                      'Retiradas para você',
                      totalsOverflow ? '—' : formatMoney(summary.sentCents),
                      Icons.arrow_forward,
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                  if (_scope != EntryScope.business) ...[
                    const SizedBox(height: 16),
                    _summaryItem(
                      'Recebido do negócio',
                      totalsOverflow ? '—' : formatMoney(summary.receivedCents),
                      Icons.arrow_back,
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                  if (_scope == null)
                    Text(
                      'Movimentações internas não entram nos totais gerais de entradas, saídas ou balanço.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => WithdrawalFormScreen(
                    repository: widget.repository,
                    onSaved: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Pagar-me'),
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
                        Icon(
                          Icons.edit_note,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final entry in displayEntries)
                  LedgerEntry(
                    entry: entry,
                    onTap: entry.isWithdrawal
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => WithdrawalFormScreen(
                                repository: widget.repository,
                                existing: entry,
                                onSaved: () => Navigator.of(context).pop(),
                              ),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Registros manuais e locais. Balanço considera entradas e saídas comuns e, por âmbito, retiradas enviadas/recebidas. Em Todos, movimentações internas são excluídas.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
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
