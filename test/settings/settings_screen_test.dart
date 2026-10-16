import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/settings/settings_screen.dart';
import 'package:notamei/theme/notamei_theme.dart';

Widget _host({
  required VoidCallback onOpenTour,
  required VoidCallback onConfigureDas,
  required bool dasEnabled,
  String? reminderWarning,
}) {
  return MaterialApp(
    theme: NotaMeiTheme.data,
    home: SettingsScreen(
      onOpenTour: onOpenTour,
      onConfigureDas: onConfigureDas,
      dasEnabled: dasEnabled,
      reminderWarning: reminderWarning,
    ),
  );
}

void main() {
  testWidgets('avisa se o lembrete configurado não pôde ser atualizado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        onOpenTour: () {},
        onConfigureDas: () {},
        dasEnabled: true,
        reminderWarning:
            'Não foi possível atualizar o lembrete neste aparelho.',
      ),
    );
    expect(
      find.textContaining('Não foi possível atualizar o lembrete'),
      findsOneWidget,
    );
  });

  testWidgets('shows local data and payment disclaimer', (tester) async {
    await tester.pumpWidget(
      _host(onOpenTour: () {}, onConfigureDas: () {}, dasEnabled: false),
    );

    await tester.ensureVisible(find.text('Ações e segurança'));
    expect(find.text('Ações e segurança'), findsOneWidget);
    expect(
      find.textContaining('cópias do sistema dependem das suas configurações'),
      findsOneWidget,
    );
    expect(find.textContaining('não confirma pagamento'), findsOneWidget);
    expect(find.text('Rever tour'), findsOneWidget);
    expect(find.textContaining('DAS'), findsWidgets);
  });

  testWidgets('reflects disabled and enabled DAS state', (tester) async {
    await tester.pumpWidget(
      _host(onOpenTour: () {}, onConfigureDas: () {}, dasEnabled: false),
    );
    expect(find.text('Desativado'), findsOneWidget);

    await tester.pumpWidget(
      _host(onOpenTour: () {}, onConfigureDas: () {}, dasEnabled: true),
    );
    expect(find.text('Ativo'), findsOneWidget);
  });

  testWidgets('opens tour and DAS configuration', (tester) async {
    var tourOpened = 0;
    var dasConfigured = 0;
    await tester.pumpWidget(
      _host(
        onOpenTour: () => tourOpened++,
        onConfigureDas: () => dasConfigured++,
        dasEnabled: false,
      ),
    );

    await tester.ensureVisible(find.text('Rever tour'));
    await tester.tap(find.text('Rever tour'));
    await tester.ensureVisible(find.text('Configurar lembrete'));
    await tester.tap(find.text('Configurar lembrete'));
    expect(tourOpened, 1);
    expect(dasConfigured, 1);
  });
}
