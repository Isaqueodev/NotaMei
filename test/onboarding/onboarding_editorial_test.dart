import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/onboarding/onboarding_flow.dart';
import 'package:notamei/theme/notamei_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await loader.load();
  });

  testWidgets(
    'folha do tour alinha descrição e valor em 390px sem reduzir texto',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: NotaMeiTheme.data,
          home: OnboardingFlow(
            showWelcome: false,
            onFinish: () {},
            onAddFirstEntry: () {},
          ),
        ),
      );
      final title = tester.getTopLeft(find.text('Venda de bolo no pote'));
      final amount = tester.getTopLeft(find.text('+ R\$ 180,00'));
      expect(amount.dy, title.dy);
      expect(amount.dx, greaterThan(title.dx));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'tour editorial usa marca exata e percorre 1/3 a conclusão em 390px com texto ampliado',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var finished = 0;
      var added = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: NotaMeiTheme.data,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: OnboardingFlow(
            onFinish: () => finished++,
            onAddFirstEntry: () => added++,
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      final brand = tester.widget<Image>(find.byType(Image).first);
      expect((brand.image as AssetImage).assetName, 'assets/brand/notamei.png');
      expect(find.text('N'), findsNothing);
      final heading = tester.widget<Text>(
        find.text('Seu negócio mais claro,\num registro de cada vez.'),
      );
      expect(heading.style?.fontFamily, 'Roboto');
      await tester.ensureVisible(find.text('Ver como funciona'));
      await tester.tap(find.text('Ver como funciona'));
      await tester.pumpAndSettle();
      for (var step = 1; step <= 3; step++) {
        expect(find.text('$step/3'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          step / 3,
        );
        expect(tester.takeException(), isNull);
        if (step == 1) {
          expect(find.text('+ R\$ 180,00'), findsOneWidget);
          expect(
            tester.widget<Text>(find.text('+ R\$ 180,00')).style?.color,
            NotaMeiTheme.income,
          );
          expect(
            tester.widget<Text>(find.text('− R\$ 52,00')).style?.color,
            NotaMeiTheme.expense,
          );
          final card = tester.widget<Card>(find.byType(Card).first);
          expect(card.color, Colors.white);
          expect(card.elevation, 0);
        }
        final next = find.text(step == 3 ? 'Começar a usar' : 'Próximo');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      expect(find.text('Pronto para começar'), findsOneWidget);
      expect(finished, 0);
      await tester.ensureVisible(find.text('Adicionar primeiro lançamento'));
      await tester.tap(find.text('Adicionar primeiro lançamento'));
      expect(added, 1);
      await tester.ensureVisible(find.text('Ir para o Início'));
      await tester.tap(find.text('Ir para o Início'));
      expect(finished, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
