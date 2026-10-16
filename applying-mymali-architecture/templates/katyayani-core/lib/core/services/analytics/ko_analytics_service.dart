import 'package:flutter/widgets.dart';

import '../katyayani_core/ko_engagement_service.dart';
import 'analytics_item.dart';
import 'analytics_service.dart';

/// [AnalyticsService] that reports to Katyayani Core only. The app uses it
/// inside [MultiDestinationAnalyticsService], which adds Google Analytics
/// and Meta.
class KoAnalyticsService implements AnalyticsService {
  const KoAnalyticsService(this._core);

  final KoEngagementService _core;

  @override
  void track(String name, {Map<String, dynamic>? properties}) =>
      _core.track(name, properties: properties);

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) =>
      _core.screenView(screenName, properties: properties);

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) =>
      _core.viewItem(items: items, value: value);

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) =>
      _core.addToCart(items: items, value: value);

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) =>
      _core.removeFromCart(items: items, value: value);

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
  void search(String searchTerm) => _core.search(searchTerm);

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
  void setUserId(String? userId) {}

  @override
  Future<void> requestTrackingPermission() async {}

  @override
  void checkNudges(BuildContext context, String route) =>
      _core.checkNudges(context, route);
}
