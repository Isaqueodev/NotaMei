import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/data/entry_repository.dart';

import 'package:notamei/finance/dashboard_screen.dart';
import 'package:notamei/finance/entry_form_screen.dart';
import 'package:notamei/finance/entry_history_screen.dart';
import 'package:notamei/theme/notamei_theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class HeldRepository extends EntryRepository {
  HeldRepository()
    : super(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
  Completer<void>? hold;
  Completer<void>? deleteHold;
  @override
  Future<void> remove(String id) async {
    if (deleteHold != null) await deleteHold!.future;
    await super.remove(id);
  }

  bool failAfterSave = false;
  final attempts = <String>[];
  @override
  Future<void> saveWithdrawal({
    required String operationId,
    required int amountCents,
    required DateTime date,
    String? note,
  }) async {
    attempts.add(operationId);
    if (hold != null) await hold!.future;
    await super.saveWithdrawal(
      operationId: operationId,
      amountCents: amountCents,
      date: date,
      note: note,
    );
    if (failAfterSave) {
      failAfterSave = false;
      throw StateError('after write/read');
    }
  }
}

void main() {
  sqfliteFfiInit();
  late HeldRepository repo;
  setUp(() async {
    repo = HeldRepository();
    await repo.initialize();
  });
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => repo.close());
    repo.dispose();
  }

  Future<void> io(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pumpAndSettle();
  }

  Widget app(Widget home, {double scale = 1}) => MaterialApp(
    theme: NotaMeiTheme.data,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: home,
  );
  testWidgets(
    'formulário 390px texto 2x e teclado conserva valor, data e cancelamento',
    (tester) async {
      try {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(
          app(
            DashboardScreen(repository: repo, onAdd: () {}, onHistory: () {}),
            scale: 2,
          ),
        );
        await tester.scrollUntilVisible(find.text('Pagar-me'), 200);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pagar-me'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(TextFormField),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '1.234,56');
        await tester.ensureVisible(find.byKey(const Key('withdrawal-date')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('withdrawal-date')));
        await tester.pumpAndSettle();
        final calendar = tester.widget<CalendarDatePicker>(
          find.byType(CalendarDatePicker),
        );
        final chosen = DateTime(
          calendar.initialDate!.year,
          calendar.initialDate!.month,
          15,
        );
        await tester.tap(find.text('15').last);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(TextField).last);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, 'Manter data');
        await tester.scrollUntilVisible(
          find.text('Salvar retirada'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Salvar retirada'));
        await tester.pumpAndSettle();
        expect(find.text('Salvar retirada').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Salvar retirada'));
        await io(tester);
        expect(
          repo.entries.every(
            (e) =>
                e.date == chosen &&
                e.amountCents == 123456 &&
                e.note == 'Manter data',
          ),
          isTrue,
        );
        expect(repo.entries, hasLength(2));
        await tester.drag(find.byType(ListView).first, const Offset(0, 1600));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Pagar-me'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pagar-me'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Cancelar'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Cancelar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNothing);
        expect(repo.entries, hasLength(2));
        expect(tester.takeException(), isNull);
      } finally {
        await finish(tester);
      }
    },
  );
  testWidgets(
    'exclusão bloqueia retorno e controles, com estado próprio legível',
    (tester) async {
      try {
        await tester.runAsync(
          () => repo.saveWithdrawal(
            operationId: 'delete',
            amountCents: 10,
            date: DateTime.now(),
          ),
        );
        await tester.pumpWidget(
          app(
            EntryFormScreen(
              repository: repo,
              existing: repo.entries.first,
              onSaved: () {},
            ),
          ),
        );
        await tester.tap(find.byTooltip('Excluir retirada'));
        await tester.pumpAndSettle();
        repo.deleteHold = Completer<void>();
        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();
        expect(find.text('Excluindo…'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.byWidgetPredicate(
                  (w) => w is IconButton && w.tooltip == 'Voltar',
                ),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<IconButton>(
                find.byWidgetPredicate(
                  (w) => w is IconButton && w.tooltip == 'Excluir retirada',
                ),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester.widget<PopScope>(find.byType(PopScope).first).canPop,
          isFalse,
        );
        expect(
          tester
              .widgetList<TextField>(find.byType(TextField))
              .every((f) => f.readOnly),
          isTrue,
        );
        repo.deleteHold!.complete();
        await io(tester);
        expect(repo.entries, isEmpty);
      } finally {
        if (repo.deleteHold?.isCompleted == false) {
          repo.deleteHold!.complete();
          await io(tester);
        }
        await finish(tester);
      }
    },
  );
  testWidgets(
    'Pagar-me visível abre fluxo, valida, bloqueia controles e retry mantém operação',
    (tester) async {
      try {
        await tester.pumpWidget(
          app(
            DashboardScreen(repository: repo, onAdd: () {}, onHistory: () {}),
          ),
        );
        await tester.ensureVisible(find.text('Pagar-me'));
        await tester.tap(find.text('Pagar-me'));
        await tester.pumpAndSettle();
        expect(find.text('Negócio → Pessoal'), findsOneWidget);
        await tester.ensureVisible(find.text('Salvar retirada'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Salvar retirada'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar retirada'));
        await tester.pumpAndSettle();
        expect(
          find.text('Informe um valor positivo no formato 1.234,56'),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextField).first, '300,00');
        await tester.enterText(find.byType(TextField).last, 'Manual');
        repo.hold = Completer<void>();
        repo.failAfterSave = true;
        await tester.ensureVisible(find.text('Salvar retirada'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Salvar retirada'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar retirada'));
        await tester.pump();
        expect(
          tester
              .widgetList<TextField>(find.byType(TextField))
              .every((f) => f.readOnly),
          isTrue,
        );
        expect(
          tester.widget<PopScope>(find.byType(PopScope).first).canPop,
          isFalse,
        );
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('Salvando…'));
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(repo.attempts, hasLength(1));
        repo.hold!.complete();
        await io(tester);
        expect(
          find.text(
            'Não foi possível salvar. Seus dados foram mantidos; tente novamente.',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          '300,00',
        );
        await tester.ensureVisible(find.text('Salvar retirada'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Salvar retirada'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar retirada'));
        await io(tester);
        expect(repo.entries, hasLength(2));
        expect(repo.attempts.toSet(), hasLength(1));
        expect(
          find.text('Retirada salva: saída do Negócio e entrada no Pessoal.'),
          findsOneWidget,
        );
      } finally {
        await finish(tester);
      }
    },
  );
  testWidgets(
    'ponta vinculada abre formulário próprio e confirma edição/exclusão conjunta',
    (tester) async {
      try {
        await tester.runAsync(
          () => repo.saveWithdrawal(
            operationId: 'edit',
            amountCents: 30000,
            date: DateTime.now(),
          ),
        );
        final ids = repo.entries.map((e) => e.id).toSet();
        final leg = repo.entries.first;
        await tester.pumpWidget(
          app(EntryFormScreen(repository: repo, existing: leg, onSaved: () {})),
        );
        expect(find.text('Editar retirada'), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNothing);
        await tester.enterText(find.byType(TextField).first, '400,00');
        await tester.ensureVisible(find.text('Salvar alterações'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Salvar alterações'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar alterações'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'A alteração afeta as DUAS pontas: saída do Negócio e entrada no Pessoal.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Confirmar'));
        await io(tester);
        expect(repo.entries.every((e) => e.amountCents == 40000), isTrue);
        expect(repo.entries.map((e) => e.id).toSet(), ids);
        await tester.tap(find.byTooltip('Excluir retirada'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Excluir as DUAS pontas desta retirada? Esta ação não poderá ser desfeita.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancelar').last);
        await tester.pumpAndSettle();
        expect(repo.entries, hasLength(2));
        await tester.tap(find.byTooltip('Excluir retirada'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir'));
        await io(tester);
        expect(repo.entries, isEmpty);
      } finally {
        await finish(tester);
      }
    },
  );
  testWidgets(
    'painel e histórico identificam internas, filtros independentes e texto 2x',
    (tester) async {
      var editCalls = 0;
      String? editedEntryId;
      try {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(
          () => repo.saveWithdrawal(
            operationId: 'history',
            amountCents: 30000,
            date: DateTime.now(),
          ),
        );
        await tester.pumpWidget(
          app(
            DashboardScreen(repository: repo, onAdd: () {}, onHistory: () {}),
            scale: 2,
          ),
        );
        expect(find.text('Retiradas para você'), findsOneWidget);
        await tester.ensureVisible(find.text('Pessoal'));
        await tester.tap(find.text('Pessoal'));
        await tester.pumpAndSettle();
        expect(find.text('Recebido do negócio'), findsOneWidget);
        await tester.pumpWidget(
          app(
            EntryHistoryScreen(
              repository: repo,
              onEdit: (e) {
                expect(e.isWithdrawal, isTrue);
                editCalls++;
                editedEntryId = e.id;
              },
            ),
            scale: 2,
          ),
        );
        await tester.tap(find.text('Saídas'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Negócio'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Todos'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'Saídas'))
              .selected,
          isTrue,
        );
        expect(find.text('Retirada do titular'), findsOneWidget);
        await tester.ensureVisible(find.text('Retirada do titular'));
        await tester.pumpAndSettle();
        expect(find.text('Retirada do titular').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Retirada do titular'));
        expect(editCalls, 1);
        expect(editedEntryId, 'withdrawal:history:business');
        expect(find.textContaining('Negócio → Pessoal'), findsWidgets);
        expect(find.text('- R\$ 300,00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await finish(tester);
      }
    },
  );
}
