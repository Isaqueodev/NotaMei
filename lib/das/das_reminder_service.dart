import 'package:shared_preferences/shared_preferences.dart';

import 'das_schedule.dart';

class DasReminderSettings {
  const DasReminderSettings({
    required this.day,
    required this.hour,
    required this.minute,
  });

  final int day;
  final int hour;
  final int minute;

  void validate() {
    nextDasReminder(now: DateTime.now(), day: day, hour: hour, minute: minute);
  }
}

abstract class DasNotificationGateway {
  Future<bool> requestPermission();
  Future<void> schedule(DasReminderSettings settings);
  Future<void> cancel();
}

/// Configuração pessoal, não data de vencimento ou confirmação do DAS.
class DasReminderService {
  DasReminderService({required this.preferences, required this.gateway});

  final SharedPreferences preferences;
  final DasNotificationGateway gateway;

  bool get enabled => preferences.getBool('das_enabled') ?? false;

  DasReminderSettings? get settings {
    final day = preferences.getInt('das_day');
    final hour = preferences.getInt('das_hour');
    final minute = preferences.getInt('das_minute');
    if (day == null || hour == null || minute == null) return null;
    return DasReminderSettings(day: day, hour: hour, minute: minute);
  }

  /// Permissão solicitada apenas após o toque de ativação. Não habilita se negada.
  Future<bool> enable(DasReminderSettings selected) async {
    selected.validate();
    if (!await gateway.requestPermission()) {
      if (enabled) {
        try {
          await gateway.cancel();
        } finally {
          await preferences.setBool('das_enabled', false);
        }
      }
      return false;
    }
    try {
      await gateway.schedule(selected);
      await preferences.setInt('das_day', selected.day);
      await preferences.setInt('das_hour', selected.hour);
      await preferences.setInt('das_minute', selected.minute);
      await preferences.setBool('das_enabled', true);
    } catch (_) {
      try {
        await gateway.cancel();
      } finally {
        await preferences.setBool('das_enabled', false);
      }
      rethrow;
    }
    return true;
  }

  Future<void> disable() async {
    await gateway.cancel();
    await preferences.setBool('das_enabled', false);
  }

  Future<void> refresh() async {
    if (enabled && settings != null) await gateway.schedule(settings!);
  }
}
