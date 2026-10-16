import 'package:flutter/foundation.dart';

/// A pretend third-party analytics SDK.
///
/// In a real app this would be a vendor package (Segment, Mixpanel, ...).
/// Here every call only prints to the console, but the call sites are the
/// behaviour that matters: which event fires, with which properties, when.
class ThirdPartyTracker {
  ThirdPartyTracker._();

  static String? _writeKey;
  static String? _userId;

  /// Whether [init] has completed.
  static bool get isInitialized => _writeKey != null;

  /// Pretends to hand-shake with the vendor using [writeKey].
  static Future<void> init(String writeKey) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    _writeKey = writeKey;
    debugPrint('[tracker] init writeKey=$writeKey');
  }

  static void track(String event, Map<String, Object?> props) {
    final payload = <String, Object?>{
      ...props,
      if (_userId != null) 'user_id': _userId,
    };
    debugPrint('[tracker] track $event $payload');
  }

  static void screen(String name) {
    debugPrint('[tracker] screen $name user=$_userId');
  }

  static void identify(String userId) {
    _userId = userId;
    debugPrint('[tracker] identify $userId');
  }

  static void reset() {
    _userId = null;
    debugPrint('[tracker] reset');
  }
}
