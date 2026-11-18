import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/backup/financial_backup.dart';
import 'package:notamei/core/money.dart';
import 'package:notamei/data/entry_record.dart';

Map<String, Object?> fields(EntryRecord entry) => {
  'id': entry.id,
  'type': entry.type.name,
  'scope': entry.scope.name,
  'amountCents': entry.amountCents,
  'category': entry.category,
  'date': entry.date.toIso8601String(),
  'note': entry.note,
  'withdrawalId': entry.withdrawalId,
};

List<EntryRecord> fixture() => [
  EntryRecord(
    id: 'registro original',
    type: EntryType.income,
    scope: EntryScope.business,
    amountCents: maxMoneyCents,
    category: ' Ação / café ',
    date: DateTime(2026, 1, 31, 23, 59, 59, 123, 456),
    note: 'Linha 1\n"café"; 😀',
  ),
  EntryRecord(
    id: 'pessoal',
    type: EntryType.expense,
    scope: EntryScope.personal,
    amountCents: 1,
    category: 'Pessoal',
    date: DateTime.utc(2025, 12, 31, 23, 59),
  ),
];

Uint8List documentWithRows(List<Object?> rows) => Uint8List.fromList(
  utf8.encode(
    jsonEncode({
      'format': 'notamei-financial-backup',
      'version': 1,
      'createdAt': '2026-11-18T00:00:00.000Z',
      'entries': rows,
    }),
  ),
);

Map<String, Object?> row(EntryRecord entry) => {
  ...fields(entry),
  'amountCents': entry.amountCents.toString(),
};

List<EntryRecord> withdrawal() => [
  for (final scope in EntryScope.values)
    EntryRecord(
      id: 'withdrawal:op:original:${scope.name}',
      withdrawalId: 'op:original',
      type: scope == EntryScope.business ? EntryType.expense : EntryType.income,
      scope: scope,
      amountCents: 12345,
      category: 'Retirada do titular',
      date: DateTime(2026, 11, 18),
      note: 'Par original',
    ),
];

