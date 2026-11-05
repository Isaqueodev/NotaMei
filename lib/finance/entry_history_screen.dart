import 'package:flutter/material.dart';

import '../data/entry_record.dart';
import '../data/entry_repository.dart';
import '../theme/notamei_theme.dart';
import 'editorial_widgets.dart';

class EntryHistoryScreen extends StatefulWidget {
  final EntryRepository repository;
  final void Function(EntryRecord) onEdit;
  const EntryHistoryScreen({
    super.key,
    required this.repository,
    required this.onEdit,
  });
  @override
  State<EntryHistoryScreen> createState() => _EntryHistoryScreenState();
}

class _EntryHistoryScreenState extends State<EntryHistoryScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  EntryScope? _scopeFilter;
  EntryType? _typeFilter;
  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_onRepoChanged);
  }

  @override
  void didUpdateWidget(EntryHistoryScreen oldWidget) {
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
    final filteredEntries =
        widget.repository
            .forMonth(_selectedMonth)
            .where(
              (entry) =>
                  (_scopeFilter == null || entry.scope == _scopeFilter) &&
                  (_typeFilter == null || entry.type == _typeFilter),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('HistÃ³rico')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            EditorialMonthSelector(
              month: _selectedMonth,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 20),
            const Text('Ã‚mbito', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  'Todos',
                  _scopeFilter == null,
                  (_) => setState(() {
                    _scopeFilter = null;
                  }),
                ),
                _chip(
                  'NegÃ³cio',
                  _scopeFilter == EntryScope.business,
                  (selected) => setState(
                    () => _scopeFilter = selected ? EntryScope.business : null,
                  ),
                ),
                _chip(
                  'Pessoal',
                  _scopeFilter == EntryScope.personal,
                  (selected) => setState(
                    () => _scopeFilter = selected ? EntryScope.personal : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  'Entradas',
                  _typeFilter == EntryType.income,
                  (selected) => setState(
                    () => _typeFilter = selected ? EntryType.income : null,
                  ),
                  color: NotaMeiTheme.income,
                ),
                _chip(
                  'SaÃ­das',
                  _typeFilter == EntryType.expense,
                  (selected) => setState(
                    () => _typeFilter = selected ? EntryType.expense : null,
                  ),
                  color: NotaMeiTheme.expense,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '${filteredEntries.length} registros',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            LedgerSheet(
              key: const Key('history-ledger'),
              children: [
                if (filteredEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_edu,
                          size: 32,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum lanÃ§amento encontrado',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tente mudar os filtros ou o mÃªs selecionado.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                for (final entry in filteredEntries)
                  LedgerEntry(entry: entry, onTap: () => widget.onEdit(entry)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    String label,
    bool selected,
    ValueChanged<bool> onSelected, {
    Color? color,
  }) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    selectedColor: color ?? Theme.of(context).colorScheme.primary,
    checkmarkColor: Theme.of(context).colorScheme.onPrimary,
    labelStyle: editorialChipLabel(context, selected),
  );
}

