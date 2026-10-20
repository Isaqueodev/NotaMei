import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/settings/settings_screen.dart';
import 'package:notamei/theme/notamei_theme.dart';

void main() {
  testWidgets(
    'ajustes editoriais mantêm ações, estado e aviso de perda em 390px com texto 2x',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var tours = 0;
      var reminders = 0;
      for (final enabled in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(enabled),
            theme: NotaMeiTheme.data,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: SettingsScreen(
              dasEnabled: enabled,
              onOpenTour: () => tours++,
              onConfigureDas: () => reminders++,
            ),
          ),
        );
        expect(tester.widget<Card>(find.byType(Card).first).elevation, 0);
        expect(find.text(enabled ? 'Ativo' : 'Desativado'), findsOneWidget);
        await tester.ensureVisible(find.text('Configurar lembrete'));
        await tester.tap(find.text('Configurar lembrete'));
        await tester.scrollUntilVisible(find.text('Rever tour'), 200);
        await tester.tap(find.text('Rever tour'));
        final loss = find.textContaining('Limpar os dados ou desinstalar');
        await tester.scrollUntilVisible(loss, 250);
        expect(loss, findsOneWidget);
        expect(find.textContaining('Não há backup próprio'), findsOneWidget);
        final lossText = tester.widget<Text>(loss);
        expect(lossText.style?.color, isNot(NotaMeiTheme.expense));
        final brand = find.byType(Image);
        await tester.scrollUntilVisible(brand, 250);
        expect(
          (tester.widget<Image>(brand).image as AssetImage).assetName,
          'assets/brand/notamei.png',
        );
        for (final card in tester.widgetList<Card>(find.byType(Card))) {
          expect(card.elevation, 0);
          expect(card.color, Colors.white);
        }
        expect(find.textContaining('5.0'), findsNothing);
        expect(find.text('Modo escuro'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      expect(tours, 2);
      expect(reminders, 2);
    },
  );
}
