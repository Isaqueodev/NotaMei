import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/app/notamei_app.dart';
import 'package:notamei/backup/backup_creation_screen.dart';
import 'package:notamei/backup/financial_backup.dart';
import 'package:notamei/das/das_reminder_service.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class QuietNotifications implements DasNotificationGateway {
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> schedule(DasReminderSettings settings) async {}
  @override
  Future<void> cancel() async {}
}

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

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  sqfliteFfiInit();
  const channel = MethodChannel('flutter_file_dialog');
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets(
    'Ajustes abre criação e salva histórico completo sem mudar SQLite ou preferências',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'theme_mode': 'dark',
      });
      final preferences = await SharedPreferences.getInstance();
      final prefsBefore = {
        for (final key in preferences.getKeys()) key: preferences.get(key),
      };
      final repository = EntryRepository(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      await repository.initialize();
      await repository.upsert(
        EntryRecord(
          id: 'outro-ano',
          type: EntryType.income,
          scope: EntryScope.business,
          amountCents: 12345,
          category: 'Serviços',
          date: DateTime(2025, 12, 31),
          note: 'Ação\nOriginal',
        ),
      );
      await repository.upsert(
        EntryRecord(
          id: 'pessoal',
          type: EntryType.expense,
          scope: EntryScope.personal,
          amountCents: 1,
          category: 'Pessoal',
          date: DateTime(2026, 1, 1),
        ),
      );
      await repository.saveWithdrawal(
        operationId: 'par',
        amountCents: 100,
        date: DateTime(2026, 11, 18),
        note: 'Duas pontas',
      );
      final before = repository.entries;
      var calls = 0;
      var notifications = 0;
      repository.addListener(() => notifications++);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls++;
            expect(call.method, 'saveFile');
            expect(call.arguments['mimeTypesFilter'], ['application/json']);
            expect(call.arguments['localOnly'], isTrue);
            expect(call.arguments['fileName'], startsWith('NotaMei_backup_'));
            final backup = FinancialBackupCodec.decode(call.arguments['data']);
            expect(
              backup.entries.map(fields).toList(),
              before.map(fields).toList(),
            );
            return '/document/synthetic-backup.json';
          });
      try {
        await tester.pumpWidget(
          NotaMeiApp(
            repository: repository,
            preferences: preferences,
            dasService: DasReminderService(
              preferences: preferences,
              gateway: QuietNotifications(),
            ),
          ),
        );
        await tester.tap(find.text('Ajustes').last);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<SettingsScreen>(find.byType(SettingsScreen))
              .onCreateBackup,
          isNotNull,
        );
        await reveal(tester, find.text('Criar backup'));
        await tester.tap(find.text('Criar backup'));
        await tester.pumpAndSettle();
        expect(find.byType(BackupCreationScreen), findsOneWidget);
        expect(calls, 0);
        await reveal(tester, find.byKey(const Key('backup-consent')));
        await tester.tap(find.byKey(const Key('backup-consent')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('backup-save')));
        await tester.tap(find.byKey(const Key('backup-save')));
        await tester.pumpAndSettle();
        expect(calls, 1);
        await reveal(tester, find.byKey(const Key('backup-message')));
        expect(
          find.textContaining('O Android informou que o arquivo foi salvo'),
          findsOneWidget,
        );
        expect(identical(repository.entries, before), isTrue);
        expect(notifications, 0);
        expect({
          for (final key in preferences.getKeys()) key: preferences.get(key),
        }, prefsBefore);
        // pageBack() searches the English tooltip; the app is localized in pt-BR.
        expect(find.byTooltip('Voltar').hitTestable(), findsOneWidget);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Criar backup'));
        await tester.tap(find.text('Criar backup'));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('backup-consent')));
        expect(
          tester
              .widget<CheckboxListTile>(find.byKey(const Key('backup-consent')))
              .value,
          isFalse,
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(repository.close);
        repository.dispose();
      }
    },
  );
}
