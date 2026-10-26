import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/app/startup_screen.dart';
import 'package:notamei/das/das_reminder_service.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FailOnceRepository extends EntryRepository {
  _FailOnceRepository({super.databaseFactory, super.path});

  bool shouldFail = false;
  bool ready = false;

  @override
  Future<void> initialize() {
    if (shouldFail) {
      shouldFail = false;
      return Future<void>.error(StateError('falha simulada'));
    }
    if (ready) return Future<void>.value();
    return super.initialize().then((_) => ready = true);
  }
}

class _ThrowingDasGateway implements DasNotificationGateway {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(DasReminderSettings settings) async {
    throw StateError('DAS indisponível');
  }

  @override
  Future<void> cancel() async {}
}

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late _FailOnceRepository repository;
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'das_enabled': true,
      'das_day': 10,
      'das_hour': 9,
      'das_minute': 0,
    });
    preferences = await SharedPreferences.getInstance();

    directory = await Directory.systemTemp.createTemp('notamei-startup-');
    repository = _FailOnceRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: '${directory.path}/notamei.db',
    );
    await repository.initialize();
    await repository.upsert(
      EntryRecord(
        id: 'venda-1',
        type: EntryType.income,
        scope: EntryScope.business,
        amountCents: 15000,
        category: 'Venda',
        date: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await repository.close();
    repository.dispose();
    await directory.delete(recursive: true);
  });

  testWidgets(
    'falha ao abrir mostra orientação e o retry preserva os registros',
    (tester) async {
      repository.shouldFail = true;

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        StartupScreen(
          repository: repository,
          preferencesLoader: () async => preferences,
          gatewayFactory: _ThrowingDasGateway.new,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível abrir o NotaMei'), findsOneWidget);
      expect(find.textContaining('Seus registros continuam'), findsOneWidget);
      expect(find.byKey(const Key('startup-retry')), findsOneWidget);

      await tester.tap(find.byKey(const Key('startup-retry')));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível abrir o NotaMei'), findsNothing);
      expect(find.byKey(const Key('recent-ledger')), findsOneWidget);
      expect(find.text('Venda'), findsWidgets);
      expect(
        repository.entries.any((entry) => entry.category == 'Venda'),
        isTrue,
      );
    },
  );

  testWidgets('falha do DAS não impede abrir os registros', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      StartupScreen(
        repository: repository,
        preferencesLoader: () async => preferences,
        gatewayFactory: _ThrowingDasGateway.new,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível abrir o NotaMei'), findsNothing);
    expect(find.byKey(const Key('recent-ledger')), findsOneWidget);
  });
}