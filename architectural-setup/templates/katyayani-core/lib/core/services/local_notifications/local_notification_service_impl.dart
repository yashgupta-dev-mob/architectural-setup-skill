import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_notification_service.dart';

/// [LocalNotificationService] on `flutter_local_notifications`.
///
/// The channel copies the React Native app's (`app.config.ts`,
/// `pushDisplay.ts`). Its id must stay `push_campaigns`: Katyayani Core puts
/// that id in every campaign, and FCM falls back to the manifest's
/// `default_notification_channel_id` only when a message names none. Android
/// freezes a channel's sound when it is created, so a new sound needs a
/// reinstall, not a new value here.
///
/// Run [init] before `KatyayaniCore.init`: the plugin keeps one tap
/// callback, and the SDK's must be the last one set.
class LocalNotificationServiceImpl implements LocalNotificationService {
  LocalNotificationServiceImpl([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String pushChannelId = 'push_campaigns';
  static const String pushChannelName = 'MY Mali';

  /// `android/app/src/main/res/raw/notification.wav`, without the extension.
  static const String pushSound = 'notification';

  /// The small icon, `res/drawable*/notification_icon.png`.
  static const String androidIcon = '@drawable/notification_icon';

  /// The brand green the RN app lights the LED with.
  static const Color _ledColor = Color(0xFF163E33);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> init() async {
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supported) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(androidIcon),
          // Permission is asked at a chosen moment, never at start-up.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              pushChannelId,
              pushChannelName,
              importance: Importance.max,
              sound: const RawResourceAndroidNotificationSound(pushSound),
              vibrationPattern: Int64List.fromList(const [0, 250, 250, 250]),
              enableLights: true,
              ledColor: _ledColor,
            ),
          );
    } catch (e) {
      log('[notifications] channel setup failed, pushes stay silent: $e');
    }
  }
}
