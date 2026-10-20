import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/das/das_reminder_service.dart';
import 'package:notamei/das/das_settings_screen.dart';
import 'package:notamei/theme/notamei_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Gateway implements DasNotificationGateway {
  Completer<bool>? permission;
  int requests = 0;
  int schedules = 0;
  @override
  Future<bool> requestPermission() {
    requests++;
    return permission?.future ?? Future.value(true);
  }

  @override
  Future<void> schedule(DasReminderSettings settings) async {
    schedules++;
  }

  @override
  Future<void> cancel() async {}
}

Widget _host(DasReminderService service, {double scale = 1, Key? screenKey}) =>
    MaterialApp(
      theme: NotaMeiTheme.data,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: true,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: DasSettingsScreen(
        key: screenKey,
        service: service,
        onChanged: () {},
      ),
    );

void main() {
  testWidgets(
    'seletor de horário padrão é flat e mantém seleção pelo teclado',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'das_day': 10,
        'das_hour': 8,
        'das_minute': 15,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = DasReminderService(
        preferences: prefs,
        gateway: _Gateway(),
      );
      await tester.pumpWidget(_host(service));
      await tester.ensureVisible(find.text('Horário do lembrete'));
      await tester.tap(find.text('Horário do lembrete'));
      await tester.pumpAndSettle();
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.elevation, 0);
      expect(dialog.backgroundColor, Colors.white);
      await tester.tap(find.byTooltip('Switch to text input mode'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '18');
      await tester.enterText(find.byType(TextField).last, '45');
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('18:45'), findsOneWidget);
      await tester.ensureVisible(find.text('Ativar lembrete'));
      await tester.tap(find.text('Ativar lembrete'));
      await tester.pumpAndSettle();
      expect(prefs.getInt('das_hour'), 18);
      expect(prefs.getInt('das_minute'), 45);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dia e hora pessoais podem ser editados, cancelados e relidos da persistência',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'das_enabled': true,
        'das_day': 31,
        'das_hour': 8,
        'das_minute': 35,
      });
      final prefs = await SharedPreferences.getInstance();
      final gateway = _Gateway();
      final service = DasReminderService(preferences: prefs, gateway: gateway);
      await tester.pumpWidget(_host(service, scale: 2));
      expect(gateway.requests, 0);
      expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .value,
        31,
      );
      expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .items,
        hasLength(31),
      );
      await tester.ensureVisible(find.text('Horário do lembrete'));
      await tester.tap(find.text('Horário do lembrete'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('das-hour')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('das-hour')))
            .controller
            ?.text,
        '08',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('das-minute')))
            .controller
            ?.text,
        '35',
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('08:35'), findsOneWidget);
      await tester.ensureVisible(find.text('Horário do lembrete'));
      await tester.tap(find.text('Horário do lembrete'));
      await tester.pumpAndSettle();
      expect(find.text('Informe uma hora de 0 a 23.'), findsNothing);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('das-hour')), '25');
      await tester.enterText(find.byKey(const Key('das-minute')), '80');
      await tester.ensureVisible(find.text('Confirmar horário'));
      await tester.tap(find.text('Confirmar horário'));
      await tester.pumpAndSettle();
      expect(find.text('Informe uma hora de 0 a 23.'), findsOneWidget);
      expect(find.text('Informe os minutos de 0 a 59.'), findsOneWidget);
      expect(prefs.getInt('das_hour'), 8);
      await tester.enterText(find.byKey(const Key('das-hour')), '18');
      await tester.enterText(find.byKey(const Key('das-minute')), '45');
      await tester.ensureVisible(find.text('Confirmar horário'));
      await tester.tap(find.text('Confirmar horário'));
      await tester.pumpAndSettle();
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.text('18:45'), findsOneWidget);
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('29').last);
      await tester.tap(find.text('29').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ativar lembrete'));
      await tester.tap(find.text('Ativar lembrete'));
      await tester.pumpAndSettle();
      expect(prefs.getInt('das_day'), 29);
      expect(prefs.getInt('das_hour'), 18);
      expect(prefs.getInt('das_minute'), 45);
      expect(service.enabled, isTrue);
      await tester.pumpWidget(
        _host(
          DasReminderService(preferences: prefs, gateway: gateway),
          scale: 2,
          screenKey: const ValueKey('reopen'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dia 29 · 18:45'), findsOneWidget);
      expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .value,
        29,
      );
      expect(find.text('18:45'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'operação pendente bloqueia controles e toque repetido até persistir',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'das_day': 12,
        'das_hour': 10,
        'das_minute': 20,
      });
      final prefs = await SharedPreferences.getInstance();
      final gateway = _Gateway()..permission = Completer<bool>();
      final service = DasReminderService(preferences: prefs, gateway: gateway);
      await tester.pumpWidget(_host(service));
      await tester.ensureVisible(find.text('Ativar lembrete'));
      final button = find.widgetWithText(FilledButton, 'Ativar lembrete');
      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Horário do lembrete'),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('das-message')), findsNothing);
      await tester.tap(button);
      await tester.pump();
      expect(gateway.requests, 1);
      expect(service.enabled, isFalse);
      gateway.permission!.complete(true);
      await tester.pumpAndSettle();
      expect(gateway.schedules, 1);
      expect(service.enabled, isTrue);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    },
  );

  testWidgets(
    'sair durante pedido de permissão não atualiza widget desmontado',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'das_day': 12,
        'das_hour': 10,
        'das_minute': 20,
      });
      final prefs = await SharedPreferences.getInstance();
      final gateway = _Gateway()..permission = Completer<bool>();
      await tester.pumpWidget(
        _host(DasReminderService(preferences: prefs, gateway: gateway)),
      );
      await tester.ensureVisible(find.text('Ativar lembrete'));
      await tester.tap(find.text('Ativar lembrete'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      gateway.permission!.complete(false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
