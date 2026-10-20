import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/das/das_reminder_service.dart';
import 'package:notamei/das/das_settings_screen.dart';
import 'package:notamei/theme/notamei_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Notifications implements DasNotificationGateway {
  bool allow = false;
  bool failSchedule = false;
  bool failCancel = false;
  int permissionRequests = 0;
  DasReminderSettings? scheduled;
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allow;
  }

  @override
  Future<void> schedule(DasReminderSettings settings) async {
    if (failSchedule) throw StateError('schedule failed');
    scheduled = settings;
  }

  @override
  Future<void> cancel() async {
    if (failCancel) throw StateError('cancel failed');
    scheduled = null;
  }
}

void main() {
  testWidgets(
    'DAS editorial distingue orientação de erro e preserva formulário, permissões e estado em 390px texto 2x',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final gateway = _Notifications();
      final service = DasReminderService(preferences: prefs, gateway: gateway);
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: NotaMeiTheme.data,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(2),
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          ),
          home: DasSettingsScreen(service: service, onChanged: () => changes++),
        ),
      );
      expect(find.byType(Card), findsWidgets);
      expect(tester.widget<Card>(find.byType(Card).first).color, Colors.white);
      expect(tester.widget<Card>(find.byType(Card).first).elevation, 0);
      expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .elevation,
        0,
      );
      expect(find.byKey(const Key('das-message')), findsNothing);
      expect(gateway.permissionRequests, 0);
      expect(
        tester.widget<Text>(find.text('Lembrete desativado')).style?.color,
        NotaMeiTheme.muted,
      );

      Future<void> activate() async {
        await tester.scrollUntilVisible(find.text('Ativar lembrete'), 200);
        await tester.tap(find.text('Ativar lembrete'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> checkMessage(String text, Color color) async {
        final message = find.byKey(const Key('das-message'));
        await tester.scrollUntilVisible(message, 150);
        expect(tester.widget<Text>(message).data, contains(text));
        expect(tester.widget<Text>(message).style?.color, color);
      }

      await activate();
      await checkMessage('Selecione o dia', NotaMeiTheme.expense);
      expect(gateway.permissionRequests, 0);
      await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField<int>),
        -200,
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1').last);
      await tester.pumpAndSettle();
      await activate();
      await checkMessage(
        'Permissão de notificações negada',
        NotaMeiTheme.expense,
      );
      expect(service.enabled, isFalse);
      expect(gateway.permissionRequests, 1);

      gateway.allow = true;
      gateway.failSchedule = true;
      await activate();
      await checkMessage('Não foi possível agendar', NotaMeiTheme.expense);
      expect(service.enabled, isFalse);
      gateway.failSchedule = false;
      await activate();
      await checkMessage(
        'Lembrete agendado no seu aparelho.',
        NotaMeiTheme.income,
      );
      expect(service.enabled, isTrue);
      expect(gateway.scheduled?.day, 1);
      expect(prefs.getInt('das_day'), 1);
      expect(prefs.getInt('das_hour'), 9);
      expect(prefs.getInt('das_minute'), 0);

      gateway.failCancel = true;
      await tester.scrollUntilVisible(find.text('Desativar lembrete'), -150);
      await tester.tap(find.text('Desativar lembrete'));
      await tester.pumpAndSettle();
      await checkMessage('Não foi possível cancelar', NotaMeiTheme.expense);
      expect(service.enabled, isTrue);
      gateway.failCancel = false;
      await tester.scrollUntilVisible(find.text('Desativar lembrete'), -150);
      await tester.tap(find.text('Desativar lembrete'));
      await tester.pumpAndSettle();
      await checkMessage('Lembrete desativado.', NotaMeiTheme.ink);
      expect(service.enabled, isFalse);
      expect(changes, 4);
      await tester.scrollUntilVisible(
        find.textContaining('A entrega não é garantida'),
        200,
      );
      expect(find.textContaining('A entrega não é garantida'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
