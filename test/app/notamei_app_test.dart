import 'dart:io';

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
  late Directory directory;
  late EntryRepository repository;
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    directory = await Directory.systemTemp.createTemp('notamei-app-');
    repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: '${directory.path}/entries.db',
    );
    await repository.initialize();
  });
  tearDown(() async {
    await repository.close();
    repository.dispose();
    await directory.delete(recursive: true);
  });

  testWidgets(
    'pular primeiro uso abre app e tour pode ser revisto sem apagar dados',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      await tester.ensureVisible(find.text('Começar sem tour'));
      await tester.tap(find.text('Começar sem tour'));
      await tester.pumpAndSettle();
      expect(find.text('Flutter Demo Home Page'), findsNothing);
      expect(find.text('NotaMei'), findsWidgets);
      expect(preferences.getBool('onboarding_completed'), isTrue);
      await tester.tap(find.text('Ajustes').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rever tour'));
      await tester.pumpAndSettle();
      expect(find.text('Registre o que entra e sai'), findsOneWidget);
      await tester.tap(find.text('Pular tour').first);
      await tester.pumpAndSettle();
      expect(find.text('Ajustes'), findsWidgets);
    },
  );

  testWidgets('Ajustes abre exportação CSV sem alterar lançamentos', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    preferences = await SharedPreferences.getInstance();
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
    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Exportar CSV'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportar CSV'));
    await tester.pumpAndSettle();
    expect(find.text('Seus registros, fora do app'), findsOneWidget);
    expect(repository.entries, isEmpty);
  });

  testWidgets('conclusão oferece primeiro registro e abas exibem ano e DAS', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    await tester.ensureVisible(find.text('Ver como funciona'));
    await tester.tap(find.text('Ver como funciona'));
    await tester.pumpAndSettle();
    for (var step = 0; step < 2; step++) {
      await tester.ensureVisible(find.text('Próximo'));
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Começar a usar'));
    await tester.tap(find.text('Começar a usar'));
    await tester.pumpAndSettle();
    expect(find.text('Pronto para começar'), findsOneWidget);
    await tester.tap(find.text('Adicionar primeiro lançamento'));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar Lançamento'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ano'));
    await tester.pumpAndSettle();
    expect(find.textContaining('não é uma apuração fiscal'), findsOneWidget);
    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configurar lembrete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('não confirma vencimento'), findsOneWidget);
  });
}
