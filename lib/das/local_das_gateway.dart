import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'das_reminder_service.dart';
import 'das_schedule.dart';

abstract class DasPlatform {
  Future<bool> requestPermission();
  Future<void> schedule(int id, DateTime when);
  Future<void> cancel(int id);
}

/// Reagenda uma janela móvel de 12 meses ao abrir o aplicativo.
class LocalDasNotificationsGateway implements DasNotificationGateway {
  LocalDasNotificationsGateway({
    required this.platform,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final DasPlatform platform;
  final DateTime Function() clock;
  static const int firstId = 1000;
  static const int count = 12;

  @override
  Future<bool> requestPermission() => platform.requestPermission();

  @override
  Future<void> schedule(DasReminderSettings settings) async {
    final dates = upcomingDasReminders(
      now: clock(), day: settings.day, hour: settings.hour,
      minute: settings.minute, count: count,
    );
    for (var index = 0; index < dates.length; index++) {
      await platform.schedule(firstId + index, dates[index]);
    }
  }

  @override
  Future<void> cancel() async {
    for (var index = 0; index < count; index++) {
      await platform.cancel(firstId + index);
    }
  }
}

/// Ponte Android. Os avisos são aproximados e não substituem calendário oficial.
class AndroidDasPlatform implements DasPlatform {
  AndroidDasPlatform() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  Future<void> _ready() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    await _ready();
    return await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  @override
  Future<void> schedule(int id, DateTime when) async {
    await _ready();
    await _plugin.zonedSchedule(
      id: id,
      title: 'Lembrete pessoal do DAS',
      body: 'Confira a data e a situação do seu DAS nos canais oficiais.',
      scheduledDate: tz.TZDateTime(
        tz.local, when.year, when.month, when.day, when.hour, when.minute,
      ),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'das_pessoal', 'Lembrete pessoal do DAS',
          channelDescription: 'Aviso configurado por você; não confirma vencimento nem pagamento.',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _ready();
    await _plugin.cancel(id: id);
  }
}
