import 'package:flutter/widgets.dart';

import '../analytics/analytics_item.dart';

/// Katyayani Core: who the user is, events, push and attribution.
///
/// The SDK registers every Firebase Messaging listener itself (foreground,
/// opened, initial message and the background handler). Firebase keeps
/// **one** background handler, so the app never registers its own.
///
/// Every method is safe to call before or without a successful [init]: it
/// then does nothing.
abstract interface class KoEngagementService {
  /// Starts the SDK and listens for its callbacks. Never throws.
  Future<void> init();

  /// Tells KC who is signed in, keyed by [phone] only. Does nothing when
  /// [phone] has no digits.
  Future<void> identify({
    required String phone,
    String? fullName,
    String? email,
  });

  /// Forgets the signed-in user. Called on sign-out.
  void resetIdentity();

  /// Asks the user to allow notifications. False when refused or unavailable.
  Future<bool> requestPushPermission();

  /// Asks for the notification permission, then ties this device to the
  /// signed-in user and subscribes it to the broadcast topic, as the React
  /// Native app's `registerPush` does. False when refused or unavailable.
  Future<bool> registerPush();

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

  /// Attributes a collected payment's revenue to the install source.
  void capturePayment(double amount, {String? orderId});

  /// Shows an in-app nudge set up for [route], if there is one.
  void checkNudges(BuildContext context, String route);
}
