// GENERIC: literal event names instead of MyMali's AppEvents; no purchase test (the template's purchase table is empty).
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/services/analytics/meta_analytics_destination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  late MetaAnalyticsDestination meta;

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), (
          call,
        ) async {
          calls.add(call);
          return null;
        });
    meta = MetaAnalyticsDestination();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('an event is one logEvent with its name and value', () async {
    meta.log('Checkout Started', {'value': 350, 'items_count': 2});
    await settle();

    expect(calls.map((c) => c.method), ['logEvent']);
    final arguments = calls.single.arguments as Map;
    expect(arguments['name'], 'Checkout Started');
    expect(arguments['_valueToSum'], 350.0);
  });

  test('the user id is set, and cleared with null', () async {
    meta
      ..setUserId('user-1')
      ..setUserId(null);
    await settle();

    expect(calls.map((c) => c.method), ['setUserID', 'clearUserID']);
  });

  test('an SDK error never reaches the caller', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(channelName),
          (call) async => throw PlatformException(code: 'nope'),
        );

    meta.log('OTP Sent', null);
    await settle();
  });
}
