import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/app/notamei_app.dart';
import 'package:notamei/backup/backup_import_screen.dart';
import 'package:notamei/backup/financial_backup.dart';
import 'package:notamei/das/das_reminder_service.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'backup_navigation_test.dart' show QuietNotifications, reveal;

void main() {
  sqfliteFfiInit();
  const channel = MethodChannel('br.edu.notamei/backup');
  testWidgets(
    'Ajustes importa backup com seletor real simulado e preserva preferências',
    (t) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'theme_mode': 'dark',
        'custom': 'preservada',
      });
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final repo = EntryRepository(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      final record = EntryRecord(
        id: 'novo',
        type: EntryType.expense,
        scope: EntryScope.personal,
        amountCents: 123,
        category: 'Pessoal',
        date: DateTime(2025, 12, 31),
        note: 'Ação',
      );
      await repo.initialize();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => FinancialBackupCodec.encode([
              record,
            ], createdAt: DateTime.utc(2026, 11, 18)),
          );
      try {
        await t.pumpWidget(
          NotaMeiApp(
            repository: repo,
            preferences: prefs,
            dasService: DasReminderService(
              preferences: prefs,
              gateway: QuietNotifications(),
            ),
          ),
        );
        await t.tap(find.text('Ajustes').last);
        await t.pumpAndSettle();
        await reveal(t, find.text('Importar backup'));
        await t.tap(find.text('Importar backup'));
        await t.pumpAndSettle();
        expect(find.byType(BackupImportScreen), findsOneWidget);
        await reveal(t, find.byKey(const Key('backup-pick')));
        await t.tap(find.byKey(const Key('backup-pick')));
        await t.pumpAndSettle();
        expect(repo.entries, isEmpty);
        await reveal(t, find.byKey(const Key('backup-import-consent')));
        await t.tap(find.byKey(const Key('backup-import-consent')));
        await t.pumpAndSettle();
        await reveal(t, find.byKey(const Key('backup-import')));
        await t.tap(find.byKey(const Key('backup-import')));
        await t.pumpAndSettle();
        expect(repo.entries.single.note, 'Ação');
        expect({
          for (final key in prefs.getKeys()) key: prefs.get(key),
        }, before);
        await t.tap(find.byTooltip('Voltar'));
        await t.pumpAndSettle();
        await reveal(t, find.text('Importar backup'));
        await t.tap(find.text('Importar backup'));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('backup-import-consent')), findsNothing);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await t.runAsync(repo.close);
        repo.dispose();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );
}
