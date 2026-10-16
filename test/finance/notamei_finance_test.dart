import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/finance/dashboard_screen.dart';
import 'package:notamei/finance/entry_form_screen.dart';
import 'package:notamei/finance/entry_history_screen.dart';

EntryRecord entry(
  String id, {
  EntryType type = EntryType.income,
  EntryScope scope = EntryScope.business,
  int amount = 10000,
  DateTime? date,
  String category = 'Vendas',
  String? note,
}) => EntryRecord(
  id: id,
  type: type,
  scope: scope,
  amountCents: amount,
  category: category,
  date: date ?? DateTime.now(),
  note: note,
);

/// Wires the finance flow exactly like the app must: dashboard -> form,
/// dashboard -> history -> edit form, with pops returning to the caller.
class FlowApp extends StatelessWidget {
  const FlowApp({super.key, required this.repository});

  final EntryRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          void openForm({EntryRecord? existing}) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EntryFormScreen(
                  repository: repository,
                  existing: existing,
                  onSaved: () => Navigator.of(context).pop(),
                  onDeleted: () => Navigator.of(context).pop(),
                ),
              ),
            );
          }

          return DashboardScreen(
            repository: repository,
            onAdd: openForm,
            onHistory: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EntryHistoryScreen(
                  repository: repository,
                  onEdit: (entry) => openForm(existing: entry),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DelayedEntryRepository extends EntryRepository {
  DelayedEntryRepository({required String path})
    : super(databaseFactory: databaseFactoryFfiNoIsolate, path: path);

  final release = Completer<void>();
  int attempts = 0;
  bool failNext = false;

  @override
  Future<void> upsert(EntryRecord record) async {
    attempts++;
    await release.future;
    if (failNext) {
      failNext = false;
      throw StateError('simulated persistence failure');
    }
    await super.upsert(record);
  }
}

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late EntryRepository repository;
  var closedInWidgetTest = false;

  setUp(() async {
    // Unique temp directory per test: real SQLite, no plugin, no shared path.
    directory = await Directory.systemTemp.createTemp('notamei-finance-');
    repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: '${directory.path}/entries.db',
    );
    await repository.initialize();
    closedInWidgetTest = false;
  });

  tearDown(() async {
    if (!closedInWidgetTest) {
      await repository.close();
      repository.dispose();
    }
    await directory.delete(recursive: true);
  });

  void financeWidgetTest(String description, WidgetTesterCallback body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => repository.close());
        repository.dispose();
        closedInWidgetTest = true;
      }
    });
  }

  Future<void> tapAndWaitForChange(WidgetTester tester, Finder target) async {
    final changed = Completer<void>();
    void listener() {
      if (!changed.isCompleted) changed.complete();
    }

    repository.addListener(listener);
    try {
      await tester.tap(target);
      // Inicia os microtasks do formulário na zona FakeAsync antes do I/O real.
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 100 && !changed.isCompleted; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
      }
      if (!changed.isCompleted) {
        throw StateError('Lançamento não foi persistido');
      }
    } finally {
      repository.removeListener(listener);
    }
  }

  Future<void> pumpFlow(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(FlowApp(repository: repository));
  }

  financeWidgetTest('dois toques durante salvamento criam um só lançamento', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repository.close();
      repository.dispose();
      repository = DelayedEntryRepository(path: '${directory.path}/entries.db');
      await repository.initialize();
    });
    final delayed = repository as DelayedEntryRepository;
    await pumpFlow(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Novo Lançamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '100,00');
    final save = find.widgetWithText(ElevatedButton, 'Adicionar Lançamento');
    await tester.tap(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    try {
      expect(delayed.attempts, 1);
    } finally {
      delayed.release.complete();
    }
    for (var i = 0; i < 50 && repository.entries.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
    expect(repository.entries, hasLength(1));
  });

  financeWidgetTest(
    'erro de persistência informa falha e permite tentar novamente',
    (tester) async {
      await tester.runAsync(() async {
        await repository.close();
        repository.dispose();
        repository = DelayedEntryRepository(
          path: '${directory.path}/entries.db',
        );
        await repository.initialize();
      });
      final delayed = repository as DelayedEntryRepository;
      delayed.release.complete();
      delayed.failNext = true;
      await pumpFlow(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Novo Lançamento'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '100,00');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Adicionar Lançamento'),
      );
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 50 && find.byKey(const Key('save-error')).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('save-error')), findsOneWidget);
      expect(repository.entries, isEmpty);
      await tapAndWaitForChange(
        tester,
        find.widgetWithText(ElevatedButton, 'Adicionar Lançamento'),
      );
      expect(repository.entries, hasLength(1));
    },
  );

  group('TDD: parsing pt-BR estrito de dinheiro no formulário', () {
    financeWidgetTest(
      '"1.234,56" é salvo exatamente como 123456 centavos e aparece no dashboard',
      (tester) async {
        await pumpFlow(tester);

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Novo Lançamento'),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '1.234,56');
        await tapAndWaitForChange(
          tester,
          find.widgetWithText(ElevatedButton, 'Adicionar Lançamento'),
        );

        expect(repository.entries, hasLength(1));
        expect(repository.entries.single.amountCents, 123456);
        // De volta ao dashboard, o valor formatado usa exatamente 123456 centavos.
        expect(find.text('R\$ 1.234,56'), findsWidgets);
        expect(find.text('Lançamentos Recentes'), findsOneWidget);
      },
    );

    financeWidgetTest(
      '"1,234.56" (formato estrangeiro) não salva e mostra erro',
      (tester) async {
        await pumpFlow(tester);

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Novo Lançamento'),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '1,234.56');
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Adicionar Lançamento'),
        );
        await tester.pumpAndSettle();

        expect(repository.entries, isEmpty);
        expect(
          find.text('Informe um valor positivo no formato 1.234,56'),
          findsOneWidget,
        );
        // Continua no formulário, sem salvar.
        expect(find.text('Adicionar Lançamento'), findsOneWidget);
      },
    );

    financeWidgetTest('valores não positivos e malformados não salvam', (
      tester,
    ) async {
      await pumpFlow(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Novo Lançamento'));
      await tester.pumpAndSettle();
      for (final value in [
        '0',
        '0,00',
        '-5',
        '1.23',
        'R\$ 10,00',
        'NaN',
        'Infinity',
        '1,234',
        '92233720368547758,08',
      ]) {
        await tester.enterText(find.byType(TextField).first, value);
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Adicionar Lançamento'),
        );
        await tester.pump();
        expect(
          find.text('Informe um valor positivo no formato 1.234,56'),
          findsOneWidget,
          reason: value,
        );
      }
      expect(repository.entries, isEmpty);
    });
  });

  financeWidgetTest(
    'salva centavos exatos acima da precisão de double e reabre SQLite',
    (tester) async {
      await pumpFlow(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Novo Lançamento'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        '90.071.992.547.409,93',
      );
      await tapAndWaitForChange(
        tester,
        find.widgetWithText(ElevatedButton, 'Adicionar Lançamento'),
      );
      expect(repository.entries.single.amountCents, 9007199254740993);
      await tester.tap(find.widgetWithText(TextButton, 'Ver todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vendas'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '90.071.992.547.409,93',
      );
      await tapAndWaitForChange(
        tester,
        find.widgetWithText(ElevatedButton, 'Salvar Alterações'),
      );
      expect(repository.entries.single.amountCents, 9007199254740993);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await repository.close();
        await repository.initialize();
      });
      expect(repository.entries.single.amountCents, 9007199254740993);
    },
  );

  financeWidgetTest('salva entrada pessoal sem alterar resumo do negócio', (
    tester,
  ) async {
    await pumpFlow(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Novo Lançamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<EntryScope>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pessoal').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1.234,56');
    await tapAndWaitForChange(
      tester,
      find.widgetWithText(ElevatedButton, 'Adicionar Lançamento'),
    );
    expect(repository.entries.single.scope, EntryScope.personal);
    expect(repository.entries.single.amountCents, 123456);
    expect(repository.summaryFor(DateTime.now()).incomeCents, 0);
    expect(find.text('R\$ 0,00'), findsNWidgets(3));
    expect(find.text('+ R\$ 1.234,56'), findsOneWidget);
  });

  group('TDD: lançamento pessoal não altera o total do negócio', () {
    test('resumo do mês ignora pessoais no repositório SQLite', () async {
      final now = DateTime.now();
      await repository.upsert(entry('1', amount: 10000, category: 'Vendas'));
      await repository.upsert(
        entry('2', type: EntryType.expense, amount: 3000, category: 'Aluguel'),
      );
      await repository.upsert(
        entry(
          '3',
          scope: EntryScope.personal,
          amount: 50000,
          category: 'Salário',
        ),
      );

      final summary = repository.summaryFor(now);
      expect(summary.incomeCents, 10000);
      expect(summary.expenseCents, 3000);
      expect(summary.balanceCents, 7000);
    });

    financeWidgetTest(
      'dashboard totaliza só o negócio mesmo listando o pessoal',
      (tester) async {
        await tester.runAsync(() async {
          await repository.upsert(
            entry('1', amount: 10000, category: 'Vendas'),
          );
          await repository.upsert(
            entry(
              '2',
              type: EntryType.expense,
              amount: 3000,
              category: 'Aluguel',
            ),
          );
          await repository.upsert(
            entry(
              '3',
              scope: EntryScope.personal,
              amount: 50000,
              category: 'Salário',
            ),
          );
        });

        await pumpFlow(tester);

        expect(find.text('R\$ 70,00'), findsOneWidget); // balanço do negócio
        expect(find.text('Pessoal'), findsOneWidget); // selo no cartão pessoal
        expect(find.text('Salário'), findsOneWidget);
      },
    );
  });

  group('fluxo cadastrar / ver no dashboard', () {
    financeWidgetTest(
      'dashboard vazio mostra estado e navega para o formulário',
      (tester) async {
        await pumpFlow(tester);

        expect(find.text('Nenhum lançamento neste mês'), findsOneWidget);
        expect(find.text('Novo Lançamento'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Novo Lançamento'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Novo Lançamento'), findsOneWidget); // título do form
        expect(find.text('Adicionar Lançamento'), findsOneWidget);

        // Volta pelo botão do AppBar e o estado vazio permanece.
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Nenhum lançamento neste mês'), findsOneWidget);
      },
    );

    financeWidgetTest(
      'cadastra receita e vê no dashboard com resumo e recentes',
      (tester) async {
        await pumpFlow(tester);

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Novo Lançamento'),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '250,00');
        await tapAndWaitForChange(
          tester,
          find.widgetWithText(ElevatedButton, 'Adicionar Lançamento'),
        );

        expect(repository.entries.single.amountCents, 25000);
        expect(repository.entries.single.category, 'Vendas');
        expect(find.text('R\$ 250,00'), findsWidgets);
        expect(find.text('Vendas'), findsOneWidget);
        expect(find.text('Lançamentos Recentes'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Ver todos'), findsOneWidget);
      },
    );
  });

  group('fluxo editar / excluir com confirmação', () {
    financeWidgetTest('editar lançamento atualiza repositório e dashboard', (
      tester,
    ) async {
      await tester.runAsync(
        () => repository.upsert(entry('e1', amount: 10000, category: 'Vendas')),
      );

      await pumpFlow(tester);
      expect(find.text('R\$ 100,00'), findsWidgets);

      await tester.tap(find.widgetWithText(TextButton, 'Ver todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vendas'));
      await tester.pumpAndSettle();
      expect(find.text('Editar Lançamento'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '100,00',
      );

      await tester.enterText(find.byType(TextField).first, '99,90');
      await tapAndWaitForChange(
        tester,
        find.widgetWithText(ElevatedButton, 'Salvar Alterações'),
      );

      expect(repository.entries.single.id, 'e1');
      expect(repository.entries.single.amountCents, 9990);
      expect(find.text('+ R\$ 99,90'), findsOneWidget); // histórico atualizado

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('R\$ 99,90'), findsWidgets); // dashboard atualizado
    });

    financeWidgetTest(
      'excluir pede confirmação: cancelar mantém, confirmar remove',
      (tester) async {
        await tester.runAsync(
          () =>
              repository.upsert(entry('e1', amount: 10000, category: 'Vendas')),
        );

        await pumpFlow(tester);
        await tester.tap(find.widgetWithText(TextButton, 'Ver todos'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vendas'));
        await tester.pumpAndSettle();

        // Cancelar preserva o lançamento.
        await tester.tap(find.byTooltip('Excluir Lançamento'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Tem certeza de que deseja excluir este lançamento? Esta ação não poderá ser desfeita.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
        await tester.pumpAndSettle();
        expect(find.text('Excluir Lançamento'), findsNothing);
        expect(find.text('Editar Lançamento'), findsOneWidget);
        expect(repository.entries, hasLength(1));

        // Confirmar remove e retorna ao histórico.
        await tester.tap(find.byTooltip('Excluir Lançamento'));
        await tester.pumpAndSettle();
        await tapAndWaitForChange(
          tester,
          find.widgetWithText(ElevatedButton, 'Excluir'),
        );

        expect(repository.entries, isEmpty);
        expect(find.text('Nenhum lançamento encontrado'), findsOneWidget);
        expect(find.text('Editar Lançamento'), findsNothing);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Nenhum lançamento neste mês'), findsOneWidget);
      },
    );
  });

  group('fluxo filtros e retorno', () {
    financeWidgetTest('filtros por escopo/tipo e retorno ao dashboard', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await repository.upsert(entry('1', amount: 20000, category: 'Vendas'));
        await repository.upsert(
          entry(
            '2',
            type: EntryType.expense,
            scope: EntryScope.personal,
            amount: 5000,
            category: 'Alimentação',
          ),
        );
      });

      await pumpFlow(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Ver todos'));
      await tester.pumpAndSettle();

      expect(find.text('Vendas'), findsOneWidget);
      expect(find.text('Alimentação'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Pessoal'));
      await tester.pump();
      expect(find.text('Alimentação'), findsOneWidget);
      expect(find.text('Vendas'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Entradas'));
      await tester.pump();
      expect(find.text('Alimentação'), findsNothing);
      expect(find.text('Nenhum lançamento encontrado'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Todos'));
      await tester.pump();
      expect(find.text('Vendas'), findsOneWidget);
      expect(find.text('Alimentação'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Lançamentos Recentes'), findsOneWidget);
      expect(find.text('R\$ 200,00'), findsWidgets);
    });
  });
}
