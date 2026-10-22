import 'package:flutter/material.dart';

import '../data/entry_record.dart';
import '../data/entry_repository.dart';
import 'csv_export.dart';
import 'export_gateway.dart';
import 'pdf_export.dart';

enum ExportFormat { csv, pdf }

class ExportScreen extends StatefulWidget {
  const ExportScreen({
    super.key,
    required this.repository,
    this.initialDate,
    this.format = ExportFormat.csv,
    this.save,
    this.share,
  });

  final EntryRepository repository;
  final DateTime? initialDate;
  final ExportFormat format;
  final ExportAction? save;
  final ExportAction? share;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late DateTime _anchor = widget.initialDate ?? DateTime.now();
  ExportPeriod _period = ExportPeriod.month;
  EntryScope? _scope = EntryScope.business;
  EntryType? _type;
  bool _notes = false;
  bool _busy = false;
  CsvReport? _exportingReport;
  String? _message;
  final _gateway = ExportGateway();
  String get _formatLabel => widget.format == ExportFormat.pdf ? 'PDF' : 'CSV';

  Future<ExportOutcome> _savePdf(CsvReport report) async =>
      _gateway.saveDocument(await buildPdfReport(report));
  Future<ExportOutcome> _sharePdf(CsvReport report) async =>
      _gateway.shareDocument(await buildPdfReport(report));

  Future<void> _export(CsvReport report, ExportAction action) async {
    if (_busy || report.entries.isEmpty) return;
    setState(() {
      _busy = true;
      _exportingReport = report;
      _message = null;
    });
    try {
      final outcome = await action(report);
      if (!mounted) return;
      setState(
        () => _message = switch (outcome) {
          ExportOutcome.saved => '$_formatLabel salvo no local escolhido.',
          ExportOutcome.shared =>
            'Arquivo entregue ao aplicativo escolhido. Confirme nele o envio.',
          ExportOutcome.cancelled =>
            'Exportação cancelada. Nenhum lançamento foi alterado.',
          ExportOutcome.unconfirmed => 'Compartilhamento aberto. Confirme o resultado no aplicativo escolhido.',
        },
      );
    } on PdfExportLimitException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Não foi possível exportar. Nenhum lançamento foi alterado. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _exportingReport = null;
        });
      }
    }
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(1900),
      lastDate: DateTime(9999, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() {
        _anchor = selected;
        _message = null;
      });
    }
  }

  String _displayDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text('Exportar $_formatLabel')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.repository,
          builder: (context, _) {
            final report =
                _exportingReport ??
                CsvReport.generate(
                  widget.repository.entries,
                  ExportSelection(
                    anchor: _anchor,
                    period: _period,
                    scope: _scope,
                    type: _type,
                    includeNotes: _notes,
                  ),
                );
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Seus registros, fora do app',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'O arquivo contém dados financeiros. Escolha com cuidado onde salvar ou com quem compartilhar. $_formatLabel não é backup restaurável nem documento fiscal.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<ExportPeriod>(
                  key: const Key('export-period'),
                  initialValue: _period,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Período'),
                  items: const [
                    DropdownMenuItem(
                      value: ExportPeriod.day,
                      child: Text('Dia'),
                    ),
                    DropdownMenuItem(
                      value: ExportPeriod.week,
                      child: Text('Semana'),
                    ),
                    DropdownMenuItem(
                      value: ExportPeriod.month,
                      child: Text('Mês'),
                    ),
                    DropdownMenuItem(
                      value: ExportPeriod.year,
                      child: Text('Ano'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _period = value!;
                          _message = null;
                        }),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _chooseDate,
                  child: Text('Data de referência: ${_displayDate(_anchor)}'),
                ),
                const Text(
                  'A semana começa na segunda-feira e termina no domingo.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('export-scope'),
                  initialValue: 'business',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Âmbito'),
                  items: const [
                    DropdownMenuItem(value: 'business', child: Text('Negócio')),
                    DropdownMenuItem(value: 'personal', child: Text('Pessoal')),
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Todos (Negócio + Pessoal)', maxLines: 2),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _scope = value == 'all'
                              ? null
                              : EntryScope.values.byName(value!);
                          _message = null;
                        }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('export-type'),
                  initialValue: 'all',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Entradas e saídas'),
                    ),
                    DropdownMenuItem(value: 'income', child: Text('Entradas')),
                    DropdownMenuItem(value: 'expense', child: Text('Saídas')),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _type = value == 'all'
                              ? null
                              : EntryType.values.byName(value!);
                          _message = null;
                        }),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Incluir observações'),
                  subtitle: const Text(
                    'Desativado por padrão para reduzir a exposição de dados.',
                  ),
                  value: _notes,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _notes = value;
                          _message = null;
                        }),
                ),
                const Divider(height: 32),
                Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${exportDate(report.selection.start)} a ${exportDate(report.lastDate)} (inclusive)',
                      ),
                      Text(
                        '${report.selection.scopeLabel} · ${report.selection.typeLabel}',
                      ),
                      Text(
                        '${report.entries.length} lançamento(s) selecionado(s)',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entradas selecionadas: R\$ ${exportAmount(report.incomeCents)}',
                      ),
                      Text(
                        'Saídas selecionadas: R\$ ${exportAmount(report.expenseCents)}',
                      ),
                      Text(
                        'Transferências enviadas: R\$ ${exportAmount(report.sentCents)}',
                      ),
                      Text(
                        'Transferências recebidas: R\$ ${exportAmount(report.receivedCents)}',
                      ),
                      Text(
                        'Balanço selecionado: R\$ ${exportAmount(report.balanceCents)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(report.summaryExplanation),
                if (report.entries.isEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum lançamento neste intervalo e filtros. Altere a seleção para exportar.',
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Semantics(liveRegion: true, child: Text(_message!)),
                ],
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy || report.entries.isEmpty
                      ? null
                      : () => _export(
                          report,
                          widget.save ??
                              (widget.format == ExportFormat.pdf
                                  ? _savePdf
                                  : _gateway.save),
                        ),
                  child: Text('Salvar $_formatLabel'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy || report.entries.isEmpty
                      ? null
                      : () => _export(
                          report,
                          widget.share ??
                              (widget.format == ExportFormat.pdf
                                  ? _sharePdf
                                  : _gateway.share),
                        ),
                  child: Text('Compartilhar $_formatLabel'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