void main() {
  test(
    'histórico vazio é válido e metadado de criação é normalizado para UTC',
    () {
      final created = DateTime(2026, 11, 18, 12);
      final bytes = FinancialBackupCodec.encode([], createdAt: created);
      final backup = FinancialBackupCodec.decode(bytes);
      expect(backup.createdAt, created.toUtc());
      expect(backup.createdAt.isUtc, isTrue);
      expect(backup.entries, isEmpty);
      expect(FinancialBackupCodec.encode([], createdAt: created), bytes);
    },
  );

  test('aceita exatamente 10000 registros sem alterar ordem ou IDs', () {
    final sample = fixture().last;
    final entries = List.generate(
      10000,
      (i) => EntryRecord(
        id: 'registro-$i',
        type: sample.type,
        scope: sample.scope,
        amountCents: 1,
        category: sample.category,
        date: sample.date,
      ),
    );
    final copy = FinancialBackupCodec.decode(
      FinancialBackupCodec.encode(entries, createdAt: DateTime.utc(2026)),
    );
    expect(copy.entries.map(fields).toList(), entries.map(fields).toList());
  });

  test('limita quantidade sem truncar registros na codificação e leitura', () {
    final sample = fixture().last;
    final records = List.generate(
      10001,
      (i) => EntryRecord(
        id: 'registro-$i',
        type: sample.type,
        scope: sample.scope,
        amountCents: 1,
        category: sample.category,
        date: sample.date,
      ),
    );
    expect(
      () => FinancialBackupCodec.encode(records, createdAt: DateTime.utc(2026)),
      throwsFormatException,
    );
    expect(
      () => FinancialBackupCodec.decode(
        documentWithRows(records.map(row).toList()),
      ),
      throwsFormatException,
    );
  });

  test('limita bytes também para escapes JSON e não trunca observações', () {
    const limit = 10 * 1024 * 1024;
    final sample = fixture().last;
    EntryRecord withNote(String note) => EntryRecord(
      id: sample.id,
      type: sample.type,
      scope: sample.scope,
      amountCents: 1,
      category: sample.category,
      date: sample.date,
      note: note,
    );
    final large = withNote('x' * limit);
    expect(
      () => FinancialBackupCodec.encode([large], createdAt: DateTime.utc(2026)),
      throwsFormatException,
    );
    expect(
      () => FinancialBackupCodec.decode(documentWithRows([row(large)])),
      throwsFormatException,
    );
    final escaped = withNote('\u0000' * (2 * 1024 * 1024));
    expect(
      () =>
          FinancialBackupCodec.encode([escaped], createdAt: DateTime.utc(2026)),
      throwsFormatException,
    );
    final overhead = FinancialBackupCodec.encode([
      withNote(''),
    ], createdAt: DateTime.utc(2026)).length;
    final boundary = withNote('x' * (limit - overhead));
    final bytes = FinancialBackupCodec.encode([
      boundary,
    ], createdAt: DateTime.utc(2026));
    expect(bytes, hasLength(limit));
    expect(
      FinancialBackupCodec.decode(bytes).entries.single.note,
      boundary.note,
    );
  });

  test('retirada preserva IDs e duas pontas sem recriar registros', () {
    final entries = [...fixture(), ...withdrawal()];
    final copy = FinancialBackupCodec.decode(
      FinancialBackupCodec.encode(entries, createdAt: DateTime.utc(2026)),
    );
    expect(copy.entries.map(fields).toList(), entries.map(fields).toList());
    expect(copy.entries.where((e) => e.isWithdrawal), hasLength(2));
  });

  test('recusa retiradas órfãs, inconsistentes ou com IDs incompatíveis', () {
    final pair = withdrawal().map(row).toList();
    final invalid = <List<Object?>>[
      [pair.first],
      [
        pair.first,
        {...pair.last, 'scope': 'business'},
      ],
      [
        pair.first,
        {...pair.last, 'type': 'expense'},
      ],
      [
        pair.first,
        {...pair.last, 'amountCents': '2'},
      ],
      [
        pair.first,
        {...pair.last, 'date': '2026-11-19T00:00:00.000'},
      ],
      [
        pair.first,
        {...pair.last, 'note': 'outra nota'},
      ],
      [
        pair.first,
        {...pair.last, 'category': 'Comum'},
      ],
      [
        pair.first,
        {...pair.last, 'id': 'outro-id'},
      ],
      [
        pair.first,
        {...pair.last, 'withdrawalId': 'outro-vínculo'},
      ],
      [
        ...pair,
        {...pair.last, 'id': 'terceira-ponta'},
      ],
    ];
    for (final bad in invalid) {
      expect(
        () => FinancialBackupCodec.decode(documentWithRows(bad)),
        throwsFormatException,
      );
    }
    expect(
      () => FinancialBackupCodec.encode([
        withdrawal().first,
      ], createdAt: DateTime.utc(2026)),
      throwsFormatException,
    );
  });

  test(
    'recusa registros inválidos, dinheiro não canônico e IDs duplicados',
    () {
      final good = row(fixture().first);
      final invalid = <Object?>[
        null,
        [],
        'registro',
        for (final value in ['', ' ', 1, null]) {...good, 'id': value},
        for (final value in ['other', 1, null]) {...good, 'type': value},
        for (final value in ['other', 1, null]) {...good, 'scope': value},
        for (final value in [
          '0',
          '-1',
          '+1',
          '01',
          '1.0',
          '1e2',
          '9223372036854775808',
          1,
          1.0,
          null,
        ])
          {...good, 'amountCents': value},
        for (final value in ['', ' ', 1, null]) {...good, 'category': value},
        for (final value in ['2026-02-30T00:00:00.000', 'invalid', 1, null])
          {...good, 'date': value},
        {...good, 'note': true},
        {...good, 'withdrawalId': 1},
        {...good, 'withdrawalId': ''},
        {...good, 'unknown': 'value'},
        Map<String, Object?>.from(good)..remove('note'),
      ];
      for (final bad in invalid) {
        expect(
          () => FinancialBackupCodec.decode(documentWithRows([bad])),
          throwsFormatException,
        );
      }
      expect(
        () => FinancialBackupCodec.decode(documentWithRows([good, good])),
        throwsFormatException,
      );
      expect(
        () => FinancialBackupCodec.encode([
          fixture().first,
          fixture().first,
        ], createdAt: DateTime.utc(2026)),
        throwsFormatException,
      );
    },
  );

  test(
    'recusa envelopes incompatíveis, campos desconhecidos e tipos errados',
    () {
      final base = jsonDecode(
        utf8.decode(
          FinancialBackupCodec.encode(
            [],
            createdAt: DateTime.utc(2026, 11, 18),
          ),
        ),
      ) as Map<String, dynamic>;
      final invalid = <Object?>[
        null,
        [],
        'não é um backup',
        {...base, 'format': 'outro-app'},
        {...base, 'version': 2},
        {...base, 'version': 1.0},
        {...base, 'version': '1'},
        {...base, 'entries': {}},
        {...base, 'entries': null},
        {...base, 'createdAt': '2026-02-30T00:00:00.000Z'},
        {...base, 'createdAt': '2026-11-18T00:00:00.000'},
        {...base, 'preferences': {}},
        Map<String, dynamic>.from(base)..remove('createdAt'),
      ];
      for (final value in invalid) {
        expect(
          () => FinancialBackupCodec.decode(
            Uint8List.fromList(utf8.encode(jsonEncode(value))),
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('JSON e UTF-8 inválidos não expõem conteúdo financeiro na exceção', () {
    for (final bytes in [
      Uint8List.fromList(utf8.encode('{"SEGREDO_FINANCEIRO":')),
      Uint8List.fromList([0xff, 0xfe, 0x80]),
    ]) {
      try {
        FinancialBackupCodec.decode(bytes);
        fail('Arquivo inválido foi aceito');
      } on FormatException catch (error) {
        expect(error.source, isNull);
        expect(error.toString(), isNot(contains('SEGREDO_FINANCEIRO')));
      }
    }
  });

  test('ida e volta preserva campos, centavos exatos e datas civis', () {
    final entries = fixture();
    final original = entries.map(fields).toList();
    final created = DateTime.utc(2026, 11, 18, 12);
    final bytes = FinancialBackupCodec.encode(entries, createdAt: created);
    final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    expect(envelope['format'], 'notamei-financial-backup');
    expect(envelope['version'], 1);
    expect(envelope['entries'][0]['amountCents'], maxMoneyCents.toString());
    final backup = FinancialBackupCodec.decode(bytes);
    expect(backup.createdAt, created);
    expect(backup.entries.map(fields).toList(), original);
    expect(entries.map(fields).toList(), original);
    expect(() => backup.entries.clear(), throwsUnsupportedError);
  });
}
