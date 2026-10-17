import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'analytics_destination.dart';
import 'analytics_event_mapper.dart';

/// Google Analytics 4 through Firebase Analytics. The only file that imports
/// `firebase_analytics`.
///
/// It sends nothing until Firebase has started (`bootstrap.dart`), so a build
/// without `google-services.json` runs without it.
class FirebaseAnalyticsDestination implements AnalyticsDestination {
  FirebaseAnalyticsDestination([FirebaseAnalytics Function()? analytics])
    : _analytics = analytics ?? (() => FirebaseAnalytics.instance);

  final FirebaseAnalytics Function() _analytics;

  @override
  void log(String eventName, Map<String, Object?>? properties) {
    final event = ga4EventFor(eventName, properties);
    _run('logEvent ${event.name}', (analytics) {
      return analytics.logEvent(
        name: event.name,
        parameters: event.parameters.isEmpty ? null : event.parameters,
      );
    });
  }

  @override
  void setUserId(String? userId) =>
      _run('setUserId', (analytics) => analytics.setUserId(id: userId));

  @override
  Future<void> requestTrackingPermission() async {}

  void _run(String what, Future<void> Function(FirebaseAnalytics) call) {
    if (Firebase.apps.isEmpty) return;
    try {
      unawaited(call(_analytics()).catchError((Object e) => _fail(what, e)));
    } catch (e) {
      _fail(what, e);
    }
  }

  void _fail(String what, Object error) {
    final message = '[ga4] $what failed: $error';
    developer.log(message);
    if (kDebugMode) debugPrint(message);
  }
}
