import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notamei/das/das_reminder_service.dart';
import 'package:notamei/das/das_settings_screen.dart';

class FakeNotifications implements DasNotificationGateway {
  bool allow = false;
  bool failSchedule = false;
  @override
  Future<bool> requestPermission() async => allow;
  @override
  Future<void> schedule(DasReminderSettings settings) async {
    if (failSchedule) throw StateError('partial scheduling');
  }

  @override
  Future<void> cancel() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('estado inativo e pedido de permissão somente após ativar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeNotifications();
    final service = DasReminderService(preferences: prefs, gateway: fake);
    await tester.pumpWidget(
      MaterialApp(
        home: DasSettingsScreen(service: service, onChanged: () {}),
      ),
    );
    expect(find.text('Lembrete desativado'), findsOneWidget);
    expect(find.textContaining('não confirma'), findsWidgets);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ativar lembrete'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Permissão de notificações negada'),
      findsOneWidget,
    );
    expect(service.enabled, isFalse);
  });
  testWidgets('falha ao alterar lembrete ativo atualiza estado e tela pai', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'das_enabled': true,
      'das_day': 15,
      'das_hour': 9,
      'das_minute': 0,
    });
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeNotifications()
      ..allow = true
      ..failSchedule = true;
    final service = DasReminderService(preferences: prefs, gateway: fake);
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DasSettingsScreen(service: service, onChanged: () => changes++),
      ),
    );
    await tester.tap(find.text('Ativar lembrete'));
    await tester.pumpAndSettle();
    expect(find.text('Lembrete desativado'), findsOneWidget);
    expect(changes, 1);
    expect(find.textContaining('Não foi possível agendar'), findsOneWidget);
  });
}
