import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
import '../data/entry_repository.dart';
import 'utils.dart';

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
  EntryScope? _scopeFilter; // null = all, business, personal
  EntryType? _typeFilter; // null = all, income, expense

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

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthEntries = widget.repository.forMonth(_selectedMonth);

    // Filter by scope and type if selected
    final filteredEntries = monthEntries.where((e) {
      if (_scopeFilter != null && e.scope != _scopeFilter) return false;
      if (_typeFilter != null && e.type != _typeFilter) return false;
      return true;
    }).toList();

    // Sort descending by date
    filteredEntries.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Histórico de Lançamentos',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month Selector Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF334155),
                    ),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    formatMonthYear(_selectedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF334155),
                    ),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Filter Chips Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selectedColor: const Color(0xFFF3ECFA),
                      checkmarkColor: const Color(0xFF6C31C7),
                      label: const Text('Todos'),
                      selected: _scopeFilter == null && _typeFilter == null,
                      onSelected: (selected) {
                        setState(() {
                          _scopeFilter = null;
                          _typeFilter = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selectedColor: const Color(0xFFF3ECFA),
                      checkmarkColor: const Color(0xFF6C31C7),
                      label: const Text('Negócio'),
                      selected: _scopeFilter == EntryScope.business,
                      onSelected: (selected) {
                        setState(() {
                          _scopeFilter = selected ? EntryScope.business : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selectedColor: const Color(0xFFF3ECFA),
                      checkmarkColor: const Color(0xFF6C31C7),
                      label: const Text('Pessoal'),
                      selected: _scopeFilter == EntryScope.personal,
                      onSelected: (selected) {
                        setState(() {
                          _scopeFilter = selected ? EntryScope.personal : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selectedColor: const Color(0xFFF3ECFA),
                      checkmarkColor: const Color(0xFF6C31C7),
                      label: const Text('Entradas'),
                      selected: _typeFilter == EntryType.income,
                      onSelected: (selected) {
                        setState(() {
                          _typeFilter = selected ? EntryType.income : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selectedColor: const Color(0xFFF3ECFA),
                      checkmarkColor: const Color(0xFF6C31C7),
                      label: const Text('Saídas'),
                      selected: _typeFilter == EntryType.expense,
                      onSelected: (selected) {
                        setState(() {
                          _typeFilter = selected ? EntryType.expense : null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // List of entries
            Expanded(
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum lançamento encontrado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tente mudar os filtros ou o mês selecionado.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        return _buildHistoryCard(entry);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(EntryRecord entry) {
    final isIncome = entry.type == EntryType.income;
    final isPersonal = entry.scope == EntryScope.personal;
    final color = isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return InkWell(
      onTap: () => widget.onEdit(entry),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.category,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (isPersonal)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Pessoal',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatShortDate(entry.date)}${entry.note != null && entry.note!.isNotEmpty ? ' • ${entry.note}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} ${formatMoney(entry.amountCents)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
