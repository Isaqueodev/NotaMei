import 'dart:math';

import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/entry_record.dart';
import '../data/entry_repository.dart';
import '../theme/notamei_theme.dart';
import 'utils.dart';

class WithdrawalFormScreen extends StatefulWidget {
  const WithdrawalFormScreen({
    super.key,
    required this.repository,
    required this.onSaved,
    this.existing,
    this.onDeleted,
  });
  final EntryRepository repository;
  final EntryRecord? existing;
  final VoidCallback onSaved;
  final VoidCallback? onDeleted;
  @override
  State<WithdrawalFormScreen> createState() => _WithdrawalFormScreenState();
}

class _WithdrawalFormScreenState extends State<WithdrawalFormScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _form = GlobalKey<FormState>();
  late final String _operationId;
  late DateTime _date;
  bool _saving = false;
  bool _deleting = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
    // Generated once per draft, not on each save/retry. No personal data in ID.
    _operationId =
        widget.existing?.withdrawalId ??
        List.generate(
          16,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
    _date = widget.existing?.date ?? DateTime.now();
    if (widget.existing case final entry?) {
      _amount.text = formatMoney(entry.amountCents).replaceFirst('R\$ ', '');
      _note.text = entry.note ?? '';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<bool> _confirm({required bool deleting}) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(deleting ? 'Excluir retirada' : 'Alterar retirada'),
          content: Text(
            deleting
                ? 'Excluir as DUAS pontas desta retirada? Esta ação não poderá ser desfeita.'
                : 'A alteração afeta as DUAS pontas: saída do Negócio e entrada no Pessoal.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(deleting ? 'Excluir' : 'Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _submit({bool deleting = false}) async {
    if (_saving || (!deleting && !_form.currentState!.validate())) return;
    // Lock before confirmation as well, preventing a second dialog/action.
    setState(() {
      _saving = true;
      _deleting = deleting;
      _error = null;
    });
    if ((deleting || widget.existing != null) &&
        !await _confirm(deleting: deleting)) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    try {
      if (deleting) {
        await widget.repository.remove(widget.existing!.id);
      } else {
        await widget.repository.saveWithdrawal(
          operationId: _operationId,
          amountCents: parseMoney(_amount.text),
          date: _date,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
      }
      if (!mounted) return;
      // Route callbacks may leave this widget mounted in embedded/test hosts.
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleting
                ? 'Retirada excluída dos dois âmbitos.'
                : 'Retirada salva: saída do Negócio e entrada no Pessoal.',
          ),
        ),
      );
      (deleting ? widget.onDeleted ?? widget.onSaved : widget.onSaved)();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = deleting
              ? 'Não foi possível confirmar a exclusão. Tente novamente.'
              : 'Não foi possível salvar. Seus dados foram mantidos; tente novamente.';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(9999, 12, 31),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: NotaMeiTheme.paper,
      appBar: AppBar(
        title: Text(
          _saving
              ? (_deleting ? 'Excluindo…' : 'Salvando retirada…')
              : widget.existing == null
              ? 'Pagar-me'
              : 'Editar retirada',
        ),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: _saving ? null : () => Navigator.maybePop(context),
        ),
        actions: [
          if (widget.existing != null)
            IconButton(
              tooltip: 'Excluir retirada',
              onPressed: _saving ? null : () => _submit(deleting: true),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Retirada do titular',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text('Negócio → Pessoal'),
              const SizedBox(height: 12),
              const Text(
                'Registro manual de movimentação interna: uma saída do Negócio e uma entrada no Pessoal vinculadas. Editar ou excluir afeta as DUAS pontas, sem duplicar os totais gerais.',
              ),
              const SizedBox(height: 12),
              const Text(
                'O app não transfere dinheiro nem calcula encargos. Não classifica automaticamente pró-labore ou lucros e não informa capacidade de pagamento.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amount,
                readOnly: _saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  hintText: '0,00',
                  errorMaxLines: 4,
                ),
                validator: (value) {
                  try {
                    parseMoney(value ?? '');
                    return null;
                  } on FormatException {
                    return 'Informe um valor positivo no formato 1.234,56';
                  }
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('withdrawal-date'),
                onPressed: _saving ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(formatShortDate(_date)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _note,
                readOnly: _saving,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: NotaMeiTheme.expense),
                  ),
                ),
              if (_saving)
                Semantics(
                  liveRegion: true,
                  child: const Text(
                    'Aguarde a conclusão. Os controles estão bloqueados.',
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(
                  _saving
                      ? (_deleting ? 'Aguarde a exclusão' : 'Salvando…')
                      : widget.existing == null
                      ? 'Salvar retirada'
                      : 'Salvar alterações',
                ),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.maybePop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
