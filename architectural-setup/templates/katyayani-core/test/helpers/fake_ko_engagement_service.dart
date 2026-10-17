import 'package:flutter/widgets.dart';
import 'package:template_app/core/di/injection_container.dart';
import 'package:template_app/core/services/analytics/analytics_item.dart';
import 'package:template_app/core/services/analytics/analytics_service.dart';
import 'package:template_app/core/services/analytics/ko_analytics_service.dart';
import 'package:template_app/core/services/katyayani_core/ko_engagement_service.dart';

/// Records what the app asked of Katyayani Core.
class FakeKoEngagementService implements KoEngagementService {
  /// The phone of every `identify`, in order.
  final List<String> identified = [];
  int resetCount = 0;
  int initCount = 0;

  /// Every event name sent through [track] and the typed events.
  final List<String> events = [];

  /// Every [track] call with its properties, in order.
  final List<({String name, Map<String, dynamic>? properties})> tracked = [];

  /// The name of every screen reported, in order.
  final List<String> screens = [];

  @override
  Future<void> init() async => initCount++;

  /// How many times [registerPush] was asked.
  int registerPushCount = 0;

  @override
  Future<bool> registerPush() async {
    registerPushCount++;
    return true;
  }

  @override
  Future<void> identify({
    required String phone,
    String? fullName,
    String? email,
  }) async => identified.add(phone);

  @override
  void resetIdentity() => resetCount++;

  @override
  Future<bool> requestPushPermission() async => true;

  @override
  void track(String name, {Map<String, dynamic>? properties}) {
    events.add(name);
    tracked.add((name: name, properties: properties));
  }

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) {
    events.add('screen_view');
    screens.add(screenName);
  }

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) =>
      events.add('view_item');

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) =>
      events.add('add_to_cart');

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) =>
      events.add('remove_from_cart');

  @override
  void viewCart({required List<AnalyticsItem> items, num? value}) =>
      events.add('view_cart');

  @override
  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  }) => events.add('begin_checkout');

  @override
  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  }) => events.add('purchase');

  @override
  void search(String searchTerm) => events.add('search');

  @override
  void login({String? method}) => events.add('login');

  @override
  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  }) => events.add('add_payment_info');

  @override
  void capturePayment(double amount, {String? orderId}) =>
      events.add('capture_payment');

  @override
  void checkNudges(BuildContext context, String route) =>
      events.add('check_nudges');
}

/// Registers a [FakeKoEngagementService] in `sl`, as every test that pumps
/// `App` needs, and returns it.
FakeKoEngagementService registerFakeEngagement() {
  final fake = FakeKoEngagementService();
  sl.registerSingleton<KoEngagementService>(fake);
  sl.registerSingleton<AnalyticsService>(KoAnalyticsService(fake));
  return fake;
}
