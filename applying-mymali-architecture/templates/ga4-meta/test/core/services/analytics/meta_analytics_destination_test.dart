import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/services/analytics/app_events.dart';
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

  test('Order Placed is one logPurchase and no logEvent', () async {
    meta.log(AppEvents.orderPlaced, {
      'order_id': 'KMM-9',
      'value': 899,
      'currency': 'INR',
    });
    await settle();

    expect(calls.map((c) => c.method), ['logPurchase']);
    final arguments = calls.single.arguments as Map;
    expect(arguments['amount'], 899.0);
    expect(arguments['currency'], 'INR');
  });

  test(
    'another event is a logEvent with its standard name and value',
    () async {
      meta.log(AppEvents.checkoutStarted, {'value': 350, 'items_count': 2});
      await settle();

      expect(calls.map((c) => c.method), ['logEvent']);
      final arguments = calls.single.arguments as Map;
      expect(arguments['name'], 'fb_mobile_initiated_checkout');
      expect(arguments['_valueToSum'], 350.0);
    },
  );

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

    meta.log(AppEvents.otpSent, null);
    await settle();
  });
}
