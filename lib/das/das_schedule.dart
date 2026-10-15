/// Encontra o próximo aviso mensal escolhido pela pessoa, no horário local.
/// O dia 29–31 é ajustado ao último dia de meses mais curtos.
DateTime nextDasReminder({
  required DateTime now,
  required int day,
  required int hour,
  required int minute,
}) {
  RangeError.checkValueInInterval(day, 1, 31, 'day');
  RangeError.checkValueInInterval(hour, 0, 23, 'hour');
  RangeError.checkValueInInterval(minute, 0, 59, 'minute');

  DateTime forMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day < lastDay ? day : lastDay, hour, minute);
  }

  final thisMonth = forMonth(now.year, now.month);
  return thisMonth.isAfter(now)
      ? thisMonth
      : forMonth(now.year, now.month + 1);
}

/// Agenda um ano por vez; reprogramar ao abrir o app atualiza o horizonte.
List<DateTime> upcomingDasReminders({
  required DateTime now,
  required int day,
  required int hour,
  required int minute,
  int count = 12,
}) {
  RangeError.checkValueInInterval(count, 1, 36, 'count');
  final dates = <DateTime>[];
  var cursor = now;
  for (var i = 0; i < count; i++) {
    cursor = nextDasReminder(now: cursor, day: day, hour: hour, minute: minute);
    dates.add(cursor);
  }
  return dates;
}
