import 'package:flutter/material.dart';

import '../data/entry_repository.dart';
import 'backup_file_picker.dart';
import 'backup_import_plan.dart';
import 'backup_inspection_service.dart';

class BackupImportScreen extends StatefulWidget {
  const BackupImportScreen({
    super.key,
    required this.repository,
    this.picker = const BackupFilePicker(),
  });
  final EntryRepository repository;
  final BackupFilePicker picker;
  @override
  State<BackupImportScreen> createState() => _BackupImportScreenState();
}

class _BackupImportScreenState extends State<BackupImportScreen> {
  bool _busy = false;
  bool _acknowledged = false;
  BackupInspection? _inspection;
  BackupImportPlan? _plan;
  String? _message;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _plan = null;
      _inspection = null;
      _acknowledged = false;
      _message = null;
    });
    try {
      final inspection = await widget.picker.pick();
      if (!mounted) return;
      if (inspection == null) {
        setState(
          () => _message = 'Seleção cancelada. Nenhum registro foi importado.',
        );
        return;
      }
      final plan = await widget.repository.previewBackupImport(
        inspection.backup,
      );
      if (!mounted) return;
      setState(() {
        _inspection = inspection;
        _plan = plan;
      });
    } on BackupInspectionException catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } on BackupImportException catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Não foi possível preparar a importação. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final plan = _plan;
    if (_busy ||
        !_acknowledged ||
        plan == null ||
        plan.conflictCount != 0 ||
        plan.addedCount == 0) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await widget.repository.importBackup(plan);
      if (!mounted) return;
      setState(() {
        _message =
            'Importação concluída: ${result.addedCount} registros adicionados; ${result.identicalCount} idênticos ignorados.';
        _plan = null;
        _inspection = null;
        _acknowledged = false;
      });
    } on BackupImportException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.toString();
          _plan = null;
          _inspection = null;
          _acknowledged = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Não foi possível concluir a importação. Confira o histórico antes de tentar novamente.';
          _plan = null;
          _inspection = null;
          _acknowledged = false;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime? date) => date == null
      ? 'sem registros'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final inspection = _inspection;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Importar backup')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Adicionar sem apagar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Escolha um backup JSON do NotaMei. Registros idênticos com o mesmo identificador serão ignorados. Se houver conteúdo diferente para um identificador existente, todo o arquivo será bloqueado.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Não importa CSV ou PDF. Não apaga nem substitui lançamentos, não restaura configurações e não sincroniza aparelhos. O arquivo JSON é legível, sem senha; escolha apenas uma cópia de origem conhecida.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('backup-pick'),
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.file_open_outlined),
              label: const Text('Escolher arquivo JSON'),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                semanticsLabel: 'Aguarde a operação de backup',
              ),
            ],
            if (plan != null && inspection != null) ...[
              const SizedBox(height: 20),
              Text('Registros no arquivo: ${inspection.recordCount}'),
              Text(
                'Negócio: ${inspection.businessCount} · Pessoal: ${inspection.personalCount}',
              ),
              Text(
                'Operações de retirada: ${inspection.withdrawalOperations} (duas linhas por operação)',
              ),
              Text(
                'Datas dos registros: ${_date(inspection.earliestDate)} a ${_date(inspection.latestDate)}',
              ),
              const SizedBox(height: 12),
              Text('Novos registros: ${plan.addedCount}'),
              Text('Idênticos ignorados: ${plan.identicalCount}'),
              Text('Conflitos: ${plan.conflictCount}'),
              if (plan.conflictCount > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Arquivo bloqueado por conflitos. Nenhum registro será importado. Os dados existentes serão mantidos.',
                  ),
                ),
              if (plan.conflictCount == 0 && plan.addedCount == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Não há registros novos para importar. O histórico não foi alterado.',
                  ),
                ),
              CheckboxListTile(
                key: const Key('backup-import-consent'),
                contentPadding: EdgeInsets.zero,
                value: _acknowledged,
                onChanged:
                    _busy || plan.conflictCount > 0 || plan.addedCount == 0
                    ? null
                    : (value) => setState(() => _acknowledged = value ?? false),
                title: const Text(
                  'Conferi a prévia e quero adicionar os registros sem apagar o histórico existente.',
                ),
              ),
              FilledButton(
                key: const Key('backup-import'),
                onPressed:
                    !_busy &&
                        _acknowledged &&
                        plan.conflictCount == 0 &&
                        plan.addedCount > 0
                    ? _import
                    : null,
                child: const Text('Confirmar e importar'),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(_message!, key: const Key('backup-import-message')),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
