/// Parses positive pt-BR amounts: comma decimals and optional grouped thousands.
/// Currency symbols, signs and decimal dots are deliberately rejected.
const maxMoneyCents = 9223372036854775807;

int checkedAddCents(int left, int right) {
  if (left < 0 ||
      right < 0 ||
      right > maxMoneyCents ||
      left > maxMoneyCents - right) {
    throw RangeError('Soma de valores fora do intervalo permitido');
  }
  return left + right;
}

int parseMoney(String input) {
  final value = input.trim();
  if (!RegExp(r'^(?:[0-9]+|[1-9][0-9]{0,2}(?:\.[0-9]{3})+)(?:,[0-9]{1,2})?$')
      .hasMatch(value)) {
    throw FormatException('Valor monetário inválido', input);
  }
  final parts = value.replaceAll('.', '').split(',');
  final exact =
      BigInt.parse(parts[0]) * BigInt.from(100) +
      BigInt.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  if (exact <= BigInt.zero || exact > BigInt.from(maxMoneyCents)) {
    throw FormatException('Valor fora do intervalo permitido', input);
  }
  return exact.toInt();
}

String formatMoney(int cents) {
  final amount = BigInt.from(cents).abs();
  final whole = (amount ~/ BigInt.from(100)).toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final fraction = (amount % BigInt.from(100)).toString().padLeft(2, '0');
  return '${cents < 0 ? '-' : ''}R\$ $grouped,$fraction';
}
