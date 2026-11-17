import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/finance/entry_form_screen.dart';
import 'package:notamei/theme/notamei_theme.dart';

import 'notamei_finance_test.dart' show FlowApp;

import 'package:notamei/data/entry_record.dart';

class SequenceRepository extends EntryRepository {
  SequenceRepository(String path)
    : super(databaseFactory: databaseFactoryFfiNoIsolate, path: path);

  bool failNext = false;
  Completer<void>? hold;
  int attempts = 0;

  @override
  Future<void> upsert(EntryRecord record) async {
    attempts++;
    if (hold != null) await hold!.future;
    if (failNext) {
      failNext = false;
      throw StateError('Falha de persistência simulada');
    }
    await super.upsert(record);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  setUpAll(() async {
    // Use the app's bundled fonts, not Ahem's synthetic layout metrics.
    final fonts = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Roboto-$weight.ttf'));
    }
    await fonts.load();
  });
  late Directory directory;
  late SequenceRepository repository;
  var closed = false;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('notamei-sequence-');
    repository = SequenceRepository('${directory.path}/entries.db');
    await repository.initialize();
    closed = false;
  });

  tearDown(() async {
    if (!closed) {
      await repository.close();
      repository.dispose();
    }
    await directory.delete(recursive: true);
  });

  void sequenceTest(String name, WidgetTesterCallback body) {
    testWidgets(name, (tester) async {
      try {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(FlowApp(repository: repository));
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Novo Lançamento'),
        );
        await tester.pumpAndSettle();
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => repository.close());
        repository.dispose();
        closed = true;
      }
    });
  }

  Future<void> settleIo(WidgetTester tester, bool Function() complete) async {
    for (var i = 0; i < 100 && !complete(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
    expect(complete(), isTrue, reason: 'Operação assíncrona não terminou');
  }

  sequenceTest(
    '390px e texto 2x preservam erro, sequência e foco acima do teclado',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          theme: NotaMeiTheme.data,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: EntryFormScreen(repository: repository, onSaved: () {}),
        ),
      );
      await tester.pumpAndSettle();
      final expenseChip = find.widgetWithText(ChoiceChip, 'Despesa (Saída)');
      expect(expenseChip.hitTestable(), findsOneWidget);
      await tester.tap(expenseChip);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(expenseChip).selected, isTrue);
      await tester.enterText(find.byType(TextField).first, '25,00');
      await tester.enterText(find.byType(TextField).last, 'Não perder');
      repository.failNext = true;
      await tester.tap(find.text('Salvar e adicionar outro'));
      await tester.pumpAndSettle();
      await settleIo(
        tester,
        () => find.byKey(const Key('save-error')).evaluate().isNotEmpty,
      );
      expect(find.byKey(const Key('save-error')).hitTestable(), findsOneWidget);
      expect(repository.entries, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '25,00',
      );
      expect(find.text('Adicionar Lançamento').hitTestable(), findsOneWidget);
      expect(
        find.text('Salvar e adicionar outro').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Salvar e adicionar outro'));
      await tester.pumpAndSettle();
      await settleIo(tester, () => repository.entries.length == 1);
      expect(repository.entries.single.category, 'Mercadorias / Matéria-prima');
      expect(repository.entries.single.note, 'Não perder');
      expect(
        tester
            .widget<TextField>(find.byType(TextField).first)
            .focusNode!
            .hasFocus,
        isTrue,
      );
      expect(
        find.text('Lançamento salvo. Você pode adicionar outro.').hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Adicionar Lançamento').hitTestable(), findsOneWidget);
      expect(
        find.text('Salvar e adicionar outro').hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.getBottomLeft(find.text('Salvar e adicionar outro')).dy,
        lessThanOrEqualTo(544),
      );
      expect(tester.takeException(), isNull);
    },
  );

  sequenceTest('não sai do formulário durante uma gravação em andamento', (
    tester,
  ) async {
    repository.hold = Completer<void>();
    await tester.enterText(find.byType(TextField).first, '10,00');
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pump();
    try {
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(EntryFormScreen), findsOneWidget);
    } finally {
      repository.hold!.complete();
      await settleIo(tester, () => repository.entries.length == 1);
    }
  });

  sequenceTest(
    'grava dois lançamentos distintos e mantém classificação e data',
    (tester) async {
      await tester.tap(find.text('Despesa (Saída)'));
      await tester.tap(find.byType(DropdownButton<EntryScope>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pessoal').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '20,50');
      await tester.enterText(find.byType(TextField).last, 'Primeiro');
      await tester.tap(find.text('Salvar e adicionar outro'));
      await tester.pumpAndSettle();
      await settleIo(tester, () => repository.entries.length == 1);
      final first = repository.entries.single;

      await tester.enterText(find.byType(TextField).first, '31,25');
      await tester.tap(find.text('Salvar e adicionar outro'));
      await tester.pumpAndSettle();
      await settleIo(tester, () => repository.entries.length == 2);
      expect(repository.entries.map((e) => e.id).toSet(), hasLength(2));
      expect(
        repository.entries.map((e) => e.amountCents),
        containsAll([2050, 3125]),
      );
      expect(
        repository.entries.every(
          (e) =>
              e.type == EntryType.expense &&
              e.scope == EntryScope.personal &&
              e.category == first.category &&
              e.date == first.date,
        ),
        isTrue,
      );
      expect(
        repository.entries.where((e) => e.note == 'Primeiro'),
        hasLength(1),
      );
      expect(find.byType(EntryFormScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(EntryFormScreen), findsNothing);
      await tester.runAsync(() async {
        await repository.close();
        await repository.initialize();
      });
      expect(repository.entries, hasLength(2));
    },
  );

  sequenceTest('erro ao continuar preserva campos e permite nova tentativa', (
    tester,
  ) async {
    repository.failNext = true;
    await tester.enterText(find.byType(TextField).first, '42,10');
    await tester.enterText(find.byType(TextField).last, 'Não perder');
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pumpAndSettle();
    await settleIo(
      tester,
      () => find.byKey(const Key('save-error')).evaluate().isNotEmpty,
    );
    expect(repository.entries, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '42,10',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'Não perder',
    );
    expect(
      find.text('Lançamento salvo. Você pode adicionar outro.'),
      findsNothing,
    );
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => repository.entries.length == 1);
    expect(repository.entries.single.amountCents, 4210);
    expect(repository.attempts, 2);
  });

  sequenceTest('botões de salvar ficam bloqueados durante a sequência', (
    tester,
  ) async {
    repository.hold = Completer<void>();
    await tester.enterText(find.byType(TextField).first, '10,00');
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pump();
    try {
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Salvar e adicionar outro'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Adicionar Lançamento'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Salvar e adicionar outro'));
      await tester.tap(find.text('Adicionar Lançamento'));
      await tester.pump();
      expect(repository.attempts, 1);
    } finally {
      repository.hold!.complete();
      await settleIo(tester, () => repository.entries.length == 1);
    }
  });

  sequenceTest('continuar rejeita valor inválido e não limpa a observação', (
    tester,
  ) async {
    await tester.enterText(find.byType(TextField).first, '0');
    await tester.enterText(find.byType(TextField).last, 'Conferir valor');
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pumpAndSettle();
    expect(repository.entries, isEmpty);
    expect(repository.attempts, 0);
    expect(
      find.text('Informe um valor positivo no formato 1.234,56'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'Conferir valor',
    );
  });

  sequenceTest('salvar normal após continuar volta sem duplicar o anterior', (
    tester,
  ) async {
    await tester.enterText(find.byType(TextField).first, '10,00');
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => repository.entries.length == 1);
    await tester.enterText(find.byType(TextField).first, '20,00');
    await tester.tap(find.text('Adicionar Lançamento'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => repository.entries.length == 2);
    expect(find.byType(EntryFormScreen), findsNothing);
  });

  sequenceTest('edição não oferece salvar e adicionar outro', (tester) async {
    await tester.enterText(find.byType(TextField).first, '10,00');
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => repository.entries.length == 1);
    await tester.pumpWidget(
      MaterialApp(
        home: EntryFormScreen(
          repository: repository,
          existing: repository.entries.single,
          onSaved: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Salvar e adicionar outro'), findsNothing);
    expect(find.text('Salvar Alterações'), findsOneWidget);
  });

  sequenceTest('formulário de sequência cabe em celular com teclado aberto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewInsets = FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField).first, '12,00');
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => repository.entries.length == 1);
    expect(tester.takeException(), isNull);
    expect(find.text('Salvar e adicionar outro').hitTestable(), findsOneWidget);
  });

  sequenceTest('campos não aceitam digitação enquanto o lançamento é salvo', (
    tester,
  ) async {
    repository.hold = Completer<void>();
    await tester.enterText(find.byType(TextField).first, '10,00');
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pump();
    try {
      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .every((chip) => chip.onSelected == null),
        isTrue,
      );
      expect(
        tester
            .widget<DropdownButton<EntryScope>>(
              find.byType(DropdownButton<EntryScope>),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('entry-date')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.readOnly),
        isTrue,
      );
    } finally {
      repository.hold!.complete();
      await settleIo(tester, () => repository.entries.length == 1);
    }
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => !field.readOnly),
      isTrue,
    );
  });

  sequenceTest('após continuar o foco volta para o valor', (tester) async {
    await tester.enterText(find.byType(TextField).first, '10,00');
    await tester.enterText(find.byType(TextField).last, 'Observação');
    await tester.tap(find.text('Salvar e adicionar outro'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => repository.entries.length == 1);
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  sequenceTest(
    'salvar e adicionar outro persiste e mantém o formulário limpo',
    (tester) async {
      await tester.enterText(find.byType(TextField).first, '123,45');
      await tester.enterText(find.byType(TextField).last, 'Primeira venda');
      await tester.tap(find.text('Salvar e adicionar outro'));
      await tester.pumpAndSettle();
      await settleIo(tester, () => repository.entries.length == 1);

      expect(find.byType(EntryFormScreen), findsOneWidget);
      expect(repository.entries.single.amountCents, 12345);
      expect(repository.entries.single.note, 'Primeira venda');
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        isEmpty,
      );
      expect(
        find.text('Lançamento salvo. Você pode adicionar outro.'),
        findsOneWidget,
      );
      expect(find.text('Informe o valor do lançamento'), findsNothing);
    },
  );
}
