// GENERIC: not in the source app (it always has Katyayani Core); the core for an app without it.
import 'package:flutter/widgets.dart';

import 'analytics_item.dart';
import 'analytics_service.dart';

/// An [AnalyticsService] that does nothing: the core for
/// `MultiDestinationAnalyticsService` when the app has no Katyayani Core, so
/// events reach only the destinations (Google Analytics 4, Meta). Also a
/// stand-in where analytics are not wanted (tests, previews).
class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  void track(String name, {Map<String, dynamic>? properties}) {}

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) {}

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) {}

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) {}

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) {}

  @override
  void viewCart({required List<AnalyticsItem> items, num? value}) {}

  @override
  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  }) {}

  @override
  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  }) {}

  @override
  void search(String searchTerm) {}

  @override
  void login({String? method}) {}

  @override
  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  }) {}

  @override
  void capturePayment(double amount, {String? orderId}) {}

  @override
  void setUserId(String? userId) {}

  @override
  Future<void> requestTrackingPermission() async {}

  @override
  void checkNudges(BuildContext context, String route) {}
}
