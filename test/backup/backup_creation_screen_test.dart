import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/backup/backup_creation_screen.dart';
import 'package:notamei/backup/backup_creation_service.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/export/export_gateway.dart';
import 'package:notamei/theme/notamei_theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Roboto-$weight.ttf'));
    }
    await loader.load();
  });
  late EntryRepository repository;
  setUp(
    () => repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    ),
  );
  tearDown(() => repository.dispose());

  testWidgets(
    '390px e texto 2x permitem ler avisos confirmar e cancelar nos dois temas',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      for (final theme in [NotaMeiTheme.light(), NotaMeiTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(theme.brightness),
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: BackupCreationScreen(
              repository: repository,
              save: () async {
                calls++;
                return ExportOutcome.cancelled;
              },
            ),
          ),
        );
        await reveal(tester, find.textContaining('restauração ainda não'));
        expect(find.textContaining('restauração ainda não'), findsOneWidget);
        await reveal(tester, find.byKey(const Key('backup-consent')));
        expect(
          find.byKey(const Key('backup-consent')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('backup-consent')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('backup-save')));
        expect(
          find.byKey(const Key('backup-save')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('backup-save')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('backup-message')));
        expect(find.text('Criação de backup cancelada.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      expect(calls, 2);
    },
  );

  testWidgets(
    'conclusão após desmontar a tela não atualiza estado descartado',
    (tester) async {
      final completion = Completer<ExportOutcome>();
      await tester.pumpWidget(
        MaterialApp(
          home: BackupCreationScreen(
            repository: repository,
            save: () => completion.future,
          ),
        ),
      );
      await reveal(tester, find.byKey(const Key('backup-consent')));
      await tester.tap(find.byKey(const Key('backup-consent')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('backup-save')));
      await tester.tap(find.byKey(const Key('backup-save')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      completion.complete(ExportOutcome.saved);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'operação pendente bloqueia duplo toque ciência e retorno até concluir',
    (tester) async {
      final completion = Completer<ExportOutcome>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: NotaMeiTheme.light(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BackupCreationScreen(
                    repository: repository,
                    save: () {
                      calls++;
                      return completion.future;
                    },
                  ),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('backup-consent')));
      await tester.tap(find.byKey(const Key('backup-consent')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('backup-save')));
      try {
        await tester.tap(find.byKey(const Key('backup-save')));
        await tester.tap(find.byKey(const Key('backup-save')));
        await tester.pump();
        expect(calls, 1);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('backup-save')))
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<CheckboxListTile>(find.byKey(const Key('backup-consent')))
              .onChanged,
          isNull,
        );
        expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.byType(BackupCreationScreen), findsOneWidget);
      } finally {
        completion.complete(ExportOutcome.cancelled);
        await tester.pumpAndSettle();
      }
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('backup-save')))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'cancelamento e falhas não anunciam sucesso e permitem retentar',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: NotaMeiTheme.light(),
          home: BackupCreationScreen(
            repository: repository,
            save: () async {
              calls++;
              return switch (calls) {
                1 => ExportOutcome.cancelled,
                2 => throw StateError('SEGREDO_FINANCEIRO caminho-privado'),
                3 => throw const BackupCreationException(
                  BackupCreationFailure.preparation,
                ),
                4 => ExportOutcome.saved,
                5 => ExportOutcome.unconfirmed,
                _ => ExportOutcome.shared,
              };
            },
          ),
        ),
      );
      await reveal(tester, find.byKey(const Key('backup-consent')));
      await tester.tap(find.byKey(const Key('backup-consent')));
      await tester.pumpAndSettle();
      final expected = [
        'Criação de backup cancelada.',
        'Não foi possível confirmar o salvamento',
        'Não foi possível preparar o backup',
        'O Android informou que o arquivo foi salvo',
        'Não foi possível confirmar o salvamento',
        'Não foi possível confirmar o salvamento',
      ];
      for (var i = 0; i < expected.length; i++) {
        await reveal(tester, find.byKey(const Key('backup-save')));
        await tester.tap(find.byKey(const Key('backup-save')));
        await tester.pumpAndSettle();
        expect(calls, i + 1);
        await reveal(tester, find.byKey(const Key('backup-message')));
        expect(find.textContaining(expected[i]), findsOneWidget);
        expect(find.textContaining('SEGREDO_FINANCEIRO'), findsNothing);
        expect(find.textContaining('caminho-privado'), findsNothing);
        if (i != 3) {
          expect(
            find.textContaining('O Android informou que o arquivo foi salvo'),
            findsNothing,
          );
        }
      }
    },
  );

  testWidgets('explica conteúdo e limitações e exige ciência antes de salvar', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: NotaMeiTheme.light(),
        home: BackupCreationScreen(
          repository: repository,
          save: () async {
            calls++;
            return ExportOutcome.saved;
          },
        ),
      ),
    );
    await reveal(tester, find.byKey(const Key('backup-save')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('backup-save')))
          .onPressed,
      isNull,
    );
    expect(calls, 0);
    await reveal(tester, find.textContaining('sem senha').first);
    expect(find.textContaining('sem senha'), findsWidgets);
    expect(find.textContaining('restauração ainda não'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('backup-consent')));
    await tester.tap(find.byKey(const Key('backup-consent')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backup-save')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('backup-save')))
          .onPressed,
      isNotNull,
    );
  });
}
