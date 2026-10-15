import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/das/das_schedule.dart';

void main() {
  test('dia 31 é ajustado ao último dia de fevereiro bissexto', () {
    final next = nextDasReminder(
      now: DateTime(2028, 2, 1), day: 31, hour: 9, minute: 30,
    );
    expect(next, DateTime(2028, 2, 29, 9, 30));
  });

  test('agendamento no instante atual avança ao próximo mês', () {
    final next = nextDasReminder(
      now: DateTime(2026, 10, 15, 9), day: 15, hour: 9, minute: 0,
    );
    expect(next, DateTime(2026, 11, 15, 9));
  });

  test('configuração fora do calendário não é aceita', () {
    expect(
      () => nextDasReminder(now: DateTime(2026), day: 0, hour: 9, minute: 0),
      throwsRangeError,
    );
    expect(
      () => nextDasReminder(now: DateTime(2026), day: 12, hour: 24, minute: 0),
      throwsRangeError,
    );
  });

  test('lista 12 avisos futuros com dias ajustados a cada mês', () {
    final dates = upcomingDasReminders(
      now: DateTime(2027, 1, 31, 10), day: 31, hour: 9, minute: 0,
    );
    expect(dates, hasLength(12));
    expect(dates.first, DateTime(2027, 2, 28, 9));
    expect(dates[1], DateTime(2027, 3, 31, 9));
    expect(dates.last.isAfter(dates.first), isTrue);
  });
}
