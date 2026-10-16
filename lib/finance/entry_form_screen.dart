import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
import '../data/entry_repository.dart';
import 'utils.dart';

class EntryFormScreen extends StatefulWidget {
  final EntryRepository repository;
  final VoidCallback onSaved;
  final EntryRecord? existing;
  final VoidCallback? onDeleted;

  const EntryFormScreen({
    super.key,
    required this.repository,
    required this.onSaved,
    this.existing,
    this.onDeleted,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  late EntryType _type;
  late EntryScope _scope;
  final _amountController = TextEditingController();
  late DateTime _date;
  String _category = '';
  final _noteController = TextEditingController();

  String? _amountError;
  String? _categoryError;
  String? _saveError;
  bool _hasAttemptedSave = false;
  bool _saving = false;

  final List<String> _businessIncomeCategories = [
    'Vendas',
    'Serviços Prestados',
    'Comissões',
    'Outras Receitas',
  ];

  final List<String> _businessExpenseCategories = [
    'Mercadorias / Matéria-prima',
    'Aluguel / Água / Luz',
    'Impostos / Taxas (DAS)',
    'Marketing / Divulgação',
    'Outras Despesas',
  ];

  final List<String> _personalCategories = [
    'Alimentação',
    'Moradia',
    'Transporte',
    'Saúde / Lazer',
    'Outros Pessoais',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _type = widget.existing!.type;
      _scope = widget.existing!.scope;
      _amountController.text = formatMoney(widget.existing!.amountCents)
          .replaceFirst('R\$ ', '');
      _date = widget.existing!.date;
      _category = widget.existing!.category;
      _noteController.text = widget.existing!.note ?? '';
    } else {
      _type = EntryType.income;
      _scope = EntryScope.business;
      _amountController.text = '';
      _date = DateTime.now();
      _category = _businessIncomeCategories.first;
    }

    _amountController.addListener(_validateAmountOnTyping);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _currentCategories {
    if (_scope == EntryScope.personal) {
      return _personalCategories;
    }
    return _type == EntryType.income
        ? _businessIncomeCategories
        : _businessExpenseCategories;
  }

  void _validateAmountOnTyping() {
    if (_hasAttemptedSave) {
      _validate();
    }
  }

  bool _validate() {
    setState(() {
      _hasAttemptedSave = true;
      final text = _amountController.text.trim();
      if (text.isEmpty) {
        _amountError = 'Informe o valor do lançamento';
      } else {
        try {
          parseMoney(text);
          _amountError = null;
        } on FormatException {
          _amountError = 'Informe um valor positivo no formato 1.234,56';
        }
      }

      if (_category.isEmpty) {
        _categoryError = 'Selecione uma categoria';
      } else {
        _categoryError = null;
      }
    });

    return _amountError == null && _categoryError == null;
  }

  Future<void> _save() async {
    if (_saving || !_validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      final amountCents = parseMoney(_amountController.text);
      final id =
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final record = EntryRecord(
        id: id,
        type: _type,
        scope: _scope,
        amountCents: amountCents,
        category: _category,
        date: _date,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      await widget.repository.upsert(record);
      if (mounted) widget.onSaved();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError = 'Não foi possível salvar o lançamento. Revise o valor e tente novamente.';
          _saving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.existing == null || _saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Lançamento'),
        content: const Text(
          'Tem certeza de que deseja excluir este lançamento? Esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _saving = true;
        _saveError = null;
      });
      try {
        await widget.repository.remove(widget.existing!.id);
        if (!mounted) return;
        if (widget.onDeleted != null) {
          widget.onDeleted!();
        } else {
          widget.onSaved();
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _saveError =
                'Não foi possível excluir o lançamento. Tente novamente.';
            _saving = false;
          });
        }
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    const primaryColor = Color(0xFF6C31C7);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditing ? 'Editar Lançamento' : 'Novo Lançamento',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              tooltip: 'Excluir Lançamento',
              onPressed: _saving ? null : _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Type Selector (Income vs Expense)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _type = EntryType.income;
                                if (!_currentCategories.contains(_category)) {
                                  _category = _currentCategories.first;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == EntryType.income
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _type == EntryType.income
                                    ? [
                                        const BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Receita (Entrada)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == EntryType.income
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _type = EntryType.expense;
                                if (!_currentCategories.contains(_category)) {
                                  _category = _currentCategories.first;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == EntryType.expense
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _type == EntryType.expense
                                    ? [
                                        const BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Despesa (Saída)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == EntryType.expense
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Scope Selector (Business vs Personal)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Escopo do Lançamento',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _scope == EntryScope.business
                                  ? 'Entra no resumo do negócio'
                                  : 'Isolado do negócio (Pessoal)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        DropdownButton<EntryScope>(
                          value: _scope,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: EntryScope.business,
                              child: Text('Negócio'),
                            ),
                            DropdownMenuItem(
                              value: EntryScope.personal,
                              child: Text('Pessoal'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _scope = val;
                                if (!_currentCategories.contains(_category)) {
                                  _category = _currentCategories.first;
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount Input Field
                  const Text(
                    'Valor (R\$)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: '0,00',
                      prefixText: 'R\$ ',
                      errorText: _amountError,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Selection
                  const Text(
                    'Categoria',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _currentCategories.contains(_category)
                        ? _category
                        : _currentCategories.first,
                    decoration: InputDecoration(
                      errorText: _categoryError,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _currentCategories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _category = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date Picker Field
                  const Text(
                    'Data',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatShortDate(_date),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Note Field (Optional)
                  const Text(
                    'Anotação (Opcional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Adicione uma observação, se desejar',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Save Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_saveError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_saveError!, key: const Key('save-error')),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEditing
                              ? 'Salvar Alterações'
                              : 'Adicionar Lançamento',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
