/// Formats an amount in paise as rupees: `123450` → `₹1,234.50`.
///
/// Rupees are grouped the Indian way (the last three digits, then groups of
/// two): `1234567890` → `₹1,23,45,678.90`. A negative amount keeps its sign
/// before the rupee symbol: `-150` → `-₹1.50`.
String formatPaise(int paise) {
  final sign = paise < 0 ? '-' : '';
  final absolute = paise.abs();
  final rupees = (absolute ~/ 100).toString();
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '$sign₹${_groupIndian(rupees)}.$fraction';
}

String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final tail = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  groups.insert(0, rest);
  return '${groups.join(',')},$tail';
}
