/// Currency arithmetic uses minor units (paise), avoiding fractional-paise
/// shares and binary floating point errors when saving amounts.
class Money {
  static int? parseMinor(String value) {
    final text = value.trim();
    if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    return int.parse(parts.first) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts.last.padRight(2, '0')));
  }

  static int minor(num value) {
    if (!value.isFinite) throw ArgumentError('Amount must be finite');
    return (value * 100).round();
  }

  static double normalize(num value) => minor(value) / 100;

  /// Earlier participants receive the remaining paise, so the shares sum
  /// exactly to the original amount.
  static List<double> split(num amount, int participants) {
    if (participants < 1) throw ArgumentError('At least one participant');
    final total = minor(amount);
    return List.generate(
      participants,
      (index) =>
          (total ~/ participants + (index < total % participants ? 1 : 0)) /
          100,
    );
  }
}
