import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/onboarding/onboarding_flow.dart';
import 'package:notamei/theme/notamei_theme.dart';

Widget _host({
  required VoidCallback onFinish,
  required VoidCallback onAddFirstEntry,
  bool showWelcome = true,
  Key? key,
}) {
  return MaterialApp(
    theme: NotaMeiTheme.data,
    home: OnboardingFlow(
      key: key,
      onFinish: onFinish,
      onAddFirstEntry: onAddFirstEntry,
      showWelcome: showWelcome,
    ),
  );
}

void main() {
  testWidgets('começar sem tour abre início sem exibir passo educativo', (
    tester,
  ) async {
    var finished = 0;
    await tester.pumpWidget(
      _host(onFinish: () => finished++, onAddFirstEntry: () {}),
    );
    await tester.ensureVisible(find.text('Começar sem tour'));
    await tester.tap(find.text('Começar sem tour'));
    await tester.pumpAndSettle();
    expect(finished, 1);
    expect(find.text('Registre o que entra e sai'), findsNothing);
  });

  testWidgets('shows the welcome actions', (tester) async {
    await tester.pumpWidget(_host(onFinish: () {}, onAddFirstEntry: () {}));

    expect(find.text('Ver como funciona'), findsOneWidget);
    expect(find.text('Começar sem tour'), findsOneWidget);
    expect(find.textContaining('cópias do sistema'), findsOneWidget);
  });

  testWidgets('can skip welcome and finish the three-step tour', (
    tester,
  ) async {
    var finished = 0;
    await tester.pumpWidget(
      _host(onFinish: () => finished++, onAddFirstEntry: () {}),
    );

    await tester.ensureVisible(find.text('Ver como funciona'));
    await tester.tap(find.text('Ver como funciona'));
    await tester.pumpAndSettle();
    expect(find.text('Registre o que entra e sai'), findsOneWidget);
    expect(find.text('Pular tour'), findsNWidgets(2));

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Separe negócio e pessoal'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Acompanhe seus avisos'), findsOneWidget);

    await tester.ensureVisible(find.text('Começar a usar'));
    await tester.tap(find.text('Começar a usar'));
    await tester.pumpAndSettle();
    expect(find.text('Pronto para começar'), findsOneWidget);
    expect(finished, 0);

    await tester.tap(find.text('Ir para o Início'));
    expect(finished, 1);
  });

  testWidgets('showWelcome false opens the first tour step', (tester) async {
    await tester.pumpWidget(
      _host(onFinish: () {}, onAddFirstEntry: () {}, showWelcome: false),
    );

    expect(find.text('Registre o que entra e sai'), findsOneWidget);
    expect(find.text('Ver como funciona'), findsNothing);
  });

  testWidgets('offers first entry from the completion screen', (tester) async {
    var added = 0;
    await tester.pumpWidget(
      _host(onFinish: () {}, onAddFirstEntry: () => added++),
    );

    await tester.ensureVisible(find.text('Ver como funciona'));
    await tester.tap(find.text('Ver como funciona'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Começar a usar'));
    await tester.pumpAndSettle();

    expect(find.text('Pronto para começar'), findsOneWidget);
    await tester.tap(find.text('Adicionar primeiro lançamento'));
    expect(added, 1);
  });

  testWidgets('skipping any tour step goes to the home callback', (
    tester,
  ) async {
    for (var step = 0; step < 3; step++) {
      var finished = 0;
      await tester.pumpWidget(
        _host(
          onFinish: () => finished++,
          onAddFirstEntry: () {},
          showWelcome: step == 0,
          key: ValueKey(step),
        ),
      );

      if (step == 0) {
        await tester.ensureVisible(find.text('Ver como funciona'));
        await tester.tap(find.text('Ver como funciona'));
        await tester.pumpAndSettle();
      }
      for (var next = 0; next < step; next++) {
        final action = find.text(next == 2 ? 'Começar a usar' : 'Próximo');
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
      }

      await tester.ensureVisible(find.text('Pular tour').last);
      await tester.tap(find.text('Pular tour').last);
      await tester.pumpAndSettle();
      expect(finished, 1);
      expect(find.text('Pronto para começar'), findsNothing);
    }
  });

  testWidgets('back returns to the previous tour step', (tester) async {
    await tester.pumpWidget(
      _host(onFinish: () {}, onAddFirstEntry: () {}, showWelcome: false),
    );

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Separe negócio e pessoal'), findsOneWidget);
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Registre o que entra e sai'), findsOneWidget);
  });
}
