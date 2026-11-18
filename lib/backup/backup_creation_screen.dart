import 'package:flutter/material.dart';

import '../data/entry_repository.dart';
import '../export/export_gateway.dart';
import 'backup_creation_service.dart';

class BackupCreationScreen extends StatefulWidget {
  const BackupCreationScreen({super.key, required this.repository, this.save});
  final EntryRepository repository;
  final Future<ExportOutcome> Function()? save;

  @override
  State<BackupCreationScreen> createState() => _BackupCreationScreenState();
}

class _BackupCreationScreenState extends State<BackupCreationScreen> {
  bool _acknowledged = false;
  bool _busy = false;
  String? _message;
  late final _service = BackupCreationService(repository: widget.repository);

  static const _saveError =
      'Não foi possível confirmar o salvamento. Confira o destino escolhido antes de tentar novamente.';

  Future<void> _save() async {
    if (!_acknowledged || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final outcome = await (widget.save ?? _service.save)();
      if (!mounted) return;
      setState(
        () => _message = switch (outcome) {
          ExportOutcome.saved => 'O Android informou que o arquivo foi salvo. Confira o arquivo no destino escolhido.',
          ExportOutcome.cancelled => 'Criação de backup cancelada.',
          _ => _saveError,
        },
      );
    } on BackupCreationException catch (error) {
      if (!mounted) return;
      setState(
        () => _message = switch (error.reason) {
          BackupCreationFailure.preparation => 'Não foi possível preparar o backup. Verifique os dados e os limites informados e tente novamente.',
          BackupCreationFailure.busy =>
            'Já existe um backup sendo salvo. Aguarde o término.',
          BackupCreationFailure.save => _saveError,
        },
      );
    } catch (_) {
      if (mounted) setState(() => _message = _saveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Criar backup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Uma cópia do histórico completo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Inclui todos os lançamentos de Negócio e Pessoal, de todos os meses e anos, com observações e retiradas vinculadas. Não usa os filtros das telas.',
            ),
            const SizedBox(height: 16),
            const Text(
              'O arquivo JSON contém dados financeiros legíveis, sem senha ou criptografia. Escolha com cuidado onde guardar e não compartilhe com pessoas não autorizadas.',
            ),
            const SizedBox(height: 16),
            const Text(
              'A restauração ainda não está disponível no aplicativo. Guardar o arquivo não substitui os dados atuais nem é garantia de recuperação nesta versão.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Limites: 10 MiB e 10.000 registros. Cada ponta de retirada conta como um registro. Esta ação não altera seus lançamentos.',
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              key: const Key('backup-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _acknowledged,
              title: const Text(
                'Entendi que a cópia inclui todos os dados e observações, sem senha.',
              ),
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _acknowledged = value ?? false;
                      _message = null;
                    }),
            ),
            const SizedBox(height: 16),
            if (_busy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: const Text('Preparando backup ou aguardando o seletor…'),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              key: const Key('backup-save'),
              onPressed: _acknowledged && !_busy ? _save : null,
              child: const Text('Escolher local e salvar'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(_message!, key: const Key('backup-message')),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
