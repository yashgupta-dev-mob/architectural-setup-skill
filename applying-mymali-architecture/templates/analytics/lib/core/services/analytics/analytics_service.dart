// GENERIC: doc comments made neutral; the Katyayani Core-only calls are no-ops for an app without it.
import 'package:flutter/widgets.dart';

import 'analytics_item.dart';

/// The events the app reports. Features call this, never an analytics SDK.
abstract interface class AnalyticsService {
  void track(String name, {Map<String, dynamic>? properties});

  void screenView(String screenName, {Map<String, dynamic>? properties});

  void viewItem({required List<AnalyticsItem> items, num? value});

  void addToCart({required List<AnalyticsItem> items, num? value});

  void removeFromCart({required List<AnalyticsItem> items, num? value});

  void viewCart({required List<AnalyticsItem> items, num? value});

  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  });

  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  });

  void search(String searchTerm);

  void login({String? method});

  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  });

  /// Attributes a collected payment's revenue to the install source, where
  /// the analytics service supports it. A no-op for an app without
  /// Katyayani Core.
  void capturePayment(double amount, {String? orderId});

  /// Ties the events sent to the analytics destinations to the signed-in
  /// user, or to nobody (sign-out) when [userId] is null.
  void setUserId(String? userId);

  /// Asks for the iOS App Tracking Transparency permission and passes the
  /// answer to the destinations that use it. Does nothing on Android.
  Future<void> requestTrackingPermission();

  /// Lets the analytics service show an in-app nudge set up for [route].
  /// [context] must sit under the navigator. A no-op for an app without
  /// Katyayani Core.
  void checkNudges(BuildContext context, String route);
}
