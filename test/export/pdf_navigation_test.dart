import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notamei/app/notamei_app.dart';
import 'package:notamei/das/das_reminder_service.dart';

import 'export_screen_test.dart' show MemoryRepository, reveal;
import 'withdrawal_csv_test.dart' show fixture;

class NoNotifications implements DasNotificationGateway {
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> schedule(DasReminderSettings settings) async {}
  @override
  Future<void> cancel() async {}
}

void main() {
  testWidgets('Ajustes oferece PDF e abre exportação sem perder a opção CSV', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final preferences = await SharedPreferences.getInstance();
    final repo = MemoryRepository()..records.addAll(fixture());
    await tester.pumpWidget(
      NotaMeiApp(
        repository: repo,
        preferences: preferences,
        dasService: DasReminderService(
          preferences: preferences,
          gateway: NoNotifications(),
        ),
      ),
    );
    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Exportar CSV'));
    expect(find.text('Exportar CSV'), findsOneWidget);
    await reveal(tester, find.text('Exportar PDF'));
    await tester.tap(find.text('Exportar PDF'));
    await tester.pumpAndSettle();
    expect(find.text('Exportar PDF'), findsOneWidget);
    await reveal(tester, find.text('Salvar PDF'));
    expect(find.text('Compartilhar PDF'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });
}
