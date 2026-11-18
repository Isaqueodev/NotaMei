import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/backup/backup_inspection_service.dart';
import 'package:notamei/backup/financial_backup.dart';
import 'package:notamei/data/entry_record.dart';

List<EntryRecord> fixture() => [
  EntryRecord(
    id: 'negocio',
    type: EntryType.income,
    scope: EntryScope.business,
    amountCents: 12345,
    category: 'Serviços',
    date: DateTime(2025, 12, 31),
    note: 'Ação\n😀',
  ),
  EntryRecord(
    id: 'pessoal',
    type: EntryType.expense,
    scope: EntryScope.personal,
    amountCents: 1,
    category: 'Pessoal',
    date: DateTime.utc(2026, 1, 1),
    note: '',
  ),
];

Map<String, Object?> fields(EntryRecord e) => {
  'id': e.id,
  'type': e.type.name,
  'scope': e.scope.name,
  'amountCents': e.amountCents,
  'category': e.category,
  'date': e.date.toIso8601String(),
  'note': e.note,
  'withdrawalId': e.withdrawalId,
};

void main() {
  test('aceita arquivo no limite exato, incluindo chunks vazios', () async {
    final date = DateTime(2026, 11, 18);
    EntryRecord withNote(String note) => EntryRecord(
      id: 'limite',
      type: EntryType.income,
      scope: EntryScope.business,
      amountCents: 1,
      category: 'Teste',
      date: date,
      note: note,
    );
    final overhead = FinancialBackupCodec.encode([
      withNote(''),
    ], createdAt: DateTime.utc(2026)).length;
    final note = 'x' * (maxFinancialBackupBytes - overhead);
    final bytes = FinancialBackupCodec.encode([
      withNote(note),
    ], createdAt: DateTime.utc(2026));
    final preview = await const BackupInspectionService().inspectStream(
      Stream<List<int>>.fromIterable([
        [],
        Uint8List.sublistView(bytes, 0, 13),
        [],
        Uint8List.sublistView(bytes, 13),
        [],
      ]),
    );
    expect(preview.byteCount, maxFinancialBackupBytes);
    expect(preview.backup.entries.single.note, note);
  });

  test('copia chunks mutáveis antes de aguardar o próximo evento', () async {
    final bytes = FinancialBackupCodec.encode(
      fixture(),
      createdAt: DateTime.utc(2026),
    );
    Stream<List<int>> source() async* {
      final reused = List<int>.from(bytes.take(13));
      yield reused;
      reused.fillRange(0, reused.length, 0);
      yield bytes.sublist(13);
    }

    final preview = await const BackupInspectionService().inspectStream(
      source(),
    );
    expect(
      preview.backup.entries.map(fields).toList(),
      fixture().map(fields).toList(),
    );
  });

  test('período da prévia usa ano mês dia e preserva representação original no empate', () async {
    final dates = [
      DateTime(2026, 5, 12, 23, 59),
      DateTime.utc(2026, 5, 12, 0, 1),
      DateTime(2026, 4, 30),
      DateTime.utc(2026, 4, 29),
    ];
    final entries = [
      for (final (i, date) in dates.indexed)
        EntryRecord(
          id: 'data-$i',
          type: EntryType.income,
          scope: EntryScope.business,
          amountCents: 1,
          category: 'Teste',
          date: date,
        ),
    ];
    final bytes = FinancialBackupCodec.encode(
      entries,
      createdAt: DateTime.utc(2026),
    );
    final preview = await const BackupInspectionService().inspectStream(
      Stream.value(bytes),
    );
    expect(
      preview.earliestDate?.toIso8601String(),
      dates.last.toIso8601String(),
    );
    expect(
      preview.latestDate?.toIso8601String(),
      dates.first.toIso8601String(),
    );
  });

  test(
    'versão incompatível IDs repetidos e retirada órfã não produzem prévia',
    () async {
      final bytes = FinancialBackupCodec.encode(
        fixture(),
        createdAt: DateTime.utc(2026),
      );
      final good = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final invalid = [
        {...good, 'version': 2},
        {
          ...good,
          'entries': [good['entries'][0], good['entries'][0]],
        },
        {
          ...good,
          'entries': [
            {
              ...good['entries'][0],
              'id': 'withdrawal:par:business',
              'type': 'expense',
              'category': 'Retirada do titular',
              'withdrawalId': 'par',
            },
          ],
        },
      ];
      for (final data in invalid) {
        await expectLater(
          const BackupInspectionService().inspectStream(
            Stream.value(utf8.encode(jsonEncode(data))),
          ),
          throwsA(
            isA<BackupInspectionException>().having(
              (e) => e.reason,
              'reason',
              BackupInspectionFailure.invalid,
            ),
          ),
        );
      }
    },
  );

  test(
    'erro após JSON completo cancela fonte sem retornar prévia parcial',
    () async {
      final bytes = FinancialBackupCodec.encode(
        fixture(),
        createdAt: DateTime.utc(2026),
      );
      var closed = false;
      Stream<List<int>> source() async* {
        try {
          yield bytes;
          throw StateError('SEGREDO_FINANCEIRO');
        } finally {
          closed = true;
        }
      }

      await expectLater(
        const BackupInspectionService().inspectStream(source()),
        throwsA(
          isA<BackupInspectionException>().having(
            (e) => e.reason,
            'reason',
            BackupInspectionFailure.read,
          ),
        ),
      );
      expect(closed, isTrue);
    },
  );

  test('arquivo real é lido sem modificar conteúdo e caminho ausente gera erro seguro', () async {
    final directory = await Directory(
      Platform.environment['TMPDIR'] ?? Directory.systemTemp.path,
    ).createTemp('notamei-inspection-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/arquivo-privado.json');
    final bytes = FinancialBackupCodec.encode(
      fixture(),
      createdAt: DateTime.utc(2026),
    );
    await file.writeAsBytes(bytes, flush: true);
    const service = BackupInspectionService();
    final preview = await service.inspectFile(file);
    expect(
      preview.backup.entries.map(fields).toList(),
      fixture().map(fields).toList(),
    );
    expect(await file.readAsBytes(), orderedEquals(bytes));
    try {
      await service.inspectFile(File('${directory.path}/ausente-privado.json'));
      fail('Arquivo ausente foi aceito');
    } catch (error) {
      expect(
        error,
        isA<BackupInspectionException>().having(
          (e) => e.reason,
          'reason',
          BackupInspectionFailure.read,
        ),
      );
      expect(error.toString(), isNot(contains('ausente-privado')));
      expect(error.toString(), isNot(contains(directory.path)));
    }
  });

  test(
    'prévia conta registros e operações de retirada sem duplicar o par',
    () async {
      final entries = [
        ...fixture(),
        for (final scope in EntryScope.values)
          EntryRecord(
            id: 'withdrawal:par:${scope.name}',
            type: scope == EntryScope.business
                ? EntryType.expense
                : EntryType.income,
            scope: scope,
            amountCents: 100,
            category: 'Retirada do titular',
            date: DateTime(2024, 3, 1),
            withdrawalId: 'par',
          ),
      ];
      final bytes = FinancialBackupCodec.encode(
        entries,
        createdAt: DateTime.utc(2026),
      );
      final preview = await const BackupInspectionService().inspectStream(
        Stream.value(bytes),
      );
      expect(preview.recordCount, entries.length);
      expect(preview.businessCount, 2);
      expect(preview.personalCount, 2);
      expect(preview.regularRecordCount, fixture().length);
      expect(preview.withdrawalOperations, 1);
      expect(
        preview.earliestDate?.toIso8601String(),
        '2024-03-01T00:00:00.000',
      );
      expect(preview.latestDate?.toIso8601String(), '2026-01-01T00:00:00.000Z');
      expect(
        preview.backup.entries.map(fields).toList(),
        entries.map(fields).toList(),
      );
    },
  );

  test('prévia vazia mantém datas nulas e não implica autorização para apagar dados', () async {
    final bytes = FinancialBackupCodec.encode(
      [],
      createdAt: DateTime.utc(2026),
    );
    final preview = await const BackupInspectionService().inspectStream(
      Stream.value(bytes),
    );
    expect([
      preview.recordCount,
      preview.businessCount,
      preview.personalCount,
      preview.regularRecordCount,
      preview.withdrawalOperations,
    ], everyElement(0));
    expect(preview.earliestDate, isNull);
    expect(preview.latestDate, isNull);
  });

  test(
    'bytes fora da faixa são recusados sem truncar ou normalizar conteúdo',
    () async {
      final bytes = FinancialBackupCodec.encode(
        fixture(),
        createdAt: DateTime.utc(2026),
      );
      final bad = List<int>.from(bytes)..[0] += 256;
      await expectLater(
        const BackupInspectionService().inspectStream(Stream.value(bad)),
        throwsA(
          isA<BackupInspectionException>().having(
            (e) => e.reason,
            'reason',
            BackupInspectionFailure.invalid,
          ),
        ),
      );
    },
  );

  test(
    'erros de leitura e formato não expõem conteúdo nem impedem nova leitura',
    () async {
      const service = BackupInspectionService();
      final cases = <(Stream<List<int>>, BackupInspectionFailure)>[
        (
          Stream<List<int>>.error(
            StateError('SEGREDO_FINANCEIRO caminho-privado'),
          ),
          BackupInspectionFailure.read,
        ),
        (
          Stream.value(utf8.encode('{"SEGREDO_FINANCEIRO":')),
          BackupInspectionFailure.invalid,
        ),
        (Stream.value([0xff, 0xfe]), BackupInspectionFailure.invalid),
        (const Stream.empty(), BackupInspectionFailure.invalid),
      ];
      for (final (stream, reason) in cases) {
        try {
          await service.inspectStream(stream);
          fail('Entrada inválida foi aceita');
        } catch (error) {
          expect(
            error,
            isA<BackupInspectionException>().having(
              (e) => e.reason,
              'reason',
              reason,
            ),
          );
          expect(error.toString(), isNot(contains('SEGREDO_FINANCEIRO')));
          expect(error.toString(), isNot(contains('caminho-privado')));
        }
      }
      final bytes = FinancialBackupCodec.encode(
        fixture(),
        createdAt: DateTime.utc(2026),
      );
      expect(
        (await service.inspectStream(Stream.value(bytes))).backup.entries,
        hasLength(fixture().length),
      );
    },
  );

  test(
    'limite de bytes interrompe consumo e cancela stream antes de novos chunks',
    () async {
      var continued = false;
      var closed = false;
      Stream<List<int>> source() async* {
        try {
          yield Uint8List(maxFinancialBackupBytes);
          yield [0];
          continued = true;
          yield [0];
        } finally {
          closed = true;
        }
      }

      await expectLater(
        const BackupInspectionService().inspectStream(source()),
        throwsA(
          isA<BackupInspectionException>().having(
            (e) => e.reason,
            'reason',
            BackupInspectionFailure.tooLarge,
          ),
        ),
      );
      expect(continued, isFalse);
      expect(closed, isTrue);
    },
  );

  test(
    'leitura por chunks preserva UTF-8 fragmentado e todos os campos',
    () async {
      final entries = fixture();
      final created = DateTime.utc(2026, 11, 18, 14);
      final bytes = FinancialBackupCodec.encode(entries, createdAt: created);
      final preview = await const BackupInspectionService().inspectStream(
        Stream<List<int>>.fromIterable(bytes.map((byte) => [byte])),
      );
      expect(
        preview.backup.entries.map(fields).toList(),
        entries.map(fields).toList(),
      );
      expect(preview.backup.createdAt, created);
      expect(preview.byteCount, bytes.length);
      expect(() => preview.backup.entries.clear(), throwsUnsupportedError);
    },
  );
}
