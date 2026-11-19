import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/backup/backup_import_screen.dart';
import 'package:notamei/backup/financial_backup.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/theme/notamei_theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> reveal(WidgetTester t, Key key) async {
  final position = t
      .state<ScrollableState>(find.byType(Scrollable).last)
      .position;
  // Restart the search above lazy children, including when revisiting the picker.
  position.jumpTo(position.minScrollExtent);
  await t.pumpAndSettle();
  await t.scrollUntilVisible(
    find.byKey(key),
    150,
    scrollable: find.byType(Scrollable).last,
  );
  await t.pumpAndSettle();
  await t.ensureVisible(find.byKey(key));
  await t.pumpAndSettle();
  expect(find.byKey(key).hitTestable(), findsOneWidget);
}

EntryRecord fixture(String id, {String? note}) => EntryRecord(
  id: id,
  type: EntryType.income,
  scope: EntryScope.business,
  amountCents: 100,
  category: 'Serviços',
  date: DateTime(2026, 11, 18),
  note: note,
);
void main() {
  sqfliteFfiInit();
  const channel = MethodChannel('br.edu.notamei/backup');
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await font.load();
  });
  for (final dark in [false, true]) {
    testWidgets(
      '390px texto 2x, conflitos, duplicados e cancelamento; tema escuro=$dark',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final repo = EntryRepository(
          databaseFactory: databaseFactoryFfiNoIsolate,
          path: inMemoryDatabasePath,
        );
        await repo.upsert(fixture('local', note: 'original'));
        Object? selected = FinancialBackupCodec.encode([
          fixture('local', note: 'diferente'),
          fixture('novo'),
        ], createdAt: DateTime.utc(2026));
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (_) async => selected);
        try {
          await t.pumpWidget(
            MaterialApp(
              theme: dark ? NotaMeiTheme.dark() : NotaMeiTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: BackupImportScreen(repository: repo),
            ),
          );
          await reveal(t, const Key('backup-pick'));
          await t.tap(find.byKey(const Key('backup-pick')));
          await t.pumpAndSettle();
          await reveal(t, const Key('backup-import'));
          expect(
            t
                .widget<FilledButton>(find.byKey(const Key('backup-import')))
                .onPressed,
            isNull,
          );
          expect(repo.entries.length, 1);
          selected = FinancialBackupCodec.encode([
            fixture('local', note: 'original'),
          ], createdAt: DateTime.utc(2026));
          await reveal(t, const Key('backup-pick'));
          await t.tap(find.byKey(const Key('backup-pick')));
          await t.pumpAndSettle();
          await reveal(t, const Key('backup-import-consent'));
          expect(
            t
                .widget<CheckboxListTile>(
                  find.byKey(const Key('backup-import-consent')),
                )
                .onChanged,
            isNull,
          );
          selected = null;
          await reveal(t, const Key('backup-pick'));
          await t.tap(find.byKey(const Key('backup-pick')));
          await t.pumpAndSettle();
          expect(find.byKey(const Key('backup-import-consent')), findsNothing);
          await reveal(t, const Key('backup-import-message'));
          expect(find.textContaining('Seleção cancelada'), findsOneWidget);
          expect(t.takeException(), isNull);
          expect(repo.entries.single.note, 'original');
        } finally {
          await t.pumpWidget(const SizedBox.shrink());
          await t.runAsync(repo.close);
          repo.dispose();
        }
      },
    );
  }
  testWidgets(
    'leitura pendente bloqueia toque repetido e retorno; erro permite nova seleção',
    (t) async {
      final repo = EntryRepository(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      final pending = Completer<Uint8List?>();
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            calls++;
            return pending.future;
          });
      try {
        await t.pumpWidget(
          MaterialApp(home: BackupImportScreen(repository: repo)),
        );
        await t.tap(find.byKey(const Key('backup-pick')));
        await t.tap(find.byKey(const Key('backup-pick')));
        await t.pump();
        expect(calls, 1);
        expect(t.widget<PopScope>(find.byType(PopScope).first).canPop, isFalse);
        pending.completeError(
          PlatformException(code: 'io', message: 'SEGREDO_FINANCEIRO'),
        );
        await t.pumpAndSettle();
        await reveal(t, const Key('backup-import-message'));
        expect(find.textContaining('SEGREDO_FINANCEIRO'), findsNothing);
        expect(find.textContaining('Não foi possível ler'), findsOneWidget);
        expect(t.widget<PopScope>(find.byType(PopScope).first).canPop, isTrue);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              channel,
              (_) async => Uint8List.fromList([0]),
            );
        await reveal(t, const Key('backup-pick'));
        await t.tap(find.byKey(const Key('backup-pick')));
        await t.pumpAndSettle();
        await reveal(t, const Key('backup-import-message'));
        expect(find.textContaining('inválido'), findsOneWidget);
        expect(repo.entries, isEmpty);
      } finally {
        if (!pending.isCompleted) pending.complete(null);
        await t.pumpWidget(const SizedBox.shrink());
        await t.runAsync(repo.close);
        repo.dispose();
      }
    },
  );
  testWidgets(
    'alteração depois da prévia invalida confirmação e preserva registros',
    (t) async {
      final repo = EntryRepository(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      await repo.initialize();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => FinancialBackupCodec.encode([
              fixture('arquivo'),
            ], createdAt: DateTime.utc(2026)),
          );
      try {
        await t.pumpWidget(
          MaterialApp(home: BackupImportScreen(repository: repo)),
        );
        await t.tap(find.byKey(const Key('backup-pick')));
        await t.pumpAndSettle();
        await repo.upsert(fixture('posterior'));
        await reveal(t, const Key('backup-import-consent'));
        await t.tap(find.byKey(const Key('backup-import-consent')));
        await t.pumpAndSettle();
        await reveal(t, const Key('backup-import'));
        await t.tap(find.byKey(const Key('backup-import')));
        await t.pumpAndSettle();
        await reveal(t, const Key('backup-import-message'));
        expect(find.textContaining('O histórico mudou'), findsOneWidget);
        expect(repo.entries.single.id, 'posterior');
        expect(find.byKey(const Key('backup-import-consent')), findsNothing);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await t.runAsync(repo.close);
        repo.dispose();
      }
    },
  );
  testWidgets(
    'seleciona, mostra prévia e só importa após ciência e confirmação',
    (t) async {
      final repo = EntryRepository(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      await repo.initialize();
      await repo.upsert(fixture('local'));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => FinancialBackupCodec.encode([
              fixture('novo'),
            ], createdAt: DateTime.utc(2026, 11, 18)),
          );
      try {
        await t.pumpWidget(
          MaterialApp(home: BackupImportScreen(repository: repo)),
        );
        await t.tap(find.byKey(const Key('backup-pick')));
        await t.pumpAndSettle();
        expect(find.text('Novos registros: 1'), findsOneWidget);
        expect(repo.entries.length, 1);
        await reveal(t, const Key('backup-import'));
        expect(
          t
              .widget<FilledButton>(find.byKey(const Key('backup-import')))
              .onPressed,
          isNull,
        );
        await reveal(t, const Key('backup-import-consent'));
        await t.tap(find.byKey(const Key('backup-import-consent')));
        await t.pumpAndSettle();
        await reveal(t, const Key('backup-import'));
        await t.tap(find.byKey(const Key('backup-import')));
        await t.pumpAndSettle();
        expect(repo.entries.length, 2);
        await reveal(t, const Key('backup-import-message'));
        expect(find.textContaining('Importação concluída'), findsOneWidget);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await t.runAsync(repo.close);
        repo.dispose();
      }
    },
  );
}
