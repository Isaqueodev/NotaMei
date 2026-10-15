import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/das/local_das_gateway.dart';
import 'package:notamei/das/das_reminder_service.dart';

class FakeDasPlatform implements DasPlatform {
  final scheduled = <int, DateTime>{};
  final cancelled = <int>[];
  bool permission = true;
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<void> schedule(int id, DateTime when) async { scheduled[id] = when; }
  @override
  Future<void> cancel(int id) async { cancelled.add(id); }
}

void main() {
  test('agenda 12 meses pessoais futuros, sem pressupor vencimento oficial', () async {
    final fake = FakeDasPlatform();
    final gateway = LocalDasNotificationsGateway(platform: fake, clock: () => DateTime(2027, 1, 31, 10));
    await gateway.schedule(const DasReminderSettings(day: 31, hour: 9, minute: 0));
    expect(fake.scheduled, hasLength(12));
    expect(fake.scheduled[1000], DateTime(2027, 2, 28, 9));
    expect(fake.scheduled[1001], DateTime(2027, 3, 31, 9));
  });

  test('desativar cancela somente IDs próprios do DAS', () async {
    final fake = FakeDasPlatform();
    final gateway = LocalDasNotificationsGateway(platform: fake);
    await gateway.cancel();
    expect(fake.cancelled, List<int>.generate(12, (i) => 1000 + i));
  });
}
