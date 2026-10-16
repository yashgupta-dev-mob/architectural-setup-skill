import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/services/analytics/analytics_event_mapper.dart';
import 'package:mymali/core/services/analytics/app_events.dart';

void main() {
  group('GA4 names', () {
    test('the recommended events use GA4 own names', () {
      expect(ga4NameFor(AppEvents.addToCart), 'add_to_cart');
      expect(ga4NameFor(AppEvents.removeFromCart), 'remove_from_cart');
      expect(ga4NameFor(AppEvents.addToFavorite), 'add_to_wishlist');
      expect(ga4NameFor(AppEvents.productView), 'view_item');
      expect(ga4NameFor(AppEvents.productSearch), 'search');
      expect(ga4NameFor(AppEvents.checkoutStarted), 'begin_checkout');
      expect(ga4NameFor(AppEvents.paymentStarted), 'add_payment_info');
      expect(ga4NameFor(AppEvents.orderPlaced), 'purchase');
      expect(ga4NameFor(AppEvents.orderRated), 'order_rated');
    });

    test('Login and Verified keep apart: Verified is the GA4 login', () {
      expect(ga4NameFor(AppEvents.verified), 'login');
      expect(ga4NameFor(AppEvents.login), 'login_completed');
      expect(ga4NameFor(AppEvents.loginStarted), 'login_started');
    });

    test('any other name is lowercase snake_case', () {
      expect(ga4NameFor('Nav Bar Icon Tapped'), 'nav_bar_icon_tapped');
      expect(ga4NameFor('OTP Sent'), 'otp_sent');
      expect(ga4NameFor('Screen Load'), 'screen_load');
      expect(ga4NameFor('Garden Waitlist Joined'), 'garden_waitlist_joined');
    });

    test('a name is cut to 40 characters', () {
      final name = ga4NameFor('A very long event name that goes on and on');
      expect(name.length, lessThanOrEqualTo(40));
      expect(name, startsWith('a_very_long_event_name'));
    });
  });

  group('GA4 parameters', () {
    test('keys are snake_case, nulls and unsupported values are dropped', () {
      final event = ga4EventFor('Edit', {
        'itemId': 'p1',
        'Search Term': 'neem',
        'skipped': null,
        'map': {'a': 1},
      });

      expect(event.parameters, {'item_id': 'p1', 'search_term': 'neem'});
    });

    test('text is cut to 100 characters', () {
      final event = ga4EventFor('Edit', {'reason': 'x' * 250});

      expect((event.parameters['reason']! as String).length, 100);
    });

    test('booleans become 1 and 0, and a list is joined', () {
      final event = ga4EventFor('Edit', {
        'enabled': true,
        'off': false,
        'fields': ['full_name', 'email'],
      });

      expect(event.parameters, {
        'enabled': 1,
        'off': 0,
        'fields': 'full_name,email',
      });
    });

    test('value or amount also goes as value and currency, INR by default', () {
      final withValue = ga4EventFor(AppEvents.cartVisit, {'value': 499});
      expect(withValue.parameters['value'], 499.0);
      expect(withValue.parameters['currency'], 'INR');

      final withAmount = ga4EventFor(AppEvents.paymentCancelled, {
        'amount': 120,
        'currency': 'USD',
      });
      expect(withAmount.parameters['value'], 120.0);
      expect(withAmount.parameters['currency'], 'USD');
    });

    test('an event with no money gets no value or currency', () {
      final event = ga4EventFor(AppEvents.otpSent, {'channel': 'sms'});

      expect(event.parameters, {'channel': 'sms'});
    });

    test('no properties at all is an empty map', () {
      expect(ga4EventFor(AppEvents.logout, null).parameters, isEmpty);
    });
  });

  group('Meta names', () {
    test('the standard events use Meta names', () {
      expect(
        metaEventFor(AppEvents.verified, null).name,
        'fb_mobile_complete_registration',
      );
      expect(
        metaEventFor(AppEvents.addToCart, null).name,
        'fb_mobile_add_to_cart',
      );
      expect(
        metaEventFor(AppEvents.addToFavorite, null).name,
        'fb_mobile_add_to_wishlist',
      );
      expect(
        metaEventFor(AppEvents.productView, null).name,
        'fb_mobile_content_view',
      );
      expect(
        metaEventFor(AppEvents.productSearch, null).name,
        'fb_mobile_search',
      );
      expect(
        metaEventFor(AppEvents.checkoutStarted, null).name,
        'fb_mobile_initiated_checkout',
      );
      expect(
        metaEventFor(AppEvents.paymentStarted, null).name,
        'fb_mobile_add_payment_info',
      );
      expect(metaEventFor(AppEvents.orderRated, null).name, 'fb_mobile_rate');
    });

    test('any other event keeps the name as written', () {
      expect(metaEventFor(AppEvents.otpSent, null).name, 'OTP Sent');
      expect(metaEventFor(AppEvents.login, null).name, 'Login');
    });
  });

  group('Meta parameters', () {
    test('money is valueToSum, with fb_currency, never a _valueToSum key', () {
      final event = metaEventFor(AppEvents.checkoutStarted, {
        'value': 350,
        'items_count': 2,
      });

      expect(event.valueToSum, 350.0);
      expect(event.parameters['fb_currency'], 'INR');
      expect(event.parameters.containsKey('_valueToSum'), isFalse);
      expect(event.isPurchase, isFalse);
    });

    test('an item id also becomes the content id of a product', () {
      final event = metaEventFor(AppEvents.addToCart, {
        'item_id': 'sku-1',
        'price': 99,
        'quantity': 2,
      });

      expect(event.parameters['fb_content_id'], 'sku-1');
      expect(event.parameters['fb_content_type'], 'product');
      expect(event.parameters['price'], 99);
    });

    test('a search carries the search string', () {
      final event = metaEventFor(AppEvents.productSearch, {
        'search_term': 'neem oil',
      });

      expect(event.parameters['fb_search_string'], 'neem oil');
    });

    test('a rating is the value to sum, out of 5, for an order', () {
      final event = metaEventFor(AppEvents.orderRated, {
        'order_id': 'KMM-1',
        'rating': 4,
      });

      expect(event.valueToSum, 4.0);
      expect(event.parameters['fb_max_rating_value'], 5);
      expect(event.parameters['fb_content_type'], 'order');
    });

    test('Payment Started is a success', () {
      final event = metaEventFor(AppEvents.paymentStarted, {
        'value': 200,
        'method': 'online',
      });

      expect(event.parameters['fb_success'], 1);
      expect(event.valueToSum, 200.0);
    });

    test('Order Placed is a purchase with its revenue, under its own name', () {
      final event = metaEventFor(AppEvents.orderPlaced, {
        'order_id': 'KMM-9',
        'value': 899,
        'items_count': 3,
        'currency': 'INR',
      });

      expect(event.isPurchase, isTrue);
      expect(event.valueToSum, 899.0);
      expect(event.currency, 'INR');
      expect(event.parameters['order_id'], 'KMM-9');
    });

    test('a purchase with no value is logged with zero', () {
      expect(
        metaEventFor(AppEvents.orderPlaced, {'order_id': 'x'}).valueToSum,
        0,
      );
    });

    test('an event with no money has no value to sum', () {
      expect(
        metaEventFor(AppEvents.otpSent, {'channel': 'sms'}).valueToSum,
        null,
      );
    });
  });
}
