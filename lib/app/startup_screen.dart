import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../das/das_reminder_service.dart';
import '../das/local_das_gateway.dart';
import '../data/entry_repository.dart';
import '../theme/notamei_theme.dart';
import 'notamei_app.dart';

enum _StartupStage { loading, error, ready }

class StartupScreen extends StatefulWidget {
  const StartupScreen({
    super.key,
    required this.repository,
    this.preferencesLoader,
    this.gatewayFactory,
  });

  final EntryRepository repository;
  final Future<SharedPreferences> Function()? preferencesLoader;
  final DasNotificationGateway Function()? gatewayFactory;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  _StartupStage _stage = _StartupStage.loading;
  SharedPreferences? _preferences;
  DasReminderService? _dasService;
  String? _reminderWarning;

  @override
  void initState() {
    super.initState();
    _initialize(showLoading: false);
  }

  Future<void> _initialize({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _stage = _StartupStage.loading);
    }
    try {
      await widget.repository.initialize();
      final preferences = await (widget.preferencesLoader ??
          SharedPreferences.getInstance)();
      final dasService = DasReminderService(
        preferences: preferences,
        gateway: (widget.gatewayFactory ?? _defaultGateway)(),
      );
      String? warning;
      try {
        await dasService.refresh();
      } catch (_) {
        warning = 'Não foi possível atualizar o lembrete neste aparelho.';
      }
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _dasService = dasService;
        _reminderWarning = warning;
        _stage = _StartupStage.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _stage = _StartupStage.error);
    }
  }

  DasNotificationGateway _defaultGateway() =>
      LocalDasNotificationsGateway(platform: AndroidDasPlatform());

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _StartupStage.loading:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: NotaMeiTheme.light(),
          darkTheme: NotaMeiTheme.dark(),
          themeMode: ThemeMode.system,
          home: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(key: Key('startup-loading')),
            ),
          ),
        );
      case _StartupStage.error:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: NotaMeiTheme.light(),
          darkTheme: NotaMeiTheme.dark(),
          themeMode: ThemeMode.system,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Não foi possível abrir o NotaMei',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Seus registros continuam no aparelho. '
                        'Tente abrir novamente.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('startup-retry'),
                        onPressed: () => _initialize(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case _StartupStage.ready:
        return NotaMeiApp(
          repository: widget.repository,
          preferences: _preferences!,
          dasService: _dasService!,
          reminderWarning: _reminderWarning,
        );
    }
  }
}