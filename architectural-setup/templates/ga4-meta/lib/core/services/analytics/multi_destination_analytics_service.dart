// GENERIC: the plain events it sends are named in this file, not in the source app's AppEvents; works without Katyayani Core (NoOpAnalyticsService).
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/widgets.dart';

import 'analytics_destination.dart';
import 'analytics_item.dart';
import 'analytics_service.dart';
import 'analytics_event_mapper.dart';

/// The one [AnalyticsService] the app uses: every event goes to the core
/// service ([_core]: Katyayani Core's, or `NoOpAnalyticsService` for an app
/// without it) and to each [AnalyticsDestination] (Google Analytics 4 and
/// Meta), so no screen or bloc ever calls an SDK.
///
/// `track` sends the event under its app name to every destination, and each
/// destination shapes the name and parameters its own way
/// (`analytics_event_mapper.dart`).
///
/// The typed calls (`addToCart`, `viewItem`, …) are the core's ecommerce
/// events, with its item lists. Only three of them also have a plain event
/// the other destinations need and nothing else sends: `addToCart`
/// ([addToCartEvent]), `removeFromCart` ([removeFromCartEvent]) and `search`
/// ([searchEvent]). The rest (`viewItem`, `viewCart`, `beginCheckout`,
/// `addPaymentInfo`, `purchase`, `login`, `screenView`) are expected to be
/// sent beside a `track` of the same moment, so they stay with the core:
/// forwarding them too would count the moment twice.
class MultiDestinationAnalyticsService implements AnalyticsService {
  const MultiDestinationAnalyticsService({
    required AnalyticsService core,
    required List<AnalyticsDestination> destinations,
  }) : _core = core,
       _destinations = destinations;

  /// The plain event [addToCart] sends to the destinations. An app that
  /// already reports this moment under another name uses that name here.
  static const String addToCartEvent = 'Added To Cart';

  /// The plain event [removeFromCart] sends to the destinations.
  static const String removeFromCartEvent = 'Removed From Cart';

  /// The plain event [search] sends to the destinations.
  static const String searchEvent = 'Product Search';

  final AnalyticsService _core;
  final List<AnalyticsDestination> _destinations;

  @override
  void track(String name, {Map<String, dynamic>? properties}) {
    _core.track(name, properties: properties);
    _send(name, properties);
  }

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) =>
      _core.screenView(screenName, properties: properties);

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) =>
      _core.viewItem(items: items, value: value);

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) {
    _core.addToCart(items: items, value: value);
    _send(addToCartEvent, _itemProperties(items));
  }

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) {
    _core.removeFromCart(items: items, value: value);
    _send(removeFromCartEvent, _itemProperties(items));
  }

  @override
  void viewCart({required List<AnalyticsItem> items, num? value}) =>
      _core.viewCart(items: items, value: value);

  @override
  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  }) => _core.beginCheckout(items: items, value: value, coupon: coupon);

  @override
  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  }) => _core.purchase(
    transactionId: transactionId,
    items: items,
    value: value,
    shipping: shipping,
    coupon: coupon,
  );

  @override
  void search(String searchTerm) {
    _core.search(searchTerm);
    _send(searchEvent, {'search_term': searchTerm});
  }

  @override
  void login({String? method}) => _core.login(method: method);

  @override
  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  }) => _core.addPaymentInfo(
    items: items,
    value: value,
    paymentType: paymentType,
  );

  @override
  void capturePayment(double amount, {String? orderId}) =>
      _core.capturePayment(amount, orderId: orderId);

  @override
  void checkNudges(BuildContext context, String route) =>
      _core.checkNudges(context, route);

  @override
  void setUserId(String? userId) {
    _core.setUserId(userId);
    for (final destination in _destinations) {
      destination.setUserId(userId);
    }
  }

  @override
  Future<void> requestTrackingPermission() async {
    await _core.requestTrackingPermission();
    await Future.wait([
      for (final destination in _destinations)
        destination.requestTrackingPermission(),
    ]);
  }

  void _send(String name, Map<String, Object?>? properties) {
    for (final destination in _destinations) {
      destination.log(name, properties);
    }
  }

  /// The first line's fields, as the cart events carry them. Money is the
  /// price of one unit; the quantity says how many.
  Map<String, Object?> _itemProperties(List<AnalyticsItem> items) {
    if (items.isEmpty) return const {};
    final item = items.first;
    return {
      'item_id': item.sku,
      'item_name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'currency': defaultCurrency,
    };
  }
}
