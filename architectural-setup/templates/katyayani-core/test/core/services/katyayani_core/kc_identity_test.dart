import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/services/katyayani_core/kc_identity.dart';

void main() {
  group('kcIdentityFor', () {
    test('keys the user by phone and sends the RN app traits', () {
      final identity = kcIdentityFor(
        phone: '+916261414316',
        fullName: '  Ram  Kumar Singh ',
        email: 'ram@example.com',
      )!;

      expect(identity.userId, '+916261414316');
      expect(identity.traits, {
        'name': 'Ram  Kumar Singh',
        'firstName': 'Ram',
        'lastName': 'Kumar Singh',
        'phone': '+916261414316',
        'country_code': '+91',
        'phone_number': '6261414316',
        'email': 'ram@example.com',
      });
    });

    test('adds the + to a phone stored without it', () {
      final identity = kcIdentityFor(phone: '916261414316')!;

      expect(identity.userId, '+916261414316');
      expect(identity.traits['country_code'], '+91');
    });

    test('a 10-digit phone gets country code +91', () {
      final identity = kcIdentityFor(phone: '6261414316')!;

      expect(identity.userId, '+6261414316');
      expect(identity.traits['country_code'], '+91');
      expect(identity.traits['phone_number'], '6261414316');
    });

    test('a one-word name has no last name; blanks are left out', () {
      final identity = kcIdentityFor(
        phone: '+916261414316',
        fullName: 'Ram',
        email: ' ',
      )!;

      expect(identity.traits['firstName'], 'Ram');
      expect(identity.traits.containsKey('lastName'), isFalse);
      expect(identity.traits.containsKey('email'), isFalse);
    });

    test('no phone means no identity, never another id', () {
      expect(kcIdentityFor(phone: ''), isNull);
      expect(kcIdentityFor(phone: '+ -'), isNull);
    });
  });
}
