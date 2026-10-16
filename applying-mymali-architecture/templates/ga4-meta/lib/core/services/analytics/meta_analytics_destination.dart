import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

import 'analytics_destination.dart';
import 'analytics_event_mapper.dart';

/// Meta (Facebook) App Events. The only file that imports
/// `facebook_app_events` and `app_tracking_transparency`.
///
/// Create it only when the Meta app id and client token are set
/// (`Env.fbAppId`, `Env.fbClientToken`): the native SDK needs both and fails
/// without them. `bootstrap`'s dependency setup leaves it out otherwise.
class MetaAnalyticsDestination implements AnalyticsDestination {
  MetaAnalyticsDestination([FacebookAppEvents? facebook])
    : _facebook = facebook ?? FacebookAppEvents();

  /// Android needs no prompt, and iOS shows its own only once.
  static const Duration _promptDelay = Duration(seconds: 1);

  final FacebookAppEvents _facebook;

  @override
  void log(String eventName, Map<String, Object?>? properties) {
    final event = metaEventFor(eventName, properties);
    if (event.isPurchase) {
      // Purchase has its own call, with the revenue. It is not also sent as
      // an event, or Meta would count it twice.
      _run(
        'logPurchase',
        () => _facebook.logPurchase(
          amount: event.valueToSum ?? 0,
          currency: event.currency,
          parameters: event.parameters,
        ),
      );
      return;
    }
    _run(
      'logEvent ${event.name}',
      () => _facebook.logEvent(
        name: event.name,
        parameters: event.parameters.isEmpty ? null : event.parameters,
        valueToSum: event.valueToSum,
      ),
    );
  }

  @override
  void setUserId(String? userId) => _run(
    'setUserId',
    () =>
        userId == null ? _facebook.clearUserID() : _facebook.setUserID(userId),
  );

  /// iOS 14.5+: asks for the App Tracking Transparency permission and tells
  /// Meta whether it may collect the advertising id. Android has nothing to
  /// ask.
  @override
  Future<void> requestTrackingPermission() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      // The prompt only shows once the app is active.
      await Future<void>.delayed(_promptDelay);
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
      await _facebook.setAdvertiserIdCollectionEnabled(
        status == TrackingStatus.authorized,
      );
    } catch (e) {
      _fail('requestTrackingPermission', e);
    }
  }

  void _run(String what, Future<void> Function() call) {
    try {
      unawaited(call().catchError((Object e) => _fail(what, e)));
    } catch (e) {
      _fail(what, e);
    }
  }

  void _fail(String what, Object error) {
    final message = '[meta] $what failed: $error';
    developer.log(message);
    if (kDebugMode) debugPrint(message);
  }
}
