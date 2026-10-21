import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../annual/annual_income_screen.dart';
import '../das/das_reminder_service.dart';
import '../das/das_settings_screen.dart';
import '../data/entry_record.dart';
import '../data/entry_repository.dart';
import '../export/export_screen.dart';
import '../finance/dashboard_screen.dart';
import '../finance/entry_form_screen.dart';
import '../finance/entry_history_screen.dart';
import '../onboarding/onboarding_flow.dart';
import '../settings/settings_screen.dart';
import '../theme/notamei_theme.dart';

class NotaMeiApp extends StatefulWidget {
  const NotaMeiApp({
    super.key,
    required this.repository,
    required this.preferences,
    required this.dasService,
    this.reminderWarning,
  });

  final EntryRepository repository;
  final SharedPreferences preferences;
  final DasReminderService dasService;
  final String? reminderWarning;

  @override
  State<NotaMeiApp> createState() => _NotaMeiAppState();
}

class _NotaMeiAppState extends State<NotaMeiApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late bool _completed =
      widget.preferences.getBool('onboarding_completed') ?? false;
  int _tab = 0;

  Future<void> _finishFirstTour({bool openEntry = false}) async {
    await widget.preferences.setBool('onboarding_completed', true);
    if (!mounted) return;
    setState(() => _completed = true);
    if (openEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openEntry();
      });
    }
  }

  void _openEntry({EntryRecord? existing}) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => EntryFormScreen(
          repository: widget.repository,
          existing: existing,
          onSaved: () => _navigatorKey.currentState?.pop(),
          onDeleted: () => _navigatorKey.currentState?.pop(),
        ),
      ),
    );
  }

  void _reviewTour() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingFlow(
          showWelcome: false,
          onFinish: () => _navigatorKey.currentState?.pop(),
          onAddFirstEntry: () {
            _navigatorKey.currentState?.pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openEntry();
            });
          },
        ),
      ),
    );
  }

  void _openExport() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => ExportScreen(repository: widget.repository),
      ),
    );
  }

  void _openDas() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => DasSettingsScreen(
          service: widget.dasService,
          onChanged: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NotaMei',
    debugShowCheckedModeBanner: false,
    navigatorKey: _navigatorKey,
    theme: NotaMeiTheme.data,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: _completed
        ? _shell()
        : OnboardingFlow(
            onFinish: _finishFirstTour,
            onAddFirstEntry: () => _finishFirstTour(openEntry: true),
          ),
  );

  Widget _shell() => Scaffold(
    body: IndexedStack(
      index: _tab,
      children: [
        DashboardScreen(
          repository: widget.repository,
          onAdd: _openEntry,
          onHistory: () => setState(() => _tab = 1),
        ),
        EntryHistoryScreen(
          repository: widget.repository,
          onEdit: (entry) => _openEntry(existing: entry),
        ),
        AnimatedBuilder(
          animation: widget.repository,
          builder: (_, _) => AnnualIncomeScreen(
            entries: widget.repository.entries,
            year: DateTime.now().year,
          ),
        ),
        SettingsScreen(
          onOpenTour: _reviewTour,
          onExportCsv: _openExport,
          onConfigureDas: _openDas,
          dasEnabled: widget.dasService.enabled,
          reminderWarning: widget.reminderWarning,
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (value) => setState(() => _tab = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Histórico',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Ano',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Ajustes',
        ),
      ],
    ),
  );
}
