import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/utils/currency_format.dart';

void main() {
  test('formats rupees without paise and with Indian grouping', () {
    expect(formatRupees(269), '₹269');
    expect(formatRupees(1250), '₹1,250');
    expect(formatRupees(125000), '₹1,25,000');
    expect(formatRupees(99.4), '₹99');
  });
}
