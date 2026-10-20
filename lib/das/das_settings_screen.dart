import 'package:flutter/material.dart';
import 'package:notamei/theme/notamei_theme.dart';

import 'das_reminder_service.dart';

/// A data é escolhida pela pessoa; nunca determina vencimento do DAS.
class DasSettingsScreen extends StatefulWidget {
  const DasSettingsScreen({
    super.key,
    required this.service,
    required this.onChanged,
  });

  final DasReminderService service;
  final VoidCallback onChanged;

  @override
  State<DasSettingsScreen> createState() => _DasSettingsScreenState();
}

enum _FeedbackKind { information, success, error }

class _DasSettingsScreenState extends State<DasSettingsScreen> {
  int? _day;
  late TimeOfDay _time;
  String? _message;
  _FeedbackKind _feedback = _FeedbackKind.information;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.service.settings;
    _day = initial?.day;
    _time = TimeOfDay(hour: initial?.hour ?? 9, minute: initial?.minute ?? 0);
  }

  void _showMessage(String message, _FeedbackKind kind) {
    setState(() {
      _message = message;
      _feedback = kind;
    });
  }

  Future<void> _activate() async {
    if (_busy) return;
    if (_day == null) {
      _showMessage('Selecione o dia do seu lembrete.', _FeedbackKind.error);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final enabled = await widget.service.enable(
        DasReminderSettings(day: _day!, hour: _time.hour, minute: _time.minute),
      );
      if (!mounted) return;
      _showMessage(
        enabled ? 'Lembrete agendado no seu aparelho.' : 'Permissão de notificações negada. O lembrete continua desativado.',
        enabled ? _FeedbackKind.success : _FeedbackKind.error,
      );
      widget.onChanged();
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Não foi possível agendar. Confira as configurações do aparelho.',
          _FeedbackKind.error,
        );
        widget.onChanged();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.service.disable();
      if (mounted) {
        _showMessage('Lembrete desativado.', _FeedbackKind.information);
        widget.onChanged();
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Não foi possível cancelar o lembrete.',
          _FeedbackKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime() async {
    // The stock input dialog has a fixed height and overflows with large text.
    // Keep the dial at normal scale; enlarged text gets a scrollable form,
    // without reducing the person's font size.
    final picked = MediaQuery.textScalerOf(context).scale(16) > 20
        ? await showDialog<TimeOfDay>(
            context: context,
            builder: (_) => _LargeTextTimeDialog(initialTime: _time),
          )
        : await showTimePicker(
            context: context,
            initialTime: _time,
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerTheme.of(context).copyWith(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: NotaMeiTheme.border),
                  ),
                ),
              ),
              child: child!,
            ),
          );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.service.enabled;
    final scheduled = widget.service.settings;
    final feedbackColor = switch (_feedback) {
      _FeedbackKind.error => NotaMeiTheme.expense,
      _FeedbackKind.success => NotaMeiTheme.income,
      _FeedbackKind.information => NotaMeiTheme.ink,
    };
    return Scaffold(
      backgroundColor: NotaMeiTheme.paper,
      appBar: AppBar(title: const Text('Lembrete do DAS')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Sheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO DO AVISO',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: NotaMeiTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      enabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      color: enabled ? NotaMeiTheme.income : NotaMeiTheme.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      enabled ? 'Lembrete ativado' : 'Lembrete desativado',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: enabled
                            ? NotaMeiTheme.income
                            : NotaMeiTheme.muted,
                      ),
                    ),
                    if (enabled && scheduled != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Dia ${scheduled.day} · ${TimeOfDay(hour: scheduled.hour, minute: scheduled.minute).format(context)}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Este é um aviso pessoal: não confirma vencimento nem pagamento do DAS. Confira a data oficial.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _Sheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Agendamento mensal',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O dia escolhido é pessoal, não o vencimento oficial do DAS.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      initialValue: _day,
                      elevation: 0,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      isExpanded: true,
                      isDense: false,
                      itemHeight: null,
                      decoration: const InputDecoration(
                        labelText: 'Dia do mês',
                      ),
                      hint: const Text('Selecione o dia'),
                      items: [
                        for (var i = 1; i <= 31; i++)
                          DropdownMenuItem(value: i, child: Text('$i')),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _day = value),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nos meses mais curtos, dias 29 a 31 serão ajustados ao último dia.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _busy ? null : _pickTime,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Horário do lembrete'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _time.format(context),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Horário local do aparelho.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _activate,
                child: const Text('Ativar lembrete'),
              ),
              if (enabled) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _disable,
                  child: const Text('Desativar lembrete'),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  semanticsLabel: 'Atualizando lembrete',
                  color: NotaMeiTheme.ink,
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: feedbackColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message!,
                      key: const Key('das-message'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: feedbackColor,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: NotaMeiTheme.ink, width: 2),
                  ),
                ),
                child: Text(
                  'A entrega não é garantida: depende das permissões e das regras de economia de bateria do Android. O lembrete não comprova pagamento.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeTextTimeDialog extends StatefulWidget {
  const _LargeTextTimeDialog({required this.initialTime});
  final TimeOfDay initialTime;
  @override
  State<_LargeTextTimeDialog> createState() => _LargeTextTimeDialogState();
}

class _LargeTextTimeDialogState extends State<_LargeTextTimeDialog> {
  final _form = GlobalKey<FormState>();
  late final _hour = TextEditingController(
    text: widget.initialTime.hour.toString().padLeft(2, '0'),
  );
  late final _minute = TextEditingController(
    text: widget.initialTime.minute.toString().padLeft(2, '0'),
  );

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      TimeOfDay(hour: int.parse(_hour.text), minute: int.parse(_minute.text)),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: NotaMeiTheme.border),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              namesRoute: true,
              header: true,
              child: Text(
                'Horário do lembrete',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('das-hour'),
              controller: _hour,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Hora (0 a 23)',
                errorMaxLines: 3,
              ),
              validator: (value) {
                final hour = int.tryParse(value ?? '');
                return hour == null || hour < 0 || hour > 23
                    ? 'Informe uma hora de 0 a 23.'
                    : null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('das-minute'),
              controller: _minute,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Minuto (0 a 59)',
                errorMaxLines: 3,
              ),
              validator: (value) {
                final minute = int.tryParse(value ?? '');
                return minute == null || minute < 0 || minute > 59
                    ? 'Informe os minutos de 0 a 59.'
                    : null;
              },
              onFieldSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _confirm,
              child: const Text('Confirmar horário'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: NotaMeiTheme.border),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
