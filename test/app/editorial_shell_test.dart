import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/app/notamei_app.dart';
import 'package:notamei/das/das_reminder_service.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Gateway implements DasNotificationGateway {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> schedule(DasReminderSettings settings) async {}
  @override
  Future<void> cancel() async {}
}

void main() {
  sqfliteFfiInit();
  testWidgets('V5 four tabs remain usable at 390px with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final preferences = await SharedPreferences.getInstance();
    final repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    await repository.initialize();
    await tester.pumpWidget(
      NotaMeiApp(
        repository: repository,
        preferences: preferences,
        dasService: DasReminderService(
          preferences: preferences,
          gateway: _Gateway(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final nav = find.byType(NavigationBar);
    expect(
      find.descendant(of: nav, matching: find.byType(NavigationDestination)),
      findsNWidgets(4),
    );
    for (final label in ['Histórico', 'Ano', 'Ajustes', 'Início']) {
      await tester.tap(find.descendant(of: nav, matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow or render failure on $label',
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(repository.close);
    repository.dispose();
  });
}
