import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notamei/das/das_reminder_service.dart';

class FakeGateway implements DasNotificationGateway {
  bool permission = true;
  bool failAfterScheduling = false;
  int scheduled = 0;
  int cancelled = 0;
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<void> schedule(DasReminderSettings settings) async {
    scheduled++;
    if (failAfterScheduling) throw StateError('partial schedule');
  }

  @override
  Future<void> cancel() async {
    cancelled++;
  }
}

void main() {
  late SharedPreferences prefs;
  late FakeGateway gateway;
  late DasReminderService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    gateway = FakeGateway();
    service = DasReminderService(preferences: prefs, gateway: gateway);
  });

  test('permissão negada não ativa nem agenda aviso', () async {
    gateway.permission = false;
    expect(
      await service.enable(
        const DasReminderSettings(day: 31, hour: 9, minute: 0),
      ),
      isFalse,
    );
    expect(service.enabled, isFalse);
    expect(gateway.scheduled, 0);
    expect(prefs.getBool('das_enabled'), isNot(true));
  });

  test(
    'configuração pessoal salva e é restaurada sem agendar duas vezes',
    () async {
      expect(
        await service.enable(
          const DasReminderSettings(day: 31, hour: 9, minute: 30),
        ),
        isTrue,
      );
      expect(gateway.scheduled, 1);
      final reloaded = DasReminderService(
        preferences: prefs,
        gateway: FakeGateway(),
      );
      expect(reloaded.enabled, isTrue);
      expect(reloaded.settings?.day, 31);
      expect(reloaded.settings?.minute, 30);
    },
  );

  test('desativar cancela avisos e preserva configuração', () async {
    await service.enable(
      const DasReminderSettings(day: 12, hour: 8, minute: 0),
    );
    await service.disable();
    expect(gateway.cancelled, 1);
    expect(service.enabled, isFalse);
    expect(service.settings?.day, 12);
  });

  test(
    'falha parcial de agendamento cancela avisos antes de reportar erro',
    () async {
      gateway.failAfterScheduling = true;
      await expectLater(
        service.enable(const DasReminderSettings(day: 15, hour: 9, minute: 0)),
        throwsStateError,
      );
      expect(gateway.scheduled, 1);
      expect(gateway.cancelled, 1);
      expect(service.enabled, isFalse);
    },
  );

  test(
    'falha ao alterar lembrete já ativo não mantém estado ativado',
    () async {
      await service.enable(
        const DasReminderSettings(day: 15, hour: 9, minute: 0),
      );
      expect(service.enabled, isTrue);
      gateway.failAfterScheduling = true;
      await expectLater(
        service.enable(const DasReminderSettings(day: 16, hour: 10, minute: 0)),
        throwsStateError,
      );
      expect(gateway.cancelled, 1);
      expect(service.enabled, isFalse);
      expect(service.settings?.day, 15);
    },
  );
  test('permissão revogada desativa lembrete antes ativo', () async {
    await service.enable(
      const DasReminderSettings(day: 15, hour: 9, minute: 0),
    );
    gateway.permission = false;
    expect(
      await service.enable(
        const DasReminderSettings(day: 16, hour: 10, minute: 0),
      ),
      isFalse,
    );
    expect(service.enabled, isFalse);
    expect(gateway.cancelled, 1);
  });
}
