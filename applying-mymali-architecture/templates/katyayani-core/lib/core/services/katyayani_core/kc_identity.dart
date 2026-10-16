/// Who the signed-in user is to Katyayani Core: the id and the profile
/// details sent with `identify`.
class KcIdentity {
  const KcIdentity({required this.userId, required this.traits});

  /// The phone in E.164, e.g. `+916261414316`. KC keys its profiles by it.
  final String userId;
  final Map<String, dynamic> traits;
}

/// The identity the React Native app sends (`RootNavigator.tsx`), built from
/// the user's [phone] and profile. Null when there is no phone: the user is
/// identified by phone only, never by another id.
///
/// KC stores the name in two fields, so it is sent split as well as whole.
/// Missing values are left out.
KcIdentity? kcIdentityFor({
  required String phone,
  String? fullName,
  String? email,
}) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  final phoneE164 = '+$digits';
  final phoneNumber = digits.length >= 10
      ? digits.substring(digits.length - 10)
      : null;
  final countryCode = phoneNumber == null
      ? null
      : '+${digits.length > 10 ? digits.substring(0, digits.length - 10) : '91'}';

  final name = fullName?.trim() ?? '';
  final parts = name.isEmpty ? const <String>[] : name.split(RegExp(r'\s+'));
  final trimmedEmail = email?.trim() ?? '';

  return KcIdentity(
    userId: phoneE164,
    traits: {
      if (name.isNotEmpty) 'name': name,
      if (parts.isNotEmpty) 'firstName': parts.first,
      if (parts.length > 1) 'lastName': parts.skip(1).join(' '),
      'phone': phoneE164,
      'country_code': ?countryCode,
      'phone_number': ?phoneNumber,
      if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
    },
  );
}
