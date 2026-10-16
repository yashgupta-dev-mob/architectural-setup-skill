// GENERIC: uses a recording fake core instead of MyMali's Katyayani Core fake, and literal event names instead of its AppEvents.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/services/analytics/analytics_destination.dart';
import 'package:mymali/core/services/analytics/analytics_item.dart';
import 'package:mymali/core/services/analytics/analytics_service.dart';
import 'package:mymali/core/services/analytics/multi_destination_analytics_service.dart';
import 'package:mymali/core/services/analytics/no_op_analytics_service.dart';

/// Records the name of every call made to the core service.
class _RecordingCore implements AnalyticsService {
  final List<String> calls = [];
  final List<String> tracked = [];

  @override
  void track(String name, {Map<String, dynamic>? properties}) {
    calls.add('track');
    tracked.add(name);
  }

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) =>
      calls.add('screenView');

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) =>
      calls.add('viewItem');

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) =>
      calls.add('addToCart');

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) =>
      calls.add('removeFromCart');

  @override
  void viewCart({required List<AnalyticsItem> items, num? value}) =>
      calls.add('viewCart');

  @override
  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  }) => calls.add('beginCheckout');

  @override
  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  }) => calls.add('purchase');

  @override
  void search(String searchTerm) => calls.add('search');

  @override
  void login({String? method}) => calls.add('login');

  @override
  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  }) => calls.add('addPaymentInfo');

  @override
  void capturePayment(double amount, {String? orderId}) =>
      calls.add('capturePayment');

  @override
  void setUserId(String? userId) => calls.add('setUserId');

  @override
  Future<void> requestTrackingPermission() async =>
      calls.add('requestTrackingPermission');

  @override
  void checkNudges(BuildContext context, String route) =>
      calls.add('checkNudges');
}

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
  late _RecordingCore core;
  late _FakeDestination ga4;
  late _FakeDestination meta;
  late MultiDestinationAnalyticsService analytics;

  const items = [
    AnalyticsItem(sku: 'sku-1', quantity: 2, price: 99, name: 'Blue Mug'),
  ];

  setUp(() {
    core = _RecordingCore();
    ga4 = _FakeDestination();
    meta = _FakeDestination();
    analytics = MultiDestinationAnalyticsService(
      core: core,
      destinations: [ga4, meta],
    );
  });

  test('track goes to the core and every destination, once', () {
    analytics.track('Signed Up', properties: {'channel': 'sms'});

    expect(core.tracked.single, 'Signed Up');
    for (final destination in [ga4, meta]) {
      expect(destination.logged.single.name, 'Signed Up');
      expect(destination.logged.single.properties, {'channel': 'sms'});
    }
  });

  test('addToCart sends its plain event with the first line', () {
    analytics.addToCart(items: items);

    expect(core.calls, ['addToCart']);
    for (final destination in [ga4, meta]) {
      expect(
        destination.logged.single.name,
        MultiDestinationAnalyticsService.addToCartEvent,
      );
      expect(destination.logged.single.properties, {
        'item_id': 'sku-1',
        'item_name': 'Blue Mug',
        'price': 99,
        'quantity': 2,
        'currency': 'INR',
      });
    }
  });

  test('removeFromCart sends its plain event', () {
    analytics.removeFromCart(items: items);

    expect(core.calls, ['removeFromCart']);
    expect(
      ga4.logged.single.name,
      MultiDestinationAnalyticsService.removeFromCartEvent,
    );
  });

  test('search sends its plain event with the term', () {
    analytics.search('mug');

    expect(core.calls, ['search']);
    expect(
      meta.logged.single.name,
      MultiDestinationAnalyticsService.searchEvent,
    );
    expect(meta.logged.single.properties, {'search_term': 'mug'});
  });

  test(
    'the typed calls that have a plain event beside them stay in the core',
    () {
      analytics
        ..viewItem(items: items)
        ..viewCart(items: items)
        ..beginCheckout(items: items)
        ..addPaymentInfo(items: items)
        ..purchase(transactionId: 'T-1', items: items)
        ..screenView('Cart')
        ..login(method: 'phone_otp');

      expect(core.calls, [
        'viewItem',
        'viewCart',
        'beginCheckout',
        'addPaymentInfo',
        'purchase',
        'screenView',
        'login',
      ]);
      expect(ga4.logged, isEmpty);
      expect(meta.logged, isEmpty);
    },
  );

  test('the user id goes to the core and every destination', () {
    analytics
      ..setUserId('user-1')
      ..setUserId(null);

    expect(core.calls, ['setUserId', 'setUserId']);
    expect(ga4.users, ['user-1', null]);
    expect(meta.users, ['user-1', null]);
  });

  test('the tracking prompt is asked of every destination', () async {
    await analytics.requestTrackingPermission();

    expect(core.calls, ['requestTrackingPermission']);
    expect(ga4.trackingRequests, 1);
    expect(meta.trackingRequests, 1);
  });

  test('with no destinations it is the core alone', () {
    final alone = MultiDestinationAnalyticsService(
      core: core,
      destinations: const [],
    );

    alone
      ..track('Logout')
      ..addToCart(items: items)
      ..setUserId('u');

    expect(core.calls, ['track', 'addToCart', 'setUserId']);
  });

  test(
    'with a NoOpAnalyticsService core the destinations still get events',
    () {
      final noCore = MultiDestinationAnalyticsService(
        core: const NoOpAnalyticsService(),
        destinations: [ga4],
      );

      noCore
        ..track('Signed Up')
        ..search('mug');

      expect(ga4.logged.map((e) => e.name), [
        'Signed Up',
        MultiDestinationAnalyticsService.searchEvent,
      ]);
    },
  );
}
