// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:katyayani_core/katyayani_core.dart';

import '../analytics/analytics_item.dart';
import '../local_notifications/local_notification_service_impl.dart';
import 'kc_identity.dart';
import 'ko_engagement_service.dart';

/// [KoEngagementService] on the `katyayani_core` SDK. The only file that
/// imports it.
class KoEngagementServiceImpl implements KoEngagementService {
  /// The FCM topic every device joins, for broadcast campaigns.
  static const String broadcastTopic = 'all_users';

  KoEngagementServiceImpl({required String siteId, required String apiBase})
    : _siteId = siteId,
      _apiBase = apiBase;

  final String _siteId;
  final String _apiBase;

  /// Logs for developers: to the debug console, and in debug builds to
  /// logcat too (`dart:developer` output never reaches it).
  static void _log(String message) {
    log(message);
    if (kDebugMode) debugPrint(message);
  }

  /// Whether [init] finished. The SDK keeps its own flag private, and its
  /// push calls throw when it never started.
  bool _started = false;

  /// The running or finished [init]. Start-up does not wait for it, so
  /// [identify] and [resetIdentity] do, or a restored session would be lost.
  Future<void>? _starting;

  @override
  Future<void> init() => _starting ??= _start();

  Future<void> _start() async {
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supported) return;
    try {
      await KatyayaniCore.init(
        KCConfig(
          siteId: _siteId,
          apiBase: _apiBase,
          // The SDK's own logs, in debug builds only.
          debug: kDebugMode,
          enablePush: true,
          autoRequestPush: false,
          androidNotificationIcon: LocalNotificationServiceImpl.androidIcon,
        ),
      );
      _started = true;
      _log('[kc] started');
      _listen();
    } catch (e) {
      _log('[kc] not started: $e');
    }
  }

  void _listen() {
    try {
      KatyayaniCore.onNotificationAction((notification, action) {
        // TODO(push): route the tap in the next phase.
        _log('[kc] notification ${action.name}: ${notification.id}');
      });
      KatyayaniCore.onNotificationButtonAction((notification, buttonId) {
        // TODO(push): act on the button in the next phase.
        _log('[kc] notification button $buttonId: ${notification.id}');
      });
      KatyayaniCore.onDeferredDeepLink((deepLink, attribution) {
        // TODO(push): open the deep link in the next phase.
        _log('[kc] deferred deep link: $deepLink');
      });
      KatyayaniCore.onReferral((referralCode, params) {
        // TODO(push): apply the referral code in the next phase.
        _log('[kc] referral: $referralCode');
      });
      KatyayaniCore.onNudgeNavigation((url) {
        // TODO(push): open the nudge's link in the next phase.
        _log('[kc] nudge navigation: $url');
      });
    } catch (e) {
      // The SDK started without push (e.g. no Firebase).
      _log('[kc] listeners not set: $e');
    }
  }

  @override
  Future<void> identify({
    required String phone,
    String? fullName,
    String? email,
  }) async {
    await _starting;
    if (!_started) return;
    final identity = kcIdentityFor(
      phone: phone,
      fullName: fullName,
      email: email,
    );
    if (identity == null) {
      _log('[kc] identify skipped: no phone');
      return;
    }
    try {
      await KatyayaniCore.identify(identity.userId, traits: identity.traits);
      _log('[kc] identified ${identity.userId}');
    } catch (e) {
      _log('[kc] identify failed: $e');
    }
  }

  @override
  void resetIdentity() {
    final starting = _starting;
    if (starting == null) return;
    unawaited(
      starting.then(
        (_) => _guard('resetIdentity', KatyayaniCore.resetIdentity),
      ),
    );
  }

  @override
  Future<bool> requestPushPermission() async {
    if (!_started) {
      _log('[kc] push permission skipped: SDK not started');
      return false;
    }
    try {
      final granted = await KatyayaniCore.requestPushPermission();
      _log('[kc] push permission granted: $granted');
      return granted;
    } catch (e) {
      _log('[kc] push permission failed: $e');
      return false;
    }
  }

  @override
  Future<bool> registerPush() async {
    final granted = await requestPushPermission();
    if (!granted) return false;
    try {
      await KatyayaniCore.subscribeToTopic(broadcastTopic);
      _log('[kc] subscribed to $broadcastTopic');
    } catch (e) {
      _log('[kc] subscribe to $broadcastTopic failed: $e');
    }
    return true;
  }

  @override
  void track(String name, {Map<String, dynamic>? properties}) =>
      _guard(name, () => KatyayaniCore.track(name, properties: properties));

  @override
  void screenView(String screenName, {Map<String, dynamic>? properties}) =>
      _guard(
        'screen_view',
        () => KatyayaniCore.screenView(screenName, properties: properties),
      );

  @override
  void viewItem({required List<AnalyticsItem> items, num? value}) => _guard(
    'view_item',
    () => KatyayaniCore.viewItem(items: _kcItems(items), value: value),
  );

  @override
  void addToCart({required List<AnalyticsItem> items, num? value}) => _guard(
    'add_to_cart',
    () => KatyayaniCore.addToCart(items: _kcItems(items), value: value),
  );

  @override
  void removeFromCart({required List<AnalyticsItem> items, num? value}) =>
      _guard(
        'remove_from_cart',
        () =>
            KatyayaniCore.removeFromCart(items: _kcItems(items), value: value),
      );

  @override
  void viewCart({required List<AnalyticsItem> items, num? value}) => _guard(
    'view_cart',
    () => KatyayaniCore.viewCart(items: _kcItems(items), value: value),
  );

  @override
  void beginCheckout({
    required List<AnalyticsItem> items,
    num? value,
    String? coupon,
  }) => _guard(
    'begin_checkout',
    () => KatyayaniCore.beginCheckout(
      items: _kcItems(items),
      value: value,
      coupon: coupon,
    ),
  );

  @override
  void purchase({
    required String transactionId,
    required List<AnalyticsItem> items,
    num? value,
    num? shipping,
    String? coupon,
  }) => _guard(
    'purchase',
    () => KatyayaniCore.purchase(
      transactionId: transactionId,
      items: _kcItems(items),
      value: value,
      shipping: shipping,
      coupon: coupon,
    ),
  );

  @override
  void search(String searchTerm) =>
      _guard('search', () => KatyayaniCore.search(searchTerm: searchTerm));

  @override
  void login({String? method}) =>
      _guard('login', () => KatyayaniCore.login(method: method));

  @override
  void addPaymentInfo({
    required List<AnalyticsItem> items,
    num? value,
    String? paymentType,
  }) => _guard(
    'add_payment_info',
    () => KatyayaniCore.addPaymentInfo(
      items: _kcItems(items),
      value: value,
      paymentType: paymentType,
    ),
  );

  @override
  void capturePayment(double amount, {String? orderId}) => _guard(
    'capturePayment',
    () => unawaited(
      KatyayaniCore.capturePayment(
        amount,
        orderId: orderId,
      ).catchError((Object e) => _log('[kc] capturePayment failed: $e')),
    ),
  );

  @override
  void checkNudges(BuildContext context, String route) => _guard(
    'checkNudges',
    () => unawaited(
      KatyayaniCore.checkNudges(
        context,
        route,
      ).catchError((Object e) => _log('[kc] checkNudges failed: $e')),
    ),
  );

  /// Runs an SDK call when started; an SDK error never reaches the app.
  void _guard(String what, void Function() call) {
    if (!_started) return;
    try {
      call();
    } catch (e) {
      _log('[kc] $what failed: $e');
    }
  }

  static List<KCItem> _kcItems(List<AnalyticsItem> items) => [
    for (final item in items)
      KCItem(
        sku: item.sku,
        qty: item.quantity,
        rate: item.price,
        name: item.name,
        category: item.category,
      ),
  ];
}
