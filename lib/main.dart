import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/notamei_app.dart';
import 'das/das_reminder_service.dart';
import 'das/local_das_gateway.dart';
import 'data/entry_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final repository = EntryRepository();
  await repository.initialize();
  final dasService = DasReminderService(
    preferences: preferences,
    gateway: LocalDasNotificationsGateway(platform: AndroidDasPlatform()),
  );
  String? reminderWarning;
  try {
    await dasService.refresh();
  } catch (_) {
    // A indisponibilidade das notificações não deve impedir acesso aos dados.
    reminderWarning = 'Não foi possível atualizar o lembrete neste aparelho.';
  }
  runApp(
    NotaMeiApp(
      repository: repository,
      preferences: preferences,
      dasService: dasService,
      reminderWarning: reminderWarning,
    ),
  );
}
