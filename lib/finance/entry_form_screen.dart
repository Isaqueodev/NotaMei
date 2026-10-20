import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
import '../data/entry_repository.dart';
import '../theme/notamei_theme.dart';
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
  final _amountFocus = FocusNode();
  final _errorKey = GlobalKey();
  late DateTime _date;
  String _category = '';
  final _noteController = TextEditingController();

  String? _amountError;
  String? _categoryError;
  String? _saveError;
  bool _hasAttemptedSave = false;
  bool _saving = false;
  bool _savedForAnother = false;

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
    _amountFocus.dispose();
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
      _savedForAnother = false;
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

  Future<void> _save({bool addAnother = false}) async {
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
      if (!mounted) return;
      if (addAnother && widget.existing == null) {
        // Only reset after persistence succeeds. Keep the classification/date
        // so a sequence of similar entries does not require repeated setup.
        setState(() {
          _hasAttemptedSave = false;
          _amountError = null;
          _categoryError = null;
          _saveError = null;
          _amountController.clear();
          _noteController.clear();
          _saving = false;
          _savedForAnother = true;
        });
        _amountFocus.requestFocus();
      } else {
        widget.onSaved();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError = 'Não foi possível salvar o lançamento. Revise o valor e tente novamente.';
          _saving = false;
        });
        _revealError();
      }
    }
  }

  void _revealError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final errorContext = _errorKey.currentContext;
      if (errorContext != null) Scrollable.ensureVisible(errorContext);
    });
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
              backgroundColor: NotaMeiTheme.expense,
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
          _revealError();
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
    final typeColor = _type == EntryType.income
        ? NotaMeiTheme.income
        : NotaMeiTheme.expense;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: NotaMeiTheme.paper,
        appBar: AppBar(
          title: Text(isEditing ? 'Editar Lançamento' : 'Novo Lançamento'),
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: NotaMeiTheme.expense,
                ),
                tooltip: 'Excluir Lançamento',
                onPressed: _saving ? null : _confirmDelete,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_saveError != null)
                        Padding(
                          key: _errorKey,
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _saveError!,
                              key: const Key('save-error'),
                              style: const TextStyle(
                                color: NotaMeiTheme.expense,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      _label('Tipo de movimentação'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in <(EntryType, String, Color)>[
                            (
                              EntryType.income,
                              'Receita (Entrada)',
                              NotaMeiTheme.income,
                            ),
                            (
                              EntryType.expense,
                              'Despesa (Saída)',
                              NotaMeiTheme.expense,
                            ),
                          ])
                            ChoiceChip(
                              label: Text(option.$2),
                              selected: _type == option.$1,
                              selectedColor: option.$3,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: _type == option.$1
                                    ? Colors.white
                                    : option.$3,
                                fontSize: 14,
                              ),
                              onSelected: _saving
                                  ? null
                                  : (_) => setState(() {
                                      _type = option.$1;
                                      if (!_currentCategories.contains(
                                        _category,
                                      )) {
                                        _category = _currentCategories.first;
                                      }
                                    }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _label('Âmbito do lançamento'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: NotaMeiTheme.border),
                        ),
                        child: DropdownButton<EntryScope>(
                          value: _scope,
                          isExpanded: true,
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
                          onChanged: _saving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      _scope = value;
                                      if (!_currentCategories.contains(
                                        _category,
                                      )) {
                                        _category = _currentCategories.first;
                                      }
                                    });
                                  }
                                },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scope == EntryScope.business
                            ? 'Entra no resumo do negócio'
                            : 'Isolado do negócio (Pessoal)',
                        style: const TextStyle(
                          color: NotaMeiTheme.muted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _label('Valor (R\$)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        readOnly: _saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '0,00',
                          prefixText: 'R\$ ',
                          errorText: _amountError,
                          errorMaxLines: 4,
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: NotaMeiTheme.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _type == EntryType.income
                            ? 'Entrada manual a ser somada no balanço'
                            : 'Saída manual a ser descontada do balanço',
                        style: TextStyle(color: typeColor, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      _label('Categoria'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey('category-${_scope.name}-${_type.name}'),
                        isExpanded: true,
                        itemHeight: null,
                        initialValue: _currentCategories.contains(_category)
                            ? _category
                            : _currentCategories.first,
                        decoration: InputDecoration(
                          errorText: _categoryError,
                          errorMaxLines: 3,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _currentCategories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                      ),
                      const SizedBox(height: 24),
                      _label('Data'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('entry-date'),
                        onPressed: _saving ? null : _pickDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                        ),
                        label: Text(formatShortDate(_date)),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: NotaMeiTheme.border),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _label('Anotação (Opcional)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        readOnly: _saving,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Adicione uma observação, se desejar',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Registro manual e local. Não é uma declaração fiscal.',
                        style: TextStyle(
                          color: NotaMeiTheme.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: NotaMeiTheme.border)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_savedForAnother)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            'Lançamento salvo. Você pode adicionar outro.',
                            style: TextStyle(
                              color: NotaMeiTheme.income,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
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
                      child: Text(
                        isEditing
                            ? 'Salvar Alterações'
                            : 'Adicionar Lançamento',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => _save(addAnother: true),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Text(
                          'Salvar e adicionar outro',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: NotaMeiTheme.ink,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}
