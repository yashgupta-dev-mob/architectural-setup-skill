// GENERIC: tests the generic rules with literal names; the source app's special-name tables are empty in the template.
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/services/analytics/analytics_event_mapper.dart';

void main() {
  group('GA4 names', () {
    test('a name is lowercase snake_case', () {
      expect(ga4NameFor('Nav Bar Icon Tapped'), 'nav_bar_icon_tapped');
      expect(ga4NameFor('OTP Sent'), 'otp_sent');
      expect(ga4NameFor('Screen Load'), 'screen_load');
      expect(ga4NameFor('Added To Cart'), 'added_to_cart');
      expect(ga4NameFor('itemViewed'), 'item_viewed');
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
        'Search Term': 'mug',
        'skipped': null,
        'map': {'a': 1},
      });

      expect(event.name, 'edit');
      expect(event.parameters, {'item_id': 'p1', 'search_term': 'mug'});
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

    test('value or amount also goes as value and currency, the default '
        'currency when none is named', () {
      final withValue = ga4EventFor('Cart Visit', {'value': 499});
      expect(withValue.parameters['value'], 499.0);
      expect(withValue.parameters['currency'], defaultCurrency);

      final withAmount = ga4EventFor('Payment Cancelled', {
        'amount': 120,
        'currency': 'USD',
      });
      expect(withAmount.parameters['value'], 120.0);
      expect(withAmount.parameters['currency'], 'USD');
    });

    test('an event with no money gets no value or currency', () {
      final event = ga4EventFor('OTP Sent', {'channel': 'sms'});

      expect(event.parameters, {'channel': 'sms'});
    });

    test('no properties at all is an empty map', () {
      expect(ga4EventFor('Logout', null).parameters, isEmpty);
    });
  });

  group('Meta', () {
    test('an event keeps its name as written', () {
      expect(metaEventFor('OTP Sent', null).name, 'OTP Sent');
      expect(metaEventFor('Login', null).name, 'Login');
    });

    test('money is valueToSum, with fb_currency, never a _valueToSum key', () {
      final event = metaEventFor('Checkout Started', {
        'value': 350,
        'items_count': 2,
      });

      expect(event.valueToSum, 350.0);
      expect(event.parameters['fb_currency'], defaultCurrency);
      expect(event.parameters.containsKey('_valueToSum'), isFalse);
      expect(event.isPurchase, isFalse);
    });

    test('an item id also becomes the content id of a product', () {
      final event = metaEventFor('Added To Cart', {
        'item_id': 'sku-1',
        'price': 99,
        'quantity': 2,
      });

      expect(event.parameters['fb_content_id'], 'sku-1');
      expect(event.parameters['fb_content_type'], 'product');
      expect(event.parameters['price'], 99);
    });

    test('a search term is also the search string', () {
      final event = metaEventFor('Product Search', {'search_term': 'mug'});

      expect(event.parameters['fb_search_string'], 'mug');
    });

    test('an event with no money has no value to sum', () {
      expect(metaEventFor('OTP Sent', {'channel': 'sms'}).valueToSum, null);
    });
  });
}
