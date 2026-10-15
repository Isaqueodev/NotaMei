import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/core/money.dart';

void main() {
  test('parse pt-BR precisely without floating point', () {
    expect(parseMoney('1.234,56'), 123456);
    expect(parseMoney('1.234'), 123400);
    expect(parseMoney('12,3'), 1230);
    expect(parseMoney('12'), 1200);
    expect(parseMoney('0,01'), 1);
    expect(parseMoney(' 10,00 '), 1000);
  });
  test('reject malformed, nonpositive and foreign decimal values', () {
    for (final value in [
      '',
      '0',
      '0,00',
      '-1',
      '1.23',
      '1,234',
      '12.34,56',
      '1,000.00',
      'NaN',
      'R\$ 1,00',
      '+1',
      '1 000',
      '92233720368547758,08',
    ]) {
      expect(() => parseMoney(value), throwsFormatException, reason: value);
    }
  });
  test('format cents, including negative balance', () {
    expect(formatMoney(123456), 'R\$ 1.234,56');
    expect(formatMoney(0), 'R\$ 0,00');
    expect(formatMoney(-1), '-R\$ 0,01');
  });
}
