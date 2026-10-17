import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/services/analytics/analytics_item.dart';
import 'package:template_app/core/services/analytics/ko_analytics_service.dart';

import '../../../helpers/fake_ko_engagement_service.dart';

void main() {
  test('every event is passed on to Katyayani Core', () {
    final core = FakeKoEngagementService();
    final analytics = KoAnalyticsService(core);
    const items = [AnalyticsItem(sku: 'SKU-1', quantity: 1, price: 99)];

    analytics
      ..track('coupon_applied')
      ..screenView('/cart')
      ..viewItem(items: items)
      ..addToCart(items: items)
      ..removeFromCart(items: items)
      ..viewCart(items: items)
      ..beginCheckout(items: items)
      ..purchase(transactionId: 'KMM-1', items: items)
      ..search('neem')
      ..login(method: 'otp');

    expect(core.events, [
      'coupon_applied',
      'screen_view',
      'view_item',
      'add_to_cart',
      'remove_from_cart',
      'view_cart',
      'begin_checkout',
      'purchase',
      'search',
      'login',
    ]);
  });
}
