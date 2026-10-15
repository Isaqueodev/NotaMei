import 'package:flutter/material.dart';

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

class _DasSettingsScreenState extends State<DasSettingsScreen> {
  int? _day;
  late TimeOfDay _time;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.service.settings;
    _day = initial?.day;
    _time = TimeOfDay(hour: initial?.hour ?? 9, minute: initial?.minute ?? 0);
  }

  Future<void> _activate() async {
    if (_day == null) {
      setState(() => _message = 'Selecione o dia do seu lembrete.');
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
      setState(
        () => _message = enabled ? 'Lembrete agendado no seu aparelho.' : 'Permissão de notificações negada. O lembrete continua desativado.',
      );
      widget.onChanged();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Não foi possível agendar. Confira as configurações do aparelho.',
        );
        widget.onChanged();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    setState(() => _busy = true);
    try {
      await widget.service.disable();
      if (mounted) {
        setState(() => _message = 'Lembrete desativado.');
        widget.onChanged();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Não foi possível cancelar o lembrete.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lembrete do DAS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.service.enabled
                  ? 'Lembrete ativado'
                  : 'Lembrete desativado',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Este é um aviso pessoal: não confirma vencimento nem pagamento do DAS. Confira a data oficial.',
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _day,
              decoration: const InputDecoration(labelText: 'Dia do mês'),
              hint: const Text('Selecione o dia'),
              items: [
                for (var i = 1; i <= 31; i++)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: _busy ? null : (value) => setState(() => _day = value),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nos meses mais curtos, dias 29 a 31 serão ajustados ao último dia.',
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Horário do lembrete'),
              subtitle: Text(_time.format(context)),
              trailing: const Icon(Icons.schedule),
              onTap: _busy
                  ? null
                  : () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null && mounted) {
                        setState(() => _time = picked);
                      }
                    },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _activate,
              child: const Text('Ativar lembrete'),
            ),
            if (widget.service.enabled)
              TextButton(
                onPressed: _busy ? null : _disable,
                child: const Text('Desativar lembrete'),
              ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, key: const Key('das-message')),
            ],
            const SizedBox(height: 24),
            const Text(
              'A entrega depende das permissões e das regras de economia de bateria do Android. Sem confirmação de pagamento.',
            ),
          ],
        ),
      ),
    );
  }
}
