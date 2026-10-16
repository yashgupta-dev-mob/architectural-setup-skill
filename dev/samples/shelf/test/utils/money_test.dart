import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/utils/money.dart';

void main() {
  group('formatPaise', () {
    test('formats rupees and paise with two decimals', () {
      expect(formatPaise(123450), '₹1,234.50');
      expect(formatPaise(0), '₹0.00');
      expect(formatPaise(5), '₹0.05');
      expect(formatPaise(99999), '₹999.99');
    });

    test('groups large amounts the Indian way', () {
      expect(formatPaise(100000), '₹1,000.00');
      expect(formatPaise(12345600), '₹1,23,456.00');
      expect(formatPaise(1234567890), '₹1,23,45,678.90');
    });

    test('keeps the sign before the rupee symbol', () {
      expect(formatPaise(-150), '-₹1.50');
    });
  });
}
