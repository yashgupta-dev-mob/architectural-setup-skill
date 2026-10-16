import 'package:intl/intl.dart';

final NumberFormat _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// Formats an amount in rupees with Indian grouping and no paise,
/// e.g. `formatRupees(1250) == '₹1,250'`.
String formatRupees(num amount) => _rupees.format(amount);
