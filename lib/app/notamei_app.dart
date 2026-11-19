import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../annual/annual_income_screen.dart';
import '../backup/backup_creation_screen.dart';
import '../backup/backup_import_screen.dart';
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
  late ThemeMode _themeMode = _loadThemeMode();

  ThemeMode _loadThemeMode() {
    final value = widget.preferences.getString('theme_mode');
    switch (value) {
    case 'dark':
      return ThemeMode.dark;
    case 'light':
    case 'system':
    default:
      return ThemeMode.light; // padrão claro
  }
}

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    String value;
    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await widget.preferences.setString('theme_mode', value);
  }


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

  void _openExport({ExportFormat format = ExportFormat.csv}) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ExportScreen(repository: widget.repository, format: format),
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

  void _openBackupImport() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => BackupImportScreen(repository: widget.repository)),
    );
  }

  void _openBackup() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => BackupCreationScreen(repository: widget.repository),
      ),
    );
  }

   @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NotaMei',
    debugShowCheckedModeBanner: false,
    navigatorKey: _navigatorKey,
    theme: NotaMeiTheme.light(),
    darkTheme: NotaMeiTheme.dark(),
    themeMode: _themeMode,
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
          onExportPdf: () => _openExport(format: ExportFormat.pdf),
          onCreateBackup: _openBackup,
          onImportBackup: _openBackupImport,
          onConfigureDas: _openDas,
          dasEnabled: widget.dasService.enabled,
          reminderWarning: widget.reminderWarning,
          themeMode: _themeMode,
          onThemeModeChanged: _setThemeMode,
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
