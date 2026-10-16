import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/services/analytics/analytics_destination.dart';
import 'package:mymali/core/services/analytics/analytics_item.dart';
import 'package:mymali/core/services/analytics/app_events.dart';
import 'package:mymali/core/services/analytics/ko_analytics_service.dart';
import 'package:mymali/core/services/analytics/multi_destination_analytics_service.dart';

import '../../../helpers/fake_ko_engagement_service.dart';

class _FakeDestination implements AnalyticsDestination {
  final List<({String name, Map<String, Object?>? properties})> logged = [];
  final List<String?> users = [];
  int trackingRequests = 0;

  @override
  void log(String eventName, Map<String, Object?>? properties) =>
      logged.add((name: eventName, properties: properties));

  @override
  void setUserId(String? userId) => users.add(userId);

  @override
  Future<void> requestTrackingPermission() async => trackingRequests++;
}

void main() {
  late FakeKoEngagementService core;
  late _FakeDestination ga4;
  late _FakeDestination meta;
  late MultiDestinationAnalyticsService analytics;

  const items = [
    AnalyticsItem(sku: 'sku-1', quantity: 2, price: 99, name: 'Neem Oil'),
  ];

  setUp(() {
    core = FakeKoEngagementService();
    ga4 = _FakeDestination();
    meta = _FakeDestination();
    analytics = MultiDestinationAnalyticsService(
      core: KoAnalyticsService(core),
      destinations: [ga4, meta],
    );
  });

  test('track goes to Katyayani Core and every destination, once', () {
    analytics.track(AppEvents.otpSent, properties: {'channel': 'sms'});

    expect(core.tracked.single.name, AppEvents.otpSent);
    for (final destination in [ga4, meta]) {
      expect(destination.logged.single.name, AppEvents.otpSent);
      expect(destination.logged.single.properties, {'channel': 'sms'});
    }
  });

  test('addToCart sends "Added To Cart" with the first line to the others', () {
    analytics.addToCart(items: items);

    expect(core.events, ['add_to_cart']);
    for (final destination in [ga4, meta]) {
      expect(destination.logged.single.name, AppEvents.addToCart);
      expect(destination.logged.single.properties, {
        'item_id': 'sku-1',
        'item_name': 'Neem Oil',
        'price': 99,
        'quantity': 2,
        'currency': 'INR',
      });
    }
  });

  test('removeFromCart sends "Removed From Cart"', () {
    analytics.removeFromCart(items: items);

    expect(core.events, ['remove_from_cart']);
    expect(ga4.logged.single.name, AppEvents.removeFromCart);
  });

  test('search sends "Product Search" with the term', () {
    analytics.search('neem');

    expect(core.events, ['search']);
    expect(meta.logged.single.name, AppEvents.productSearch);
    expect(meta.logged.single.properties, {'search_term': 'neem'});
  });

  test('the typed calls that have a plain event beside them stay in KC', () {
    analytics
      ..viewItem(items: items)
      ..viewCart(items: items)
      ..beginCheckout(items: items)
      ..addPaymentInfo(items: items)
      ..purchase(transactionId: 'KMM-1', items: items)
      ..screenView('Cart')
      ..login(method: 'phone_otp');

    expect(core.events, [
      'view_item',
      'view_cart',
      'begin_checkout',
      'add_payment_info',
      'purchase',
      'screen_view',
      'login',
    ]);
    expect(ga4.logged, isEmpty);
    expect(meta.logged, isEmpty);
  });

  test('the user id goes to every destination, and null clears it', () {
    analytics
      ..setUserId('user-1')
      ..setUserId(null);

    expect(ga4.users, ['user-1', null]);
    expect(meta.users, ['user-1', null]);
  });

  test('the tracking prompt is asked of every destination', () async {
    await analytics.requestTrackingPermission();

    expect(ga4.trackingRequests, 1);
    expect(meta.trackingRequests, 1);
  });

  test('with no destinations it is Katyayani Core alone', () {
    final alone = MultiDestinationAnalyticsService(
      core: KoAnalyticsService(core),
      destinations: const [],
    );

    alone
      ..track(AppEvents.logout)
      ..addToCart(items: items)
      ..setUserId('u');

    expect(core.events, ['Logout', 'add_to_cart']);
  });
}
